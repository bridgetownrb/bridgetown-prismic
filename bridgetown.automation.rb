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

create_file "models/post.rb", File.read(File.join(__dir__, "test", "fixtures", "models", "post.rb"))