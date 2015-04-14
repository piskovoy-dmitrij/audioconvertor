# bundle exec sidekiq --queue elasticsearch --verbose
# rake environment elasticsearch:import:model CLASS='User' BATCH=100 FORCE=y
#
module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    # Customize the index name
    #
    index_name [Rails.application.engine_name, Rails.env].join('_')

    # Set up index configuration and mapping
    #
    settings index: {number_of_shards: 1, number_of_replicas: 0} do
      mapping do
        indexes :name, type: 'multi_field' do
          indexes :name, analyzer: 'snowball'
          indexes :tokenized, analyzer: 'simple'
        end

        indexes :birth_date, type: 'date'

        indexes :audios do
          indexes :title, type: 'multi_field' do
            indexes :title, analyzer: 'snowball'
            indexes :tokenized, analyzer: 'simple'
          end
        end

        indexes :friendships do
          indexes :user_id, type: 'integer'
        end
      end
    end

    # Set up callbacks for updating the index on model changes
    #
    after_commit lambda { Indexer.perform_async(:index, self.class.to_s, self.id) }, on: :create
    after_commit lambda { Indexer.perform_async(:update, self.class.to_s, self.id) }, on: :update
    after_commit lambda { Indexer.perform_async(:delete, self.class.to_s, self.id) }, on: :destroy

    # Customize the JSON serialization for Elasticsearch
    #
    def as_indexed_json(options={})
      self.as_json(
          include: {audios: {methods: [:title], only: [:title]}}
      )
    end

    # Search in title and content fields for `query`, include highlights in response
    #
    # @param query [String] The user query
    # @return [Elasticsearch::Model::Response::Response]
    #
    def self.search(query, options={})

      # Prefill and set the filters (top-level `filter` and `facet_filter` elements)
      #
      __set_filters = lambda do |key, f|

        @search_definition[:filter][:and] ||= []
        @search_definition[:filter][:and] |= [f]

        @search_definition[:facets][key.to_sym][:facet_filter][:and] ||= []
        @search_definition[:facets][key.to_sym][:facet_filter][:and] |= [f]
      end

      @search_definition = {
          query: {},

          highlight: {
              pre_tags: ['<mark>'],
              post_tags: ['</mark>'],
              fields: {
                  name: {number_of_fragments: 0}
              }
          },

          filter: {},

          facets: {
              audios: {
                  terms: {
                      field: 'audios.title'
                  },
                  facet_filter: {}
              },
              friendships: {
                  terms: {
                      field: 'friendships.friend_id'
                  },
                  facet_filter: {}
              },
              birthdate: {
                  date_histogram: {
                      field: 'birth_date',
                      interval: 'year'
                  },
                  facet_filter: {}
              }
          }
      }

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

        __set_filters.(:birthdate, f)
        __set_filters.(:friendships, f)
      end

      if options[:birthdate_year]
        f = {
            range: {
                published_on: {
                    gte: options[:birthdate_year],
                    lte: "#{options[:birthdate_year]}||+1y"
                }
            }
        }

        __set_filters.(:audios, f)
        __set_filters.(:friendships, f)
      end

      if options[:friendship]
        f = {term: {'friendships.friend_id' => options[:friendship]}}

        __set_filters.(:birthdate, f)
        __set_filters.(:audios, f)
      end

      if options[:sort]
        @search_definition[:sort] = {options[:sort] => 'asc'}
        @search_definition[:track_scores] = true
      end

      unless query.blank?
        @search_definition[:suggest] = {
            text: query,
            suggest_name: {
                term: {
                    field: 'name.tokenized',
                    suggest_mode: 'always'
                }
            }
        }
      end

      __elasticsearch__.search(@search_definition)
    end
  end
end
