module BridgetownPrismic
  module API
    def configure_prismic
      Bridgetown.logger.info "Prismic API:", "Connecting to #{site.config.prismic_repository.yellow}..."
      site.config.prismic_api = Prismic.api("https://#{site.config.prismic_repository}.cdn.prismic.io/api")
      site.config.prismic_link_resolver ||= Prismic::LinkResolver.new(nil) do |link|
        if site.config.prismic_preview_token
          next "/preview/#{link.type}/#{link.id}"
        end

        if model_exists_for_prismic_type? link.type
          model_for_prismic_type(link.type).prismic_url(link)
        else
          "/"
        end
      end
    end

    def query_prismic(custom_type, options = {})
      Bridgetown.logger.info "Prismic API:", "Loading #{custom_type.to_s.green}..."

      BridgetownPrismic
        .api
        .query(Prismic::Predicates.at("document.type", custom_type.to_s), options)
        .results
    end

    def query_prismic_and_generate_resources_for(klass)
      query_options = {}

      query_prismic(klass.prismic_custom_type, query_options)
        .map { |doc| klass.import_prismic_document(doc) }
        .each(&:as_resource_in_collection)
    end

    def model_for_prismic_type(type)
      Bridgetown::Model::Base.descendants.find do |klass|
        klass.respond_to?(:prismic_custom_type) && klass.prismic_custom_type == type
      end
    end

    def prismic_types
      Bridgetown::Model::Base.descendants.map do |klass|
        klass.respond_to?(:prismic_custom_type) ? klass.prismic_custom_type : nil
      end.compact
    end

    def model_exists_for_prismic_type?(type)
      prismic_types.include? type.to_sym
    end
  end
end
