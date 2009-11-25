set :application, "nwb-site"

set :scm, :git
set :repository,  "git@github.com:railsdog/nwb-site.git"
set :branch, "master"

set :deploy_via, :remote_cache
set :git_enable_submodules, 1
set :git_shallow_clone, 1
set :keep_releases, 5

role :web, "dev.naturalwellbeing.com"                   # Your HTTP server, Apache/etc
role :app, "dev.naturalwellbeing.com"                   # This may be the same as your `Web` server
role :db,  "dev.naturalwellbeing.com", :primary => true # This is where Rails migrations will run

set :use_sudo, false
set :user, "railsdog"

ssh_options[:forward_agent] = true

set :deploy_to, "/mnt/apps/#{application}"

namespace :deploy do
  task :start do; end
  task :stop do; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

set :shared_assets, ['config/database.yml', 'config/s3.yml', 'public/assets']

namespace :spree do
  task :create_symlinks, :roles => :app do
    shared_assets.each do |asset|
      origin_path = File.join(shared_path, asset)
      destination_path = File.join(release_path, asset)
      run "ln -nsf #{origin_path} #{destination_path}"
    end
  end

  namespace :gems do
    desc "Install gems"
    task :install, :roles => :app do
      run "cd #{release_path} && #{sudo} /usr/bin/env rake gems:install RAILS_ENV=production"
      run "cd #{release_path} && #{sudo} chown -R #{user}:deploy public/*"
    end
  end

  namespace :db do
    task :drop, :roles => :db do
      run "cd #{current_path} && /usr/bin/env rake db:drop RAILS_ENV=production"
    end

    task :create, :roles => :db do
      run "cd #{current_path} && /usr/bin/env rake db:create RAILS_ENV=production"
    end

    task :migrate, :roles => :db do
      run "cd #{current_path} && /usr/bin/env rake db:migrate RAILS_ENV=production"
    end

    task :seed, :roles => :db do
      run "cd #{current_path} && /usr/bin/env rake db:seed RAILS_ENV=production"
    end

    task :bootstrap, :roles => :db do
      spree.db.drop
      spree.db.create
      run "cd #{current_path} && /usr/bin/env rake db:bootstrap AUTO_ACCEPT=true RAILS_ENV=production"
    end
  end
end

after 'deploy:update_code', 'spree:create_symlinks'
after 'spree:create_symlinks', 'spree:gems:install'
