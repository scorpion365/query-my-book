Rails.application.routes.draw do
  root 'pages#index'
  post '/ask', to: 'pages#ask' 
end