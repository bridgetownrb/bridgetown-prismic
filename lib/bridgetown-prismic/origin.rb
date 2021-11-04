module BridgetownPrismic
  class Origin < Bridgetown::Model::Origin
    # @return [Pathname]
    attr_reader :relative_path

    attr_reader :prismic_document

    def self.handle_scheme?(scheme) = scheme == "prismic"
    
    def self.import_document(document) = new("prismic://#{document.type}/#{document.id}", document).read

    def initialize(id, prismic_document = nil)
      self.id = id
      @relative_path = Pathname.new(id.delete_prefix("prismic://"))
      @prismic_document = prismic_document # could be nil, so model should load single preview instance
    end

    def verify_model?(klass)
      klass.prismic_custom_type.to_s == URI.parse(id).host
    end

    def read
      klass = Bridgetown::Model::Base.klass_for_id(id)
      if klass.name == "Bridgetown::Model::Base"
        raise "Could not find a specialized model class for ID `#{id}'"
      end

      unless klass.extensions_have_been_registered
        Bridgetown::Resource.register_extension klass
      end
      @data = klass.prismic_data(self, @prismic_document)
      @data[:_id_] = id
      @data[:_origin_] = self

      @data
    end

    def exists?
      false
    end
  end
end
