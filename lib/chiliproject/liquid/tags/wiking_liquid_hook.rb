class WikingLiquidHook < ChiliProject::Liquid::Tags::Tag

    def initialize(tag_name, markup, tokens)
        @arguments = []
        @options = {}

        markup.strip!
        if markup =~ %r{^\((.*)\)$}
            markup = $1
        end

        if markup.present?
            markup.split(',').each do |arg|
                arg.strip!
                if arg =~ %r{^([^=]+)\=(.*)$}
                    name, value = $1.strip.downcase.to_sym, $2.strip
                    if value =~ %r{^(["'])(.*)\1$}
                        value = $2
                    end
                    @options[name] = value
                else
                    @arguments << arg
                end
            end

            @hook = @arguments.shift
        end

        super
    end

    def render(context)
        content = ''

        unless @hook.blank?
            page = nil
            if context.registers[:object].is_a?(WikiContent)
                page = context.registers[:object]
            end

            content = context.registers[:view].call_hook("wiking_hook_#{@hook}", { :page => page, :args => @arguments, :options => @options })
        end

        content
    end

end
