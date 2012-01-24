Doubloon::Application.routes.draw do
  resources :icons, :only => [:show]
  root :to => "home#index"
end
