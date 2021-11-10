class SingleTestPage < Bridgetown::Model::Base
  class << self
    def collection_name = :pages
    def prismic_custom_type = :test_page
    def prismic_slug(doc) = doc.slug
    def prismic_url(doc) = "/test-page"
  end

  def self.process_prismic_document(doc)
    provide_data do
      # Variable        # Prismic Field                 # Formatting
      id                doc.id
      slug from: ->     { "#{prismic_slug(doc)}.html" }
      type              doc.type
      created_at        doc.first_publication_date

      title             doc["test_page.title"]          .as_text

      content           doc["test_page.body"]           .as_html with_links
    end
  end
end
