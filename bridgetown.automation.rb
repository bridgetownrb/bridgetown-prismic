add_bridgetown_plugin("bridgetown-prismic")

append_to_file "bridgetown.config.yml" do
  <<~YAML


    # Prismic config:
    prismic_repository: repo_name_here
    autoload_paths:
      - path: models
        eager: true
  YAML
end

get "https://raw.githubusercontent.com/bridgetownrb/bridgetown-prismic/main/test/fixtures/models/post.rb",
    "models/post.rb"
