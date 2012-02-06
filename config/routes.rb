Iconomus::Application.routes.draw do
  root :to => "home#index"
  match ":id" => 'icons#show'
end
