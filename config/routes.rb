Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "imports#new"

  resources :imports, only: [ :new, :create, :show ] do
    collection do
      get :status
    end
  end

  resources :import_batches, only: [ :show ]

  resources :grants, only: [ :index, :update ] do
    collection do
      post :bulk_update
    end
  end

  # Admin routes (demo purposes - no auth)
  get "admin", to: "admin#index"
  delete "admin/grants", to: "admin#destroy_all_grants", as: "admin_destroy_grants"
  delete "admin/batches", to: "admin#destroy_all_batches", as: "admin_destroy_batches"
end
