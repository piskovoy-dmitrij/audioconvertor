# bundle exec sidekiq --queue elasticsearch --verbose
# rake environment elasticsearch:import:model CLASS='User' BATCH=100 FORCE=y
#
module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    index_name [Rails.application.engine_name, self.to_s.downcase, Rails.env].join('_')

    after_commit lambda { Indexer.perform_async(:index, self.class.to_s, self.id) }, on: :create
    after_commit lambda { Indexer.perform_async(:update, self.class.to_s, self.id) }, on: :update
    after_commit lambda { Indexer.perform_async(:delete, self.class.to_s, self.id) }, on: :destroy

    def self.set_es_filters(f)

      @search_definition[:filter][:and] ||= []
      @search_definition[:filter][:and] |= [f]
    end

    def self.search(query, options={})

      @search_definition = {
          query: {},

          highlight: {
              pre_tags: ['<mark>'],
              post_tags: ['</mark>'],
              fields: {}
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

      @search_definition[:query] = {match_all: {}}

      options = self.set_needed_filters(query, options) if self.methods().include?(:set_needed_filters)

      options.each do |key, value|
        next unless @search_definition.include?(key)

        f = {term: {key.to_sym => value}}

        self.set_es_filters(f)
      end

      __elasticsearch__.search(@search_definition)
    end
  end
end
