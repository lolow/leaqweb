Leaqweb::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'

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
     collection do
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
