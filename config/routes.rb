Leaqweb::Application.routes.draw do
  
  devise_for :users

  resources :commodities do
    member do
      post :duplicate
    end
    collection do
      get :list
      delete :destroy_all
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
    end
  end

  resources :demand_drivers do
    collection do
      get :list
      delete :destroy_all
    end
  end

  resources :combustions do
    collection do
      get :list
      delete :destroy_all
      put :update_value
    end
  end

  resources :solvers do
    collection do
      get :list
      delete :destroy_all
    end
  end

  resources :parameter_values do
    collection do
      put :update_value
    end
  end

  resources :result_sets do
     member do
       get :file
       get :import
     end
     collection do
       get :list
       delete :destroy_all
     end
  end

  resources :stored_queries do
     member do
       get :duplicate
     end
     collection do
       get :list
       delete :destroy_all
     end
  end

  resources :versions do
     member do
       get :list
     end
  end

  resources :flows
  resources :markets
  resources :aggregates
  
  match '/backup.zip'        => 'dashboard#backup',   :as => 'backup_db'
  match '/restore'           => 'dashboard#restore',  :as => 'restore_db'
  match '/check_db'          => 'dashboard#check_db', :as => 'check_db'
  match '/reset'             => 'dashboard#reset',    :as => 'reset_db'
  post "versions/:id/revert" => "versions#revert",    :as => "revert_version"

  root :to => 'dashboard#index'

end
