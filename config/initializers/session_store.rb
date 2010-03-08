# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_leaqweb_session',
  :secret      => 'fe5b8f31d30e80dfefc591d9700f60e6f0e7e82fa8f716cd6b131b99ee49db84729fa00763abb5b6afaf518085ef1f90fe2073f691d948180e71d626664a7378'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
ActionController::Base.session_store = :active_record_store
