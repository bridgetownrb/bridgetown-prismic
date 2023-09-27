**Update:** Primic abandoned official support for Ruby some time ago, and the one production project I was officially using this plugin on ended up getting scrapped. I'm naturally predisposed towards keeping content in Git anyway and was always a little uncomfortable using a proprietary API service. So I've archived this plugin. If anyone else wants to pick up maintenance, let me know!

----

# Bridgetown Prismic CMS Plugin

The [Bridgetown](https://edge.bridgetownrb.com) Prismic plugin allows you to pull content directly out of your [Prismic CMS](https://prismic.io) repository and generate resources you can use in all of your templates and plugins the same as if they were files saved directly in your site's `src` folder. Posts, pages, and any custom collections you want to set up are fully supported.

In addition, this plugin allows you to set up draft previews so you can see how your content will look before it's published and deployed as a static site. This will require you to host a preview site on a platform which supports Ruby Rack-based applications. We recommend [Render](https://render.com), but you can use Heroku or most other platforms which support Ruby (Rails, etc.).

This plugin requires Ruby 3 and the latest alpha version of [Bridgetown 1.0](https://edge.bridgetownrb.com).

## Installation

Add the gem to your Gemfile and set up initial configuration by running the automation script:

```sh
bin/bridgetown apply https://github.com/bridgetownrb/bridgetown-prismic
```

This will add a `prismic_repository` setting to your `bridgetown.config.yml` file. Replace that with the subdomain of your Prismic repo.

It will also set up a `models` folder where you will add the Bridgetown models corresponding to your Prismic custom types. More details on that below.

### Draft Previews

To set up previews using your Bridgetown Roda backend, modify your `server/roda_app.rb` file by adding:

```ruby
require "bridgetown-prismic/roda/previews"
```

to the top of the file, and then adding:

```ruby
include BridgetownPrismic::Roda::Previews
```

right underneath `class RodaApp < Bridgetown::Rack::Roda`.

Also ensure you have the Bridgetown SSR plugin installed (aka `plugin :bridgetown_ssr` is somewhere above your `route do |r|` block).

Your file should end up looking something like this:

```ruby
require "bridgetown-prismic/roda/previews"

class RodaApp < Bridgetown::Rack::Roda
  include BridgetownPrismic::Roda::Previews

  plugin :bridgetown_ssr

  route do |r|
    r.bridgetown
  end
end
```

Next, create a `server/routes/preview.rb` route file:

```ruby
class Routes::Preview < Bridgetown::Rack::Routes
  route do |r|
    r.on "preview" do
      # Route hit by the Prismic preview flow
      # route: /preview
      r.is do
        unless prismic_preview_token
          response.status = 403
          next prismic_token_error_msg
        end

        r.redirect prismic_preview_redirect_url
      end

      # Rendering pathway to preview a page
      # route: /preview/:custom_type/:id
      r.is String, String do |custom_type, id|
        unless prismic_preview_token
          response.status = 403
          next prismic_token_error_msg
        end

        save_prismic_preview_token

        Bridgetown::Model::Base
          .find("prismic://#{custom_type}/#{id}")
          .render_as_resource
          .output
      end
    end
  end
end
```

This file handles two routes: `/preview` and `/preview/:custom_type/:id`. Upon clicking the preview icon in the Prismic editing interface, Prismic will hit your `/preview` route first with an access token. That saves a cookie, which is then used after the redirect to the `/preview/:custom_type/:id` route (which in practice will look something like `/page/YYsenhEAACIADwbi`). As long as you've set up your models correctly, Bridgetown will automatically know how to render the resource for the preview.

## Setting Up Your Content Models

This is where all the magic happens. ✨

By creating a content model class for each custom type in Prismic, you establish a 1:1 mapping between a piece of content in Prismic and a piece of content your site will use to build resources. The automation script installed an example of a **Post** content model. Let's take a closer look.

At the top of the file are a series of configuration options:

```ruby
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
```

* `collection_name`: this can be a built-in collection such as `posts` or `pages`, or it can be a custom collection you've configured in `bridgetown.config.yml`.
* `prismic_custom_type`: this will be the "API ID" of the custom type in Prismic.
* `prismic_slug`: this should return the "slug" (aka `my-document-title`) of a Prismic document. In this example the slug Prismic chose is being used verbatim, but you can make alterations as you see fit.
* `prismic_url`: this should return the full URL of the final destination for the content. It should match the permalink settings of your collection. This is used by the "link resolver"—aka anywhere in a Prismic document where you've added a link to another Prismic document, the URL for that link is resolved using this return value for the custom type.

All right, with those options out of the way, on to the main event:

```ruby
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
```

This where you create the 1:1 mappings between the Prismic fields and the "front matter" (aka data) + content of your model/resource. Any time you access the resource in templates by writing `resource.data.title` or `resource.content`, it will be pulling those values from these mappings.

Within the `provide_data` block, you use a special Ruby DSL in a spreadsheet-like manner to set up the mappings. On the left-hand "column", you specify the name of the front matter variable, as well as  `content` (optional but recommended). In the middle column, you use Prismic's Ruby API to get a field value or metadata. On the right-hand column, you "coerce" the value into the type of data you're looking for. Note that any field which the author hasn't filled in has a `nil` value, so you can see we're using Ruby's safe navigation operator `&` (whimsically known as the "lonely operator") most of the time so nil values won't crash the import process.

You can [read more about Prismic's Ruby Document API here](https://prismic.io/docs/technologies/the-document-object-ruby) for information on when to use `value` or `as_text` or `url`, etc.

A few notes on the Ruby DSL:

* Any time you see `from: -> { ... }`, that's a lambda which is evaluated directly in the model object scope. Essentially it's a way to "escape" the DSL.
* You can nest values using a block, for example:
  ```ruby
  attachment do
    name            doc["bulletin.name"]            .value.downcase
    pdf_url         doc["bulletin.pdf_file"]        .url
  end
  ```
  which would let you access the data like so:
  ```ruby
  resource.data.attachment.name
  resource.data.attachment.pdf_url
  ```
* You can call `provide_data` from within a `from:` lambda, which is very useful when looping through Prismic slices and generating nested content. For example:
  ```ruby
  tiles from: -> {
    doc["homepage.body"].slices.map do |slice|
      case slice.slice_type
      when "homepage_tile"
        slice.repeat.group_documents.map do |tile|
          provide_data do
            backdrop      tile["backdrop"]   &.url
            heading       tile["heading"]    &.as_text
            description   tile["description"]&.as_html with_links
          end
        end
      end
    end.flatten.compact
  }
  ```
This would result in a `resource.data.tiles` array with one or more hashes including `backdrop`, `heading`, and `description` keys.

The Ruby DSL is pretty nifty, but you may occasionally run into a conflict between your variable name and an existing Ruby method. For example, you couldn't add something like `method  doc["page.method"]  .as_text` because `method` is an existing Ruby object method. Instead, use `set` like so:

```ruby
set :method, doc["page.method"].as_text
```

Finally, if you decide to need to bail and want to provide a standard hash instead of using the Ruby DSL, you can do that too! It's not as flexible as the DSL because you can't arbitrarily insert multi-line statements of Ruby code within the data hash, but it's easy enough to understand:

```ruby
def self.process_prismic_document(doc)
  provide_data({
    # Variable        # Prismic Field                 # Formatting
    id:               doc.id,
    slug:             prismic_slug(doc),
    type:             doc.type,
    created_at:       doc.first_publication_date,

    layout:           :post,
    title:            doc["test_page.title"]          .as_text,

    content:          doc["test_page.body"]           &.as_html(with_links),
  })
end
```

Just remember to put all your colons, commas, and parentheses in the right places! 😅

### Mind your defaults!

One gotcha to be aware of is that Prismic-sourced resources _will not pick up front matter defaults_ from any `_defaults.yml` files you may add to your `src` tree (for example in `src/_posts`). This is because `_defaults.yml` acts upon the file system directly, and resources originating from Prismic aren't part of the filesystem per se.

However, you can definitely use the YAML-based front matter defaults which you add to `bridgetown.config.yml` to set defaults for any collection. In addition, you can put any "default" data directly in your model definitions (such as the `layout: post` example above).

### Trying Out Your Models

The Bridgetown console is a good place to inspect your content. Just run `bin/bridgetown console` or `c` and then you can poke through your collections and see what's what.

```
irb> resource = site.collections.pages.resources.find { |page| page.data.slug == "my-page" }

irb> resource.data

irb> resource.content

irb> resource.model.prismic_doc # access the original Prismic Document object
```

## Indicating Previews in Your Site's Layout

When previewing content, it's helpful to know at a glance that you're looking at a preview, not a piece of published content. You can add a conditional block to the top of your layout's `<body>` which will detect the presense of a preview token and display a preview notice at the top of the page.

Example for a Liquid layout:

```liquid
{% if site.prismic_preview_token %}
  <p class="text-center" style="padding:7px; background:rgb(255, 230, 0); border-bottom:2px solid #333; margin:0; font-family:sans-serif; font-weight:bold; font-size:110%">
    PREVIEW
  </p>
{% endif %}
```

or an ERB layout:

```erb
<% if site.config.prismic_preview_token %>
  <p class="text-center" style="padding:7px; background:rgb(255, 230, 0); border-bottom:2px solid #333; margin:0; font-family:sans-serif; font-weight:bold; font-size:110%">
    PREVIEW
  </p>
<% end %>
```

## Deploying on Render

You can easily deploy your preview site on [Render](https://render.com) and use it for previewing draft content. For modest website deployments, your preview site could also serve as your public site (with the public only seeing the "static" published content), but generally we recommend a second static site deployment for the public to access (which Render also supports—you can run `bin/bridgetown configure render` to set up a static site config).

The starter plan (US $7/month as of the time of this writing) is recommended. Simply add (or edit) a `render.yaml` file in the root of your site repo:

```yaml
services:
  - type: web
    name: your-site-name-here
    env: ruby
    repo: https://github.com/username/your-site-name-here
    buildCommand: bundle install && yarn install && bin/bridgetown frontend:build
    startCommand: bin/bridgetown start
    envVars:
      - key: BRIDGETOWN_ENV
        value: production
```

Once your repo is checked into GitHub, you can access it in Render and it will be configured and deployed "automagically." 😁

After that, in your Prismic CMS settings under "Previews", you can create a new preview with the following settings:

* Site Name: Preview
* Domain: https://your-site-name-here.onrender.com
* Link Resolver: /preview

In addition, you'll want to set up a webhook so any published content will trigger a rebuild of your preview and public sites.

Go to the "Webhooks" settings page and add a new webook:

* Name of the webhook: Preview Site (or Public Site)
* URL: (you will need to obtain this from your [Render site's deploy hook config (see documentation)](https://render.com/docs/deploy-hooks)
* Secret: (leave this blank)

## Questions? Feedback?

Please submit an issue to this GitHub repo and we'll address your concerns as soon as possible. In addition, [you can get in touch with the Bridgetown core team and community members](https://www.bridgetownrb.com/docs/community) through the usual channels.

## Testing This Gem

* Run `bundle exec rake test` to run the test suite (make sure to run `bundle
  install`)
* Or run `script/cibuild` to validate with Rubocop and Minitest together.

## Contributing

1. Fork it (https://github.com/bridgetownrb/bridgetown-prismic/fork)
2. Clone the fork using `git clone` to your local development machine.
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request
