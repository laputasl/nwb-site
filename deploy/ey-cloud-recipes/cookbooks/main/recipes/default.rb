execute "testing" do
  command %Q{
    echo "i ran at #{Time.now}" >> /root/cheftime
  }
end

#configure s3 for paperclip, etc.
require_recipe "s3"

#install xapian bindings and create symlinks for xapiandb
require_recipe "xapian"