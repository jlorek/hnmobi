use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :hnmobi, HnmobiWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :hnmobi, Hnmobi.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "hnmobi_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :hnmobi, :pandoc_path, "pandoc"
config :hnmobi, :kindlegen_path, "./bin/KindleGen_Mac_i386_v2_9/kindlegen"