require_dependency 'journals_controller'
require_dependency 'messages_controller'

module WikingLlControllerPatch

    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable
        end
    end

    module InstanceMethods

        def ll(lang, str, value = nil)
            if str == :text_user_wrote
                super(lang, str, "user##{value.id}")
            else
                super(lang, str, value)
            end
        end

    end

end
