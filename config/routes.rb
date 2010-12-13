Leaqweb::Application.routes.draw do |map|
  
  resources :markets

  devise_for :users

  resources :queries do
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
  resources :solver
  resources :demand_drivers
  
  match '/backup.zip' => 'dashboard#backup'
  match '/restore' => 'dashboard#restore'
  root :to => 'dashboard#index'

  match ':controller(/:action(/:id(.:format)))'
end