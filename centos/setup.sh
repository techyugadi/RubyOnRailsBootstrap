#!/bin/bash

# This script sets up a basic Ruby on Rails environment using Puma, with MySQL
# as database and ngnix as reverse proxy. It also deploys a test application
# called 'myapp' running on port 3000. The appication can be accessed through
# nginx on HTTP port 80.

# Set versions and application name before running the script
NODEJS_VER=13
RUBY_VER=2.6.5
RAILS_VER=6.0.1
MYSQL_VER=80
APPNAME=myapp

# Choose a strong mysql root password
MYPASS=Mysql12_

scriptdir=`dirname "$(readlink -f "$0")"`

sudo yum install -y curl

# Install Node.js for Javascript compilation required by RoR
sudo yum install -y gcc-c++ make
curl -sL https://rpm.nodesource.com/setup_$NODEJS_VER.x | sudo -E bash -
sudo yum install -y nodejs

# Install pre-requisite packages
sudo yum install -y git-core zlib zlib-devel gcc-c++ patch readline readline-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison

# Install Ruby using rbenv
cd
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
source ~/.bash_profile

git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bash_profile
source ~/.bash_profile

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
sudo yum localinstall -y https://dev.mysql.com/get/mysql_$MYSQL_VER-community-release-el7-1.noarch.rpm
sudo yum update -y
sudo yum install -y mysql-server
sudo systemctl start mysqld
sudo systemctl enable mysqld
# Install mysql2 gem
sudo yum install -y mysql-devel
gem install mysql2
rbenv rehash

sudo systemctl stop mysqld
sudo systemctl set-environment MYSQLD_OPTS="--skip-grant-tables --skip-networking"
sudo systemctl start mysqld
# First reset the root password to blank
sudo mysql --user="root" --execute="UPDATE mysql.user SET authentication_string = '' WHERE User = 'root' AND Host = 'localhost' ; FLUSH PRIVILEGES"
sudo systemctl stop mysqld
sudo systemctl unset-environment MYSQLD_OPTS
sudo systemctl start mysqld
# Finally set root password to $MYPASS
sudo mysql --user="root" --password="" --connect-expired-password --execute="SET PASSWORD FOR 'root'@'localhost' = '$MYPASS'"

# Create an app using MySQL as database
rails new $APPNAME -d mysql
# Initialize the database
cd $APPNAME
appdir=`pwd`

# First update the Mysql root password in rails db config
passline="password: $MYPASS"
sed -i "s/password:$/$passline/" $appdir/config/database.yml

rake db:create

curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
sudo yum install -y yarn
rails webpacker:install
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
sudo yum install -y epel-release
sudo yum install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Set up nginx as proxy
cd $scriptdir
cp myapp /tmp/$APPNAME
sudo cp /tmp/$APPNAME "/etc/nginx/conf.d/$APPNAME.conf"
sudo systemctl restart nginx

# Start the app again
cd $appdir
rails server -d

# Check the HTTP Status Code through nginx
status_nginx=`curl -s -w "%{http_code}\n" http://127.0.0.1 -o /dev/null`

if [ $status_nginx == "200" ]; then
  echo "Nginx proxy working"
  pkill ruby
else 
  echo "Nginx proxy not working"
  pkill ruby
fi
