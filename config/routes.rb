Rails.application.routes.draw do
  resources :projects, :id => /\d+/ do
    collection do
      get  :advanced_search
      post :filter
      get  :options
      get  :field_group
      match :auto_complete
      get  :redraw
      get  :versions
    end
    member do
      put  :attach
      post :discard
      post :subscribe
      post :unsubscribe
      get  :contacts
    end
  end
end
