#!/bin/bash

# This script sets up a basic Ruby on Rails environment using Puma, with MySQL
# as database and ngnix as reverse proxy. It also deploys a test application
# called 'myapp' running on port 3000. The appication can be accessed through
# nginx on HTTP port 80.

# Set versions and application name before running the script
NODEJS_VER=13
RUBY_VER=2.6.5
RAILS_VER=6.0.1
APPNAME=myapp

sudo apt install curl

# Install Node.js for Javascript compilation required by RoR
sudo apt-get install -y gcc g++ make
curl -sL https://deb.nodesource.com/setup_$NODEJS_VER.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install pre-requisite packages
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update
sudo apt-get install -y git-core zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev nodejs yarn

# Install Ruby using rbenv
cd
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
exec $SHELL

git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
exec $SHELL

rbenv install --verbose $RUBY_VER
rbenv global $RUBY_VER
ruby -v

# Install bundler
gem install bundler
rbenv rehash

# Install RAILS
gem install rails -v $RAILS_VER
rbenv rehash

# Install MySQL
sudo apt-get install -y mysql-server mysql-client libmysqlclient-dev
# Install mysql2 gem
gem install mysql2
rbenv rehash

# Ensure MySQL is accessible to Rails app using default (blank) password
sudo mysql --user="root" --password="" --execute="ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY ''" 
sudo mysql --user="root" --password="" --execute="FLUSH PRIVILEGES"

# Create an app using MySQL as database
rails new $APPNAME -d mysql
# Initialize the database
cd $APPNAME
rake db:create

# Start the app
rails server -d

# Check the HTTP Status Code
status_ror=`curl -s -w "%{http_code}\n" http://localhost:3000 -o /dev/null`

if [ $status_ror == "200" ]; then
  echo "App Started successfully"
  pkill ruby
else 
  echo "App Not started successfully. Cleaning up anyway"
  pkill ruby
fi

# Install nginx
sudo apt-get install -y nginx

# Set up nginx as proxy
cp myapp /tmp/$APPNAME
sudo cp /tmp/$APPNAME /etc/nginx/sites-available/.
sudo ln -nfs /etc/nginx/sites-available/$APPNAME /etc/nginx/sites-enabled/$APPNAME
sudo systemctl restart nginx

# Start the app again
rails server -d

# Check the HTTP Status Code through nginx
status_nginx=`curl -s -w "%{http_code}\n" http://127.0.0.1:3000 -o /dev/null`

if [ $status_nginx == "200" ]; then
  echo "Nginx proxy working"
  pkill ruby
else 
  echo "Nginx proxy not working"
  pkill ruby
fi
