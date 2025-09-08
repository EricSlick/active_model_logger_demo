Rails.application.routes.draw do
  root "home#index"

  get "home/index"
  post "home/create_demo", as: :create_demo
  post "home/create_session_demo", as: :create_session_demo
  post "home/create_batch_demo", as: :create_batch_demo
  post "home/create_cleanup_demo", as: :create_cleanup_demo
  post "home/create_block_demo", as: :create_block_demo
  delete "home/clear_logs", as: :clear_logs
  delete "home/cleanup_old_logs", as: :cleanup_old_logs

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
