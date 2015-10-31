class MacrosController < ApplicationController
    layout 'admin'
    menu_item :custom_macros

    before_filter :require_admin
    before_filter :find_macro, :only => [ :edit, :update, :destroy ]

    def index
        @macros = WikiMacro.all(:order => :name)
    end

    def new
        @macro = WikiMacro.new
    end

    def create
        @macro = WikiMacro.new(params[:wiki_macro])
        if request.post? && @macro.save
            flash[:notice] = l(:notice_successful_create)
            @macro.register!
            redirect_to(:action => 'index')
        else
            render(:action => 'new')
        end
    end

    def edit
    end

    def update
        if request.put?
            old_name = @macro.name
            @macro.attributes = params[:wiki_macro]
            name_changed = @macro.name_changed?
            desc_changed = @macro.description_changed?
            if @macro.save
                if name_changed
                    WikiMacro.unregister!(old_name)
                    @macro.register!
                elsif desc_changed
                    @macro.update_description!
                end
                flash[:notice] = l(:notice_successful_update)
                redirect_to(:action => 'index')
            else
                render(:action => 'edit')
            end
        else
            render(:action => 'edit')
        end
    end

    def destroy
        if request.delete?
            @macro.unregister!
            @macro.destroy
        end
        redirect_to(:action => 'index')
    end

private

    def find_macro
        @macro = WikiMacro.find(params[:id])
    rescue ActiveRecord::RecordNotFound
        render_404
    end

end
