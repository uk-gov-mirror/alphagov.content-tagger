require "rails_helper"

RSpec.feature "Tagging History", type: :feature do
  include ContentItemHelper
  include PublishingApiHelper

  scenario "Show added link changes" do
    given_there_are_some_added_link_changes
    when_i_visit_the_tagging_history_index_page
    then_i_see_a_list_of_added_link_changes
  end

  scenario "Show removed link changes" do
    given_there_are_some_removed_link_changes
    when_i_visit_the_tagging_history_index_page
    then_i_see_a_list_of_removed_link_changes
  end

  scenario "Show user and organisation" do
    given_there_are_some_link_changes_with_user_data
    when_i_visit_the_tagging_history_index_page
    then_i_see_the_user_and_organisation
  end

  scenario "Show changes for an individual taxon" do
    given_that_the_publishing_api_has_an_individual_taxon
    given_there_are_some_link_changes_for_an_individual_taxon
    when_i_visit_the_tagging_history_show_page
    then_i_see_the_link_changes_for_the_individual_taxon
  end

  private

  def given_there_are_some_added_link_changes
    stub_link_changes_request(added_link_changes)
  end

  def given_there_are_some_removed_link_changes
    stub_link_changes_request(removed_link_changes)
  end

  def given_there_are_some_link_changes_with_user_data
    stub_link_changes_request(link_changes_with_user_data)
  end

  def given_that_the_publishing_api_has_an_individual_taxon
    publishing_api_has_item(individual_taxon)
  end

  def given_there_are_some_link_changes_for_an_individual_taxon
    stub_link_changes_request(
      link_changes_for_an_individual_taxon,
      link_types: ['taxons'],
      target_content_ids: [individual_taxon[:content_id]]
    )
  end

  def when_i_visit_the_tagging_history_index_page
    visit tagging_history_index_path
  end

  def when_i_visit_the_tagging_history_show_page
    visit tagging_history_path(individual_taxon[:content_id])
  end

  def then_i_see_a_list_of_added_link_changes
    page.all('tbody tr').zip(added_link_changes).each do |tr, link_change|
      expect(tr).to have_link(
        link_change['source']['title'],
        href: tagging_path(link_change['source']['content_id'])
      )
      expect(tr).to have_link(
        link_change['target']['title'],
        href: tagging_history_path(link_change['target']['content_id'])
      )
      expect(tr).to have_text('tagged to')
      expect(tr).to have_text('Unknown user')
    end
  end

  def then_i_see_a_list_of_removed_link_changes
    page.all('tbody tr').zip(removed_link_changes).each do |tr, link_change|
      expect(tr).to have_link(
        link_change['source']['title'],
        href: tagging_path(link_change['source']['content_id'])
      )
      expect(tr).to have_link(
        link_change['target']['title'],
        href: tagging_history_path(link_change['target']['content_id'])
      )
      expect(tr).to have_text('removed')
      expect(tr).to have_text('Unknown user')
    end
  end

  def then_i_see_the_user_and_organisation
    page.all('tbody tr').each do |tr|
      expect(tr).to have_text('Foo')
      expect(tr).to have_text('Bar baz')
    end
  end

  def then_i_see_the_link_changes_for_the_individual_taxon
    page.all('tbody tr').zip(link_changes_for_an_individual_taxon).each do |tr, link_change|
      expect(tr).to have_link(
        link_change['source']['title'],
        href: tagging_path(link_change['source']['content_id'])
      )
    end
  end

  def stub_link_changes_request(link_changes, params = { link_types: ['taxons'] })
    stub_request(:get, "#{PUBLISHING_API}/v2/links/changes?#{params.to_query}")
      .to_return(body: { link_changes: link_changes }.to_json)
  end

  def link_changes_with_user_data
    user = FactoryGirl.create(:user, name: 'Foo', organisation_slug: 'bar-baz')
    @_link_changes_with_user_data ||= FactoryGirl.build_list(:link_change, 3, change: 'add', user_uid: user.uid)
  end

  def added_link_changes
    @_added_link_changes ||= FactoryGirl.build_list(:link_change, 3, change: 'add')
  end

  def removed_link_changes
    @_removed_link_changes ||= FactoryGirl.build_list(:link_change, 3, change: 'remove')
  end

  def individual_taxon
    basic_content_item("Taxon 1")
  end

  def link_changes_for_an_individual_taxon
    @_link_changes_for_an_individual_taxon ||= FactoryGirl.build_list(
      :link_change,
      3,
      target: { content_id: individual_taxon[:content_id] }
    )
  end
end