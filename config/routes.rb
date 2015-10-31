if Rails::VERSION::MAJOR < 3

    ActionController::Routing::Routes.draw do |map|
        map.connect('mentions/:id',    :controller => 'mentions', :action => 'index')
        map.connect('macros',          :controller => 'macros',   :action => 'index')
        map.connect('macros/new',      :controller => 'macros',   :action => 'new')
        map.connect('macros/create',   :controller => 'macros',   :action => 'create',  :conditions => { :method => :post })
        map.connect('macros/:id/edit', :controller => 'macros',   :action => 'edit')
        map.connect('macros/:id',      :controller => 'macros',   :action => 'update',  :conditions => { :method => :put })
        map.connect('macros/:id',      :controller => 'macros',   :action => 'destroy', :conditions => { :method => :delete })
    end

else

    match('mentions/:id',    :to => 'mentions#index')
    match('macros',          :to => 'macros#index')
    match('macros/new',      :to => 'macros#new')
    post('macros/create',    :to => 'macros#create')
    match('macros/:id/edit', :to => 'macros#edit')
    put('macros/:id',        :to => 'macros#update')
    delete('macros/:id',     :to => 'macros#destroy')

end
