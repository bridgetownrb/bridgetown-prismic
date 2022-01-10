# This is an example of how to build a model object suitable for Prismic
class Post < Bridgetown::Model::Base
  class << self
    def collection_name = :posts
    def prismic_custom_type = :blog_post
    def prismic_slug(doc) = doc.slug
    def prismic_url(doc)
      doc_date = doc["blog_post.optional_publish_datetime"]&.value&.localtime || doc.first_publication_date
      ymd = "#{doc_date.strftime("%Y")}/#{doc_date.strftime("%m")}/#{doc_date.strftime("%d")}"
      "/#{ymd}/#{prismic_slug(doc)}/"
    end
  end

  def self.process_prismic_document(doc)
    provide_data do
      # Variable        # Prismic Field                 # Formatting
      id                doc.id
      slug from: ->     { prismic_slug(doc) }
      type              doc.type
      created_at        doc.first_publication_date
      date              doc["blog_post.optional_publish_datetime"]&.value&.localtime || created_at

      layout            :post
      title             doc["blog_post.title"]          .as_text
      subtitle          doc["blog_post.subtitle"]       &.as_text
      author            doc["blog_post.author_name"]    &.as_text
      featured_image    doc["blog_post.featured_image"] &.url

      content           doc["blog_post.post_body"]      &.as_html with_links
    end
  end
end
