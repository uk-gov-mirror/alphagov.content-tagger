desc "copy taxons title field to internal name"
task copy_taxons_title: :environment do
  total = RemoteTaxons.new.search.search_response["total"]
  taxons = RemoteTaxons.new.search(per_page: total).taxons

  taxons.each do |taxon|
    next unless taxon.internal_name.empty?

    taxon.internal_name = taxon.title
    Taxonomy::PublishTaxon.call(taxon: taxon)
  end
end
