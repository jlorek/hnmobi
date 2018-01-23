# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :hnmobi,
  ecto_repos: [Hnmobi.Repo]

# Configures the endpoint
config :hnmobi, HnmobiWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Ck3AfxbTvqnnMa5d1tf3b4HSQ2L4jmW7UKcA4Ul4XKsGHSLHQb0c6t3or4Ek4270",
  render_errors: [view: HnmobiWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Hnmobi.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :hnmobi, Hnmobi.Main.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
    api_key: "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"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

# Import Timber, structured logging
import_config "timber.exs"
