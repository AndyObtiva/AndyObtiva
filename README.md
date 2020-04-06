# nested_inherited_jruby_include_package

JRuby's `include_package` (mentioned in https://github.com/jruby/jruby/wiki/CallingJavaFromJRuby) includes Java packages in JRuby on `const_missing`. However, it does not trickle down to subclasses/submodules nor nested-classes/nested-modules.

`nested_inherited_jruby_include_package` patches up JRuby to add that capability.

Example (nesting):

```ruby
require 'nested_inherited_jruby_include_package'

class OuterClass
  include_package java.util
  class InnerClass
    def initialize
      p Arrays.asList(1, 2, 3)
    end
  end
end

OuterClass::InnerClass.new
# prints #<Java::JavaUtil::Arrays::ArrayList:0x233fe9b6>
```

Example (inheritance):

```ruby
require 'nested_inherited_jruby_include_package'

class SuperClass
  include_package java.util
end

class SubClass < SuperClass
  def initialize
    p Arrays.asList(1, 2, 3)
  end
end

SubClass.new
# prints #<Java::JavaUtil::Arrays::ArrayList:0x7ce3cb8e>
```

More examples can be found in:

[spec/lib/core/src/main/ruby/jruby/java/core_ext/module_spec.rb](spec/lib/core/src/main/ruby/jruby/java/core_ext/module_spec.rb)

# Setup

Add the following to `Gemfile`:
```
gem 'nested_inherited_jruby_include_package', '~> 0.2.0'
```

And, then run:
```
jruby -S bundle install
```

If you are not using Bundler, run:
```
jruby -S gem install nested_inherited_jruby_include_package -v 0.2.0
```

Then add this line to your code:

```ruby
require 'nested_inherited_jruby_include_package'
```

# Caveats

This gem relies on `Module#const_missing` after it aliases it to `Module#const_missing_without_nested_inherited_jruby_include_package`

As such, it works optimally if your project and loaded gems do not override `Module#const_missing`

# Implementation Note

To avoid method and constant pollution in `Module`, the implementation intentionally trades off code clarity for lack of pollution by not relying on methods, yet local lambdas, in modularizing logic.

# Issue Reporting

This is an early alpha. It has only been used in a couple of projects. As such, there are no guarantees for its functionality. Please report any issues you might discover when using on your own projects.

# Change Log

[CHANGELOG.md](CHANGELOG.md)

# License

The MIT License

[LICENSE.txt](LICENSE.txt)

# Copyright

Copyright (c) 2020 Andy Maleh
