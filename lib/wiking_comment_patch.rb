require_dependency 'comment'

module WikingCommentPatch

    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable
        end
    end

    module InstanceMethods

        def mentioning_class
            if commented.is_a?(News)
                'news-comments'
            else
                'reply'
            end
        end

        def mentioning_project
            if commented.respond_to?(:project)
                commented.project
            else
                nil
            end
        end

        def mentioning_title
            if commented.respond_to?(:mentioning_title)
                commented.mentioning_title
            elsif commented.respond_to?(:event_title)
                commented.event_title
            elsif commented.respond_to?(:title)
                commented.title
            elsif commented.respond_to?(:subject)
                commented.subject
            elsif commented.respond_to?(:name)
                commented.name
            else
                nil
            end
        end

        def mentioning_url
            if commented.respond_to?(:mentioning_url)
                commented.mentioning_url
            elsif commented.respond_to?(:event_url)
                commented.event_url
            elsif commented.respond_to?(:url)
                commented.url
            else
                nil
            end
        end

        def mentioning_description
            comments
        end

    end

end
