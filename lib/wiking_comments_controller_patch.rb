require_dependency 'comments_controller'

module WikingCommentsControllerPatch

    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable
        end
    end

    module InstanceMethods

        def redirect_to(options = {}, response_status = {})
            if action_name == 'create' && @comment && flash[:notice]
                render_to_string(:partial => 'wiking/textilizable',
                                 :locals => { :object => @comment, :method => :comments })
            end
            super
        end

    end

end
