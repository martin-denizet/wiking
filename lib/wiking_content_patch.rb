require_dependency 'wiki_content'

module WikingContentPatch

    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable
        end
    end

    module InstanceMethods

        def mentioning_class
            page.event_type
        end

        def mentioning_title
            page.event_title
        end

        def mentioning_url
            page.event_url
        end

        def mentioning_author
            nil
        end

    end

end
