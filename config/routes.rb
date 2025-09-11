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
  resources :users do
    resources :blogs, shallow: true do
      member do
        post :upvote
        post :downvote
        post :remove_vote
      end
      resources :comments, shallow: true do
        member do
          post :upvote
          post :downvote
          post :remove_vote
        end
      end
    end
  end
  resources :comments, only: [] do
    post :replies, to: "comments#create_reply"
  end
end
