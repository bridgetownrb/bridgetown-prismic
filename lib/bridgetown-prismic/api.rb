# frozen_string_literal: true

module BridgetownPrismic
  module API
    def configure_prismic # rubocop:disable Metrics/AbcSize
      Bridgetown.logger.info "Prismic API:",
                             "Connecting to #{site.config.prismic_repository.yellow}..."
      site.config.prismic_api = Prismic.api("https://#{site.config.prismic_repository}.cdn.prismic.io/api")
      site.config.prismic_link_resolver ||= Prismic::LinkResolver.new(nil) do |link|
        next "/preview/#{link.type}/#{link.id}" if site.config.prismic_preview_token

        if model_exists_for_prismic_type? link.type
          model_for_prismic_type(link.type).prismic_url(link)
        else
          "/"
        end
      end
    end

    def query_prismic(custom_type, options = {})
      Bridgetown.logger.info "Prismic API:", "Loading #{custom_type.to_s.green}..."

      results = []
      page = 1
      finalpage = false
      options["pageSize"] ||= 100 # pull in as much data as possible for a single request

      until finalpage
        options["page"] = page

        response = BridgetownPrismic
          .api
          .query(Prismic::Predicates.at("document.type", custom_type.to_s), options)

        results += response.results
        if response.total_pages > page
          page += 1
        else
          finalpage = true
        end
      end

      results
    end

    def query_prismic_and_generate_resources_for(klass)
      query_options = {}

      query_prismic(klass.prismic_custom_type, query_options)
        .map { |doc| klass.import_prismic_document(doc) }
        .each(&:as_resource_in_collection)
    end

    def model_for_prismic_type(type)
      Bridgetown::Model::Base.descendants.find do |klass|
        klass.respond_to?(:prismic_custom_type) && klass.prismic_custom_type == type.to_sym
      end
    end

    def prismic_types
      Bridgetown::Model::Base.descendants.filter_map do |klass|
        klass.respond_to?(:prismic_custom_type) ? klass.prismic_custom_type : nil
      end
    end

    def model_exists_for_prismic_type?(type)
      prismic_types.include? type.to_sym
    end
  end
end
