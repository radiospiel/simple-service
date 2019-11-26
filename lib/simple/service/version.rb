module Simple # :nodoc:
end

module Simple::Service
  module GemHelper # :nodoc:
    extend self

    def version(name)
      spec = Gem.loaded_specs[name]
      version = spec ? spec.version.to_s : "0.0.0"
      version += "+unreleased" if !spec || unreleased?(spec)
      version
    end

    private

    def unreleased?(spec)
      return false unless defined?(Bundler::Source::Gemspec)
      return true if spec.source.is_a?(::Bundler::Source::Gemspec)
      # :nocov:
      return true if spec.source.is_a?(::Bundler::Source::Path)

      false
      # :nocov:
    end
  end

  VERSION = GemHelper.version "simple-service"
end
