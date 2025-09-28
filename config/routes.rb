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
    resources :blogs, only: [ :index, :show ], shallow: true, concerns: :votable do
      resources :comments, shallow: true, concerns: :votable
    end
  end
  resources :users, concerns: :blogable
  resources :blogs, shallow: true, concerns: :votable


  resources :categories, only: [ :index ], concerns: :blogable do
    resources :blogs, only: [ :index ], concerns: :votable
  end

  resources :tags, only: [ :index ], concerns: :blogable do
    resources :blogs, only: [ :index ], concerns: :votable
  end

  resources :tags, only: [ :show, :create, :update, :destroy ]
  resources :categories, only: [ :show, :create, :update, :destroy ]


  resources :comments, only: [] do
    post :replies, to: "comments#create_reply"
  end

  resources :analytics, only: [] do
    collection do
      get :top_views
      get :top_likes
      get :summary
    end
  end

  resources :bookmarks, only: [ :index, :create, :destroy ]
  mount LetterOpenerWeb::Engine, at: "/letter_opener"

  resources :audit_logs, only: [ :index, :show, :destroy ]
end
