
    get('mentions/:id',      :to => 'mentions#index')
    get('macros',            :to => 'macros#index')
    get('macros/new',        :to => 'macros#new')
    post('macros/create',    :to => 'macros#create')
    get('macros/:id/edit',   :to => 'macros#edit')
    put('macros/:id',        :to => 'macros#update')
    delete('macros/:id',     :to => 'macros#destroy')

