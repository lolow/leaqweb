Leaq web application
====================

Leaqweb is a web application which manages the leaq database

It is based on Rails 3.2 and can be installed on a server or a desktop machine.

Install
-------

The following instructions describe how to install the application 
on an ubuntu machine (it also works on Mac OS X with few adjustments, for Windows see below).

1) Install ruby 1.9.2 with RVM (http://beginrescueend.com/)

2) Configure the database (if you want to use mysql)

    # sudo apt-get install mysql-server mysql-client libmysqlclient-dev
    # gem install mysql2

3) Configure the database (if you want to use sqlite)

    # sudo apt-get install sqlite3 libsqlite3-dev

4) Clone the repository

    # git clone git://github.com/lolow/leaqweb.git
    # cd leaqweb
    # cp config/database.yml{.default,}

5) Adjust conf/database.yml to your configuration

    # vim conf/database.yml

6) Install gems and setup database

    # sudo gem install bundler
    # bundle install
    # bundle exec rake db:create
    # bundle exec rake db:migrate
    # bundle exec rake db:seed

5) Install R (output management)

    # sudo apt-get install r-base
    # R
    # install.packages('ggplot2',dependencies=TRUE)
    # install.packages('reshape',dependencies=TRUE)

6) Solver requirements

You need GLPK > 4.45 or GAMS + an LP solver (CBC, CPLEX, XPRESS, MOSEK...):

    # sudo apt-get install glpk-utils

7) Run it
  
    # bundle exec rails server
    # bundle exec script/delayed_job start
    # firefox http://127.0.0.1:3000


Under Windows
-------------

1) Install railsinstaller [http://railsinstaller.org]

2) Open a Terminal (Start-> Execute...-> "cmd.exe")

3) Go somewhere to download the application

    # c:
    # cd c:\Sites

4) Clone the repository, configure and install gems (follow the post-installation instructions given by bundle install):

    # git clone git://github.com/lolow/leaqweb.git
    # cd leaqweb
    # copy config/database.yml.default config/database.yml
    # bundle install 
    # rake db:migrate
    # rake db:seed

5) Run it
 
    # rails server

6) Go to http://localhost:3000 in your browser

Default User
------------

The default user, created via rake db:seed, is

    # email: admin@domain.com
    # password: password

Copyright
---------

The code is licensed to the MIT License (MIT). See the LICENSE file for the full license.
Copyright (c) 2009-2012 Public Research Center Henri Tudor

Author
------

Laurent Drouet <ldrouet at gmail dot com>

