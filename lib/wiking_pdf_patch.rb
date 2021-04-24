require_dependency 'redmine/export/pdf'

module WikingPDFPatch

    def self.included(base)
        if base.method_defined?(:formatted_text)
            base.send(:include, InstanceMethods)
        else
            base.send(:include, Redmine1InstanceMethods)
        end
        base.class_eval do
            unloadable

            if method_defined?(:formatted_text)
                alias_method :formatted_text_without_wiking, :formatted_text
                alias_method :formatted_text, :formatted_text_with_wiking
            else
                alias_method :fix_text_encoding_without_wiking, :fix_text_encoding
                alias_method :formatted_text, :fix_text_encoding_with_wiking
            end
        end
    end

    module InstanceMethods

        def formatted_text_with_wiking(text)
            html = formatted_text_without_wiking(text)

            html.gsub!(%r{<span class="wiking (marker|smiley) [^"]+" title="([^"]+)"></span>}) do |match|
                type, title = $1, $2
                case type
                when 'marker'
                    '{' + title + '}'
                else
                    title
                end
            end

            html
        end

    end

    module Redmine1InstanceMethods

        def fix_text_encoding_with_wiking(text)
            text.gsub!(%r{<span class="wiking (marker|smiley) [^"]+" title="([^"]+)"></span>}) do |match|
                type, title = $1, $2
                case type
                when 'marker'
                    '{' + title + '}'
                else
                    title
                end
            end unless text.nil?

            fix_text_encoding_without_wiking(text)
        end

    end

end
