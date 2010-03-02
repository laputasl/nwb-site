# Please install the Engine Yard Capistrano gem
# gem install eycap --source http://gems.engineyard.com
require "eycap/recipes"

set :keep_releases, 5
set :application,   'nwbsite'
set :repository,    'git@github.com:railsdog/nwb-site.git'
set :deploy_to,     "/data/#{application}"
set :deploy_via,    :export
set :monit_group,   "#{application}"
set :scm,           :git
set :git_enable_submodules, 1
# This is the same database name for all environments
set :production_database,'nwbsite_production'

set :environment_host, 'localhost'
set :deploy_via, :remote_cache

# uncomment the following to have a database backup done before every migration
# before "deploy:migrate", "db:dump"

# comment out if it gives you trouble. newest net/ssh needs this set.
ssh_options[:paranoid] = false
default_run_options[:pty] = true
ssh_options[:forward_agent] = true
default_run_options[:pty] = true # required for svn+ssh:// andf git:// sometimes

# This will execute the Git revision parsing on the *remote* server rather than locally
set :real_revision, 			lambda { source.query_revision(revision) { |cmd| capture(cmd) } }


task :nwb_staging do
  role :web, '184.73.225.160'
  role :app, '184.73.225.160'
  role :db,  '184.73.225.160', :primary => true
  set :environment_database, Proc.new { production_database }
  set :dbuser,        'deploy'
  set :user,          'deploy'
  set :runner,        'deploy'
  set :rails_env,     'production'
  set :shared_assets, ['db/xapiandb']
end

namespace :spree do
  task :create_symlinks, :roles => :app do
    shared_assets.each do |asset|
      origin_path = File.join(shared_path, asset)
      destination_path = File.join(release_path, asset)
      run "ln -nsf #{origin_path} #{destination_path}"
    end

    # %w(pets people).each do |store|
    #   origin_path= File.join(release_path, 'public')
    #   destination_path = File.join(release_path, 'public', store)
    #   run "ln -nsf #{origin_path} #{destination_path}"
    # end

     # origin_path = File.join(shared_path, 'blog', 'nwb_uploads')
     # destination_path = File.join(release_path, 'public', 'nwb_blog', 'wp-content', 'uploads')
     # run "ln -nsf #{origin_path} #{destination_path}"
     # 
     # origin_path = File.join(shared_path, 'blog', 'pwb_uploads')
     # destination_path = File.join(release_path, 'public', 'pwb_blog', 'wp-content', 'uploads')
     # run "ln -nsf #{origin_path} #{destination_path}"
     # 
     # origin_path = '/home/uploads/static'
     # destination_path = File.join(release_path, 'public', 's')
     # run "ln -nsf #{origin_path} #{destination_path}"
     # 
     # origin_path = File.join(release_path, 'config', 'redirect-map.txt')
     # destination_path = '/etc/apache2/rewrite-map.txt'
     # run "sudo ln -nsf #{origin_path} #{destination_path}"
  end
end


# TASKS
# Don't change unless you know what you are doing!

after "deploy", "deploy:cleanup"
after "deploy:migrations", "deploy:cleanup"
after "deploy:update_code","deploy:symlink_configs"
after 'deploy:update_code', 'spree:create_symlinks'


# 
# set :shared_assets, ['config/database.yml', 'config/s3.yml', 'public/assets', 'db/xapiandb']
# 

