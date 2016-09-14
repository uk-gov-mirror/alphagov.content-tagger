class TaxonsValidator < ActiveModel::Validator
  def validate(record)
    return if record.taxons.empty?

    unless (record.taxons - known_taxon_content_ids).empty?
      record.errors[:taxons] << I18n.t('tag_import.errors.invalid_taxons_found')
    end
  end

private

  def known_taxon_content_ids
    Taxonomy::FetchAllTaxons.new.taxon_content_ids
  end
end
