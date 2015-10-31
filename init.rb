require 'redmine'

require_dependency 'wiking_hook'

Rails.logger.info 'Starting WikiNG Plugin for Redmine'

ActiveRecord::Base.observers << :mention_observer

Rails.configuration.to_prepare do
    unless Redmine::WikiFormatting::Textile::Formatter.included_modules.include?(WikingFormatterPatch)
        Redmine::WikiFormatting::Textile::Formatter.send(:include, WikingFormatterPatch)
    end
    unless Redmine::WikiFormatting::Textile::Helper.included_modules.include?(WikingWikiHelperPatch)
        Redmine::WikiFormatting::Textile::Helper.send(:include, WikingWikiHelperPatch)
    end
    unless Redmine::WikiFormatting::Macros::Definitions.included_modules.include?(WikingMacrosDefinitionsPatch)
        Redmine::WikiFormatting::Macros::Definitions.send(:include, WikingMacrosDefinitionsPatch)
    end
    unless ApplicationHelper.included_modules.include?(WikingApplicationHelperPatch)
        ApplicationHelper.send(:include, WikingApplicationHelperPatch)
    end

    unless Redmine::Export::PDF::ITCPDF.included_modules.include?(WikingPDFPatch)
        Redmine::Export::PDF::ITCPDF.send(:include, WikingPDFPatch)
    end

    unless JournalsController.included_modules.include?(WikingLlControllerPatch)
        JournalsController.send(:include, WikingLlControllerPatch)
    end
    unless MessagesController.included_modules.include?(WikingLlControllerPatch)
        MessagesController.send(:include, WikingLlControllerPatch)
    end
    unless CommentsController.included_modules.include?(WikingCommentsControllerPatch)
        CommentsController.send(:include, WikingCommentsControllerPatch)
    end

    unless User.included_modules.include?(WikingUserPatch)
        User.send(:include, WikingUserPatch)
    end

    unless WikiContent.included_modules.include?(WikingContentPatch)
        WikiContent.send(:include, WikingContentPatch)
    end
    unless Comment.included_modules.include?(WikingCommentPatch)
        Comment.send(:include, WikingCommentPatch)
    end

    if defined? Redmine::Notifiable # to protect Redmine 1.0
        unless Redmine::Notifiable.included_modules.include?(WikingNotifiablePatch)
            Redmine::Notifiable.send(:include, WikingNotifiablePatch)
        end
    end
    unless Mailer.included_modules.include?(WikingMailerPatch)
        Mailer.send(:include, WikingMailerPatch)
    end

    if defined? ChiliProject::Liquid::Tags
        require_dependency 'chiliproject/liquid/tags/wiking_liquid_hook'

        ChiliProject::Liquid::Tags.register_tag('wiking_hook', WikingLiquidHook, :html => true)
    end
end

Redmine::Plugin.register :wiking do
    name 'WikiNG'
    author 'Andriy Lesyuk'
    author_url 'http://www.andriylesyuk.com/'
    description 'Wiki Next Generation plugin extends Redmine Wiki syntax.'
    url 'http://projects.andriylesyuk.com/projects/wiking'
    version '1.0.0b'

    project_module :wiki do
        permission :view_hidden_content, {}
    end

    menu :admin_menu, :custom_macros,
                    { :controller => 'macros', :action => 'index' },
                      :caption => :label_custom_wiki_macro_plural,
                      :after => :custom_fields
end

unless defined? ChiliProject::Liquid::Tags

    Redmine::WikiFormatting::Macros.register do
        desc "Adds new Redmine hook to Wiki page and calls it. Example:\n\n  !{{wiking_hook(name, argument=value)}}"
        macro :wiking_hook do |page, args|
            if args.size > 0
                hook = args.shift

                params = []
                options = {}
                args.each do |arg|
                    if arg =~ %r{^([^=]+)=(.*)$}
                        options[$1.downcase.to_sym] = $2
                    else
                        params << arg
                    end
                end

                call_hook("wiking_hook_#{hook}", { :page => page, :args => params, :options => options })
            end
        end
    end

    WikiMacro.register_all! if ActiveRecord::Base.connection.table_exists?(:wiki_macros)

end
