CREATE SERVICE "eg_exp_items" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "DBA"."usp_eg_exp_items"();
CREATE SERVICE "egdatacheck" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "DBA"."usp_table_datacheck"(:url1,:url2,:url3,:url4,:url5,:url6);
CREATE SERVICE "egtbcheck" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "dba"."usp_trial_balance_datacheck"(:url1,:url2,:url3,:url4,:url5);
CREATE SERVICE "egwebservices" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_eg_webservice"(:url1,:url2,:url3);
CREATE SERVICE "egwebservices2" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "usp_eg_webservice2"(:url1,:url2,:url3);
CREATE SERVICE "egwebservices3" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "usp_eg_webservice3"(:url1,:url2,:url3);
CREATE SERVICE "get_data_ecoconnect" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "DBA"."usp_get_data_ecoconnect"(:url1,:url2,:url3,:url4);
CREATE SERVICE "stocklookup" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "DBA"."usp_stocklookup"(:url1,:url2);
CREATE SERVICE "ws_04m_add_modify_ip" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_04m_add_modify_ip"();
CREATE SERVICE "ws_04m_awb_no_update" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_04m_awb_no_update"();
CREATE SERVICE "ws_04M_create_sord" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_04M_create_sord"();
CREATE SERVICE "ws_04M_create_sord_without_order_id" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_04M_create_sord"();
CREATE SERVICE "ws_04m_cust_details" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_04m_cust_details"();
CREATE SERVICE "ws_04m_cust_history" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_04m_cust_history"();
CREATE SERVICE "ws_04m_cust_mst_incr" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_04m_cust_mst_incr"();
CREATE SERVICE "ws_04m_inv" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_04m_inv"();
CREATE SERVICE "ws_04m_item_detail" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_04m_item_detail"();
CREATE SERVICE "ws_04m_item_mst_incr" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_04m_item_mst_incr"();
CREATE SERVICE "ws_04m_item_price" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_04m_item_price"();
CREATE SERVICE "ws_04m_item_search" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" AS call "usp_04m_item_search"();
CREATE SERVICE "ws_04m_molecule_list" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_04m_molecule_list"();
CREATE SERVICE "ws_04m_ord_status" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_04m_ord_status"();
CREATE SERVICE "ws_04M_sales_order_status" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "usp_04M_sales_order_status"();
CREATE SERVICE "ws_04m_sales_register" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_04m_sales_register"();
CREATE SERVICE "ws_04m_serv_crnt" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_04m_serv_crnt"();
CREATE SERVICE "ws_04m_settle_mst_comment" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_04m_settle_mst_comment"();
CREATE SERVICE "ws_04m_sord" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_04m_sord"();
CREATE SERVICE "ws_04m_stock_search" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" AS call "usp_04m_stock_search"();
CREATE SERVICE "ws_04m_store_mst_incr" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_04m_store_mst_incr"();
CREATE SERVICE "ws_admin_loyalty_data" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_admin_loyalty_data"();
CREATE SERVICE "ws_auto_cust_rec_from_supp_pay" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "usp_auto_cust_rec_from_supp_pay"(:url1,:url2,:url2);
CREATE SERVICE "ws_barcode_verification" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_barcode_verification"();
CREATE SERVICE "ws_branch_customer_emoji" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_branch_customer_emoji"();
CREATE SERVICE "ws_branch_customer_logo" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_branch_customer_logo"();
CREATE SERVICE "ws_branch_invoice_list" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_branch_invoice_list"();
CREATE SERVICE "ws_branch_note_type" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_branch_note_type"();
CREATE SERVICE "ws_branch_qc_emoji" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_branch_qc_emoji"();
CREATE SERVICE "ws_branch_terminal_list" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_branch_terminal_list"();
CREATE SERVICE "WS_C2_Services_GetData" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "USP_C2_Services_GetData"(:url1,:url2,:url3,:url4);
CREATE SERVICE "WS_C2_Services_GetTableData" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "USP_C2_Services_GetTableData"(:url1,:url2,:url3,:url4,:url5);
CREATE SERVICE "ws_checkid_update" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_checkid_update"();
CREATE SERVICE "ws_cogs_values" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "DBA"."usp_ws_cogs_values"(:url1,:url2,:url3,:url4);
CREATE SERVICE "ws_cust_feedback_data" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_cust_feedback_data"();
CREATE SERVICE "ws_cust_feedback_form" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_cust_feedback_form"();
CREATE SERVICE "ws_cust_feedback_form_billwise" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_cust_feedback_form_billwise"();
CREATE SERVICE "ws_cust_feedback_with_image" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_cust_feedback_with_image"();
CREATE SERVICE "ws_cust_mobile_terminal_det" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_cust_mobile_terminal_det"();
CREATE SERVICE "ws_customer_details" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root> ' from "usp_customer_details"();
CREATE SERVICE "ws_delivery_slip" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_delivery_slip"();
CREATE SERVICE "ws_disable_dashboard" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_disable_dashboard"(:url1);
CREATE SERVICE "ws_ecogreen_logo_c2code" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_ecogreen_logo_c2code"();
CREATE SERVICE "ws_eg_crnt_dbnt_settlement" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml"+'</root>' from "usp_eg_crnt_dbnt_settlement"();
CREATE SERVICE "ws_eg_ip_creation" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select "as_str" from "usp_eg_ip_creation"();
CREATE SERVICE "ws_eg_local" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select 'Eg local Connection is OK; Time : '+"string"("now"());
CREATE SERVICE "ws_eg_masters" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml"+'</root>' from "usp_eg_masters"();
CREATE SERVICE "ws_eg_services_br_cancel_po" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "usp_eg_br_po_cancel_service"();
CREATE SERVICE "ws_eg_touch_Store" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_get_master_list"();
CREATE SERVICE "ws_eg_update_geo_tagging" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_eg_update_geo_tagging"(:url1,:url2,:url3,:url4,:url5);
CREATE SERVICE "ws_eg360" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root> ' from "usp_eg360"();
CREATE SERVICE "ws_eg360_br_live_data" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select "as_str" from "usp_eg360_br_live_data"();
CREATE SERVICE "ws_egservice_04M_eg_utility_fetch_data_from_doc_bank" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservice_04M_eg_utility_fetch_data_from_doc_bank"();
CREATE SERVICE "ws_egservice_04M_eg_utility_get_data_for_doc_bank" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservice_04M_eg_utility_get_data_for_doc_bank"();
CREATE SERVICE "ws_egservice_04M_eg_utility_get_item_details" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservice_04M_eg_utility_get_item_details"();
CREATE SERVICE "ws_egservice_04M_eg_utility_get_latest_transaction" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservice_04M_eg_utility_get_latest_transaction"();
CREATE SERVICE "ws_egservice_04M_eg_utility_get_preview_image" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservice_04M_eg_utility_get_preview_image"();
CREATE SERVICE "ws_egservice_04M_eg_utility_get_reason_master_details" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservice_04M_eg_utility_get_reason_master_details"();
CREATE SERVICE "ws_egservice_04M_eg_utility_get_transaction" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservice_04M_eg_utility_get_transaction"();
CREATE SERVICE "ws_egservice_04M_eg_utility_image_cancel" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservice_04M_eg_utility_image_cancel"();
CREATE SERVICE "ws_egservice_04M_eg_utility_invoice_prescription_details" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservice_04M_eg_utility_invoice_prescription_details"();
CREATE SERVICE "ws_egservice_04M_eg_utility_invoice_prescription_document_details" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservice_04M_eg_utility_invoice_prescription_document_details"();
CREATE SERVICE "ws_egservice_04M_eg_utility_item_barcode_search" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservice_04M_eg_utility_item_barcode_search"();
CREATE SERVICE "ws_egservice_04M_eg_utility_last_tran_history_list" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservice_04M_eg_utility_last_tran_history_list"();
CREATE SERVICE "ws_egservice_04M_eg_utility_preview_get_image_list" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservice_04M_eg_utility_preview_get_image_list"();
CREATE SERVICE "ws_egservice_04M_eg_utility_temp_allocated_unallocated_prescription_image_upload" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservice_04M_eg_utility_temp_allocated_unallocated_prescription_image_upload"();
CREATE SERVICE "ws_egservice_04M_eg_utility_temp_tran_prescription_image_upload" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservice_04M_eg_utility_temp_tran_prescription_image_upload"();
CREATE SERVICE "ws_egservice_04M_hyp_branch_stock_details" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservice_04M_hyp_branch_stock_details"();
CREATE SERVICE "ws_egservice_04M_hyp_create_sord" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservice_04M_hyp_create_sord"();
CREATE SERVICE "ws_egservice_04M_hyp_get_item_incremental_details" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservice_04M_hyp_get_item_incremental_details"();
CREATE SERVICE "ws_egservice_04M_hyp_get_item_master_details" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservice_04M_hyp_get_item_master_details"();
CREATE SERVICE "ws_egservice_04M_hyp_stock_details" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservice_04M_hyp_stock_details"();
CREATE SERVICE "ws_egservice_create_sord" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservice_create_sord"();
CREATE SERVICE "ws_egservice_get_einvoice_admin_to_branch" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservice_get_einvoice_admin_to_branch"();
CREATE SERVICE "ws_egservices_04M_get_invoice_details" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservices_04M_get_invoice_details"();
CREATE SERVICE "ws_egservices_04M_get_invoice_details_2" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservices_04M_get_invoice_details_2"();
CREATE SERVICE "ws_egservices_cancel_document" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservices_cancel_document"(:url1);
CREATE SERVICE "ws_egservices_create_dc_invoice" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservices_create_dc_invoice"(:url1);
CREATE SERVICE "ws_egservices_create_dc_return" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservices_create_dc_return"(:url1);
CREATE SERVICE "ws_egservices_create_invoice" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservices_create_invoice"(:url1);
CREATE SERVICE "ws_egservices_create_masters" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "usp_egservices_create_masters"();
CREATE SERVICE "ws_egservices_create_sales_return" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservices_create_sales_return"(:url1);
CREATE SERVICE "ws_egservices_item_stock_hold_release" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservices_item_stock_hold_release"(:url1);
CREATE SERVICE "ws_egservices_outscan_status" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservices_outscan_status"(:url1);
CREATE SERVICE "ws_egservices_Recreate_dc" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservices_Recreate_dc"(:url1);
CREATE SERVICE "ws_enable_dashboard" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_enable_dashboard"(:url1);
CREATE SERVICE "ws_ewallet" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "dba"."usp_ewallet"();
CREATE SERVICE "ws_feedback_mst_list" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_feedback_mst_list"();
CREATE SERVICE "ws_gate_pass_label_print" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "DBA"."usp_gate_pass_label_print"();
CREATE SERVICE "ws_generic_service" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_table_sync"();
CREATE SERVICE "ws_get_apk_version" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_get_apk_version"();
CREATE SERVICE "ws_get_attendance_employee_list" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."get_attendance_employee_list"(:url1,:url2);
CREATE SERVICE "ws_get_eg_supp_item_code" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_get_eg_supp_item_code"(:url1,:url2,:url3,:url4);
CREATE SERVICE "ws_get_exit_bay" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_st_get_exit_no"();
CREATE SERVICE "ws_get_gdn_bounce_data_xml" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS METHODS 'HEAD,GET,POST,PUT' AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_get_gdn_bounce_data_xml"(:url1,:url2,:url3,:url4,:url5);
CREATE SERVICE "ws_get_menu_rights" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "usp_get_menu_rights"(:url1,:url2,:url3,:url4);
CREATE SERVICE "ws_get_order_status" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_get_order_status"(:url1,:url2);
CREATE SERVICE "ws_get_order_xml" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_get_order_xml"(:url1,:url2,:url3,:url4,:url5);
CREATE SERVICE "ws_get_pending_po_details" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "usp_get_pending_po_details"(:url1,:url2,:url3,:url4);
CREATE SERVICE "ws_getting_images" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_getting_images"();
CREATE SERVICE "ws_getting_images_meq3" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_getting_images_meq3"();
CREATE SERVICE "ws_getting_maxno" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_getting_maxno"();
CREATE SERVICE "ws_getting_maxno_comparison" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_getting_maxno_comparison"();
CREATE SERVICE "ws_getting_maxno_comparison_meq3" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_getting_maxno_comparison_meq3"();
CREATE SERVICE "ws_image_saveas_file" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_image_saveas_file"();
CREATE SERVICE "ws_import_gdn_bounce" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_import_gdn_bounce"(:url1,:url2);
CREATE SERVICE "ws_insert_gdn_request" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_insert_gdn_request"();
CREATE SERVICE "ws_inward_tray_print" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "dba"."usp_inward_tray_print"(:url1);
CREATE SERVICE "ws_ip_fetch" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_ip_fetch"();
CREATE SERVICE "ws_ip_mst_refresh_from_admin" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "dba"."usp_ip_mst_refresh_from_admin"(:url1);
CREATE SERVICE "ws_item_creation_alteration_request" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_item_creation_alteration_request"();
CREATE SERVICE "ws_JV_auto_create" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_JV_auto_create"();
CREATE SERVICE "ws_loyalty_points" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"as_str"+'</root> ' from "usp_loyalty_points"();
CREATE SERVICE "ws_loyalty_points_eg" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select "as_str" from "usp_loyalty_points_eg"();
CREATE SERVICE "ws_messaging" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_messaging"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9,:url10,:url11,:url12,:url13,:url14,:url15,:url15);
CREATE SERVICE "ws_mgn_dc_ord" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select "is_xml_string" from "usp_mgn_dc_ord"(:url1,:url2,:url3,:url4);
CREATE SERVICE "ws_mgn_mst_import_incr" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select "is_xml_string" from "usp_mgn_mst_import_incr"();
CREATE SERVICE "ws_mgn_online_invoice_update" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select "is_xml_string" from "usp_mgn_online_invoice_update"();
CREATE SERVICE "ws_mgn_pincode_search" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select "is_xml_string" from "usp_mgn_pincode_search"();
CREATE SERVICE "ws_mgn_product_search" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select "is_xml_string" from "usp_mgn_product_search"();
CREATE SERVICE "ws_mini_sync" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_mini_sync"(:url1,:url2,:url3,:url4,:url5,:url6);
CREATE SERVICE "ws_mini_sync_get_tran_count" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_mini_sync_get_tran_count"(:url1,:url2,:url3);
CREATE SERVICE "ws_missing_order_data" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "usp_missing_order_data"();
CREATE SERVICE "ws_multi_barcode_insert" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "dba"."usp_multi_barcode_insert_by_ws"('');
CREATE SERVICE "ws_new_delivery_slip" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_new_delivery_slip"();
CREATE SERVICE "ws_nt_item" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_nt_item"();
CREATE SERVICE "ws_nt_po" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_nt_po"();
CREATE SERVICE "ws_orderbuk_item_coupon" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<Masters>'+"is_xml_string"+'</Masters> ' from "usp_orderbuk_item_coupon"();
CREATE SERVICE "ws_orderbuk_top_sold_item" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "usp_orderbuk_top_sold_item"();
CREATE SERVICE "ws_pa_dc_pur_srno_post" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_pa_dc_pur_srno_post"(:url1);
CREATE SERVICE "ws_pass_sales_return_from_purchase_return" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_pass_sales_return_from_purchase_return"(:url1,:url2,:url3,:url4,:url5);
CREATE SERVICE "ws_pass_sales_return_from_return_sale" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "DBA"."usp_pass_sales_return_from_return_sale"(:url1,:url2,:url3,:url4,:url5);
CREATE SERVICE "ws_po_pending_points_fetch" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"as_str"+'</root>' from "usp_po_pending_points_fetch"();
CREATE SERVICE "ws_post_po_from_branch" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select "is_xml_string" from "usp_post_po_from_branch"();
CREATE SERVICE "ws_pot_details" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_pot_details"();
CREATE SERVICE "ws_pot_po" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_pot_po"();
CREATE SERVICE "ws_presc_details" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_presc_details"();
CREATE SERVICE "ws_presc_details_dashboard_history" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_presc_details_dashboard_history"();
CREATE SERVICE "ws_presc_details_dashboard_meq3" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_presc_details_dashboard_meq3"();
CREATE SERVICE "ws_presc_login" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_presc_login"();
CREATE SERVICE "ws_print_barcode_tray" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "dba"."usp_tray_barcode_print"(:url1);
CREATE SERVICE "ws_ps_document_insert" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_ps_tab_document_insert"();
CREATE SERVICE "ws_ps_get_delimiter" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_ps_get_delimiter"(:url1,:url2,:url3);
CREATE SERVICE "ws_ps_print" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "dba"."usp_ps_print"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9);
CREATE SERVICE "ws_ps_tab_batch_key" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "dba"."usp_ps_tab_batch_key"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9,:url10);
CREATE SERVICE "ws_ps_tab_batch_key_gst" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_ps_tab_batch_key_gst"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9,:url10);
CREATE SERVICE "ws_ps_tab_billwise_cust_os" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "dba"."usp_ps_tab_billwise_cust_os"(:url1,:url2,:url3,:url4,:url5);
CREATE SERVICE "ws_ps_tab_counter_insert" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "DBA"."usp_ps_tab_counter_insert"(:url1,:url2,:url3,:url4,:url5,:url6,:url7);
CREATE SERVICE "ws_ps_tab_counter_insert_gst" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_ps_tab_counter_insert_gst"(:url1,:url2,:url3,:url4,:url5,:url6,:url7);
CREATE SERVICE "ws_ps_tab_Customer_history" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "dba"."usp_ps_tab_Customer_history"(:url1,:url2,:url3,:url4,:url5);
CREATE SERVICE "ws_ps_tab_get_data" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "dba"."usp_ps_tab_get_data"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8);
CREATE SERVICE "ws_ps_tab_get_item_batch" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "dba"."usp_ps_tab_get_item_batch"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9);
CREATE SERVICE "ws_ps_tab_get_item_batch_gst" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_ps_tab_get_item_batch_gst"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9);
CREATE SERVICE "ws_ps_tab_indent" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "dba"."usp_ps_tab_indent"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9);
CREATE SERVICE "ws_ps_tab_item_bounce_entry" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "dba"."usp_ps_tab_item_bounce_entry"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9);
CREATE SERVICE "ws_ps_tab_master" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "dba"."usp_ps_tab_master"(
:url1,:url2,:url3,:url4,:url5);
CREATE SERVICE "ws_ps_tab_master_gst" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "dba"."usp_ps_tab_master_gst"(:url1,:url2,:url3,:url4,:url5);
CREATE SERVICE "ws_ps_tab_row_validation" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "dba"."usp_ps_tab_row_validation"(:url1,:url2,:url3,:url4,:url5,:url6,:url7);
CREATE SERVICE "ws_ps_tab_row_validation_gst" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_ps_tab_row_validation_gst"(:url1,:url2,:url3,:url4,:url5,:url6,:url7);
CREATE SERVICE "ws_ps_tab_save_invoice" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "dba"."usp_ps_tab_save_invoice"(:url1,:url2,:url3,:url4,:url5,:url6,:url7);
CREATE SERVICE "ws_ps_tab_save_invoice_gst" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_ps_tab_save_invoice_gst"(:url1,:url2,:url3,:url4,:url5,:url6,:url7);
CREATE SERVICE "ws_ps_tab_user_validation" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "dba"."usp_ps_tab_user_validation"(:url1,:url2,:url3,:url4,:url5);
CREATE SERVICE "ws_ps_tab_validate_login" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "dba"."usp_ps_tab_validate_login"(:url1,:url2,:url3,:url4);
CREATE SERVICE "ws_qc_audit_group_mst_list" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_qc_audit_group_mst_list"();
CREATE SERVICE "ws_qc_audit_login_br_setup" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_qc_audit_login_br_setup"();
CREATE SERVICE "ws_qc_audit_master_list" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_qc_audit_master_list"();
CREATE SERVICE "ws_qc_audit_question_list" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_qc_audit_question_list"();
CREATE SERVICE "ws_qc_audit_save" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_qc_audit_save"();
CREATE SERVICE "ws_read_file" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "DBA"."usp_read_file"(:url1,:url2);
CREATE SERVICE "ws_recall_for_cofirmed_audit" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_recall_for_cofirmed_audit"();
CREATE SERVICE "ws_rx_branch_list" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_rx_branch_list"(:url1,:url2,:url3,:ur14);
CREATE SERVICE "ws_rx_history" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "dba"."usp_rx_history"(:url1,:url2,:url3,:url4,:url5,:ur16,:ur17,:ur18);
CREATE SERVICE "ws_rx_image_insert" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_rx_image_insert"();
CREATE SERVICE "ws_rx_save" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "dba"."usp_rx_save"(:url1,:url2,:url3,:url4,:url5,:url6,:ur17,:ur18);
CREATE SERVICE "ws_slip_create" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_slip_create"();
CREATE SERVICE "ws_slip_print" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "dba"."usp_slip_print"(:url1);
CREATE SERVICE "ws_special_JV_create" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_special_JV_create"();
CREATE SERVICE "ws_special_order_detais" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_special_order_detais"();
CREATE SERVICE "ws_st_barcoding_verification" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_st_barcoding_verification"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9,:url10,:url11);
CREATE SERVICE "ws_st_batch_error_performance_dashboard" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "DBA"."usp_st_batch_error_performance_dashboard"(:url1,:url2,:url3,:url4,:url5);
CREATE SERVICE "ws_st_dashboard" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "usp_st_dashboard"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9,:url10);
CREATE SERVICE "ws_st_dispatch_area_dash_board" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "DBA"."usp_st_dispatch_area_dash_board"(:url1,:url2,:url3,:url4,:url5,:url6,:url7);
CREATE SERVICE "ws_st_expiry_dash_board" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "DBA"."usp_st_expiry_dash_board"(:url1,:url2,:url3,:url4,:url5,:url6,:url7);
CREATE SERVICE "ws_st_expiry_tray_status" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "DBA"."usp_st_expiry_tray_status"(:url1,:url2,:url3,:url4,:url5);
CREATE SERVICE "ws_st_gate_pass_entry" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "DBA"."usp_st_gate_pass_entry"(:url1,:url2,:url3,:url4);
CREATE SERVICE "ws_st_goods_receipt_entry" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "DBA"."usp_st_goods_receipt_entry"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9,:url10,:url11,:url12,:url13,:url14,:url15);
CREATE SERVICE "ws_st_inward_area_dash_board" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "DBA"."usp_st_inward_area_dash_board"(:url1,:url2,:url3,:url4,:url5,:url6,:url7);
CREATE SERVICE "ws_st_inward_schedule" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_st_inward_schedule"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9,:url10,:url11);
CREATE SERVICE "ws_st_login_validation" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_st_login_validation"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url19,:url110);
CREATE SERVICE "ws_st_operational_avg" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "DBA"."usp_st_operational_avg"(:url1,:url2,:url3,:url4,:url5,:url6);
CREATE SERVICE "ws_st_operational_dashboard" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "DBA"."usp_st_operational_dashboard"(:url1,:url2,:url3,:url4,:url5,:url6);
CREATE SERVICE "ws_st_order_tray_status" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_st_order_tray_status"(:url1,:url2,:url3,:url4);
CREATE SERVICE "ws_st_outwawrd_tray_prediction" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_st_outwawrd_tray_prediction"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9,:url10,:url11);
CREATE SERVICE "ws_st_pallet_tray_movement" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_st_pallet_tray_movement"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9,:url10,:url11);
CREATE SERVICE "ws_st_pending_order_dashboard" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_st_pending_order_dashboard"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9,:url10,:url11);
CREATE SERVICE "ws_st_performance_dashboard" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_st_performance_dashboard"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8);
CREATE SERVICE "ws_st_pick_in_process_tray" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_st_pick_in_pocess_tray"(:url1,:url2,:url3);
CREATE SERVICE "ws_st_print_barcode" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_st_print_barcode"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8);
CREATE SERVICE "ws_st_retail_stock_removal" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "DBA"."usp_st_retail_stock_removal"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9,:url10,:url11);
CREATE SERVICE "ws_st_stock_audit" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_st_stock_audit"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9,:url10,:url11);
CREATE SERVICE "ws_st_stock_removal" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_st_stock_removal"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9,:url10,:url11);
CREATE SERVICE "ws_st_store_in" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_st_store_in"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9,:url10,:url11,:url12);
CREATE SERVICE "ws_st_store_in_assignment" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_st_store_in_assignment"();
CREATE SERVICE "ws_st_store_in_assignment_quarantine" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "DBA"."usp_st_store_in_assignment_quarantine"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9,:url10,:url11,:url12);
CREATE SERVICE "ws_st_store_in_assignment_traywise" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_st_store_in_assignment_traywise"();
CREATE SERVICE "ws_st_storein_operational_dashboard" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "DBA"."usp_st_storein_operational_dashboard"(:url1,:url2,:url3,:url4);
CREATE SERVICE "ws_st_storein_quarantine" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_st_storein_quarantine"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9,:url10,:url11,:url12);
CREATE SERVICE "ws_st_track_tray" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "dba"."usp_st_track_tray"();
CREATE SERVICE "ws_st_tray_merge_util" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "DBA"."usp_st_tray_merge_util"(:url1,:url2,:url3,:url4,:url5,:url6);
CREATE SERVICE "ws_st_tray_pickup" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_st_tray_pickup"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9,:url10,:url11);
CREATE SERVICE "ws_st_user_performance_dashboard" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_st_user_performance_dashboard"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8);
CREATE SERVICE "ws_st_utility" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_st_utility"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9,:url10,:url11);
CREATE SERVICE "ws_stk_audit_connection_settings" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_stk_login_settings"();
CREATE SERVICE "ws_stk_audit_cust_outstanding" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_stk_audit_cust_outstanding"();
CREATE SERVICE "ws_stk_audit_datewise_cust_outstanding" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_stk_audit_datewise_cust_outstanding"();
CREATE SERVICE "ws_stk_audit_filtered_item_list" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_stk_audit_filtered_item_list"();
CREATE SERVICE "ws_stk_audit_get_branch_list" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_stk_get_branch_list"();
CREATE SERVICE "ws_stk_audit_get_master_list" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_stk_get_master_list"();
CREATE SERVICE "ws_stk_audit_get_mASter_list_for_change_request" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_stk_get_mASter_list_for_change_request"();
CREATE SERVICE "ws_stk_audit_get_multi_branch_list" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_stk_audit_get_multi_branch_list"();
CREATE SERVICE "ws_stk_audit_item_search" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_stk_audit_item_search"();
CREATE SERVICE "ws_stk_audit_login" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_stk_login"();
CREATE SERVICE "ws_stk_audit_ps_tab_master_gst" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "dba"."usp_ps_tab_master_gst"(:url1,:url2,:url3,:url4,:url5);
CREATE SERVICE "ws_stk_audit_save_transaction" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_stk_audit_save_transaction"();
CREATE SERVICE "ws_stk_audit_transaction_item_list" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_stk_audit_transaction_item_list"();
CREATE SERVICE "ws_stock_mst_refresh_from_admin" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "DBA"."usp_stock_mst_refresh_from_admin"(:url1,:url2);
CREATE SERVICE "ws_sync_datacheck" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "DBA"."usp_sync_datacheck"(:url1,:url2,:url3,:url4,:url5);
CREATE SERVICE "ws_take_employee_attendace" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_take_employee_attendace"(:url1,:url2,:url3);
CREATE SERVICE "ws_unimported_trans" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root> ' from "usp_unimported_trans"();
CREATE SERVICE "ws_update_br_act_details" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select "is_xml_string" from "usp_update_br_act_details"();
CREATE SERVICE "ws_update_item_details" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "DBA"."usp_update_item_details"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url9,:url9);
CREATE SERVICE "ws_update_order_status" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_update_order_status"(:url1,:url2,:url3,:url4,:url5);
CREATE SERVICE "ws_update_po_cancel" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root> ' from "usp_update_po_cancel"();
CREATE SERVICE "ws_update_procedure" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root> ' from "usp_update_procedure"();
CREATE SERVICE "ws_update_trans_ldate_from_admin" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
  from "usp_update_trans_ldate_from_admin"(:url1);
CREATE SERVICE "ws_user_rpt_menu" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_user_rpt_menu"(:url1,:url2);
CREATE SERVICE "ws_user_rpt_menu_all" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_user_rpt_menu_all"(:url1);
CREATE SERVICE "ws_usp_egservice_04M_eg_utility_login" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_egservice_04M_eg_utility_login"();
CREATE SERVICE "ws_usp_meq_confirm" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_meq_confirm"();
CREATE SERVICE "ws_usp_presc_details_dashboard" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_presc_details_dashboard"();
CREATE SERVICE "ws_usp_stk_audit_in_out_qty_det" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "DBA"."usp_stk_audit_in_out_qty"();
CREATE SERVICE "ws_usp_stk_audit_in_out_qty_det_mrp" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "DBA"."usp_stk_audit_in_out_qty_mrpaudit"();
CREATE SERVICE "ws_usp_stk_audit_item_batch_list" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "DBA"."usp_stk_audit_item_batch_list"();
CREATE SERVICE "ws_usp_stk_audit_transaction_confirm" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_stk_audit_transaction_confirm"();
CREATE SERVICE "ws_usp_stk_audit_transaction_det" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_stk_audit_transaction_det"();
CREATE SERVICE "ws_usp_stk_audit_transaction_update_item" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_stk_audit_transaction_update_item"();
CREATE SERVICE "ws_usp_stk_audit_user_transaction" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_stk_audit_user_transaction"();
CREATE SERVICE "ws_usp_stk_audit_verify_otp" TYPE 'JSON' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_stk_audit_verify_otp"();
CREATE SERVICE "Ws_usp_WF_customer_inv_fetch" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_WF_customer_inv_fetch"();
CREATE SERVICE "ws_virtual_po_import" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_virtual_po_import"(:url1,:url2,:url3,:url4,:url5,:url6);
CREATE SERVICE "ws_web_api" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>' from "DBA"."usp_web_api"(:url1,:url2);
CREATE SERVICE "ws_WF_stock_details_json" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS call "usp_WF_stock_details_json"();
