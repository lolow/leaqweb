Leaqweb::Application.routes.draw do |map|
  
  devise_for :users

  map.resources :commodities,
                :member => {:duplicate => :post},
                :collection => {:list => :get, :destroy_all => :delete}

  map.resources :technologies,
                :member => {:duplicate => :post, :emission => :post},
                :collection => {:list => :get, :destroy_all => :delete}

  map.resources :demand_drivers,
                :collection => {:list => :get, :destroy_all => :delete}

  map.resources :combustions,
                :collection => {:list => :get, :destroy_all => :delete, :update_value => :put}

  map.resources :solvers,
                :collection => {:list => :get, :destroy_all => :delete}

  map.resources :parameter_values,
                :collection => {:update => :put}

  map.resources :outputs,
                :member => {:csv => :get, :import => :get},
                :collection => {:list => :get, :destroy_all => :delete}

  map.resources :stored_queries,
                :member => {:duplicate => :get},
                :collection => {:list => :get, :destroy_all => :delete}

  map.resources :flows
  map.resources :markets
  map.resources :aggregates


  
  match '/backup.zip', :to => 'dashboard#backup',   :as => 'backup_db'
  match '/restore',    :to => 'dashboard#restore',  :as => 'restore_db'
  match '/check_db',   :to => 'dashboard#check_db', :as => 'check_db'
  match '/reset',      :to => 'dashboard#reset',    :as => 'reset_db'
  match '/log',        :to => 'dashboard#log',      :as => 'log'

  root :to => 'dashboard#index'

end