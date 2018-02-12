# local setup

- Install the pandoc first with like `brew install pandoc`
- Download kindlegen and create symlink from `/use/bin/kindlegen`

# hackernews.mobi setup

## create fresh ubuntu 16.04 LTS droplet
```
$ sudo apt-get update
```

## create new user
https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-16-04
```
# as root user
$ adduser app
$ usermod -aG sudo app 
$ su - app
$ mkdir ~/.ssh
$ chmod 700 ~/.ssh
$ nano ~/.ssh/authorized_keys
# paste public key
$ chmod 600 ~/.ssh/authorized_keys
```

## create swapfile
https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-ubuntu-16-04

## update LC_ALL
https://stackoverflow.com/a/32407431/1010496
```
$ nano -w /etc/default/locale
# append
# LC_ALL=en_US.UTF-8
# or maybe just
$ echo 'LC_ALL=en_US.UTF-8' | sudo tee -a /etc/default/locale
```

## node via nvm
https://github.com/creationix/nvm#install-script
```
# as app user
$ curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
# close shell and reconnect
$ nvm install --lts
```

## brunch
```
# npm install -g brunch
```

## python 2.7
required for KindleUnpack - https://github.com/kevinhendricks/KindleUnpack
```
$ sudo apt install python2.7 python-pip
```

## inotify-tools
https://github.com/rvoicilas/inotify-tools/wiki
```
# as app user
# for hot-reload in elixir
$ sudo apt-get install inotify-tools
```

## postgresql
https://www.digitalocean.com/community/tutorials/how-to-install-and-use-postgresql-on-ubuntu-16-04
```
$ sudo apt-get install postgresql postgresql-contrib
$ sudo -i -u postgres
$ createuser --createdb --pwprompt prd
$ createdb --owner=prd hnmobile
```
And some PSQL commands for quick lookup
```
# psql
# CREATE ROLE prd WITH LOGIN PASSWORD 'prd';
# For existing user: ALTER USER prd WITH PASSWORD 'prd';
# ALTER ROLE prd CREATEDB;
# CREATE DATABASE hnmobile;
# GRANT ALL PRIVILEGES ON DATABASE hnmobile TO prd;
# \du
# \list
```

## pandoc
dont install from repository since it's outdated
```
$ wget https://github.com/jgm/pandoc/releases/download/2.1.1/pandoc-2.1.1-1-amd64.deb
$ sudo dpkg -i pandoc-2.1.1-1-amd64.deb
```

## kindlegen
https://www.amazon.com/gp/feature.html?docId=1000765211
```
$ wget http://kindlegen.s3.amazonaws.com/kindlegen_linux_2.6_i386_v2_9.tar.gz
$ mkdir kindlegen
$ tar vxzf kindlegen_linux_2.6_i386_v2_9.tar.gz -C kindlegen
sudo ln -s /home/app/kindlegen/kindlegen /usr/local/bin/kindlegen
```

## erlang, elixir, phoenix
https://www.digitalocean.com/community/tutorials/how-to-automate-elixir-phoenix-deployment-with-distillery-and-edeliver-on-ubuntu-16-04#step-1-�-installing-elixir-and-phoenix-on-the-local-development-machine
```
$ wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
$ sudo dpkg -i erlang-solutions_1.0_all.deb
$ sudo apt-get update
$ sudo apt-get install esl-erlang
$ sudo apt-get install elixir
$ mix local.hex
$ mix local.rebar
$ mix archive.install https://github.com/phoenixframework/archives/raw/master/phx_new-1.3.0.ez
```

## nginx
https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-16-04
```
$ sudo apt-get install nginx
```
some basic configuration

https://www.digitalocean.com/community/tutorials/how-to-automate-elixir-phoenix-deployment-with-distillery-and-edeliver-on-ubuntu-16-04#step-9-�-setting-up-a-reverse-proxy-on-the-production-server
```
$ sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.original
$ sudo nano -w /etc/nginx/sites-available/default
```

at the very top add
```
upstream phoenix {
    server 127.0.0.1:4000;
}
```
then find the following block
```
location / {
        # First attempt to serve request as file, then
        # as directory, then fall back to displaying a 404.
        try_files $uri $uri/ =404;
}
```
and replace with
```
  location / {
    allow all;

    # Proxy Headers
    proxy_http_version 1.1;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_set_header X-Cluster-Client-Ip $remote_addr;

    # WebSockets
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";

    proxy_pass http://phoenix;
  }
```
verify the configuration and restart
```
$ sudo nginx -t
$ sudo systemctl restart nginx
```

## nginx with tls
https://www.digitalocean.com/community/tutorials/how-to-set-up-let-s-encrypt-with-nginx-server-blocks-on-ubuntu-16-04
```
TODO
```

## get up running
```
$ git clone https://jlorek@bitbucket.org/thegermans/elixir.git
$ cd elixir/assets && npm install
```

### for development
```
$ mix dept.get
$ mix phx.server
```

### for release
https://hexdocs.pm/phoenix/deployment.html
```
$ mix deps.get --only prod
$ MIX_ENV=prod mix compile
$ cd assets && npm install && brunch build --production
$ MIX_ENV=prod mix phx.digest
$ MIX_ENV=prod mix ecto.migrate
```
for testing the server
```
$ MIX_ENV=prod mix phx.server
```
or daemonize
```
$ MIX_ENV=prod elixir --detached -S mix do compile, phx.server
```

# Hello

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
