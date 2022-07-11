CREATE PROCEDURE "DBA"."usp_st_pending_order_dashboard"( 
  in @gsBr char(6),
  in @devID char(200),
  in @sKey char(20),
  in @UserId char(20),
  in @PhaseCode char(6),
  in @StageCode char(6),
  in @RackGrpCode char(300),
  in @cIndex char(30),
  in @HdrData char(7000),
  in @DetData char(32767),
  in @GodownCode char(6) ) 
result( "is_xml_string" xml ) 
begin
  declare @simulation_mode_flag numeric(1);
  declare @simulation_users_logged_in numeric(8);
  declare @scan_users_logged_in numeric(18);
  declare @scan_start_time char(30);
  declare @t_scan_end_time char(30);
  declare @scan_users_required numeric(18);
  declare @pick_start_time char(30); --
  declare @pick_end_time char(30);
  declare @n_route_code char(6);
  declare @c_cust_code char(6);
  declare @n_approve_flag numeric(1);
  declare @picking_users_required numeric(18);
  declare @pending_items_cnt numeric(18);
  declare @logged_in_user_pending_items_cnt numeric(18);
  declare @logged_in_users numeric(18);
  if @devID = '' or @devID is null then
    set @gsBr = "http_variable"('gsBr'); --1
    set @devID = "http_variable"('devID'); --2
    set @sKey = "http_variable"('sKey'); --3
    set @UserId = "http_variable"('UserId'); --4
    set @PhaseCode = "http_variable"('PhaseCode'); --5		
    set @RackGrpCode = "http_variable"('RackGrpCode'); --6	
    set @StageCode = "http_variable"('StageCode'); --7
    set @cIndex = "http_variable"('cIndex'); --8
    set @HdrData = "http_variable"('HdrData'); --9
    set @DetData = "http_variable"('DetData'); --10
    set @n_approve_flag = "http_variable"('approveFlag'); --11 
    set @n_route_code = "http_variable"('RouteCode'); --11 
    set @c_cust_code = "http_variable"('CustCode'); --11a 
    set @GodownCode = "http_variable"('GodownCode'); --12	
    set @simulation_users_logged_in = "http_variable"('SimulationUsersLoggedIn');
    set @simulation_mode_flag = "http_variable"('SimulationModeFlag')
  end if;
  if @simulation_mode_flag is null or @simulation_mode_flag = '' then
    set @simulation_mode_flag = 0
  end if;
  if @simulation_users_logged_in is null or @simulation_users_logged_in = '' then
    set @simulation_users_logged_in = 0
  end if;
  case @cIndex
  when 'line_item_pick_det' then
    //http://10.89.209.19:49503/ws_st_pending_order_dashboard?&cIndex=line_item_pick_det&GodownCode=&gsbr=000&StageCode=&RackGrpCode=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=
    select "SUM"("pending_count") as "n_pick_pending",
      "sum"("in_progress_count") as "n_pick_in_progress",
      "sum"("complted_count") as "n_pick_completed"
      from(select if("n_complete" = 0 and "c_tray_code" is null) then 1 else 0 endif as "pending_count",
          if("n_complete" in( 0,1 ) and "c_tray_code" is not null) then 1 else 0 endif as "in_progress_count",
          if "n_complete" in( 9,2 ) then 1 else 0 endif as "complted_count"
          from "st_track_det" where "n_inout" = 0 and "st_track_det"."c_doc_no" not like '%/162/%') as "line_item_pick_det" for xml raw,elements
  /*select "d_date",
"sum"("unassigned_tray_item_cnt") as "n_unassigned_tray_item_cnt",
"sum"("pick_pending_item_cnt") as "n_pick_pending",
"sum"("pick_complete_item_cnt") as "n_pick_completed",
"sum"("pick_reject_item_cnt") as "n_pick_rejected",
"sum"("conversion_done_item_cnt") as "n_conversion_completed"
--and st_track_det.c_doc_no = '038/19/O/846' and st_track_mst.d_date = uf_default_date()
from(select "st_track_mst"."c_doc_no" as "doc_no",
"st_track_mst"."d_date" as "d_date",
"sum"(if("st_track_det"."c_tray_code" is null and "st_track_det"."n_complete" = 0) then 1 else 0 endif) as "unassigned_tray_item_cnt",
"sum"(if("st_track_det"."c_tray_code" is not null and "st_track_det"."n_complete" = 0) then 1 else 0 endif) as "pick_pending_item_cnt",
"sum"(if("st_track_det"."c_tray_code" is not null and "st_track_det"."n_complete" = 1) then 1 else 0 endif) as "pick_complete_item_cnt",
"sum"(if("st_track_det"."c_tray_code" is not null and "st_track_det"."n_complete" = 2) then 1 else 0 endif) as "pick_reject_item_cnt",
"sum"(if("st_track_det"."c_tray_code" is not null and "st_track_det"."n_complete" = 9) then 1 else 0 endif) as "conversion_done_item_cnt"
from "st_track_det" join "st_track_mst" on "st_track_mst"."c_doc_no" = "st_track_det"."c_doc_no" and "st_track_mst"."n_inout" = "st_track_det"."n_inout"
where "st_track_det"."n_inout" = 0 and "st_track_det"."c_doc_no" not like '%/162/%' and "st_track_mst"."d_date" = '2019-10-18'
group by "doc_no","d_date") as "t"
group by "d_date" for xml raw,elements*/
  when 'dispatch_route_wise_summary' then
    //http://10.89.209.19:49503/ws_st_pending_order_dashboard?&cIndex=dispatch_route_wise_summary&GodownCode=&gsbr=000&StageCode=&RackGrpCode=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=
    select "sum"("n_completed_cnt") as "n_completed_routes",
      "sum"("n_completed_cnt") as "n_ready_to_dispatch",
      "sum"("n_process_cnt") as "n_in_progress_routes",
      "sum"("n_pending_cnt") as "n_pending_routes"
      from(select "c_rt_code" as "c_route_code",
          "c_rt_name" as "c_route_name",
          "sum"("ds_ng_cnt") as "del_slip_not_generated_doc_cnt",
          "sum"("ds_g_cnt") as "del_slip_generated_doc_cnt",
          if "del_slip_generated_doc_cnt" = 0 and "del_slip_not_generated_doc_cnt" <> 0 then 1 else 0 endif as "n_pending_cnt",
          if "del_slip_generated_doc_cnt" <> 0 and "del_slip_not_generated_doc_cnt" <> 0 then 1 else 0 endif as "n_process_cnt",
          if "del_slip_generated_doc_cnt" <> 0 and "del_slip_not_generated_doc_cnt" = 0 then 1 else 0 endif as "n_completed_cnt"
          from(select "route_mst"."c_code" as "c_rt_code",
              "route_mst"."c_name" as "c_rt_name",
              "sum"(if "c_inv_prefix" is null then 1 else 0 endif) as "ds_ng_cnt",
              "sum"(if "c_inv_prefix" is not null then 1 else 0 endif) as "ds_g_cnt"
              from "gdn_mst"
                left outer join "slip_det"
                on "gdn_mst"."c_br_code" = "slip_det"."c_inv_br"
                and "gdn_mst"."c_year" = "slip_det"."c_inv_year"
                and "gdn_mst"."c_prefix" = "slip_det"."c_inv_prefix"
                and "gdn_mst"."n_srno" = "slip_det"."n_inv_no"
                and "slip_det"."n_cancel_flag" = 0
                left outer join "act_route"
                on "act_route"."c_br_code" = "gdn_mst"."c_ref_br_code"
                and "act_route"."c_code" = "uf_get_br_code"('')
                left outer join "route_mst" on "route_mst"."c_code" = "act_route"."c_route_code"
              where "gdn_mst"."d_date" = "uf_default_date"()
              group by "c_rt_code","c_rt_name" union all
            select "route_mst"."c_code" as "c_rt_code",
              "route_mst"."c_name" as "c_rt_name",
              "sum"(if "c_inv_prefix" is null then 1 else 0 endif) as "ds_ng_cnt",
              "sum"(if "c_inv_prefix" is not null then 1 else 0 endif) as "ds_g_cnt"
              from "inv_mst"
                left outer join "slip_det"
                on "inv_mst"."c_br_code" = "slip_det"."c_inv_br"
                and "inv_mst"."c_year" = "slip_det"."c_inv_year"
                and "inv_mst"."c_prefix" = "slip_det"."c_inv_prefix"
                and "inv_mst"."n_srno" = "slip_det"."n_inv_no"
                and "slip_det"."n_cancel_flag" = 0
                left outer join "act_route"
                on "act_route"."c_br_code" = "inv_mst"."c_cust_code"
                and "act_route"."c_code" = "uf_get_br_code"('')
                left outer join "route_mst" on "route_mst"."c_code" = "act_route"."c_route_code"
              where "inv_mst"."d_date" = "uf_default_date"()
              group by "c_rt_code","c_rt_name") as "t1"
          group by "c_route_code","c_route_name") as "t" for xml raw,elements
  when 'pick_tray_item_summary' then
    //http://10.89.209.19:49503/ws_st_pending_order_dashboard?&cIndex=pick_tray_item_summary&GodownCode=&gsbr=000&StageCode=&RackGrpCode=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=
    select "sum"("n_pick_tray_cnt") as "n_pick_tray_req", --10891
      "count"(distinct "doc_no") as "n_orders",
      "sum"("n_item_cnt") as "n_line_item",
      "count"(distinct "act_code") as "n_stores"
      --rack_group_mst.c_code as c_rck_grp_code,
      --st_store_stage_mst.c_stage_grp_code
      --order by c_stage_code, n_item_cnt
      --rack_group_mst.c_code as c_rck_grp_code,
      --st_store_stage_mst.c_stage_grp_code
      --order by c_stage_code, n_item_cnt
      --39
      --rack_group_mst.c_code as c_rck_grp_code,
      --st_store_stage_mst.c_stage_grp_code
      --order by c_stage_code, n_item_cnt
      --6
      --rack_group_mst.c_code as c_rck_grp_code,
      --st_store_stage_mst.c_stage_grp_code
      from(select "order_det"."c_br_code",
          "order_det"."c_year",
          "order_det"."c_prefix",
          "order_det"."n_srno",
          "act_mst"."c_code" as "act_code",
          "act_mst"."c_name" as "act_name",
          "order_det"."c_br_code"+'/'+"order_det"."c_year"+'/'+"order_det"."c_prefix"+'/'+"string"("order_det"."n_srno") as "doc_no",
          "order_det"."d_date",
          "count"(distinct "order_det"."c_item_code") as "n_item_cnt",
          "ceiling"(cast("n_item_cnt" as decimal)/40) as "n_pick_tray_cnt",
          "st_store_stage_det"."c_stage_code"
          from "order_det"
            join "order_mst" on "order_mst"."n_srno" = "order_det"."n_srno"
            and "order_mst"."c_br_code" = "order_det"."c_br_code"
            and "order_mst"."c_year" = "order_det"."c_year"
            and "order_mst"."c_prefix" = "order_det"."c_prefix"
            join "act_mst" on "order_mst"."c_ref_br_code" = "act_mst"."c_code"
            join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "uf_get_br_code"('000')
            and "item_mst_br_info"."c_code" = "order_det"."c_item_code"
            join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
            and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
            join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code"
            and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
            join "st_store_stage_det" on "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
            and "st_store_stage_det"."c_rack_grp_code" = "rack_group_mst"."c_code"
            join "st_store_stage_mst" on "st_store_stage_det"."c_br_code" = "st_store_stage_mst"."c_br_code"
            and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
            join "st_track_mst" on "order_mst"."c_br_code" = "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1)
            and "order_mst"."c_year" = "left"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))-1)
            and "order_mst"."c_prefix" = "left"("substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1))-1)
            and "order_mst"."n_srno" = "reverse"("left"("reverse"("st_track_mst"."c_doc_no"),"charindex"('/',"reverse"("st_track_mst"."c_doc_no"))-1))
          where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "order_mst"."n_store_track" = 2
          group by "order_det"."c_br_code","order_det"."c_year","order_det"."c_prefix","doc_no","order_det"."n_srno","order_det"."d_date",
          "st_store_stage_det"."c_stage_code","st_store_stage_mst"."c_stage_grp_code","act_code","act_name" union all
        select "ord_det"."c_br_code",
          "ord_det"."c_year",
          "ord_det"."c_prefix",
          "ord_det"."n_srno",
          "act_mst"."c_code" as "act_code",
          "act_mst"."c_name" as "act_name",
          "ord_det"."c_br_code"+'/'+"ord_det"."c_year"+'/'+"ord_det"."c_prefix"+'/'+"string"("ord_det"."n_srno") as "doc_no",
          "ord_det"."d_date",
          "count"(distinct "ord_det"."c_item_code") as "n_item_cnt",
          "ceiling"(cast("n_item_cnt" as decimal)/40) as "n_pick_tray_cnt",
          "st_store_stage_det"."c_stage_code"
          from "ord_det"
            join "ord_mst" on "ord_mst"."n_srno" = "ord_det"."n_srno"
            and "ord_mst"."c_br_code" = "ord_det"."c_br_code"
            and "ord_mst"."c_year" = "ord_det"."c_year"
            and "ord_mst"."c_prefix" = "ord_det"."c_prefix"
            join "act_mst" on "ord_mst"."c_cust_code" = "act_mst"."c_code"
            join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "uf_get_br_code"('000')
            and "item_mst_br_info"."c_code" = "ord_det"."c_item_code"
            join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
            and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
            join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code"
            and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
            join "st_store_stage_det" on "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
            and "st_store_stage_det"."c_rack_grp_code" = "rack_group_mst"."c_code"
            join "st_store_stage_mst" on "st_store_stage_det"."c_br_code" = "st_store_stage_mst"."c_br_code"
            and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
            join "st_track_mst" on "ord_mst"."c_br_code" = "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1)
            and "ord_mst"."c_year" = "left"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))-1)
            and "ord_mst"."c_prefix" = "left"("substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1))-1)
            and "ord_mst"."n_srno" = "reverse"("left"("reverse"("st_track_mst"."c_doc_no"),"charindex"('/',"reverse"("st_track_mst"."c_doc_no"))-1))
          where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "ord_mst"."n_store_track" = 2
          group by "ord_det"."c_br_code","ord_det"."c_year","ord_det"."c_prefix","doc_no","ord_det"."n_srno","ord_det"."d_date",
          "st_store_stage_det"."c_stage_code","st_store_stage_mst"."c_stage_grp_code","act_code","act_name" union all
        select "gdn_det"."c_br_code",
          "gdn_det"."c_year",
          "gdn_det"."c_prefix",
          "gdn_det"."n_srno",
          "act_mst"."c_code" as "act_code",
          "act_mst"."c_name" as "act_name",
          "gdn_det"."c_br_code"+'/'+"gdn_det"."c_year"+'/'+"gdn_det"."c_prefix"+'/'+"string"("gdn_det"."n_srno") as "doc_no",
          "gdn_det"."d_date",
          "count"(distinct "gdn_det"."c_item_code") as "n_item_cnt",
          "ceiling"(cast("n_item_cnt" as decimal)/40) as "n_pick_tray_cnt",
          "st_store_stage_det"."c_stage_code"
          from "gdn_det"
            join "gdn_mst" on "gdn_mst"."n_srno" = "gdn_det"."n_srno"
            and "gdn_mst"."c_br_code" = "gdn_det"."c_br_code"
            and "gdn_mst"."c_year" = "gdn_det"."c_year"
            and "gdn_mst"."c_prefix" = "gdn_det"."c_prefix"
            join "act_mst" on "gdn_mst"."c_ref_br_code" = "act_mst"."c_code"
            join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "uf_get_br_code"('000')
            and "item_mst_br_info"."c_code" = "gdn_det"."c_item_code"
            join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
            and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
            join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code"
            and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
            join "st_store_stage_det" on "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
            and "st_store_stage_det"."c_rack_grp_code" = "rack_group_mst"."c_code"
            join "st_store_stage_mst" on "st_store_stage_det"."c_br_code" = "st_store_stage_mst"."c_br_code"
            and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
            join "st_track_mst" on "gdn_mst"."c_br_code" = "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1)
            and "gdn_mst"."c_year" = "left"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))-1)
            and "gdn_mst"."c_prefix" = "left"("substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1))-1)
            and "gdn_mst"."n_srno" = "reverse"("left"("reverse"("st_track_mst"."c_doc_no"),"charindex"('/',"reverse"("st_track_mst"."c_doc_no"))-1))
          where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "gdn_mst"."n_store_track" = 2
          group by "gdn_det"."c_br_code","gdn_det"."c_year","gdn_det"."c_prefix","doc_no","gdn_det"."n_srno","gdn_det"."d_date",
          "st_store_stage_det"."c_stage_code","st_store_stage_mst"."c_stage_grp_code","act_code","act_name" union all
        select "inv_det"."c_br_code",
          "inv_det"."c_year",
          "inv_det"."c_prefix",
          "inv_det"."n_srno",
          "act_mst"."c_code" as "act_code",
          "act_mst"."c_name" as "act_name",
          "inv_det"."c_br_code"+'/'+"inv_det"."c_year"+'/'+"inv_det"."c_prefix"+'/'+"string"("inv_det"."n_srno") as "doc_no",
          "inv_det"."d_date",
          "count"(distinct "inv_det"."c_item_code") as "n_item_cnt",
          "ceiling"(cast("n_item_cnt" as decimal)/40) as "n_pick_tray_cnt",
          "st_store_stage_det"."c_stage_code"
          from "inv_det"
            join "inv_mst" on "inv_mst"."n_srno" = "inv_det"."n_srno"
            and "inv_mst"."c_br_code" = "inv_det"."c_br_code"
            and "inv_mst"."c_year" = "inv_det"."c_year"
            and "inv_mst"."c_prefix" = "inv_det"."c_prefix"
            join "act_mst" on "inv_mst"."c_cust_code" = "act_mst"."c_code"
            join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "uf_get_br_code"('000')
            and "item_mst_br_info"."c_code" = "inv_det"."c_item_code"
            join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
            and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
            join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code"
            and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
            join "st_store_stage_det" on "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
            and "st_store_stage_det"."c_rack_grp_code" = "rack_group_mst"."c_code"
            join "st_store_stage_mst" on "st_store_stage_det"."c_br_code" = "st_store_stage_mst"."c_br_code"
            and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
            join "st_track_mst" on "inv_mst"."c_br_code" = "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1)
            and "inv_mst"."c_year" = "left"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))-1)
            and "inv_mst"."c_prefix" = "left"("substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1))-1)
            and "inv_mst"."n_srno" = "reverse"("left"("reverse"("st_track_mst"."c_doc_no"),"charindex"('/',"reverse"("st_track_mst"."c_doc_no"))-1))
          where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "inv_mst"."n_store_track" = 2
          group by "inv_det"."c_br_code","inv_det"."c_year","inv_det"."c_prefix","doc_no","inv_det"."n_srno","inv_det"."d_date",
          "st_store_stage_det"."c_stage_code","st_store_stage_mst"."c_stage_grp_code","act_code","act_name"
          order by "c_stage_code" asc,"n_item_cnt" asc) as "t" for xml raw,elements
  when 'route_wise_order_det' then
    //http://10.89.209.19:49503/ws_st_pending_order_dashboard?&cIndex=route_wise_order_det&GodownCode=&gsbr=000&StageCode=&RackGrpCode=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=
    select "route_code" as "c_route_code",
      "tray_summary"."c_route_name" as "c_route_name",
      "sum"("order_cnt") as "n_total_orders",
      "sum"("store_cnt") as "n_number_of_stores",
      "sum"("line_item_cnt") as "n_number_of_line_items",
      "isnull"("pending_tray"."unassign_rg_cnt",0) as "n_unassigned_rack_grps_cnt",
      "tray_summary"."n_pending_trays_pick" as "n_pending_trays_pick",
      "tray_summary"."n_pick_trays_completed" as "n_pick_trays_completed",
      "tray_summary"."n_pending_trays_on_conveyor" as "n_pending_trays_on_conveyor",
      "tray_summary"."n_pending_trays_pack" as "n_pending_trays_pack",
      0 as "n_pending_trays_dispatch",
      if "n_unassigned_rack_grps_cnt" = 0 then
        if "n_pending_trays_pick" = 0 and "n_pending_trays_on_conveyor" = 0 and "n_pending_trays_pack" = 0 and "n_pending_trays_dispatch" = 0 then 'Complete'
        else 'Partial'
        endif
      else
        if "n_pending_trays_pick" = 0 and "n_pending_trays_on_conveyor" = 0 and "n_pending_trays_pack" = 0 and "n_pending_trays_dispatch" = 0 then 'Open'
        else 'Partial'
        endif
      endif as "c_status"
      from(select "act_route"."c_Route_code" as "route_code",
          "count"(distinct("order_det"."c_br_code"+'/'+"order_det"."c_year"+'/'+"order_det"."c_prefix"+'/'+"string"("order_det"."n_srno"))) as "order_cnt",
          "count"(distinct "act_mst"."c_code") as "store_cnt",
          "count"("order_det"."c_item_code") as "line_item_cnt"
          from "order_det"
            join "order_mst" on "order_mst"."n_srno" = "order_det"."n_srno"
            and "order_mst"."c_br_code" = "order_det"."c_br_code"
            and "order_mst"."c_year" = "order_det"."c_year"
            and "order_mst"."c_prefix" = "order_det"."c_prefix"
            join "act_mst" on "order_mst"."c_ref_br_code" = "act_mst"."c_code"
            join "act_route" on "act_mst"."c_code" = "act_route"."c_br_code"
            join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "uf_get_br_code"('000')
            and "item_mst_br_info"."c_code" = "order_det"."c_item_code"
            join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
            and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
            join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code"
            and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
            join "st_store_stage_det" on "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
            and "st_store_stage_det"."c_rack_grp_code" = "rack_group_mst"."c_code"
            join "st_store_stage_mst" on "st_store_stage_det"."c_br_code" = "st_store_stage_mst"."c_br_code"
            and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
            join "st_track_mst" on "order_mst"."c_br_code" = "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1)
            and "order_mst"."c_year" = "left"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))-1)
            and "order_mst"."c_prefix" = "left"("substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1))-1)
            and "order_mst"."n_srno" = "reverse"("left"("reverse"("st_track_mst"."c_doc_no"),"charindex"('/',"reverse"("st_track_mst"."c_doc_no"))-1))
          where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "order_mst"."n_store_track" = 2
          group by "route_code" union all
        select "act_route"."c_Route_code" as "route_code",
          "count"(distinct("ord_det"."c_br_code"+'/'+"ord_det"."c_year"+'/'+"ord_det"."c_prefix"+'/'+"string"("ord_det"."n_srno"))) as "order_cnt",
          "count"(distinct "act_mst"."c_code") as "store_cnt",
          "count"("ord_det"."c_item_code") as "line_item_cnt"
          from "ord_det"
            join "ord_mst" on "ord_mst"."n_srno" = "ord_det"."n_srno"
            and "ord_mst"."c_br_code" = "ord_det"."c_br_code"
            and "ord_mst"."c_year" = "ord_det"."c_year"
            and "ord_mst"."c_prefix" = "ord_det"."c_prefix"
            join "act_mst" on "ord_mst"."c_cust_code" = "act_mst"."c_code"
            join "act_route" on "act_mst"."c_code" = "act_route"."c_br_code"
            join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "uf_get_br_code"('000')
            and "item_mst_br_info"."c_code" = "ord_det"."c_item_code"
            join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
            and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
            join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code"
            and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
            join "st_store_stage_det" on "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
            and "st_store_stage_det"."c_rack_grp_code" = "rack_group_mst"."c_code"
            join "st_store_stage_mst" on "st_store_stage_det"."c_br_code" = "st_store_stage_mst"."c_br_code"
            and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
            join "st_track_mst" on "ord_mst"."c_br_code" = "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1)
            and "ord_mst"."c_year" = "left"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))-1)
            and "ord_mst"."c_prefix" = "left"("substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1))-1)
            and "ord_mst"."n_srno" = "reverse"("left"("reverse"("st_track_mst"."c_doc_no"),"charindex"('/',"reverse"("st_track_mst"."c_doc_no"))-1))
          where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "ord_mst"."n_store_track" = 2
          group by "route_code" union all
        select "act_route"."c_Route_code" as "route_code",
          "count"(distinct("gdn_det"."c_br_code"+'/'+"gdn_det"."c_year"+'/'+"gdn_det"."c_prefix"+'/'+"string"("gdn_det"."n_srno"))) as "order_cnt",
          "count"(distinct "act_mst"."c_code") as "store_cnt",
          "count"("gdn_det"."c_item_code") as "line_item_cnt"
          from "gdn_det"
            join "gdn_mst" on "gdn_mst"."n_srno" = "gdn_det"."n_srno"
            and "gdn_mst"."c_br_code" = "gdn_det"."c_br_code"
            and "gdn_mst"."c_year" = "gdn_det"."c_year"
            and "gdn_mst"."c_prefix" = "gdn_det"."c_prefix"
            join "act_mst" on "gdn_mst"."c_ref_br_code" = "act_mst"."c_code"
            join "act_route" on "act_mst"."c_code" = "act_route"."c_br_code"
            join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "uf_get_br_code"('000')
            and "item_mst_br_info"."c_code" = "gdn_det"."c_item_code"
            join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
            and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
            join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code"
            and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
            join "st_store_stage_det" on "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
            and "st_store_stage_det"."c_rack_grp_code" = "rack_group_mst"."c_code"
            join "st_store_stage_mst" on "st_store_stage_det"."c_br_code" = "st_store_stage_mst"."c_br_code"
            and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
            join "st_track_mst" on "gdn_mst"."c_br_code" = "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1)
            and "gdn_mst"."c_year" = "left"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))-1)
            and "gdn_mst"."c_prefix" = "left"("substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1))-1)
            and "gdn_mst"."n_srno" = "reverse"("left"("reverse"("st_track_mst"."c_doc_no"),"charindex"('/',"reverse"("st_track_mst"."c_doc_no"))-1))
          where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "gdn_mst"."n_store_track" = 2
          group by "route_code" union all
        select "act_route"."c_Route_code" as "route_code",
          "count"(distinct("inv_det"."c_br_code"+'/'+"inv_det"."c_year"+'/'+"inv_det"."c_prefix"+'/'+"string"("inv_det"."n_srno"))) as "order_cnt",
          "count"(distinct "act_mst"."c_code") as "store_cnt",
          "count"("inv_det"."c_item_code") as "line_item_cnt"
          from "inv_det"
            join "inv_mst" on "inv_mst"."n_srno" = "inv_det"."n_srno"
            and "inv_mst"."c_br_code" = "inv_det"."c_br_code"
            and "inv_mst"."c_year" = "inv_det"."c_year"
            and "inv_mst"."c_prefix" = "inv_det"."c_prefix"
            join "act_mst" on "inv_mst"."c_cust_code" = "act_mst"."c_code"
            join "act_route" on "act_mst"."c_code" = "act_route"."c_br_code"
            join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "uf_get_br_code"('000')
            and "item_mst_br_info"."c_code" = "inv_det"."c_item_code"
            join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
            and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
            join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code"
            and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
            join "st_store_stage_det" on "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
            and "st_store_stage_det"."c_rack_grp_code" = "rack_group_mst"."c_code"
            join "st_store_stage_mst" on "st_store_stage_det"."c_br_code" = "st_store_stage_mst"."c_br_code"
            and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
            join "st_track_mst" on "inv_mst"."c_br_code" = "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1)
            and "inv_mst"."c_year" = "left"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))-1)
            and "inv_mst"."c_prefix" = "left"("substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1))-1)
            and "inv_mst"."n_srno" = "reverse"("left"("reverse"("st_track_mst"."c_doc_no"),"charindex"('/',"reverse"("st_track_mst"."c_doc_no"))-1))
          where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "inv_mst"."n_store_track" = 2
          group by "route_code") as "t"
        --where st.c_doc_no = '074/19/O/962' 
        //                left outer join "act_mst" on if "sm"."c_cust_code" <> "left"("st"."c_doc_no","charindex"('/',"st"."c_doc_no")-1) then "sm"."c_cust_code" else "left"("st"."c_doc_no","charindex"('/',"st"."c_doc_no")-1) endif = "act_mst"."c_code"
        //                left outer join "act_route" on if "sm"."c_cust_code" <> "left"("st"."c_doc_no","charindex"('/',"st"."c_doc_no")-1) then "sm"."c_cust_code" else "left"("st"."c_doc_no","charindex"('/',"st"."c_doc_no")-1) endif = "act_route"."c_br_code"
        left outer join(select "rt_code" as "c_rute_code",
          "rt_name" as "c_route_name",
          "sum"("pending_tray_cnt") as "n_pending_trays_pick",
          "sum"("pick_completed_cnt") as "n_pick_trays_completed",
          "sum"("Conveyor_Belt_cnt") as "n_pending_trays_on_conveyor",
          "sum"("conversion_pending_cnt") as "n_pending_trays_pack"
          from(select "act_route"."c_route_code" as "rt_code",
              "route_mst"."c_name" as "rt_name",
              "isnull"(if "st"."n_inout" = 0 then "count"("c_tray_code") endif,0) as "pending_tray_cnt",
              "isnull"(if "st"."n_inout" <> 0 and "st"."n_flag" in( 0,1,2,3 ) then "count"("c_tray_code") endif,0) as "pick_completed_cnt",
              "isnull"(if "st"."n_inout" <> 0 and "st"."n_flag" in( 0,1,2,3,4,5 ) then "count"("c_tray_code") endif,0) as "Conveyor_Belt_cnt",
              "isnull"(if "st"."n_inout" <> 0 and "st"."n_flag" in( 6 ) then "count"("c_tray_code") endif,0) as "conversion_pending_cnt"
              from "st_track_mst" as "sm"
                left outer join "st_track_tray_move" as "st" on "sm"."c_doc_no" = "st"."c_doc_no"
                left outer join "act_mst" on if "sm"."c_cust_code" <> "left"("sm"."c_doc_no","charindex"('/',"sm"."c_doc_no")-1) then "sm"."c_cust_code" else "left"("sm"."c_doc_no","charindex"('/',"sm"."c_doc_no")-1) endif = "act_mst"."c_code"
                left outer join "act_route" on if "sm"."c_cust_code" <> "left"("sm"."c_doc_no","charindex"('/',"sm"."c_doc_no")-1) then "sm"."c_cust_code" else "left"("sm"."c_doc_no","charindex"('/',"sm"."c_doc_no")-1) endif = "act_route"."c_br_code"
                left outer join "route_mst" on "act_route"."c_route_code" = "route_mst"."c_code"
              group by "st"."n_inout","st"."n_flag","rt_code","rt_name") as "t"
          group by "c_rute_code","c_route_name") as "tray_summary" on "tray_summary"."c_rute_code" = "t"."route_code"
        left outer join(select "rt_code" as "c_rt_code","count"() as "unassign_rg_cnt"
          from(select distinct "route_mst"."c_code" as "rt_code",
              "isnull"("st_track_det"."c_rack_grp_code",'-') as "c_rg_code",
              "isnull"("st_track_det"."c_stage_code",'-') as "c_stg_code"
              from "st_track_mst"
                join "st_track_det" on "st_track_det"."c_doc_no" = "st_track_mst"."c_doc_no" and "st_track_det"."n_inout" = "st_track_mst"."n_inout"
                left outer join "act_route" on if "c_cust_code" <> "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1) then "st_track_mst"."c_cust_code" else "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1) endif = "act_route"."c_br_code"
                left outer join "route_mst" on "act_route"."c_route_code" = "route_mst"."c_code"
                join "act_mst" on "act_mst"."c_code" = "st_track_mst"."c_cust_code"
              where "st_track_det"."c_tray_code" is null and "st_track_mst"."n_inout" = 0 and "st_track_mst"."c_doc_no" not like '%/162/%') as "t" group by "c_rt_code") as "pending_tray" on "pending_tray"."c_rt_code" = "t"."route_code"
      group by "c_status","c_route_code","c_route_name","n_unassigned_rack_grps_cnt","n_pending_trays_pick","n_pending_trays_on_conveyor","n_pending_trays_pack","n_pending_trays_dispatch","n_pick_trays_completed" for xml raw,elements
  when 'store_wise_order_det' then
    //http://10.89.209.19:49503/ws_st_pending_order_dashboard?&cIndex=store_wise_order_det&GodownCode=&gsbr=000&RouteCode=RT0008&StageCode=&RackGrpCode=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=
    select "act_code" as "c_store_code",
      "act_name" as "c_store_name",
      "route_code" as "c_route_code",
      "sum"("order_cnt") as "n_total_orders",
      "sum"("line_item_cnt") as "n_number_of_line_items",
      "isnull"("pending_tray"."unassign_rg_cnt",0) as "n_unassigned_rack_grps_cnt",
      "tray_summary"."n_pending_trays_pick" as "n_pending_trays_pick",
      "tray_summary"."n_pick_trays_completed" as "n_pick_trays_completed",
      "tray_summary"."n_pending_trays_on_conveyor" as "n_pending_trays_on_conveyor",
      "tray_summary"."n_pending_trays_pack" as "n_pending_trays_pack",
      10 as "n_pending_trays_dispatch",
      if "n_unassigned_rack_grps_cnt" = 0 then
        if "n_pending_trays_pick" = 0 and "n_pending_trays_on_conveyor" = 0 and "n_pending_trays_pack" = 0 and "n_pending_trays_dispatch" = 0 then 'Complete'
        else 'Partial'
        endif
      else
        if "n_pending_trays_pick" = 0 and "n_pending_trays_on_conveyor" = 0 and "n_pending_trays_pack" = 0 and "n_pending_trays_dispatch" = 0 then 'Open'
        else 'Partial'
        endif
      endif as "c_status"
      from(select "act_mst"."c_code" as "act_code",
          "act_mst"."c_name" as "act_name",
          "act_route"."c_Route_code" as "route_code",
          "count"(distinct "order_det"."c_br_code"+'/'+"order_det"."c_year"+'/'+"order_det"."c_prefix"+'/'+"string"("order_det"."n_srno")) as "order_cnt",
          "count"("order_det"."c_item_code") as "line_item_cnt"
          from "order_det"
            join "order_mst" on "order_mst"."n_srno" = "order_det"."n_srno"
            and "order_mst"."c_br_code" = "order_det"."c_br_code"
            and "order_mst"."c_year" = "order_det"."c_year"
            and "order_mst"."c_prefix" = "order_det"."c_prefix"
            join "act_mst" on "order_mst"."c_ref_br_code" = "act_mst"."c_code"
            join "act_route" on "act_mst"."c_code" = "act_route"."c_br_code"
            join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "uf_get_br_code"('000')
            and "item_mst_br_info"."c_code" = "order_det"."c_item_code"
            join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
            and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
            join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code"
            and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
            join "st_store_stage_det" on "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
            and "st_store_stage_det"."c_rack_grp_code" = "rack_group_mst"."c_code"
            join "st_store_stage_mst" on "st_store_stage_det"."c_br_code" = "st_store_stage_mst"."c_br_code"
            and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
            join "st_track_mst" on "order_mst"."c_br_code" = "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1)
            and "order_mst"."c_year" = "left"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))-1)
            and "order_mst"."c_prefix" = "left"("substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1))-1)
            and "order_mst"."n_srno" = "reverse"("left"("reverse"("st_track_mst"."c_doc_no"),"charindex"('/',"reverse"("st_track_mst"."c_doc_no"))-1))
          where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "order_mst"."n_store_track" = 2
          group by "act_code","act_name","route_code" union all
        select "act_mst"."c_code" as "act_code",
          "act_mst"."c_name" as "act_name",
          "act_route"."c_Route_code" as "route_code",
          "count"(distinct("ord_det"."c_br_code"+'/'+"ord_det"."c_year"+'/'+"ord_det"."c_prefix"+'/'+"string"("ord_det"."n_srno"))) as "order_cnt",
          "count"("ord_det"."c_item_code") as "line_item_cnt"
          from "ord_det"
            join "ord_mst" on "ord_mst"."n_srno" = "ord_det"."n_srno"
            and "ord_mst"."c_br_code" = "ord_det"."c_br_code"
            and "ord_mst"."c_year" = "ord_det"."c_year"
            and "ord_mst"."c_prefix" = "ord_det"."c_prefix"
            join "act_mst" on "ord_mst"."c_cust_code" = "act_mst"."c_code"
            join "act_route" on "act_mst"."c_code" = "act_route"."c_br_code"
            join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "uf_get_br_code"('000')
            and "item_mst_br_info"."c_code" = "ord_det"."c_item_code"
            join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
            and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
            join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code"
            and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
            join "st_store_stage_det" on "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
            and "st_store_stage_det"."c_rack_grp_code" = "rack_group_mst"."c_code"
            join "st_store_stage_mst" on "st_store_stage_det"."c_br_code" = "st_store_stage_mst"."c_br_code"
            and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
            join "st_track_mst" on "ord_mst"."c_br_code" = "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1)
            and "ord_mst"."c_year" = "left"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))-1)
            and "ord_mst"."c_prefix" = "left"("substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1))-1)
            and "ord_mst"."n_srno" = "reverse"("left"("reverse"("st_track_mst"."c_doc_no"),"charindex"('/',"reverse"("st_track_mst"."c_doc_no"))-1))
          where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "ord_mst"."n_store_track" = 2
          group by "route_code","act_code","act_name" union all
        select "act_mst"."c_code" as "act_code",
          "act_mst"."c_name" as "act_name",
          "act_route"."c_Route_code" as "route_code",
          "count"(distinct("gdn_det"."c_br_code"+'/'+"gdn_det"."c_year"+'/'+"gdn_det"."c_prefix"+'/'+"string"("gdn_det"."n_srno"))) as "order_cnt",
          "count"("gdn_det"."c_item_code") as "line_item_cnt"
          from "gdn_det"
            join "gdn_mst" on "gdn_mst"."n_srno" = "gdn_det"."n_srno"
            and "gdn_mst"."c_br_code" = "gdn_det"."c_br_code"
            and "gdn_mst"."c_year" = "gdn_det"."c_year"
            and "gdn_mst"."c_prefix" = "gdn_det"."c_prefix"
            join "act_mst" on "gdn_mst"."c_ref_br_code" = "act_mst"."c_code"
            join "act_route" on "act_mst"."c_code" = "act_route"."c_br_code"
            join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "uf_get_br_code"('000')
            and "item_mst_br_info"."c_code" = "gdn_det"."c_item_code"
            join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
            and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
            join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code"
            and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
            join "st_store_stage_det" on "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
            and "st_store_stage_det"."c_rack_grp_code" = "rack_group_mst"."c_code"
            join "st_store_stage_mst" on "st_store_stage_det"."c_br_code" = "st_store_stage_mst"."c_br_code"
            and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
            join "st_track_mst" on "gdn_mst"."c_br_code" = "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1)
            and "gdn_mst"."c_year" = "left"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))-1)
            and "gdn_mst"."c_prefix" = "left"("substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1))-1)
            and "gdn_mst"."n_srno" = "reverse"("left"("reverse"("st_track_mst"."c_doc_no"),"charindex"('/',"reverse"("st_track_mst"."c_doc_no"))-1))
          where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "gdn_mst"."n_store_track" = 2
          group by "route_code","act_code","act_name" union all
        select "act_mst"."c_code" as "act_code",
          "act_mst"."c_name" as "act_name",
          "act_route"."c_Route_code" as "route_code",
          "count"(distinct("inv_det"."c_br_code"+'/'+"inv_det"."c_year"+'/'+"inv_det"."c_prefix"+'/'+"string"("inv_det"."n_srno"))) as "order_cnt",
          "count"("inv_det"."c_item_code") as "line_item_cnt"
          from "inv_det"
            join "inv_mst" on "inv_mst"."n_srno" = "inv_det"."n_srno"
            and "inv_mst"."c_br_code" = "inv_det"."c_br_code"
            and "inv_mst"."c_year" = "inv_det"."c_year"
            and "inv_mst"."c_prefix" = "inv_det"."c_prefix"
            join "act_mst" on "inv_mst"."c_cust_code" = "act_mst"."c_code"
            join "act_route" on "act_mst"."c_code" = "act_route"."c_br_code"
            join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "uf_get_br_code"('000')
            and "item_mst_br_info"."c_code" = "inv_det"."c_item_code"
            join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
            and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
            join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code"
            and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
            join "st_store_stage_det" on "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
            and "st_store_stage_det"."c_rack_grp_code" = "rack_group_mst"."c_code"
            join "st_store_stage_mst" on "st_store_stage_det"."c_br_code" = "st_store_stage_mst"."c_br_code"
            and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
            join "st_track_mst" on "inv_mst"."c_br_code" = "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1)
            and "inv_mst"."c_year" = "left"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))-1)
            and "inv_mst"."c_prefix" = "left"("substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1))-1)
            and "inv_mst"."n_srno" = "reverse"("left"("reverse"("st_track_mst"."c_doc_no"),"charindex"('/',"reverse"("st_track_mst"."c_doc_no"))-1))
          where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "inv_mst"."n_store_track" = 2
          group by "route_code","act_code","act_name") as "t"
        -- "route_mst"."c_name" as rt_name,
        --        left outer join "route_mst" on "act_route"."c_route_code" = "route_mst"."c_code"
        --where st.c_doc_no = '074/19/O/962' 
        join(select "custo_code" as "c_cust_code",
          "custo_name" as "c_cust_name",
          "rt_code" as "c_rute_code",
          "sum"("pending_tray_cnt") as "n_pending_trays_pick",
          "sum"("pick_completed_cnt") as "n_pick_trays_completed",
          "sum"("Conveyor_Belt_cnt") as "n_pending_trays_on_conveyor",
          "sum"("conversion_pending_cnt") as "n_pending_trays_pack"
          from(select "sm"."c_cust_code" as "custo_code",
              "act_route"."c_route_code" as "rt_code",
              "act_mst"."c_name" as "custo_name",
              "isnull"(if "st"."n_inout" = 0 then "count"("c_tray_code") endif,0) as "pending_tray_cnt",
              "isnull"(if "st"."n_inout" <> 0 and "st"."n_flag" in( 0,1,2,3 ) then "count"("c_tray_code") endif,0) as "pick_completed_cnt",
              "isnull"(if "st"."n_inout" <> 0 and "st"."n_flag" in( 4,5 ) then "count"("c_tray_code") endif,0) as "Conveyor_Belt_cnt",
              "isnull"(if "st"."n_inout" <> 0 and "st"."n_flag" in( 6 ) then "count"("c_tray_code") endif,0) as "conversion_pending_cnt"
              from "st_track_mst" as "sm"
                left outer join "st_track_tray_move" as "st" on "sm"."c_doc_no" = "st"."c_doc_no"
                left outer join "act_mst" on if "sm"."c_cust_code" <> "left"("sm"."c_doc_no","charindex"('/',"sm"."c_doc_no")-1) then "sm"."c_cust_code" else "left"("sm"."c_doc_no","charindex"('/',"sm"."c_doc_no")-1) endif = "act_mst"."c_code"
                left outer join "act_route" on if "sm"."c_cust_code" <> "left"("sm"."c_doc_no","charindex"('/',"sm"."c_doc_no")-1) then "sm"."c_cust_code" else "left"("sm"."c_doc_no","charindex"('/',"sm"."c_doc_no")-1) endif = "act_route"."c_br_code"
              group by "st"."n_inout","st"."n_flag","rt_code","custo_code","custo_name") as "t"
          group by "c_rute_code","c_cust_name","c_cust_code") as "tray_summary" on "t"."act_code" = "tray_summary"."c_cust_code" and "tray_summary"."c_rute_code" = "t"."route_code"
        left outer join(select "cust_code" as "c_cust_code","rt_code" as "c_rt_code","count"() as "unassign_rg_cnt"
          from(select distinct "act_mst"."c_code" as "cust_code",
              "route_mst"."c_code" as "rt_code",
              "st_track_det"."c_rack_grp_code" as "c_rg_code",
              "st_track_det"."c_stage_code" as "c_stg_code"
              from "st_track_det"
                join "st_track_mst" on "st_track_det"."c_doc_no" = "st_track_mst"."c_doc_no" and "st_track_det"."n_inout" = "st_track_mst"."n_inout"
                left outer join "act_route" on if "c_cust_code" <> "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1) then "st_track_mst"."c_cust_code" else "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1) endif = "act_route"."c_br_code"
                left outer join "route_mst" on "act_route"."c_route_code" = "route_mst"."c_code"
                join "act_mst" on "act_mst"."c_code" = "st_track_mst"."c_cust_code"
              where "st_track_det"."c_tray_code" is null and "st_track_det"."n_inout" = 0 and "st_track_det"."c_doc_no" not like '%/162/%') as "t"
          group by "c_cust_code","c_rt_code") as "pending_tray" on "pending_tray"."c_rt_code" = "t"."route_code" and "t"."act_code" = "pending_tray"."c_cust_code"
      where "c_route_code" = @n_route_code
      group by "c_store_code","c_store_name","c_route_code","n_unassigned_rack_grps_cnt","n_pending_trays_pick","n_pending_trays_on_conveyor","n_pending_trays_pack","n_pending_trays_dispatch","c_status","n_pick_trays_completed" for xml raw,elements
  when 'store_wise_unassigned_rg_list' then
    //http://10.89.209.19:49503/ws_st_pending_order_dashboard?&cIndex=store_wise_unassigned_rg_list&GodownCode=&gsbr=000&RouteCode=RT0007&CustCode=028&StageCode=&RackGrpCode=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=
    select distinct "act_mst"."c_code" as "cust_code",
      "route_mst"."c_code" as "rt_code",
      "st_track_det"."c_rack_grp_code" as "c_rg_code",
      "st_track_det"."c_stage_code" as "c_stg_code"
      from "st_track_det"
        join "st_track_mst" on "st_track_det"."c_doc_no" = "st_track_mst"."c_doc_no" and "st_track_det"."n_inout" = "st_track_mst"."n_inout"
        left outer join "act_route" on if "c_cust_code" <> "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1) then "st_track_mst"."c_cust_code" else "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1) endif = "act_route"."c_br_code"
        left outer join "route_mst" on "act_route"."c_route_code" = "route_mst"."c_code"
        join "act_mst" on "act_mst"."c_code" = "st_track_mst"."c_cust_code"
      where "st_track_det"."c_tray_code" is null and "st_track_det"."n_inout" = 0 and "st_track_det"."c_doc_no" not like '%/162/%'
      and "rt_code" = @n_route_code and "c_cust_code" = @c_cust_code order by "c_rg_code" asc for xml raw,elements
  when 'route_wise_unassigned_rg_list' then
    //http://10.89.209.19:49503/ws_st_pending_order_dashboard?&cIndex=route_wise_unassigned_rg_list&GodownCode=&gsbr=000&RouteCode=&StageCode=&RackGrpCode=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=
    select distinct "route_mst"."c_code" as "rt_code",
      "st_track_det"."c_rack_grp_code" as "c_rg_code",
      "st_track_det"."c_stage_code" as "c_stg_code"
      from "st_track_det"
        join "st_track_mst" on "st_track_det"."c_doc_no" = "st_track_mst"."c_doc_no" and "st_track_det"."n_inout" = "st_track_mst"."n_inout"
        left outer join "act_route" on if "c_cust_code" <> "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1) then "st_track_mst"."c_cust_code" else "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1) endif = "act_route"."c_br_code"
        left outer join "route_mst" on "act_route"."c_route_code" = "route_mst"."c_code"
        join "act_mst" on "act_mst"."c_code" = "st_track_mst"."c_cust_code"
      where "st_track_det"."c_tray_code" is null and "st_track_det"."n_inout" = 0 and "st_track_det"."c_doc_no" not like '%/162/%' and "rt_code" is not null and "rt_code" = @n_route_code
      order by "rt_code" asc,"c_rg_code" asc for xml raw,elements
  /*  select distinct "route_mst"."c_code" as "rt_code",
"st_track_det"."c_rack_grp_code" as "c_rg_code",
"st_track_det"."c_stage_code" as "c_stg_code"
from "st_track_det"
join "st_track_mst" on "st_track_det"."c_doc_no" = "st_track_mst"."c_doc_no" and "st_track_det"."n_inout" = "st_track_mst"."n_inout"
left outer join "act_route" on if "c_cust_code" <> "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1) then "st_track_mst"."c_cust_code" else "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1) endif = "act_route"."c_br_code"
left outer join "route_mst" on "act_route"."c_route_code" = "route_mst"."c_code"
join "act_mst" on "act_mst"."c_code" = "st_track_mst"."c_cust_code"
where "st_track_det"."c_tray_code" is null and "st_track_det"."n_inout" = 0 and "st_track_det"."c_doc_no" not like '%/162/%' and "rt_code" is not null 
union all
select "act_route"."c_Route_code" as "route_code",
//          "count"(distinct("order_det"."c_br_code"+'/'+"order_det"."c_year"+'/'+"order_det"."c_prefix"+'/'+"string"("order_det"."n_srno"))) as "order_cnt",
//          "count"(distinct "act_mst"."c_code") as "store_cnt",
rack_group_mst.c_code as c_rg_code,
st_store_stage_det.c_stage_code as c_stage_code
//          "count"("order_det"."c_item_code") as "line_item_cnt"
from "order_det"
join "order_mst" on "order_mst"."n_srno" = "order_det"."n_srno"
and "order_mst"."c_br_code" = "order_det"."c_br_code"
and "order_mst"."c_year" = "order_det"."c_year"
and "order_mst"."c_prefix" = "order_det"."c_prefix"
join "act_mst" on "order_mst"."c_ref_br_code" = "act_mst"."c_code"
join "act_route" on "act_mst"."c_code" = "act_route"."c_br_code"
join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "uf_get_br_code"('000')
and "item_mst_br_info"."c_code" = "order_det"."c_item_code"
join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code"
and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
join "st_store_stage_det" on "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
and "st_store_stage_det"."c_rack_grp_code" = "rack_group_mst"."c_code"
join "st_store_stage_mst" on "st_store_stage_det"."c_br_code" = "st_store_stage_mst"."c_br_code"
and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
join "st_track_mst" on "order_mst"."c_br_code" = "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1)
and "order_mst"."c_year" = "left"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))-1)
and "order_mst"."c_prefix" = "left"("substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1))-1)
and "order_mst"."n_srno" = "reverse"("left"("reverse"("st_track_mst"."c_doc_no"),"charindex"('/',"reverse"("st_track_mst"."c_doc_no"))-1))
where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "order_mst"."n_store_track" = 2
//          group by "route_code" , c_rg_code 
union all
select "act_route"."c_Route_code" as "route_code",
//          "count"(distinct("ord_det"."c_br_code"+'/'+"ord_det"."c_year"+'/'+"ord_det"."c_prefix"+'/'+"string"("ord_det"."n_srno"))) as "order_cnt",
//          "count"(distinct "act_mst"."c_code") as "store_cnt
rack_group_mst.c_code as c_rg_code,
st_store_stage_det.c_stage_code as c_stage_code
//          "count"("ord_det"."c_item_code") as "line_item_cnt"
from "ord_det"
join "ord_mst" on "ord_mst"."n_srno" = "ord_det"."n_srno"
and "ord_mst"."c_br_code" = "ord_det"."c_br_code"
and "ord_mst"."c_year" = "ord_det"."c_year"
and "ord_mst"."c_prefix" = "ord_det"."c_prefix"
join "act_mst" on "ord_mst"."c_cust_code" = "act_mst"."c_code"
join "act_route" on "act_mst"."c_code" = "act_route"."c_br_code"
join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "uf_get_br_code"('000')
and "item_mst_br_info"."c_code" = "ord_det"."c_item_code"
join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code"
and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
join "st_store_stage_det" on "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
and "st_store_stage_det"."c_rack_grp_code" = "rack_group_mst"."c_code"
join "st_store_stage_mst" on "st_store_stage_det"."c_br_code" = "st_store_stage_mst"."c_br_code"
and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
join "st_track_mst" on "ord_mst"."c_br_code" = "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1)
and "ord_mst"."c_year" = "left"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))-1)
and "ord_mst"."c_prefix" = "left"("substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1))-1)
and "ord_mst"."n_srno" = "reverse"("left"("reverse"("st_track_mst"."c_doc_no"),"charindex"('/',"reverse"("st_track_mst"."c_doc_no"))-1))
where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "ord_mst"."n_store_track" = 2 and ord_mst.n_srno = 122
//          group by "route_code" , c_rg_code
union all
select "act_route"."c_Route_code" as "route_code",
//          "count"(distinct("gdn_det"."c_br_code"+'/'+"gdn_det"."c_year"+'/'+"gdn_det"."c_prefix"+'/'+"string"("gdn_det"."n_srno"))) as "order_cnt",
//          "count"(distinct "act_mst"."c_code") as "store_cnt",
rack_group_mst.c_code as c_rg_code,
st_store_stage_det.c_stage_code as c_stage_code
//          "count"("gdn_det"."c_item_code") as "line_item_cnt"
from "gdn_det"
join "gdn_mst" on "gdn_mst"."n_srno" = "gdn_det"."n_srno"
and "gdn_mst"."c_br_code" = "gdn_det"."c_br_code"
and "gdn_mst"."c_year" = "gdn_det"."c_year"
and "gdn_mst"."c_prefix" = "gdn_det"."c_prefix"
join "act_mst" on "gdn_mst"."c_ref_br_code" = "act_mst"."c_code"
join "act_route" on "act_mst"."c_code" = "act_route"."c_br_code"
join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "uf_get_br_code"('000')
and "item_mst_br_info"."c_code" = "gdn_det"."c_item_code"
join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code"
and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
join "st_store_stage_det" on "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
and "st_store_stage_det"."c_rack_grp_code" = "rack_group_mst"."c_code"
join "st_store_stage_mst" on "st_store_stage_det"."c_br_code" = "st_store_stage_mst"."c_br_code"
and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
join "st_track_mst" on "gdn_mst"."c_br_code" = "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1)
and "gdn_mst"."c_year" = "left"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))-1)
and "gdn_mst"."c_prefix" = "left"("substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1))-1)
and "gdn_mst"."n_srno" = "reverse"("left"("reverse"("st_track_mst"."c_doc_no"),"charindex"('/',"reverse"("st_track_mst"."c_doc_no"))-1))
where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "gdn_mst"."n_store_track" = 2
//          group by "route_code", c_rg_code 
union all
select "act_route"."c_Route_code" as "route_code",
//          "count"(distinct("inv_det"."c_br_code"+'/'+"inv_det"."c_year"+'/'+"inv_det"."c_prefix"+'/'+"string"("inv_det"."n_srno"))) as "order_cnt",
//          "count"(distinct "act_mst"."c_code") as "store_cnt",
rack_group_mst.c_code as c_rg_code,
st_store_stage_det.c_stage_code as c_stage_code
//          "count"("inv_det"."c_item_code") as "line_item_cnt"
from "inv_det"
join "inv_mst" on "inv_mst"."n_srno" = "inv_det"."n_srno"
and "inv_mst"."c_br_code" = "inv_det"."c_br_code"
and "inv_mst"."c_year" = "inv_det"."c_year"
and "inv_mst"."c_prefix" = "inv_det"."c_prefix"
join "act_mst" on "inv_mst"."c_cust_code" = "act_mst"."c_code"
join "act_route" on "act_mst"."c_code" = "act_route"."c_br_code"
join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "uf_get_br_code"('000')
and "item_mst_br_info"."c_code" = "inv_det"."c_item_code"
join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code"
and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
join "st_store_stage_det" on "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
and "st_store_stage_det"."c_rack_grp_code" = "rack_group_mst"."c_code"
join "st_store_stage_mst" on "st_store_stage_det"."c_br_code" = "st_store_stage_mst"."c_br_code"
and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
join "st_track_mst" on "inv_mst"."c_br_code" = "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1)
and "inv_mst"."c_year" = "left"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))-1)
and "inv_mst"."c_prefix" = "left"("substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1))-1)
and "inv_mst"."n_srno" = "reverse"("left"("reverse"("st_track_mst"."c_doc_no"),"charindex"('/',"reverse"("st_track_mst"."c_doc_no"))-1))
where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "inv_mst"."n_store_track" = 2
//          group by "route_code", c_rg_code
order by "rt_code" asc,"c_rg_code" asc */
  when 'pick_req_workforce' then
    //http://10.89.209.19:49503/ws_st_pending_order_dashboard?&cIndex=pick_req_workforce&GodownCode=&gsbr=000&RouteCode=&StageCode=&RackGrpCode=&SimulationModeFlag=1&SimulationUsersLoggedIn=2&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=
    select "count"(distinct "c_rack_grp_code")
      //          where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "order_mst"."n_store_track" = 2
      //          where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "ord_mst"."n_store_track" = 2
      //          where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "gdn_mst"."n_store_track" = 2
      //          where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "inv_mst"."n_store_track" = 2
      into @picking_users_required
      from(select "order_det"."c_br_code",
          "order_det"."c_year",
          "order_det"."c_prefix",
          "order_det"."n_srno",
          "act_mst"."c_code" as "act_code",
          "order_det"."c_br_code"+'/'+"order_det"."c_year"+'/'+"order_det"."c_prefix"+'/'+"string"("order_det"."n_srno") as "doc_no",
          "order_det"."d_date",
          "count"(distinct "order_det"."c_item_code") as "item_cnt",
          "st_store_stage_det"."c_rack_grp_code",
          "st_store_stage_det"."c_stage_code"
          from "order_det"
            join "order_mst" on "order_mst"."n_srno" = "order_det"."n_srno"
            and "order_mst"."c_br_code" = "order_det"."c_br_code"
            and "order_mst"."c_year" = "order_det"."c_year"
            and "order_mst"."c_prefix" = "order_det"."c_prefix"
            join "act_mst" on "order_mst"."c_ref_br_code" = "act_mst"."c_code"
            join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "uf_get_br_code"('000')
            and "item_mst_br_info"."c_code" = "order_det"."c_item_code"
            join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
            and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
            join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code"
            and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
            join "st_store_stage_det" on "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
            and "st_store_stage_det"."c_rack_grp_code" = "rack_group_mst"."c_code"
            join "st_store_stage_mst" on "st_store_stage_det"."c_br_code" = "st_store_stage_mst"."c_br_code"
            and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
            join "st_track_mst" on "order_mst"."c_br_code" = "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1)
            and "order_mst"."c_year" = "left"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))-1)
            and "order_mst"."c_prefix" = "left"("substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1))-1)
            and "order_mst"."n_srno" = "reverse"("left"("reverse"("st_track_mst"."c_doc_no"),"charindex"('/',"reverse"("st_track_mst"."c_doc_no"))-1))
          where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "order_mst"."n_store_track" = 2
          group by "order_det"."c_br_code","order_det"."c_year","order_det"."c_prefix","doc_no","order_det"."n_srno","order_det"."d_date",
          "st_store_stage_det"."c_stage_code","st_store_stage_mst"."c_stage_grp_code","act_code","st_store_stage_det"."c_rack_grp_code" union all
        select "ord_det"."c_br_code",
          "ord_det"."c_year",
          "ord_det"."c_prefix",
          "ord_det"."n_srno",
          "act_mst"."c_code" as "act_code",
          "ord_det"."c_br_code"+'/'+"ord_det"."c_year"+'/'+"ord_det"."c_prefix"+'/'+"string"("ord_det"."n_srno") as "doc_no",
          "ord_det"."d_date",
          "count"(distinct "ord_det"."c_item_code") as "n_item_cnt",
          "st_store_stage_det"."c_rack_grp_code",
          "st_store_stage_det"."c_stage_code"
          from "ord_det"
            join "ord_mst" on "ord_mst"."n_srno" = "ord_det"."n_srno"
            and "ord_mst"."c_br_code" = "ord_det"."c_br_code"
            and "ord_mst"."c_year" = "ord_det"."c_year"
            and "ord_mst"."c_prefix" = "ord_det"."c_prefix"
            join "act_mst" on "ord_mst"."c_cust_code" = "act_mst"."c_code"
            join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "uf_get_br_code"('000')
            and "item_mst_br_info"."c_code" = "ord_det"."c_item_code"
            join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
            and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
            join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code"
            and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
            join "st_store_stage_det" on "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
            and "st_store_stage_det"."c_rack_grp_code" = "rack_group_mst"."c_code"
            join "st_store_stage_mst" on "st_store_stage_det"."c_br_code" = "st_store_stage_mst"."c_br_code"
            and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
            join "st_track_mst" on "ord_mst"."c_br_code" = "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1)
            and "ord_mst"."c_year" = "left"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))-1)
            and "ord_mst"."c_prefix" = "left"("substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1))-1)
            and "ord_mst"."n_srno" = "reverse"("left"("reverse"("st_track_mst"."c_doc_no"),"charindex"('/',"reverse"("st_track_mst"."c_doc_no"))-1))
          where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "ord_mst"."n_store_track" = 2
          group by "ord_det"."c_br_code","ord_det"."c_year","ord_det"."c_prefix","doc_no","ord_det"."n_srno","ord_det"."d_date",
          "st_store_stage_det"."c_stage_code","st_store_stage_mst"."c_stage_grp_code","act_code","st_store_stage_det"."c_rack_grp_code" union all
        select "gdn_det"."c_br_code",
          "gdn_det"."c_year",
          "gdn_det"."c_prefix",
          "gdn_det"."n_srno",
          "act_mst"."c_code" as "act_code",
          "gdn_det"."c_br_code"+'/'+"gdn_det"."c_year"+'/'+"gdn_det"."c_prefix"+'/'+"string"("gdn_det"."n_srno") as "doc_no",
          "gdn_det"."d_date",
          "count"(distinct "gdn_det"."c_item_code") as "n_item_cnt",
          "st_store_stage_det"."c_rack_grp_code",
          "st_store_stage_det"."c_stage_code"
          from "gdn_det"
            join "gdn_mst" on "gdn_mst"."n_srno" = "gdn_det"."n_srno"
            and "gdn_mst"."c_br_code" = "gdn_det"."c_br_code"
            and "gdn_mst"."c_year" = "gdn_det"."c_year"
            and "gdn_mst"."c_prefix" = "gdn_det"."c_prefix"
            join "act_mst" on "gdn_mst"."c_ref_br_code" = "act_mst"."c_code"
            join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "uf_get_br_code"('000')
            and "item_mst_br_info"."c_code" = "gdn_det"."c_item_code"
            join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
            and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
            join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code"
            and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
            join "st_store_stage_det" on "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
            and "st_store_stage_det"."c_rack_grp_code" = "rack_group_mst"."c_code"
            join "st_store_stage_mst" on "st_store_stage_det"."c_br_code" = "st_store_stage_mst"."c_br_code"
            and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
            join "st_track_mst" on "gdn_mst"."c_br_code" = "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1)
            and "gdn_mst"."c_year" = "left"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))-1)
            and "gdn_mst"."c_prefix" = "left"("substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1))-1)
            and "gdn_mst"."n_srno" = "reverse"("left"("reverse"("st_track_mst"."c_doc_no"),"charindex"('/',"reverse"("st_track_mst"."c_doc_no"))-1))
          where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "gdn_mst"."n_store_track" = 2
          group by "gdn_det"."c_br_code","gdn_det"."c_year","gdn_det"."c_prefix","doc_no","gdn_det"."n_srno","gdn_det"."d_date",
          "st_store_stage_det"."c_stage_code","st_store_stage_mst"."c_stage_grp_code","act_code","st_store_stage_det"."c_rack_grp_code" union all
        select "inv_det"."c_br_code",
          "inv_det"."c_year",
          "inv_det"."c_prefix",
          "inv_det"."n_srno",
          "act_mst"."c_code" as "act_code",
          "inv_det"."c_br_code"+'/'+"inv_det"."c_year"+'/'+"inv_det"."c_prefix"+'/'+"string"("inv_det"."n_srno") as "doc_no",
          "inv_det"."d_date",
          "count"(distinct "inv_det"."c_item_code") as "n_item_cnt",
          "st_store_stage_det"."c_rack_grp_code",
          "st_store_stage_det"."c_stage_code"
          from "inv_det"
            join "inv_mst" on "inv_mst"."n_srno" = "inv_det"."n_srno"
            and "inv_mst"."c_br_code" = "inv_det"."c_br_code"
            and "inv_mst"."c_year" = "inv_det"."c_year"
            and "inv_mst"."c_prefix" = "inv_det"."c_prefix"
            join "act_mst" on "inv_mst"."c_cust_code" = "act_mst"."c_code"
            join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "uf_get_br_code"('000')
            and "item_mst_br_info"."c_code" = "inv_det"."c_item_code"
            join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
            and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
            join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code"
            and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
            join "st_store_stage_det" on "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
            and "st_store_stage_det"."c_rack_grp_code" = "rack_group_mst"."c_code"
            join "st_store_stage_mst" on "st_store_stage_det"."c_br_code" = "st_store_stage_mst"."c_br_code"
            and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
            join "st_track_mst" on "inv_mst"."c_br_code" = "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1)
            and "inv_mst"."c_year" = "left"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))-1)
            and "inv_mst"."c_prefix" = "left"("substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1))-1)
            and "inv_mst"."n_srno" = "reverse"("left"("reverse"("st_track_mst"."c_doc_no"),"charindex"('/',"reverse"("st_track_mst"."c_doc_no"))-1))
          where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "inv_mst"."n_store_track" = 2
          group by "inv_det"."c_br_code","inv_det"."c_year","inv_det"."c_prefix","doc_no","inv_det"."n_srno","inv_det"."d_date",
          "st_store_stage_det"."c_stage_code","st_store_stage_mst"."c_stage_grp_code","act_code","st_store_stage_det"."c_rack_grp_code"
          order by "c_stage_code" asc) as "t";
    select "count"(distinct "c_rack_grp_code") into @logged_in_users from "st_store_login_det"
        join "st_store_login" on "st_store_login_det"."c_br_code" = "st_store_login"."c_br_code"
        and "st_store_login_det"."c_user_id" = "st_store_login"."c_user_id"
        and "st_store_login_det"."n_inout" = "st_store_login"."n_inout"
        and "st_store_login_det"."c_device_id" = "st_store_login"."c_device_id"
        and "st_store_login_det"."t_login_time" = "st_store_login"."t_login_time"
      where "st_store_login_det"."t_login_time" is not null and "st_store_login"."n_inout" = 0;
    //    select "isnull"("min"("t_action_start_time"),'00:00:00.000')
    //      into @pick_start_time
    //      from "st_track_tray_time"
    //      where "c_work_place" = 'PICKING'
    //      and cast("t_time" as date) = "today"() --"uf_default_date"()
    //      and "t_action_end_time" is not null
    //      and("st_track_tray_time"."n_bounce_count"+"st_track_tray_time"."n_pick_count") > 0;
    select "isnull"("min"("t_action_start_time"),'00:00:00.000'),"isnull"("max"("t_action_end_time"),'00:00:00.000')
      into @pick_start_time,@pick_end_time
      from "st_track_tray_time"
      where "c_work_place" = 'PICKING'
      and cast("t_time" as date) = "today"()
      and "t_action_end_time" is not null
      and("st_track_tray_time"."n_bounce_count"+"st_track_tray_time"."n_pick_count") > 0;
    select "count"()/if @picking_users_required = 0 then 1 else @picking_users_required endif into @pending_items_cnt from "st_track_det" where "n_complete" = 0 and "n_inout" = 0 and "st_track_det"."c_doc_no" not like '%/162/%';
    select "count"()/if @simulation_mode_flag = 1 then if @simulation_users_logged_in <> 0 then @simulation_users_logged_in else @picking_users_required endif
      else if @logged_in_users = 0 then @picking_users_required else @logged_in_users endif
      endif into @logged_in_user_pending_items_cnt from "st_track_det" where "n_complete" = 0 and "n_inout" = 0 and "st_track_det"."c_doc_no" not like '%/162/%';
    select @pick_start_time as "t_pick_start_time",
      @pick_end_time as "t_pick_end_time",
      @picking_users_required as "n_pick_user_required",
      cast(@pending_items_cnt*("sum"("n_avg_time_in_seconds_to_pick")/"sum"("n_avg_item_count"))/86400 as integer) as "t_pick_prediction_etc_days",
      cast("mod"(@pending_items_cnt*("sum"("n_avg_time_in_seconds_to_pick")/"sum"("n_avg_item_count")),86400)/3600 as integer) as "t_pick_prediction_etc_hours",
      cast("mod"("mod"(@pending_items_cnt*("sum"("n_avg_time_in_seconds_to_pick")/"sum"("n_avg_item_count")),86400),3600)/60 as integer) as "t_pick_prediction_etc_minutes",
      cast("mod"("mod"("mod"(@pending_items_cnt*("sum"("n_avg_time_in_seconds_to_pick")/"sum"("n_avg_item_count")),86400),3600),60) as integer) as "t_pick_prediction_etc_seconds",
      if @simulation_mode_flag = 1 then if @simulation_users_logged_in <> 0 then @simulation_users_logged_in else @picking_users_required endif
      else if @logged_in_users = 0 then @picking_users_required else @logged_in_users endif
      endif as "n_pick_logged_in_users",cast(@logged_in_user_pending_items_cnt*("sum"("n_avg_time_in_seconds_to_pick")/"sum"("n_avg_item_count"))/86400 as integer) as "t_pick_logged_in_etc_days",
      cast("mod"(@logged_in_user_pending_items_cnt*("sum"("n_avg_time_in_seconds_to_pick")/"sum"("n_avg_item_count")),86400)/3600 as integer) as "t_pick_logged_in_etc_hours",
      cast("mod"("mod"(@logged_in_user_pending_items_cnt*("sum"("n_avg_time_in_seconds_to_pick")/"sum"("n_avg_item_count")),86400),3600)/60 as integer) as "t_pick_logged_in_etc_minutes",
      cast("mod"("mod"("mod"(@logged_in_user_pending_items_cnt*("sum"("n_avg_time_in_seconds_to_pick")/"sum"("n_avg_item_count")),86400),3600),60) as integer) as "t_pick_logged_in_etc_seconds"
      from "st_work_place_efficiency_summary" where "c_work_place" = 'PICKING' for xml raw,elements
  when 'scan_req_workforce' then
    //http://10.89.209.19:49503/ws_st_pending_order_dashboard?&cIndex=scan_req_workforce&GodownCode=&gsbr=000&RouteCode=&StageCode=&RackGrpCode=&SimulationModeFlag=1&SimulationUsersLoggedIn=2&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=
    select "count"(distinct "c_user") as "n_scan_users_logged_in","isnull"("min"("t_action_start_time"),'00:00:00.000') as "t_scan_start_time","isnull"("max"("t_action_end_time"),'00:00:00.000') as "t_scan_end_time"
      into @scan_users_logged_in,@scan_start_time,@t_scan_end_time
      from "st_track_tray_time"
      where "c_work_place" = 'SCANNIG'
      and cast("t_time" as date) = "today"() --"uf_default_date"()
      and "t_action_end_time" is not null
      and("st_track_tray_time"."n_bounce_count"+"st_track_tray_time"."n_pick_count") > 0;
    select "count"(distinct "st_route_table_mapping"."c_table_code")
      into @scan_users_required
      from(select "order_det"."c_br_code",
          "order_det"."c_year",
          "order_det"."c_prefix",
          "order_det"."n_srno",
          "act_mst"."c_code" as "act_code",
          "order_det"."c_br_code"+'/'+"order_det"."c_year"+'/'+"order_det"."c_prefix"+'/'+"string"("order_det"."n_srno") as "doc_no",
          "order_det"."d_date",
          "st_store_stage_det"."c_rack_grp_code",
          "st_store_stage_det"."c_stage_code"
          from "order_det"
            join "order_mst" on "order_mst"."n_srno" = "order_det"."n_srno"
            and "order_mst"."c_br_code" = "order_det"."c_br_code"
            and "order_mst"."c_year" = "order_det"."c_year"
            and "order_mst"."c_prefix" = "order_det"."c_prefix"
            join "act_mst" on "order_mst"."c_ref_br_code" = "act_mst"."c_code"
            join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "uf_get_br_code"('000')
            and "item_mst_br_info"."c_code" = "order_det"."c_item_code"
            join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
            and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
            join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code"
            and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
            join "st_store_stage_det" on "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
            and "st_store_stage_det"."c_rack_grp_code" = "rack_group_mst"."c_code"
            join "st_store_stage_mst" on "st_store_stage_det"."c_br_code" = "st_store_stage_mst"."c_br_code"
            and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
            join "st_track_mst" on "order_mst"."c_br_code" = "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1)
            and "order_mst"."c_year" = "left"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))-1)
            and "order_mst"."c_prefix" = "left"("substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1))-1)
            and "order_mst"."n_srno" = "reverse"("left"("reverse"("st_track_mst"."c_doc_no"),"charindex"('/',"reverse"("st_track_mst"."c_doc_no"))-1))
          where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "order_mst"."n_store_track" = 2 union all
        select "ord_det"."c_br_code",
          "ord_det"."c_year",
          "ord_det"."c_prefix",
          "ord_det"."n_srno",
          "act_mst"."c_code" as "act_code",
          "ord_det"."c_br_code"+'/'+"ord_det"."c_year"+'/'+"ord_det"."c_prefix"+'/'+"string"("ord_det"."n_srno") as "doc_no",
          "ord_det"."d_date",
          "st_store_stage_det"."c_rack_grp_code",
          "st_store_stage_det"."c_stage_code"
          from "ord_det"
            join "ord_mst" on "ord_mst"."n_srno" = "ord_det"."n_srno"
            and "ord_mst"."c_br_code" = "ord_det"."c_br_code"
            and "ord_mst"."c_year" = "ord_det"."c_year"
            and "ord_mst"."c_prefix" = "ord_det"."c_prefix"
            join "act_mst" on "ord_mst"."c_cust_code" = "act_mst"."c_code"
            join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "uf_get_br_code"('000')
            and "item_mst_br_info"."c_code" = "ord_det"."c_item_code"
            join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
            and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
            join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code"
            and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
            join "st_store_stage_det" on "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
            and "st_store_stage_det"."c_rack_grp_code" = "rack_group_mst"."c_code"
            join "st_store_stage_mst" on "st_store_stage_det"."c_br_code" = "st_store_stage_mst"."c_br_code"
            and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
            join "st_track_mst" on "ord_mst"."c_br_code" = "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1)
            and "ord_mst"."c_year" = "left"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))-1)
            and "ord_mst"."c_prefix" = "left"("substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1))-1)
            and "ord_mst"."n_srno" = "reverse"("left"("reverse"("st_track_mst"."c_doc_no"),"charindex"('/',"reverse"("st_track_mst"."c_doc_no"))-1))
          where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "ord_mst"."n_store_track" = 2 union all
        select "gdn_det"."c_br_code",
          "gdn_det"."c_year",
          "gdn_det"."c_prefix",
          "gdn_det"."n_srno",
          "act_mst"."c_code" as "act_code",
          "gdn_det"."c_br_code"+'/'+"gdn_det"."c_year"+'/'+"gdn_det"."c_prefix"+'/'+"string"("gdn_det"."n_srno") as "doc_no",
          "gdn_det"."d_date",
          "st_store_stage_det"."c_rack_grp_code",
          "st_store_stage_det"."c_stage_code"
          from "gdn_det"
            join "gdn_mst" on "gdn_mst"."n_srno" = "gdn_det"."n_srno"
            and "gdn_mst"."c_br_code" = "gdn_det"."c_br_code"
            and "gdn_mst"."c_year" = "gdn_det"."c_year"
            and "gdn_mst"."c_prefix" = "gdn_det"."c_prefix"
            join "act_mst" on "gdn_mst"."c_ref_br_code" = "act_mst"."c_code"
            join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "uf_get_br_code"('000')
            and "item_mst_br_info"."c_code" = "gdn_det"."c_item_code"
            join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
            and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
            join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code"
            and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
            join "st_store_stage_det" on "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
            and "st_store_stage_det"."c_rack_grp_code" = "rack_group_mst"."c_code"
            join "st_store_stage_mst" on "st_store_stage_det"."c_br_code" = "st_store_stage_mst"."c_br_code"
            and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
            join "st_track_mst" on "gdn_mst"."c_br_code" = "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1)
            and "gdn_mst"."c_year" = "left"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))-1)
            and "gdn_mst"."c_prefix" = "left"("substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1))-1)
            and "gdn_mst"."n_srno" = "reverse"("left"("reverse"("st_track_mst"."c_doc_no"),"charindex"('/',"reverse"("st_track_mst"."c_doc_no"))-1))
          where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "gdn_mst"."n_store_track" = 2 union all
        select "inv_det"."c_br_code",
          "inv_det"."c_year",
          "inv_det"."c_prefix",
          "inv_det"."n_srno",
          "act_mst"."c_code" as "act_code",
          "inv_det"."c_br_code"+'/'+"inv_det"."c_year"+'/'+"inv_det"."c_prefix"+'/'+"string"("inv_det"."n_srno") as "doc_no",
          "inv_det"."d_date",
          "st_store_stage_det"."c_rack_grp_code",
          "st_store_stage_det"."c_stage_code"
          from "inv_det"
            join "inv_mst" on "inv_mst"."n_srno" = "inv_det"."n_srno"
            and "inv_mst"."c_br_code" = "inv_det"."c_br_code"
            and "inv_mst"."c_year" = "inv_det"."c_year"
            and "inv_mst"."c_prefix" = "inv_det"."c_prefix"
            join "act_mst" on "inv_mst"."c_cust_code" = "act_mst"."c_code"
            join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "uf_get_br_code"('000')
            and "item_mst_br_info"."c_code" = "inv_det"."c_item_code"
            join "rack_mst" on "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
            and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
            join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code"
            and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
            join "st_store_stage_det" on "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
            and "st_store_stage_det"."c_rack_grp_code" = "rack_group_mst"."c_code"
            join "st_store_stage_mst" on "st_store_stage_det"."c_br_code" = "st_store_stage_mst"."c_br_code"
            and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
            join "st_track_mst" on "inv_mst"."c_br_code" = "left"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")-1)
            and "inv_mst"."c_year" = "left"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))-1)
            and "inv_mst"."c_prefix" = "left"("substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1),"charindex"('/',"substring"("st_track_mst"."c_doc_no","charindex"('/',"st_track_mst"."c_doc_no")+1))+1))-1)
            and "inv_mst"."n_srno" = "reverse"("left"("reverse"("st_track_mst"."c_doc_no"),"charindex"('/',"reverse"("st_track_mst"."c_doc_no"))-1))
          where(("st_track_MST"."n_confirm" = 0 and "st_track_mst"."n_inout" = 0) or "st_track_Mst"."d_date" = "uf_default_date"()) and "inv_mst"."n_store_track" = 2) as "temp_table"
        join "act_route" on "temp_table"."act_code" = "act_route"."c_br_code"
        join "st_route_table_mapping" on "st_route_table_mapping"."c_route_code" = "act_route"."c_route_code";
    select "count"()/if @scan_users_required = 0 then 1 else @scan_users_required endif into @pending_items_cnt from "st_track_det" where "n_complete" = 1 and "n_inout" = 0 and "st_track_det"."c_doc_no" not like '%/162/%';
    select "count"()/if @simulation_mode_flag = 1 then if @simulation_users_logged_in <> 0 then @simulation_users_logged_in else if @scan_users_required = 0 then 1 else @scan_users_required endif endif
      else(if @scan_users_logged_in = 0 then(if @scan_users_required = 0 then 1 else @scan_users_required endif) else @scan_users_logged_in endif)
      endif into @logged_in_user_pending_items_cnt from "st_track_det" where "n_complete" = 1 and "n_inout" = 0 and "st_track_det"."c_doc_no" not like '%/162/%';
    select @scan_start_time as "t_scan_start_time",
      @t_scan_end_time as "t_scan_end_time",
      @scan_Users_required as "n_Scan_users_required",
      cast(@pending_items_cnt*("sum"("n_avg_time_in_seconds_to_pick")/"sum"("n_avg_item_count"))/86400 as integer) as "t_scan_prediction_etc_days",
      cast("mod"(@pending_items_cnt*("sum"("n_avg_time_in_seconds_to_pick")/"sum"("n_avg_item_count")),86400)/3600 as integer) as "t_scan_prediction_etc_hours",
      cast("mod"("mod"(@pending_items_cnt*("sum"("n_avg_time_in_seconds_to_pick")/"sum"("n_avg_item_count")),86400),3600)/60 as integer) as "t_scan_prediction_etc_minutes",
      cast("mod"("mod"("mod"(@pending_items_cnt*("sum"("n_avg_time_in_seconds_to_pick")/"sum"("n_avg_item_count")),86400),3600),60) as integer) as "t_scan_prediction_etc_seconds",
      if @simulation_mode_flag = 1 then if @simulation_users_logged_in <> 0 then @simulation_users_logged_in else if @scan_users_required = 0 then 1 else @scan_users_required endif endif
      else(if @scan_users_logged_in = 0 then(if @scan_users_required = 0 then 1 else @scan_users_required endif) else @scan_users_logged_in endif)
      endif as "n_scan_logged_in_users",cast(@logged_in_user_pending_items_cnt*("sum"("n_avg_time_in_seconds_to_pick")/"sum"("n_avg_item_count"))/86400 as integer) as "t_scan_logged_in_etc_days",
      cast("mod"(@logged_in_user_pending_items_cnt*("sum"("n_avg_time_in_seconds_to_pick")/"sum"("n_avg_item_count")),86400)/3600 as integer) as "t_scan_logged_in_etc_hours",
      cast("mod"("mod"(@logged_in_user_pending_items_cnt*("sum"("n_avg_time_in_seconds_to_pick")/"sum"("n_avg_item_count")),86400),3600)/60 as integer) as "t_scan_logged_in_etc_minutes",
      cast("mod"("mod"("mod"(@logged_in_user_pending_items_cnt*("sum"("n_avg_time_in_seconds_to_pick")/"sum"("n_avg_item_count")),86400),3600),60) as integer) as "t_scan_logged_in_etc_seconds"
      from "st_work_place_efficiency_summary" where "c_work_place" = 'SCANNIG' for xml raw,elements
  end case
end;