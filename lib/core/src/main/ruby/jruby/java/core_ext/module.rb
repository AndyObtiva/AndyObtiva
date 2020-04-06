# Extensions to the standard Module package.
class Module

  alias const_missing_without_nested_inherited_jruby_include_package const_missing

  def const_missing(constant)
    hidden_methods = {
      included_packages_from_ancestors_namespaces: lambda do |m|
        collection = []
        hidden_methods[:collect_ancestors_namespaces].call(collection, m)
        collection.uniq.map do |klass|
            hidden_methods[:included_packages].call(klass)
          end.map(&:to_a).reduce([], :+).uniq
      end,

      collect_ancestors_namespaces: lambda do |collection, m|
        return if m.is_a?(Java::JavaPackage) || collection.include?(m)
        collection << m
        result = (m.ancestors + hidden_methods[:namespaces].call(m)[1..-1]).uniq
        if result.size == 1
          return
        else
          result[1..-1].each do |klass|
            hidden_methods[:collect_ancestors_namespaces].call(collection, klass)
          end
        end
      end,

      included_packages_from_namespaces: lambda do |m|
        hidden_methods[:namespaces].call(m).map do |klass|
          hidden_methods[:included_packages].call(klass)
        end.map(&:to_a).reduce([], :+).uniq
      end,

      included_packages: lambda do |m|
        return [] unless m.respond_to?(:instance_variable_get)
        m.instance_variable_set(:@included_packages, []) unless m.instance_variable_get(:@included_packages)
        m.instance_variable_get(:@included_packages)
      end,

      java_aliases_from_ancestors_namespaces: lambda do |m|
        return [] if m.is_a?(Java::JavaPackage)
        m.ancestors.map do |klass|
          hidden_methods[:java_aliases_from_namespaces].call(klass)
        end.reverse.reduce({}, :merge)
      end,

      java_aliases_from_namespaces: lambda do |m|
        hidden_methods[:namespaces].call(m).map do |klass|
          hidden_methods[:java_aliases].call(klass)
        end.reverse.reduce({}, :merge)
      end,

      java_aliases: lambda do |m|
        return {} unless m.respond_to?(:instance_variable_get)
        m.instance_variable_set(:@java_aliases, {}) unless m.instance_variable_get(:@java_aliases)
        m.instance_variable_get(:@java_aliases)
      end,

      # Returns namespaces containing this module/class starting with self.
      # Example: `Outer::Inner::Shape.namespaces` returns:
      # => [Outer::Inner::Shape, Outer::Inner, Outer]
      namespaces: lambda do |m|
        return [m] if m.name.nil?
        namespace_constants = m.name.split(/::/).map(&:to_sym)
        namespace_constants.reduce([Object]) do |output, namespace_constant|
          output += [output.last.const_get(namespace_constant)]
        end[1..-1].uniq.reverse
      end
    }
    all_included_packages = hidden_methods[:included_packages_from_ancestors_namespaces].call(self)
    return const_missing_without_nested_inherited_jruby_include_package(constant) if all_included_packages.empty?
    real_name = hidden_methods[:java_aliases_from_ancestors_namespaces].call(self)[constant] || constant

    java_class = nil
    last_error = nil

    all_included_packages.each do |package|
      begin
        java_class = JavaUtilities.get_java_class("#{package}.#{real_name}")
      rescue NameError => e
        # we only rescue NameError, since other errors should bubble out
        last_error = e
      end
      break if java_class
    end

    if java_class
      return JavaUtilities.create_proxy_class(constant, java_class, self)
    else
      # try to chain to super's const_missing
      begin
        return const_missing_without_nested_inherited_jruby_include_package(constant)
      rescue NameError => e
        # super didn't find anything either, raise our Java error
        raise NameError.new("#{constant} not found in packages #{all_included_packages.join(', ')}; last error: #{(last_error || e).message}")
      end
    end
  end

  private

  ##
  # Includes a Java package into this class/module. The Java classes in the
  # package will become available in this class/module, unless a constant
  # with the same name as a Java class is already defined.
  #
  def include_package(package)
    hidden_methods = {
      included_packages: lambda do |m|
        return [] unless m.respond_to?(:instance_variable_get)
        m.instance_variable_set(:@included_packages, []) unless m.instance_variable_get(:@included_packages)
        m.instance_variable_get(:@included_packages)
      end,
    }
    package = package.package_name if package.respond_to?(:package_name)
    the_included_packages = hidden_methods[:included_packages].call(self)
    the_included_packages << package unless the_included_packages.include?(package)
    nil
  end

  def java_alias(new_id, old_id)
    hidden_methods = {
      java_aliases: lambda do |m|
        return {} unless m.respond_to?(:instance_variable_get)
        m.instance_variable_set(:@java_aliases, {}) unless m.instance_variable_get(:@java_aliases)
        m.instance_variable_get(:@java_aliases)
      end,
    }
    hidden_methods[:java_aliases].call(self)[new_id] = old_id
  end

end
