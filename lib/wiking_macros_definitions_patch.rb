require_dependency 'redmine/wiki_formatting/macros'

module WikingMacrosDefinitionsPatch

    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable

            alias_method_chain :macro_exists?, :custom if method_defined?(:macro_exists?)
            alias_method_chain :exec_macro,    :custom
        end
    end

    module InstanceMethods

        def macro_exists_with_custom?(name)
            exists = macro_exists_without_custom?(name)
            unless exists
                if macro = WikiMacro.find_by_name(name)
                    macro.register!
                    exists = true
                end
            end
            exists
        end

        def exec_macro_with_custom(*args)
            method_name = "macro_#{args[0].downcase}"
            unless respond_to?(method_name)
                macro = WikiMacro.find_by_name(args[0])
                macro.register! if macro
            end
            if method_name == 'macro_macro_list'
                if Redmine::WikiFormatting::Macros.respond_to?(:available_macros)
                    available_macros = Redmine::WikiFormatting::Macros.available_macros
                else
                    available_macros = Redmine::WikiFormatting::Macros.send(:class_variable_get, :@@available_macros)
                end
                WikiMacro.all.each do |macro|
                    macro.register! unless available_macros.has_key?(macro.name.to_sym)
                end
            end
            exec_macro_without_custom(*args)
        end

    end

end
