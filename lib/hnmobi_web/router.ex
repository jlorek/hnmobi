defmodule HnmobiWeb.Router do
  use HnmobiWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Turbolinks
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HnmobiWeb do
    pipe_through :browser # Use the default browser stack

    # Main Routes
    get "/", PageController, :index
    get "/help", PageController, :help
    get "/next-steps", PageController, :next_steps
    get "/top", PageController, :top
    get "/show/:hnid/:scraper", PageController, :show
    get "/mobi/:hnid", PageController, :mobi
    get "/user/:hash", PageController, :config_user
    get "/sponsors", PageController, :sponsors

    put "/user/update", PageController, :update_user
    post "/top/email", PageController, :create_user

    # Debug Routes
    get "/debug", DebugController, :index
    get "/debug/show", DebugController, :show
    get "/debug/download", DebugController, :download
    get "/debug/send/:email", DebugController, :send_email
    get "/debug/daily/:email", DebugController, :send_daily

    get "/*path", CatchAllController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", HnmobiWeb do
  #   pipe_through :api
  # end
end
