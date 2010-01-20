class Admin::SuspiciousOrderSettingsController < Admin::BaseController

  def update
    Spree::Config.set(params[:preferences])
    flash[:notice] = "Suspicious order settings updated"
    respond_to do |format|
      format.html {
        redirect_to admin_configurations_url
      }
    end
  end

end
