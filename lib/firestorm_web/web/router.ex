defmodule FirestormWeb.Web.Router do
  use FirestormWeb.Web, :router
  use ExAdmin.Router

  pipeline :browser do
    plug Ueberauth
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug FirestormWeb.Web.Plugs.CurrentUser
    plug FirestormWeb.Web.Plugs.Notifications
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug FirestormWeb.Web.Plugs.ApiCurrentUser
  end

  pipeline :admin do
    plug Ueberauth
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug FirestormWeb.Web.Plugs.CurrentUser
    plug FirestormWeb.Web.Plugs.RequireAdmin
    plug FirestormWeb.Web.Plugs.Notifications
  end

  # setup the ExAdmin routes on /admin
  scope "/admin", ExAdmin do
    pipe_through :admin
    admin_routes()
  end

  scope "/auth", FirestormWeb.Web do
    pipe_through :browser

    get "/logout", AuthController, :delete
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    post "/:provider/callback", AuthController, :callback
    delete "/logout", AuthController, :delete
  end

  scope "/", FirestormWeb.Web do
    pipe_through :browser # Use the default browser stack

    get "/", ThreadController, :recent
    get "/login", AuthController, :login
    resources "/users", UserController, only: [:index, :edit, :update, :show]
    get "/threads/watching", ThreadController, :watching
    get "/threads/participating", ThreadController, :participating
    resources "/notifications", NotificationController, only: [:index, :show]
    resources "/categories", CategoryController do
      get "/threads/:id/watch", ThreadController, :watch
      get "/threads/:id/unwatch", ThreadController, :unwatch

      resources "/threads", ThreadController do
        resources "/posts", PostController, only: [:new, :create]
      end
    end
  end

  # API routes
  scope "/api/v1", FirestormWeb.Web.Api.V1 do
    pipe_through :api

    resources "/preview", PreviewController, only: [:create]
    resources "/upload_signature", UploadSignatureController, only: [:create]
    resources "/posts", PostController, only: [:create]
    post "/auth/identity", AuthController, :identity
  end

  # Inbound email routes
  scope "/inbound", FirestormWeb.Web do
    pipe_through :api

    post "/sendgrid", InboundController, :sendgrid
  end

  if Mix.env == :dev do
    forward "/sent_emails", Bamboo.SentEmailViewerPlug
  end
end
