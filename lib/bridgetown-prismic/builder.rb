# frozen_string_literal: true

module BridgetownPrismic
  class Builder < Bridgetown::Builder
    include BridgetownPrismic::API

    def build
      configure_prismic # in API module

      return if site.ssr?

      load_prismic_documents
    end

    def load_prismic_documents
      batches = []
      Async do |task|
        prismic_types.map do |type|
          task.async do
            Bridgetown::Current.site = site # ensure fiber has copy of the current site
            klass = model_for_prismic_type(type)
            batches.push [klass, query_prismic(klass.prismic_custom_type, {})]
          end
        end
      end

      batches.each do |batch|
        klass, docs = batch
        docs.map { |doc| klass.import_prismic_document(doc) }.each(&:as_resource_in_collection)
      end
    end
  end
end

BridgetownPrismic::Builder.register
