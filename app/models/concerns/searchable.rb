# bundle exec sidekiq --queue elasticsearch --verbose
# rake environment elasticsearch:import:model CLASS='User' BATCH=100 FORCE=y
#
module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    # Customize the index name
    #
    index_name [Rails.application.engine_name, self.to_s.downcase, Rails.env].join('_')

    # settings index: {number_of_shards: 1, number_of_replicas: 0} do
    #   mapping do
    #     indexes :name, type: 'multi_field' do
    #       indexes :name, analyzer: 'snowball'
    #       indexes :tokenized, analyzer: 'simple'
    #     end
    #   end
    # end

    # Set up callbacks for updating the index on model changes
    #
    after_commit lambda { Indexer.perform_async(:index, self.class.to_s, self.id) }, on: :create
    after_commit lambda { Indexer.perform_async(:update, self.class.to_s, self.id) }, on: :update
    after_commit lambda { Indexer.perform_async(:delete, self.class.to_s, self.id) }, on: :destroy

    # Customize the JSON serialization for Elasticsearch
    #
    def as_indexed_json(options={})
      self.as_json(
          include: {
              audios: {only: [:title]},
              friendships: {only: [:friend_id, :is_confirmed]},
          }
      )
    end

    __set_filters = lambda do |key, f|

      @search_definition[:filter][:and] ||= []
      @search_definition[:filter][:and] |= [f]

      @search_definition[:facets][key.to_sym][:facet_filter][:and] ||= []
      @search_definition[:facets][key.to_sym][:facet_filter][:and] |= [f]
    end

    # Search in title and content fields for `query`, include highlights in response
    #
    # @param query [String] The user query
    # @return [Elasticsearch::Model::Response::Response]
    #
    def self.search(query, options={})

      @search_definition = {
          query: {},

          highlight: {
              pre_tags: ['<mark>'],
              post_tags: ['</mark>'],
              fields: {
                  name: {number_of_fragments: 0}
              }
          },

          filter: {}
      }


      if options[:sortby]
        sort = 'desc'
        if options[:sort]
          sort = options[:sort]
          options.delete(:sort)
        end

        @search_definition[:sort] = {options[:sortby] => sort}
        @search_definition[:track_scores] = true

        options.delete(:sortby)
      end

      options = self.set_needed_filters(query, options)

      options.delete(:name)

      options.each do |key, value|
        next unless @search_definition.include?(key)

        f = {term: {key.to_sym => value}}

        __set_filters.(key, f)
      end

      __elasticsearch__.search(@search_definition)
    end

    def self.set_needed_filters(query, options)
      unless query.blank?
        @search_definition[:query] = {
            bool: {
                should: [
                    {
                        match: {
                            name: query
                        }
                    }
                ]
            }
        }
      else
        @search_definition[:query] = {match_all: {}}
        @search_definition[:sort] = {name: 'asc'}
      end

      if options[:audio]
        f = {term: {'audios.title' => options[:audio]}}

        __set_filters.(:audios, f)
        options.delete(:audio)
      end

      if options[:friendship]
        f = {term: {'friendships.friend_id' => options[:friendship]}}

        __set_filters.(:friendships, f)
        options.delete(:friendship)
      end

      options
    end
  end
end
