class Admin::GwoTestsController < Admin::BaseController
  #require File.dirname(__FILE__) + '/../../helpers/admin/gwo_tests_helper.rb'
  resource_controller

  update.response do |wants|
    wants.html { redirect_to collection_url }
  end

  update.after do
    Rails.cache.delete('gwo_tests')
  end

  create.response do |wants|
    wants.html { redirect_to collection_url }
  end

  create.after do
    Rails.cache.delete('gwo_tests')
  end

  def enable
    @gwo_test=GwoTest.find(params[:id])
    @gwo_test.update_attribute(:status, "enabled")
    respond_to do |format|
      format.js
      format.html
    end
    #redirect_to collection_url
  end

  def disable
    @gwo_test=GwoTest.find(params[:id])
    @gwo_test.update_attribute(:status, "disabled")
    respond_to do |format|
      format.js
      format.html
    end
    #redirect_to collection_url
  end

end
