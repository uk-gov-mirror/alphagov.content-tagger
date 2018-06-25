module Taxonomy
  class ShowPage
    delegate :content_id, :draft?, :published?, :unpublished?, :redirected?,
             :draft_and_published_editions_exist?, :redirect_to, :base_path, to: :taxon

    attr_reader :taxon, :visualisation

    def initialize(taxon, visualisation = "taxonomy_tree")
      @taxon = taxon
      @visualisation = visualisation
    end

    def title
      taxon.internal_name
    end

    def publication_state_display_name
      publication_state_name.humanize.downcase
    end

    def publication_state_name
      return "published_with_new_draft" if draft_and_published_editions_exist?

      {
        "draft" => "draft",
        "published" => "published",
        "unpublished" => "deleted",
      }.fetch(taxon.publication_state)
    end

    def taxon_content_id
      taxon.content_id
    end

    def taxonomy_tree
      @taxonomy_tree ||= Taxonomy::ExpandedTaxonomy.new(taxon_content_id).build
    end

    def taxonomy_size
      @taxonomy_size ||= Taxonomy::TaxonsWithContentCountPresenter.new(
        Taxonomy::TaxonsWithContentCount.new(taxon)
      )
    end

    def children
      @children ||= taxonomy_tree.child_expansion.children
    end

    def chevron_hierarchy
      taxonomy_tree.parent_expansion.map(&:title).reverse.join(" > ")
    end

    def tagged
      @tagged ||= begin
        return [] if taxon.unpublished?

        Services.publishing_api.get_linked_items(
          taxon.content_id,
          link_type: "taxons",
          fields: %w[title content_id base_path document_type]
        )
      end
    end

    def taxons_for_select
      Linkables.new.taxons(exclude_ids: taxon_content_id)
    end

    def associated_taxons
      taxonomy_tree.associated_taxons
    end

    def taxon_deletable?
      taxon.content_id != GovukTaxonomy::ROOT_CONTENT_ID
    end

    def email_subscribers
      @email_subscribers ||= begin
        begin
          email_lists = Services.email_alert_api.find_subscriber_list("links" => { taxon_tree: [taxon.content_id] })
          email_lists.dig("subscriber_list", "active_subscriptions_count")
        rescue GdsApi::HTTPNotFound
          "0"
        rescue GdsApi::BaseError, SocketError => e
          GovukError.notify(e)
          "?"
        end
      end
    end
  end
end
