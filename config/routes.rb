ActionController::Routing::Routes.draw do |map|

  map.resources :tables, :member => {:clone => :get}
  map.resources :outputs, :except => [:edit], :member => { :import => :get, :csv => :get }
  map.resources :solver, :except => [:edit]
  map.resources :demand_drivers, :controller => :drivers
  map.resources :technologies, :member => { :clone => :post }
  map.resources :commodities, :member => { :clone => :post }
  map.resources :flows
  map.devise_for :users

  map.root :controller => "welcome"

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
