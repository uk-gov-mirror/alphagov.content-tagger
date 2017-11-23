require 'rails_helper'
include Taxonomy

RSpec.describe Taxonomy::TaxonomyQuery do
  def query
    TaxonomyQuery.new(%w[content_id base_path])
  end
  describe '#root_taxons' do
    it 'returns an empty array' do
      expect(Services.content_store).to receive(:content_item).with('/').and_return no_taxons
      expect(query.root_taxons).to be_empty
    end

    it 'returns root taxons' do
      expect(Services.content_store).to receive(:content_item).with('/').and_return root_taxons
      expect(query.root_taxons)
        .to match_array [{ 'content_id' => 'rrrr_aaaa', 'base_path' => '/taxons/root_taxon_a' },
                         { 'content_id' => 'rrrr_bbbb', 'base_path' => '/taxons/root_taxon_b' }]
    end
  end

  describe '#child_taxons' do
    it 'returns an empty array' do
      expect(Services.content_store).to receive(:content_item).with('/taxons/root_taxon').and_return no_taxons
      expect(query.child_taxons('/taxons/root_taxon')).to be_empty
    end
    it 'returns an single level of taxons' do
      expect(Services.content_store).to receive(:content_item).with('/taxons/root_taxon').and_return single_level_child_taxons('rrrr', 'aaaa', 'bbbb')
      expect(query.child_taxons('/taxons/root_taxon'))
        .to match_array [{ 'content_id' => 'aaaa', 'base_path' => '/taxons/aaaa', 'parent_content_id' => 'rrrr' },
                         { 'content_id' => 'bbbb', 'base_path' => '/taxons/bbbb', 'parent_content_id' => 'rrrr' }]
    end
    it 'returns multiple levels of taxons' do
      expect(Services.content_store).to receive(:content_item).with('/taxons/root_taxon').and_return multi_level_child_taxons
      expect(query.child_taxons('/taxons/root_taxon'))
        .to match_array [{ 'content_id' => 'aaaa', 'base_path' => '/root_taxon/taxon_a', 'parent_content_id' => 'rrrr' },
                         { 'content_id' => 'aaaa_1111', 'base_path' => '/root_taxon/taxon_1', 'parent_content_id' => 'aaaa' },
                         { 'content_id' => 'aaaa_2222', 'base_path' => '/root_taxon/taxon_2', 'parent_content_id' => 'aaaa' }]
    end
  end

  describe '#content_tagged_to_taxons' do
    it 'returns an empty array' do
      expect(TaxonomyQuery.new.content_tagged_to_taxons([], slice_size: 50)).to eq([])
    end
    it 'returns content tagged to taxons' do
      stub_rummager({ filter_taxons: %w[taxon_id_1 taxon_id_2] },
                    [{ 'content_id' => 'content_id_1' }, { 'content_id' => 'content_id_2' }])
      stub_rummager({ filter_taxons: ['taxon_id_3'] },
                    [{ 'content_id' => 'content_id_3' }])

      expect(query.content_tagged_to_taxons(%w[taxon_id_1 taxon_id_2 taxon_id_3], slice_size: 2))
        .to eq(%w[content_id_1 content_id_2 content_id_3])
    end
    it 'removes duplicates' do
      stub_rummager({}, [{ 'content_id' => 'content_id_1' }, { 'content_id' => 'content_id_1' }])
      expect(query.content_tagged_to_taxons(['id'])).to eq(['content_id_1'])
    end

    def stub_rummager(query_hash, return_values)
      stub_request(:get, Regexp.new(Plek.new.find('rummager')))
        .with(query: hash_including(query_hash))
        .to_return(body: { 'results' => return_values }.to_json)
    end
  end

  describe '#taxons_per_level' do
    context 'there are no root taxons' do
      before :each do
        allow(Services.content_store).to receive(:content_item).with('/').and_return no_taxons
      end
      it 'returns an empty taxonomy' do
        expect(query.taxons_per_level).to be_empty
      end
    end

    context 'there are root taxons and one level of children' do
      before :each do
        allow(Services.content_store).to receive(:content_item).with('/').and_return root_taxons
        allow(Services.content_store).to receive(:content_item).with('/taxons/root_taxon_a')
                                           .and_return single_level_child_taxons('root_taxon_a', 'child_a_1', 'child_a_2')
        allow(Services.content_store).to receive(:content_item).with('/taxons/root_taxon_b')
                                           .and_return single_level_child_taxons('root_taxon_b', 'child_b_1', 'child_b_2')
      end

      it 'returns root taxons in the first array' do
        expect(query.taxons_per_level.first)
          .to match_array [{ 'content_id' => 'root_taxon_a', 'base_path' => '/taxons/root_taxon_a' },
                           { 'content_id' => 'root_taxon_b', 'base_path' => '/taxons/root_taxon_b' }]
      end

      it 'returns the first level of child taxons after the root taxons' do
        expect(query.taxons_per_level.second)
          .to match_array [{ 'content_id' => 'child_a_1', 'base_path' => '/taxons/child_a_1' },
                           { 'content_id' => 'child_a_2', 'base_path' => '/taxons/child_a_2' },
                           { 'content_id' => 'child_b_1', 'base_path' => '/taxons/child_b_1' },
                           { 'content_id' => 'child_b_2', 'base_path' => '/taxons/child_b_2' }]
      end
    end

    context 'there are root taxons and two levels of children' do
      before :each do
        allow(Services.content_store).to receive(:content_item).with('/').and_return root_taxon
        allow(Services.content_store).to receive(:content_item).with('/taxons/root_taxon')
                                           .and_return multi_level_child_taxons
      end
      it 'returns three levels' do
        expect(query.taxons_per_level.size).to eq(3)
      end
    end
  end

  def multi_level_child_taxons
    {
      "base_path" => "/taxons/root_taxon",
      "content_id" => "rrrr",
      "links" => {
        "child_taxons" => [
          {
            "base_path" => "/root_taxon/taxon_a",
            "content_id" => "aaaa",
            "links" => {
              "child_taxons" => [
                {
                  "base_path" => "/root_taxon/taxon_1",
                  "content_id" => "aaaa_1111",
                  "links" => {}
                },
                {
                  "base_path" => "/root_taxon/taxon_2",
                  "content_id" => "aaaa_2222",
                  "links" => {}
                }
              ]
            }
          }
        ]
      }
    }
  end

  def single_level_child_taxons(root, child_1, child_2)
    {
      "base_path" => "/taxons/#{root}",
      "content_id" => root.to_s,
      "links" => {
        "child_taxons" => [
          {
            "base_path" => "/taxons/#{child_1}",
            "content_id" => child_1.to_s,
            "links" => {}
          },
          {
            "base_path" => "/taxons/#{child_2}",
            "content_id" => child_2.to_s,
            "links" => {}
          }
        ]
      }
    }
  end

  def root_taxons
    {
      "base_path" => "/",
      "content_id" => "hhhh",
      "links" => {
        "root_taxons" => [
          {
            "base_path" => "/taxons/root_taxon_a",
            "content_id" => "rrrr_aaaa"
          },
          {
            "base_path" => "/taxons/root_taxon_b",
            "content_id" => "rrrr_bbbb"
          }
        ],
      }
    }
  end

  def root_taxon
    {
      "links" => {
        "root_taxons" => [
          {
            "base_path" => "/taxons/root_taxon",
            "content_id" => "rrrr"
          }
        ]
      }
    }
  end

  def no_taxons
    {
      "base_path" => "/",
      "content_id" => "f3bbdec2-0e62-4520-a7fd-6ffd5d36e03a"
    }
  end
end
