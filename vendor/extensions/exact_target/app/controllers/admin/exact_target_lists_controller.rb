class Admin::ExactTargetListsController < Admin::BaseController
  resource_controller

  update.wants.html { redirect_to collection_url }
  create.wants.html { redirect_to collection_url }

  def get_lists
    @lists = []
    @list_id = params[:list_id] if params.key? :list_id

    et_list = ET::List.new(Spree::Config.get(:exact_target_user), Spree::Config.get(:exact_target_password))
    et_list.all.each do |list_id|
      list = et_list.retrieve_by_id list_id
      @lists << ["#{list.attributes['list_name']} (#{list_id})", list_id.to_s]
    end
    render :partial => "get_lists", :layout => false
  end
end
