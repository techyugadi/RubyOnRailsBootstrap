#### RubyOnRailsBootstrap
This repository contains scripts to set up a Ruby On Rails application (based on Puma) with an nginx reverse proxy and mysql database.

Simply run `setup.sh` for the chosen platform.

By default, mysql root password is blank, but it can be set in `config/database.yml` in the application directory.

A simple virtual host configuration file is created for nginx according to the app name chosen.

A simple Ruby on Rails app is started on port 3000, and can be accessed through the URL: `http://localhost:3000`. 
To access the same app through nginx, the URL is: `http://127.0.0.1`. In production, the IP address of fully qualified domain name of the host may be supplied.
