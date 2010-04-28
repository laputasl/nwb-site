require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Recipe do
  before(:each) do
    # we don't want to trigger the sync process with these
    XapitSync.override_syncing { }
  end
  
  it "should make xapit change when created" do
    XapitChange.delete_all
    recipe = Recipe.create!(:name => "foo")
    change = XapitChange.first
    change.target_class.should == "Recipe"
    change.target_id.should == recipe.id
    change.operation.should == "create"
  end
  
  it "should make xapit change when updated" do
    recipe = Recipe.create!(:name => "foo")
    XapitChange.delete_all
    recipe.update_attribute(:name, "bar")
    change = XapitChange.first
    change.target_class.should == "Recipe"
    change.target_id.should == recipe.id
    change.operation.should == "update"
  end
  
  it "should make xapit change when destroyed" do
    recipe = Recipe.create!(:name => "foo")
    XapitChange.delete_all
    recipe.destroy
    change = XapitChange.first
    change.target_class.should == "Recipe"
    change.target_id.should == recipe.id
    change.operation.should == "destroy"
  end
end
