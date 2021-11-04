# frozen_string_literal: true

require_relative "./helper"
#require_relative "fixtures/models/post"

class TestBridgetownPrismic < Bridgetown::TestCase
  def setup
    @site = Bridgetown::Site.new(Bridgetown.configuration(
                                   "root_dir"    => root_dir,
                                   "source"      => source_dir,
                                   "destination" => dest_dir,
                                   "quiet"       => true
                                 ))
  end

  context "post model" do
    setup do
      @site.process
      @contents = File.read(dest_dir("index.html"))
    end

    should "output resource front matter" do
      assert_includes @contents, "title: |This is a Blog Post|"
      assert_includes @contents, "subtitle: |This is a Subtitle|"
      assert_includes @contents, "author: |Jared White|"
      assert_includes @contents, "featured_image: |https://images.prismic.io/slicemachine-blank/30d6602b-c832-4379-90ef-100d32c5e4c6_selfie.png?auto=compress,format&amp;rect=0,0,2048,1536&amp;w=1252&amp;h=939|"
    end

    should "output resource content" do
      assert_includes @contents, "<p>Hello.</p>"
      assert_includes @contents, "<p>I am the <strong>post body</strong>.</p>"
    end

    should "provide original document" do
      @site.collections.posts.resources.first.model.prismic_document.is_a?(Prismic::Document)
    end
  end
end
