require "rails_helper"

RSpec.feature "Delete Taxon", type: :feature do
  include ContentItemHelper
  include PublishingApiHelper

  scenario "deleting a taxon with no children or tagged content" do
    given_a_taxon_with_no_children
    when_i_visit_the_taxon_page
    when_i_click_delete_taxon
    then_i_see_a_basic_prompt_to_delete
    when_i_confirm_deletion
    then_the_taxon_is_deleted
  end

  scenario "deleting a taxon with children" do
    given_a_taxon_with_children
    when_i_visit_the_taxon_page
    then_i_expect_to_see_the_child_taxon
    when_i_click_delete_taxon
    then_i_see_a_prompt_to_delete_with_a_warning_message
    when_i_confirm_deletion
    then_the_taxon_is_deleted
  end

  scenario "deleting a taxon with tagged content" do
    given_a_taxon_with_tagged_content
    when_i_visit_the_taxon_page
    then_i_expect_to_see_the_tagged_content
    when_i_click_delete_taxon
    then_i_see_a_prompt_to_delete_with_a_warning_message
    when_i_confirm_deletion
    then_the_taxon_is_deleted
  end

  def given_a_taxon_with_no_children
    @taxon_content_id = SecureRandom.uuid
    @taxon = content_item_with_details(
      "Taxon 1",
      other_fields: { content_id: @taxon_content_id }
    )
    publishing_api_has_item(@taxon)

    publishing_api_has_links(
      content_id: @taxon_content_id,
      links: {}
    )
    publishing_api_has_expanded_links(
      content_id: @taxon_content_id,
      expanded_links: {}
    )
    publishing_api_has_linked_items(
      [],
      content_id: @taxon_content_id,
      link_type: "taxons"
    )
  end

  def given_a_taxon_with_children
    given_a_taxon_with_no_children
    add_a_child_taxon
  end

  def given_a_taxon_with_tagged_content
    given_a_taxon_with_no_children
    add_tagged_content
  end

  def when_i_visit_the_taxon_page
    visit taxon_path(@taxon_content_id)
  end

  def when_i_click_delete_taxon
    click_on "Delete taxon"
  end

  def then_i_see_a_basic_prompt_to_delete
    expect(page).to have_text('You are about to delete "Taxon 1"')
    expect(page).to_not have_text("Before you delete this taxon, make sure you've")
    expect(page).to have_link('Cancel')
    expect(page).to have_link('I understand and I want to delete it')
  end

  def when_i_confirm_deletion
    @unpublish_request = stub_publishing_api_unpublish(@taxon_content_id, body: { type: :gone }.to_json)
    publishing_api_has_taxons([])
    click_on "I understand and I want to delete it!"
  end

  def then_the_taxon_is_deleted
    expect(@unpublish_request).to have_been_made
    expect(page).to_not have_content @taxon.fetch(:title)
  end

  def then_i_expect_to_see_the_child_taxon
    within(".taxonomy-tree") do
      expect(page).to have_text('A child taxon')
    end
  end

  def then_i_expect_to_see_the_tagged_content
    within(".tagged-content") do
      expect(page).to have_text('tagged content')
    end
  end

  def then_i_see_a_prompt_to_delete_with_a_warning_message
    expect(page).to have_text('You are about to delete "Taxon 1"')
    expect(page).to have_text("Before you delete this taxon, make sure you've")
    expect(page).to have_link('Cancel')
    expect(page).to have_link('I understand and I want to delete it')
  end

private

  def add_a_child_taxon
    @child_taxon_content_id = SecureRandom.uuid
    @child_taxon = content_item_with_details(
      "A child taxon",
      other_fields: { content_id: @child_taxon_content_id }
    )
    #
    # Stub realistic values for links and expanded links to correctly render
    # the tree on the taxon show page
    publishing_api_has_links(
      content_id: @taxon_content_id,
      links: {
        child_taxons: [@child_taxon_content_id],
      }
    )
    publishing_api_has_expanded_links(
      content_id: @taxon_content_id,
      expanded_links: {
        child_taxons: [@child_taxon],
      }
    )
    publishing_api_has_expanded_links(
      content_id: @child_taxon_content_id,
      expanded_links: {
        parent_taxons: [@taxon]
      }
    )
  end

  def add_tagged_content
    publishing_api_has_linked_items(
      [basic_content_item("tagged content")],
      content_id: @taxon_content_id,
      link_type: "taxons"
    )
  end
end