Leaqweb::Application.routes.draw do

  get "parameter/suggest"

  devise_for :users

  resources :commodities do
    member do
      post :duplicate
    end
    collection do
      get :list
      delete :destroy_all
      get :suggest
      get :suggest_pollutant
      get :suggest_fuel
    end
  end

  resources :technologies do
    member do
      post :duplicate
      post :emission
    end
    collection do
      get :list
      delete :destroy_all
      get :suggest
    end
  end

  resources :demand_drivers do
    collection do
      get :list
      delete :destroy_all
    end
  end

  resources :demand_driver_values do
    collection do
      put :update_value
    end
  end

  resources :technology_sets do
    collection do
      get :list
      delete :destroy_all
      get :suggest
    end
  end

  resources :commodity_sets do
    collection do
      get :list
      delete :destroy_all
      get :suggest
    end
  end

  resources :combustions do
    collection do
      get :list
      get :import
      get :download
      post :zip
      post :upload
      delete :destroy_all
      put :update_value
    end
  end

  resources :solver_jobs do
    collection do
      get :list
      delete :destroy_all
    end
  end

  resources :parameter_values do
    collection do
      put :update_value
      post :destroy_all
      post :list
    end
  end

  resources :parameters do
    collection do
      get :suggest
    end
  end

  resources :result_sets do
     member do
       get :file
     end
     collection do
       post :import
       get :list
       get :suggest
       delete :destroy_all
     end
  end

  resources :scenarios do
     member do
       get :duplicate
     end
     collection do
       post :select
       get :list
       get :suggest
       delete :destroy_all
     end
  end

  resources :stored_queries do
     member do
       get :duplicate
     end
     collection do
       get :list
       get :import
       get :download
       post :upload
       post :zip
       delete :destroy_all
     end
  end

  resources :versions do
     collection do
       get :list
     end
  end

  resources :flows

  resources :energy_systems do
    member do
      get :backup
      get :restore
      post :upload
    end
    collection do
      post :select
    end
  end

  match '/check_db'          => 'dashboard#check_db', :as => 'check_db'
  match '/reset'             => 'dashboard#reset',    :as => 'reset_db'
  match 'query'              => 'query#index',        :as => 'query'
  get   'query_plot'         => 'query#result_plot',  :as => 'query_plot', :defaults => { :format => 'png' }
  post "versions/:id/revert" => "versions#revert",    :as => "revert_version"

  root :to => 'dashboard#index'

end