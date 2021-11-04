module Bridgetown
  module Utils
    class PrismicData < RubyFrontMatter
      def with_links = Bridgetown::Current.site.config.prismic_link_resolver

      def provide_data(&block)
        if @provided_called
          return PrismicData.new(scope: @scope).tap { |fm| fm.instance_exec(&block) }.to_h
        end

        @provided_called = true
        self.instance_exec(&block)

        nil
      end

      def reset_stack
        @provided_called = false
      end
    end
  end
end
