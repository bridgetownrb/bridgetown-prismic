# frozen_string_literal: true

require "bridgetown"
require "prismic"
require "async"

module BridgetownPrismic
  def self.api = Bridgetown::Current.site.config.prismic_api
end

require_relative "bridgetown-prismic/api"
require_relative "bridgetown-prismic/builder"
require_relative "bridgetown-prismic/origin"
require_relative "bridgetown/utils/prismic_data"

Bridgetown::Model::Base.class_eval do
  class << self
    attr_accessor :extensions_have_been_registered
  end

  def self.import_prismic_document(doc) = new(BridgetownPrismic::Origin.import_document(doc))
  def self.with_links = Bridgetown::Current.site.config.prismic_link_resolver
  def self.provide_data(&block)
    @prismic_data.provide_data(&block)
  end

  def self.prismic_data(origin, doc = nil)
    site = Bridgetown::Current.site
    @prismic_data = Bridgetown::Utils::PrismicData.new(scope: self)

    unless doc
      prismic_id = origin.id.split("/").last
      # note: if site.config.prismic_preview_token isn't set, it will default to master (published) ref
      doc = site.config.prismic_api.getByID(prismic_id, { ref: site.config.prismic_preview_token })
    end

    @prismic_data = @prismic_data.tap do
      process_prismic_document(doc)
    end.to_h

    if @prismic_data[:content]
      @prismic_data[:_content_] = @prismic_data[:content]
      @prismic_data.delete :content
    end
    @prismic_data[:_collection_] = Bridgetown::Current.site.collections[collection_name]
    @prismic_data[:prismic_doc] = doc if Bridgetown.env.development? # good for debugging

    @prismic_data.tap do # return data while setting the ivar to nil
      @prismic_data = nil
    end
  end

  def prismic_document
    return nil unless BridgetownPrismic::Origin === origin

    origin.prismic_document
  end
end
