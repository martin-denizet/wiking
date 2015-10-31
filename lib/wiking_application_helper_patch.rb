# encoding: utf-8

require_dependency 'application_helper'

module WikingApplicationHelperPatch

    def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
            unloadable

            alias_method_chain :textilizable,        :wiking
            alias_method_chain :parse_headings,      :wiking unless Redmine::VERSION::MAJOR == 1 && Redmine::VERSION::MINOR == 0
            alias_method_chain :parse_wiki_links,    :wiking
            alias_method_chain :parse_redmine_links, :wiking

            alias_method_chain :link_to_user, :login

            define_method :parse_wiking_conditions, instance_method(:parse_wiking_conditions)
            define_method :parse_glyphs,            instance_method(:parse_glyphs)
            define_method :parse_footnotes,         instance_method(:parse_footnotes)
            define_method :update_mentions,         instance_method(:update_mentions)

            define_method :inline_dashes,     instance_method(:inline_dashes)
            define_method :inline_quotes,     instance_method(:inline_quotes)
            define_method :inline_apostrophe, instance_method(:inline_apostrophe)
            define_method :inline_arrows,     instance_method(:inline_arrows)
        end
    end

    module ClassMethods
    end

    module InstanceMethods

        LT = "&lt;"
        GT = "&gt;"

        def update_mentions(object, mentions = [])
            mentions.uniq!
            digest = mentions.collect(&:id).sort.join(',')
            unless digest == Mention.digest(object)
                Mention.transaction do
                    mentions.each do |user|
                        Mention.create(:mentioning => object, :mentioned => user)
                    end
                end
            end
        end

        WIKING_CONDITION_RE = %r{!?\{\{(date|version)\s*((?:[<=>]|#{LT}|#{GT})=?)\s*([^\}]+)\}\}(.*?)\{\{\1\}\}}m

        def parse_wiking_conditions(text, project, obj, attr, only_path, options)

            text.gsub!(WIKING_CONDITION_RE) do |m|
                tag, condition, value, content = $1, $2, $3, $4
                unless m[0,1] == '!'
                    result = false

                    case tag
                    when 'date'
                        begin
                            date = Date.parse(value)
                            today = Date.today
                            result = (today <=> date)
                        rescue
                            result = true
                        end
                    when 'version'
                        if project
                            name = value.gsub(%r{^"(.*)"$}, "\\1")
                            current = project.versions.find(:all).sort.reverse.select{ |v| v.is_a?(Version) && v.closed? }.first
                            if current
                                if version = project.versions.find_by_name(name)
                                    result = (current <=> version)
                                else
                                    result = (current.name <=> name)
                                end
                            else
                                result = -1
                            end
                        end
                    end

                    condition.gsub!(%r{#{LT}}, '<')
                    condition.gsub!(%r{#{GT}}, '>')
                    unless result === true || result === false
                        if condition[-1..-1] == '=' && result == 0
                            result = true
                        else
                            case condition[0,1]
                            when '<'
                                result = (result < 0)
                            when '>'
                                result = (result > 0)
                            else
                                result = false
                            end
                        end
                    end

                    if result
                        content
                    elsif User.current.allowed_to?(:view_hidden_content, project)
                        '<span class="wiking-hidden">' + content + '</span>'
                    else
                        nil
                    end
                else
                    m[1..-1]
                end
            end

        end

        HTMLATTRS = %r{(?:\s+[\w\d\-]+(?:\s*=\s*(?:"[^"]*"|'[^']*'|[^"'>\s]+))?)*}

        WIKING_REPLACEABLE_RE = %r{(<(/)?([\w\d]+)#{HTMLATTRS}\s*/?>)(.*?)(?=</?[\w\d]+#{HTMLATTRS}\s*/?>|$)}

        def parse_glyphs(text, project, obj, attr, only_path, options)
            codepre = 0
            text.gsub!(WIKING_REPLACEABLE_RE) do |m|
                tag, closure, tagname, content = $1, $2, $3, $4
                if tagname =~ RedCloth3::OFFTAGS
                    if closure
                        codepre -= 1
                        codepre = 0 if codepre < 0
                    else
                        codepre += 1
                    end
                end
                if codepre.zero?
                    [ :inline_dashes, :inline_quotes, :inline_apostrophe, :inline_arrows ].each do |inline_rule|
                        send(inline_rule, content)
                    end
                end
                tag + content
            end
        end

        WIKING_FOOTNOTE_RE = %r{([^\s\(,\-.])(!)?\(\(([^\)]*)\)\)(?=(?=[[:punct:]]\W)|,|\s|\]|<|$)}

        def parse_footnotes(text, project, obj, attr, only_path, options)
            footnotes = []

            text.gsub!(WIKING_FOOTNOTE_RE) do |m|
                leading, esc, content = $1, $2, $3
                if esc.nil?
                    footnotes << content
                    leading + '<sup><a href="#fng' + footnotes.size.to_s + '">' + footnotes.size.to_s + '</a></sup>'
                else
                    leading + '((' + content + '))'
                end
            end

            if footnotes.any?
                text << '<div id="footnotes" class="footnotes">'
                footnotes.each_with_index do |footnote, index|
                    text << '<p id="fng' + (index + 1).to_s + '" class="footnote"><sup>' + (index + 1).to_s + '</sup> ' + footnote + "</p>\n"
                end
                text << '</div>'
            end
        end

        def textilizable_with_wiking(*args)
            @mentions = []

            text = textilizable_without_wiking(*args)

            options = args.last.is_a?(Hash) ? args.pop : {}
            case args.size
            when 1
                object = options[:object]
            when 2
                object = args[0]
            end

            if object && !object.new_record? && object.changed.size == 0 && (controller_name rescue nil) != 'previews' && (action_name rescue nil) != 'preview'
                update_mentions(object, @mentions)
            end

            if (!defined?(ChiliProject) || ChiliProject::VERSION::MAJOR < 3) && Redmine::VERSION::MAJOR == 1 && Redmine::VERSION::MINOR == 0 # For Redmine 1.0
                case args.size
                when 1
                    obj = options[:object]
                when 2
                    obj = args.shift
                    attr = args.shift
                else
                    return text
                end
                return text if text.blank?
                project = options[:project] || @project || (obj && obj.respond_to?(:project) ? obj.project : nil)
                only_path = options.delete(:only_path) == false ? false : true

                parse_wiking_conditions(text, project, obj, attr, only_path, options)
            end

            text
        end

        def parse_headings_with_wiking(text, project, obj, attr, only_path, options)
            parse_wiking_conditions(text, project, obj, attr, only_path, options)
            parse_glyphs(text, project, obj, attr, only_path, options)

            parse_headings_without_wiking(text, project, obj, attr, only_path, options)

            parse_footnotes(text, project, obj, attr, only_path, options)
        end

        WIKING_LINK_RE = %r{(!)?(\[\[(wikipedia|google|redmine|chiliproject)(?:\[([^\]]+)\])?>([^\]\n\|]+)(?:\|([^\]\n\|]+))?\]\])}

        def parse_wiki_links_with_wiking(text, project, obj, attr, only_path, options)

            # External links:
            #   [[wikipedia>Ruby (programming language)#Features|Ruby]] -> Link to Wikipedia page describing Ruby language
            #   [[google>Redmine Wiki|check search results]] -> Link to google search results for "Redmine Wiki"
            text.gsub!(WIKING_LINK_RE) do |m|
                esc, all, resource, option, page, title = $1, $2, $3, $4, $5, $6
                if esc.nil?
                    title ||= page
                    case resource
                    when 'wikipedia'
                        lang = (option || 'en')
                        if page =~ %r{^(.+?)#(.*)$}
                            page, anchor = $1, $2
                        end
                        page = URI.escape(page.gsub(%r{\s}, '_'))
                        page << '#' + URI.escape(anchor) if anchor
                        link_to(h(title), "http://#{URI.escape(lang)}.wikipedia.org/wiki/#{page}", :class => 'wiking external wiking-wikipedia')
                    when 'google'
                        link_to(h(title), "http://www.google.com/search?q=#{URI.escape(page)}", :class => 'wiking external wiking-google')
                    when 'redmine', 'chiliproject'
                        if page =~ %r{^#([0-9]+)$}
                            page = $1
                            link_to(h(title).gsub(%r{##{page}}){ |s| "!##{page}" }, "http://www.#{resource}.org/issues/#{page}", :class => "wiking external wiking-#{resource} wiking-issue")
                        else
                            if page =~ %r{^(.+?)#(.*)$}
                                page, anchor = $1, $2
                            end
                            page = URI.escape(page)
                            page << '#' + URI.escape(anchor) if anchor
                            link_to(h(title), "http://www.#{resource}.org/projects/#{resource}/wiki/#{page}", :class => "wiking external wiking-#{resource}")
                        end
                    end
                else
                    all
                end
            end

            parse_wiki_links_without_wiking(text, project, obj, attr, only_path, options)
        end

        WIKING_USER_RE = %r{([\s\(,\-\[\>]|^)(!)?(([a-z0-9\-_]+):)?(user|file)(\(([^\)]+?)\)|\[([^\]]+?)\])?(?:(#)(\d+)|(:)([^"\s<>][^\s<>]*?|"[^"]+?"))(?=(?=[[:punct:]]\W)|,|\s|\]|<|$)}m

        def parse_redmine_links_with_wiking(text, project, obj, attr, only_path, options)
            parse_redmine_links_without_wiking(text, project, obj, attr, only_path, options)

            # Users:
            #   user#1 -> Link to user with id 1
            #   user:s-andy -> Link to user with username "s-andy"
            #   user:"s-andy" -> Link to user with username "s-andy"
            #   user(me)#1 | user(me):s-andy -> Display "me" instead of firstname and lastname
            #   user[f]#1 | user[f]:s-andy -> Display firstname
            # Files:
            #   file#1 -> Link to file with id 1
            #   file:filename.ext -> Link to file with filename "filename.ext"
            #   file:"filename.ext" -> Link to file with filename "filename.ext"
            #   file(download here)#1 | file(download here):filename.ext -> Display "download here" instead of filename
            text.gsub!(WIKING_USER_RE) do |m|
                leading, esc, project_prefix, project_identifier, prefix, option, display, format, sep, identifier = $1, $2, $3, $4, $5, $6, $7, $8, $9 || $11, $10 || $12
                link = nil
                if esc.nil?
                    if project_identifier
                        project = Project.visible.find_by_identifier(project_identifier)
                    end
                    if prefix == 'user' && format
                        case format
                        when 'fl'
                            format = 'firstname_lastname'
                        when 'f'
                            format = 'firstname'
                        when 'lf'
                            format = 'lastname_firstname'
                        when 'u'
                            format = 'username'
                        end
                        format = format.to_sym
                    end
                    if sep == '#'
                        oid = identifier.to_i
                        case prefix
                        when 'user'
                            if user = User.find_by_id(oid)
                                name = display || user.name(format)
                                if user.active?
                                    user_id = user.login.match(%r{^[a-z0-9_\-]+$}i) ? user.login.downcase : user
                                    link = link_to(h(name), { :only_path => only_path, :controller => 'users', :action => 'show', :id => user_id },
                                                              :class => 'user')
                                else
                                    link = h(name)
                                end

                                @mentions << user
                            end
                        when 'file'
                            if project && file = Attachment.find_by_id(oid)
                                if (file.container.is_a?(Version) && file.container.project == project) ||
                                   (file.container.is_a?(Project) && file.container == project)
                                    name = display || file.filename
                                    link = link_to(h(name), { :only_path => only_path, :controller => 'attachments', :action => 'download', :id => file },
                                                              :class => 'attachment')
                                end
                            end
                        end
                    elsif sep == ':'
                        oname = identifier.gsub(%r{^"(.*)"$}, "\\1")
                        case prefix
                        when 'user'
                            if user = User.find_by_login(oname)
                                name = display || user.name(format)
                                if user.active?
                                    user_id = user.login.match(%r{^[a-z0-9_\-]+$}i) ? user.login.downcase : user
                                    link = link_to(h(name), { :only_path => only_path, :controller => 'users', :action => 'show', :id => user_id },
                                                              :class => 'user')
                                else
                                    link = h(name)
                                end

                                @mentions << user
                            end
                        when 'file'
                            if project
                                conditions = "container_type = 'Project' AND container_id = #{project.id}"
                                if project.versions.any?
                                    conditions = "(#{conditions}) OR "
                                    conditions << "(container_type = 'Version' AND container_id IN (#{project.versions.collect{ |version| version.id }.join(', ')}))"
                                end
                                if file = Attachment.find_by_filename(oname, :conditions => conditions)
                                    name = display || file.filename
                                    link = link_to(h(name), { :only_path => only_path, :controller => 'attachments', :action => 'download', :id => file },
                                                              :class => 'attachment')
                                end
                            end
                        end
                    end
                end
                leading + (link || "#{project_prefix}#{prefix}#{option}#{sep}#{identifier}")
            end

        end

        def inline_dashes(text)
            text.gsub!(%r{([^\w\-])(-{2,3})(?=[^\w\-]|$)}) do |match|
                case $2
                when '--'
                    "#{$1}–"
                else
                    "#{$1}—"
                end
            end
        end

        WIKING_QUOTES_RE = %r{(?:(^|>|\s|[^\w"])(!)?"(?=\w|[^\w"]*")|(\w[^\w"\s]*|[^\w"\s]*)(!)?"(?=[^\w"\s]*(?:\s|<|$)))}

        def inline_quotes(text)
            text.gsub!(WIKING_QUOTES_RE) do |match|
                leading, esc, closing = $1 || $3, $2 || $4, $3
                glyph = ll(Setting.default_language, closing.nil? ? :glyph_left_quote : :glyph_right_quote)
                if esc.nil?
                    leading + glyph
                else
                    leading + '"'
                end
            end
        end

        def inline_apostrophe(text)
            text.gsub!(%r{(\w)'}) do |match|
                "#{$1}’"
            end
        end

        WIKING_ARROWS = {
            '<=>' => '⇔',
            '<->' => '↔',
            '<='  => '⇐',
            '<-'  => '←',
            '=>'  => '⇒',
            '->'  => '→'
        }

        def inline_arrows(text)
            WIKING_ARROWS.sort{ |a, b| b[0].length <=> a[0].length }.each do |code, entity|
                text.gsub!(%r{#{code}}m, entity)
            end
        end

        def link_to_user_with_login(user, options = {})
            if user.is_a?(User) && user.active? && user.login.match(%r{^[a-z0-9_\-]+$}i) && user.login != 'current'
                link_to(h(user.name(options[:format])), :controller => 'users', :action => 'show', :id => user.login.downcase)
            else
                link_to_user_without_login(user, options)
            end
        end

    end

end
