class SiteHooks < Spree::ThemeSupport::HookListener

  insert_after :product_properties do
    %(<div class="pr_review_summary">
      <script type="text/javascript">POWERREVIEWS.display.engine(document, { pr_page_id : "<%= @product.legacy_id %>" });</script>
    </div>)
  end

  insert_after :admin_product_tabs, "admin/shared/additional_fields_product_tabs"

  insert_after :admin_orders_index_headers, :partial => "admin/orders/index_headers"
  insert_after :admin_orders_index_rows, :partial => "admin/orders/index_rows"
  insert_before :admin_orders_index_search, :partial => "admin/orders/index_search_fields"

  insert_after :admin_products_index_headers, :partial => "admin/products/index_headers"
  insert_after :admin_products_index_rows, :partial => "admin/products/index_rows"
  insert_before :admin_products_index_search, :partial => "admin/products/index_search_fields"

  #remove :homepage_sidebar_navigation
  replace :search_results, :partial => "shared/search_results"
  insert_before :search_results, :partial => 'shared/suggestion'

  #disables 'can be part' flag if product is an assembly/kit
  insert_after :admin_product_form_additional_fields, :partial => "admin/products/hide_parts"


  insert_after :admin_exact_target_lists_index_headers, :partial => "admin/exact_target_lists/index_headers"
  insert_after :admin_exact_target_lists_index_rows, :partial => "admin/exact_target_lists/index_rows"
  insert_after :admin_exact_target_lists_form, :partial => "admin/exact_target_lists/form_fields"

  insert_after :signup_below_password_fields, :partial => "users/set_store"
end
