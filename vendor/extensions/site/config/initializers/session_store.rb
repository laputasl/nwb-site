# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_nwb-site_session',
  :secret      => '1c6fb4191948327b15b423352d8662ab6e1c4017538e42982c61dbd78e76f1fdd60d6621cae8ef0f5737c15beb01739b57fc9755668ac23b5e18bf870e143890'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
ActionController::Base.session_store = :cookie_store