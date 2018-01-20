kill -9 `ps -aux | grep '/usr/lib/erlang' | grep -v grep | awk '{print $2}'`
git pull
mix deps.get --only prod
MIX_ENV=prod elixir --detached -S mix do compile, phx.server
