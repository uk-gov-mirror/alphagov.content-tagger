require "rails_helper"
require "gds_api/test_helpers/publishing_api_v2"
include ::GdsApi::TestHelpers::PublishingApiV2

RSpec.describe Tagging::Untagger do
  before :each do
    @content_id = "51ac4247-fd92-470a-a207-6b852a97f2db"
  end
  it "untags a taxon" do
    publishing_api_has_links(
      "content_id" => @content_id,
      "version" => 5,
      "links" => {
        "taxons" => %w[aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb],
      },
    )

    stub_any_publishing_api_patch_links
    Tagging::Untagger.call(@content_id, %w[aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa])
    assert_publishing_api_patch_links(@content_id, "previous_version" => 5, "links" => { "taxons" => %w[bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb] })
  end
  it "retries 3 times" do
    publishing_api_has_links(content_id: @content_id, links: { taxons: %w[aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa] }, version: 5)

    stub_any_publishing_api_patch_links.and_raise(GdsApi::HTTPConflict).times(2).then.to_return(body: "{}")
    expect { Tagging::Untagger.call(@content_id, %w[aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa]) }.to_not raise_error

    stub_any_publishing_api_patch_links.and_raise(GdsApi::HTTPConflict).times(3).then.to_return(body: "{}")
    expect { Tagging::Untagger.call(@content_id, %w[aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa]) }.to raise_error(GdsApi::HTTPConflict)
  end
end
