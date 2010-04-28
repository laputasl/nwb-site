#XapitSync.domains = ["localhost:5000", "localhost:5001", "localhost:5002", "localhost:5003", "localhost:5004", "localhost:5005"] if Rails.env.production?
#try with no notification first.
XapitSync.domains = [] if Rails.env.production?