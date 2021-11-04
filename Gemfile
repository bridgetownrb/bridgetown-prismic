# frozen_string_literal: true

source "https://rubygems.org"
gemspec

gem "bridgetown", ENV["BRIDGETOWN_VERSION"] if ENV["BRIDGETOWN_VERSION"]
gem "bridgetown-core", "~> 1.0.0.alpha6", github: "bridgetownrb/bridgetown", branch: "zeitwerk-autoload-paths"

group :test do
  gem "minitest"
  gem "minitest-reporters"
  gem "shoulda"
end
