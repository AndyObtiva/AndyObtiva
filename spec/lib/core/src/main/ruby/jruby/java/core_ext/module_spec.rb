require_relative '../../../../../../../../spec_helper'
require_relative '../../../../../../../../../lib/core/src/main/ruby/jruby/java/core_ext/module.rb'

describe Module do
  after do
    %w[
      OuterClass
      OuterModule
      SuperClass
      SubClass
      SubSubClass
      AnotherSuperClass
      AnotherSubClass
      SuperModule
      AnotherSuperModule
      SubModule
      SubSubModule
    ].each do |constant|
      Object.send(:remove_const, constant) if Object.const_defined?(constant)
    end
  end

  it "can be imported from an outer class container using 'include_package package.module" do
    class OuterClass
      include_package java.lang
      class InnerClass
        include_package java.util
        class InnerInnerClass
        end
        module InnerInnerModule
        end
      end
      module InnerModule
      end
    end
    expect(OuterClass::InnerClass::System).to respond_to 'getProperty'
    expect(OuterClass::InnerModule::System).to respond_to 'getProperty'
    expect(OuterClass::InnerClass::InnerInnerClass::System).to respond_to 'getProperty'
    expect(OuterClass::InnerClass::InnerInnerModule::System).to respond_to 'getProperty'
    expect(OuterClass::InnerClass::InnerInnerClass::Arrays).to respond_to 'asList'
    expect(OuterClass::InnerClass::InnerInnerModule::Arrays).to respond_to 'asList'
  end

  it "can be imported from an outer module container using 'include_package package.module" do
    module OuterModule
      include_package java.lang
      class InnerClass
      end
      module InnerModule
        include_package java.util
        class InnerInnerClass
        end
        module InnerInnerModule
        end
      end
    end
    expect(OuterModule::InnerClass::System).to respond_to 'getProperty'
    expect(OuterModule::InnerModule::System).to respond_to 'getProperty'
    expect(OuterModule::InnerModule::InnerInnerClass::System).to respond_to 'getProperty'
    expect(OuterModule::InnerModule::InnerInnerModule::System).to respond_to 'getProperty'
    expect(OuterModule::InnerModule::InnerInnerClass::Arrays).to respond_to 'asList'
    expect(OuterModule::InnerModule::InnerInnerModule::Arrays).to respond_to 'asList'
  end

  it "can be imported from a superclass using 'include_package package.module" do
    class SuperClass
      include_package java.lang
      class AnotherSuperClass
      end
    end
    class SubClass < SuperClass
      include_package java.util
    end
    class AnotherSubClass < SuperClass::AnotherSuperClass
    end
    class SubSubClass < SubClass
    end
    expect(SuperClass::System).to respond_to 'getProperty'
    expect(SubClass::System).to respond_to 'getProperty'
    expect(AnotherSubClass::System).to respond_to 'getProperty'
    expect(SubSubClass::System).to respond_to 'getProperty'
    expect(SubSubClass::Arrays).to respond_to 'asList'
  end

  it "can be imported from a supermodule using 'include_package package.module" do
    module SuperModule
      include_package java.lang
      module AnotherSuperModule
      end
    end
    class SuperClass
      include SuperModule
    end
    class SubClass < SuperClass
    end
    class AnotherSuperClass
      include SuperClass::AnotherSuperModule
    end
    class AnotherSubClass < AnotherSuperClass
    end
    module SubModule
      include SuperModule
      include_package java.util
    end
    module SubSubModule
      include SubModule
    end
    expect(SuperModule::System).to respond_to 'getProperty'
    expect(SuperClass::System).to respond_to 'getProperty'
    expect(SubClass::System).to respond_to 'getProperty'
    expect(AnotherSuperClass::System).to respond_to 'getProperty'
    expect(AnotherSubClass::System).to respond_to 'getProperty'
    expect(SubModule::System).to respond_to 'getProperty'
    expect(SubSubModule::Arrays).to respond_to 'asList'
  end

end
