# The Simple::Workflow::Reloader provides a way to locate and reload a module
module Simple::Workflow::Reloader
  extend self

  def reload(a_module)
    source_paths = locate(a_module)
    if source_paths.empty?
      logger&.warn "#{a_module}: cannot reload module: cannot find sources"
      return
    end

    source_paths.each do |source_path|
      logger&.debug "#{a_module}: reload #{source_path}"
    end

    logger&.info "#{a_module}: reloaded module"
  end

  # This method tries to identify source files for a module's functions.
  def locate(a_module)
    expect! a_module => Module

    @registered_source_paths ||= {}
    @registered_source_paths[a_module.name] ||= locate_source_paths(a_module)
  end

  private

  def logger
    ::Simple::Workflow.logger
  end

  def locate_source_paths(a_module)
    source_paths = []

    source_paths.concat locate_by_instance_methods(a_module)
    source_paths.concat locate_by_methods(a_module)
    source_paths.concat locate_by_name(a_module)

    source_paths.uniq
  end

  def locate_by_instance_methods(a_module)
    method_names = a_module.instance_methods(false)
    methods = method_names.map { |sym| a_module.instance_method(sym) }
    methods.map(&:source_location).map(&:first)
  end

  def locate_by_methods(a_module)
    method_names = a_module.methods(false)
    methods = method_names.map { |sym| a_module.method(sym) }
    methods.map(&:source_location).map(&:first)
  end

  def locate_by_name(a_module)
    source_file = "#{underscore(a_module.name)}.rb"

    $LOAD_PATH.each do |dir|
      full_path = File.join(dir, source_file)
      return [full_path] if File.exist?(full_path)
    end

    []
  end

  # Makes an underscored, lowercase form from the expression in the string.
  #
  # Changes '::' to '/' to convert namespaces to paths.
  #
  # This is copied and slightly changed (we don't support any custom
  # inflections) from activesupport's  lib/active_support/inflector/methods.rb
  #
  def underscore(camel_cased_word)
    return camel_cased_word unless /[A-Z-]|::/.match?(camel_cased_word)

    word = camel_cased_word.to_s.gsub("::", "/")

    word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
    word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
    word.tr!("-", "_")
    word.downcase!
    word
  end
end
