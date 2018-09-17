require 'rails_helper'
require 'gds_api/test_helpers/rummager'
require 'gds_api/test_helpers/content_store'

include ::GdsApi::TestHelpers::Rummager
include ::GdsApi::TestHelpers::ContentStore

RSpec.describe Taxonomy::OrganisationCount do
  describe "#organisation_counts" do
    let(:taxon_ids) { [SecureRandom.uuid, SecureRandom.uuid] }

    before :each do
      content_store_has_item('/', level_one_taxons.to_json, draft: true)
      content_store_has_item('/taxons/level_one', single_level_child_taxons.to_json, draft: true)
      stub_rummager({ 'aggregate_primary_publishing_organisation' => %r{\d+},  'filter_taxons' => [taxon_ids.first] },
                    rummager_body([{ slug: 'organisation1', count: 1 },
                                   { slug: 'organisation2', count: 2 },
                                   { slug: 'organisation3', count: 3 }]))
      stub_rummager({ 'aggregate_primary_publishing_organisation' => %r{\d+},  'filter_taxons' => [taxon_ids.second] },
                    rummager_body([{ slug: 'organisation2', count: 4 },
                                   { slug: 'organisation1', count: 5 }]))
    end

    it 'counts all tags to taxons per organisation' do
      results = Taxonomy::OrganisationCount.new.all_taggings_per_organisation
      sheet = results.first[:sheet]
      expected_results = [['organisation1', 6, '/taxons/child', 5, '/taxons/level_one', 1],
                          ['organisation2', 6, '/taxons/child', 4, '/taxons/level_one', 2],
                          ['organisation3', 3, '/taxons/level_one', 3]]
      expect(sheet[1..-1]).to match_array(expected_results)
      expect(results.first[:title]).to eq('taxon_title')
    end

    def rummager_body(slug_counts)
      {
        'aggregates' => {
          'primary_publishing_organisation' => {
            'options' => slug_counts.map do |slug_count|
              {
                'value' => {
                  'slug' => slug_count[:slug],
                },
                'documents' => slug_count[:count]
              }
            end
          }
        }
      }
    end

    def stub_rummager(query_hash, json_body)
      stub_request(:get, Regexp.new(Plek.new.find('rummager')))
        .with(query: hash_including(query_hash))
        .to_return(body: json_body.to_json)
    end

    def single_level_child_taxons
      {
        'base_path' => '/taxons/level_one',
        'content_id' => taxon_ids.first,
        'links' => {
          'child_taxons' => [
            {
              'base_path' => '/taxons/child',
              'content_id' => taxon_ids.second,
              'links' => {}
            }
          ]
        }
      }
    end

    def level_one_taxons
      {
        'base_path' => '/',
        'content_id' => 'hhhh',
        'links' => {
          'level_one_taxons' => [
            {
              'base_path' => '/taxons/level_one',
              'content_id' => taxon_ids.first,
              'title' => 'taxon_title'
            }
          ],
        }
      }
    end
  end
end