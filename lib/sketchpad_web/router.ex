defmodule SketchpadWeb.Router do
  use SketchpadWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SketchpadWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    post "/signin", PageController, :signin # Should really be in its own controller.  USing page for brevity
  end
end
