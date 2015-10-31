require_dependency 'redmine/wiki_formatting/textile/helper'

module WikingWikiHelperPatch

    def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable
            alias_method :wikitoolbar_for, :wikitoolbar_with_wiking_for
        end
    end

    module ClassMethods
    end

    module InstanceMethods

        def wikitoolbar_with_wiking_for(field_id)
            unless @heads_for_wiki_formatter_included
                content_for :header_tags do
                    wiki_heads = ''
                    if File.exist?("#{Rails.public_path}/javascripts/jstoolbar/jstoolbar-textile.min.js")
                        wiki_heads << javascript_include_tag('jstoolbar/jstoolbar-textile.min')
                    else
                        wiki_heads << javascript_include_tag('jstoolbar/jstoolbar')
                        wiki_heads << javascript_include_tag('jstoolbar/textile')
                    end
                    wiki_heads << javascript_include_tag("jstoolbar/lang/jstoolbar-#{current_language.to_s.downcase}")
                    wiki_heads << stylesheet_link_tag('jstoolbar')
                    if wiki_heads.respond_to?(:html_safe)
                        wiki_heads.html_safe
                    else
                        wiki_heads
                    end
                end
                @heads_for_wiki_formatter_included = true
            end

            unless Redmine::VERSION::MAJOR < 2 || (Redmine::VERSION::MAJOR == 2 && Redmine::VERSION::MINOR < 2) ||
                  (Redmine::VERSION::MAJOR == 2 && Redmine::VERSION::MINOR == 2 && Redmine::VERSION::TINY < 3)
                unless @wiking_heads_for_wiki_formatter_included
                    content_for :header_tags do
                        javascript_include_tag('wiking', :plugin => 'wiking')
                    end
                    @wiking_heads_for_wiki_formatter_included = true
                end
            end

            if defined? ChiliProject
                url = url_for(:controller => 'help', :action => 'wiki_syntax')
            elsif File.exists?(File.join(Rails.root, 'public/help', current_language.to_s.downcase, 'wiki_syntax.html'))
                url = "#{Redmine::Utils.relative_url_root}/help/#{current_language.to_s.downcase}/wiki_syntax.html"
            else
                url = "#{Redmine::Utils.relative_url_root}/help/wiki_syntax.html"
            end

            if File.exists?(File.join(Rails.root, 'plugins/wiking/assets/help/', current_language.to_s.downcase, 'wiki_syntax.html'))
                wiking_url = "#{Redmine::Utils.relative_url_root}/plugin_assets/wiking/help/#{current_language.to_s.downcase}/wiki_syntax.html"
            else
                wiking_url = "#{Redmine::Utils.relative_url_root}/plugin_assets/wiking/help/en/wiki_syntax.html"
            end

            js_code = "var wikiToolbar = new jsToolBar(document.getElementById('#{field_id}'));"

            if Redmine::VERSION::MAJOR < 2 || (Redmine::VERSION::MAJOR == 2 && Redmine::VERSION::MINOR < 2) ||
              (Redmine::VERSION::MAJOR == 2 && Redmine::VERSION::MINOR == 2 && Redmine::VERSION::TINY < 3)
                help_link = l(:setting_text_formatting) + ': ' +
                    link_to(l(:label_help), url, :class => 'help-link',
                        :onclick => "window.open(\"#{url}\", \"\", \"resizable=yes, location=no, width=300, height=640, menubar=no, status=no, scrollbars=yes\"); return false;") + ' &amp; ' +
                    link_to(l(:label_more), wiking_url, :class => 'help-link',
                        :onclick => "window.open(\"#{wiking_url}\", \"\", \"resizable=yes, location=no, width=300, height=640, menubar=no, status=no, scrollbars=yes\"); return false;")
            else
                js_code << "wikiToolbar.setMoreLink('#{escape_javascript(wiking_url)}');"

                help_link = url
            end

            js_code << "wikiToolbar.setHelpLink('#{escape_javascript(help_link)}');"
            js_code << "wikiToolbar.draw();"

            javascript_tag(js_code)
        end

    end

end
