# frozen_string_literal: true

require_relative "lib/bridgetown-prismic/version"

Gem::Specification.new do |spec|
  spec.name          = "bridgetown-prismic"
  spec.version       = BridgetownPrismic::VERSION
  spec.author        = "Bridgetown Team"
  spec.email         = "maintainers@bridgetownrb.com"
  spec.summary       = "A Prismic CMS integration plugin for Bridgetown"
  spec.homepage      = "https://github.com/bridgetownrb/bridgetown-prismic"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r!^(test|script|spec|features|frontend)/!) }
  spec.test_files    = spec.files.grep(%r!^test/!)
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.0"

  spec.add_dependency "bridgetown", ">= 1.2.0", "< 2.0"
  spec.add_dependency "prismic.io", ">= 1.8"
  spec.add_dependency "async", ">= 1.30", "< 2.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "rubocop-bridgetown", "~> 0.3"
end
