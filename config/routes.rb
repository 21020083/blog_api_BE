Rails.application.routes.draw do
  devise_for :users, path: "", path_names: {
    sign_in: "login",
    sign_out: "logout",
    registration: "signup"
  },
  controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }

  concern :votable do
    member do
      post :upvote
      post :downvote
      post :remove_vote
    end
  end

  concern :blogable do
    resources :blogs, shallow: true, concerns: :votable do
      resources :comments, shallow: true, concerns: :votable
    end
  end

  resources :users, concerns: :blogable
  get "categories/*slug", to: "categories#show"
  resources :categories, concerns: :blogable

  resources :comments, only: [] do
    post :replies, to: "comments#create_reply"
  end
end
