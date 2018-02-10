kill -9 `ps -aux | grep '/usr/lib/erlang' | grep -v grep | awk '{print $2}'`
git pull
mix deps.get --only prod
cd assets
npm install
brunch build --production
cd ..
MIX_ENV=prod mix phx.digest
MIX_ENV=prod mix ecto.migrate
MIX_ENV=prod elixir --detached -S mix do compile, phx.server
