Leaq web application
====================

Leaqweb is a web application which manages the leaq database

It is based on Rails 3. It can be install on a server or a desktop machine.

Install
-------

The following instructions describe how to install the application 
on an ubuntu machine (it works also on Mac OS X, not tested on windows yet).


1) Install ruby (works with ruby 1.8.7)

    # sudo apt-get install ruby ruby-dev rubygems libopenssl-ruby

2) Install rubygems from source (the version will be more up-to-date)
http://rubygems.org/pages/download

3) Install rails

    # sudo gem update --system
    # sudo gem install rails
    # sudo gem install mongrel

4) Configure the database (if you want to use mysql)

    # sudo apt-get install mysql-server mysql-client
    # sudo gem install mysql
    # mysql -p -u root
    <enter your root password for mysql>
    > CREATE DATABASE leaq;
    > GRANT ALL PRIVILEGES ON leaq.* TO "leaq"@"localhost";

5) Configure the database (if you want to use sqlite)

    # sudo apt-get install sqlite3 libsqlite3-dev

6) Clone the repository, configure and install gems:

    # git clone git://github.com/lolow/leaqweb.git
    # cd leaqweb
    # cp config/database.yml{.default,}
    # sudo gem install bundler
    # bundle install
    # rake db:setup

7) Install R to compute result cross-tables

    # sudo apt-get install r-base
    # sudo R
    # install.packages('reshape',dependencies=TRUE)
  
8) Run it
  
    # rails server
    # firefox http://127.0.0.1:3000/

Copyright
---------

The code is licensed as GNU AGPLv3. See the LICENSE file for the full license.

Copyright (c) 2009-2010 Laurent Drouet <ldrouet at gmail dot com>