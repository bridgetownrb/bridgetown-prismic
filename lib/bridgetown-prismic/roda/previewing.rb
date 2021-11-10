module BridgetownPrismic
  module Roda
    module Previewing
      def prismic_preview_token
        request.params["token"] || request.cookies[Prismic::PREVIEW_COOKIE]
      end

      def save_prismic_preview_token
        bridgetown_site.config.prismic_preview_token = prismic_preview_token
      end

      def prismic_preview_redirect_url
        save_prismic_preview_token
        response.set_cookie Prismic::PREVIEW_COOKIE, bridgetown_site.config.prismic_preview_token
        BridgetownPrismic.api.preview_session(
          bridgetown_site.config.prismic_preview_token,
          bridgetown_site.config.prismic_link_resolver(),
          "/"
        )
      end

      def prismic_token_error_msg
        "A valid Prismic preview token was not provided."
      end
    end
  end
end
