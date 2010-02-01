class ExactTargetHooks < Spree::ThemeSupport::HookListener
  insert_after :admin_configurations_menu do
    "<%= configurations_menu_item(I18n.t('exact_target.lists_admin'), admin_exact_target_lists_url, I18n.t('exact_target.manage_settings')) %>"
  end

  insert_after :account_my_orders, :partial => "exact_target_lists/edit"
  insert_after :signup_inside_form, :partial => "exact_target_lists/signup"
end
