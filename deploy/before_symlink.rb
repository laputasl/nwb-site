run "ln -nfs #{shared_path}/config/memcached.yml  #{release_path}/config/memcached.yml"
run "ln -nfs #{shared_path}/config/s3.yml #{release_path}/config/s3.yml"
run "ln -nfs #{shared_path}/db/xapiandb #{release_path}/db/xapiandb"
run "ln -nfs #{shared_path}/static_people #{release_path}/public/sl"
run "ln -nfs #{shared_path}/static_pets #{release_path}/public/st"

%w(pets people).each do |store|
  origin_path= File.join(release_path, 'public')
  destination_path = File.join(release_path, 'public', store)
  run "ln -nsf #{origin_path} #{destination_path}"
end