Leaqweb::Application.routes.draw do |map|
  
  devise_for :users

  resources :stored_queries do
    member do
      get :duplicate
    end
  end

  resources :outputs do  
    member do
      get :csv
      get :import
    end 
  end

  resources :technologies do  
    member do
      post :duplicate
      post :emission
    end  
  end

  resources :commodities do  
    member do
      post :duplicate
    end
  end
  
  resources :combustions do
    collection do
      put :update
    end
  end

  resources :parameter_values do
    collection do
      put :update
    end
  end

  resources :flows
  resources :markets
  resources :aggregates
  resources :solvers
  resources :demand_drivers
  
  match '/backup.zip', :to => 'dashboard#backup', :as => 'backup_db'
  match '/restore', :to => 'dashboard#restore', :as => 'restore_db'
  match '/check_db', :to => 'dashboard#check_db', :as => 'check_db'
  match '/reset', :to => 'dashboard#reset', :as => 'reset_db'

  match '/log', :to => 'dashboard#log', :as => 'log'

  root :to => 'dashboard#index'

  #match ':controller(/:action(/:id(.:format)))'
end