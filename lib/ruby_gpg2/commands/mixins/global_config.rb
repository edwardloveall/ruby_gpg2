module RubyGPG2
  module Commands
    module Mixins
      module GlobalConfig
        def configure_command(builder, opts)
          home_directory = opts[:home_directory]

          builder = super(builder, opts)
          builder = builder.with_option(
              '--homedir', home_directory, quoting: '"') if home_directory
          builder
        end
      end
    end
  end
end
