class MacrosController < ApplicationController
  layout 'admin'
  menu_item :custom_macros

  before_action :require_admin
  before_action :find_macro, :only => [:edit, :update, :destroy]

  def index
    @macros = WikiMacro.order(:name)
  end

  def new
    @macro = WikiMacro.new
  end

  def create
    @macro = WikiMacro.new(macro_params)
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
    if params[:wiki_macro]
      old_name = @macro.name
      @macro.update_attributes(macro_params)
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

  private

  def macro_params
    params.require(:wiki_macro).permit(:name, :description, :content)
  end

end
