CREATE PROCEDURE "DBA"."usp_st_outwawrd_tray_prediction"( 
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
  declare @shelf_code char(6);
  declare @route_code char(6);
  declare @time_slot_code char(6);
  declare @gate_code char(6);
  declare @in_out_flag numeric(1);
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
    set @GodownCode = "http_variable"('GodownCode'); --11
    set @in_out_flag = "http_variable"('inOutFlag');
    set @route_code = "http_variable"('RouteCode');
    set @time_slot_code = "http_variable"('TimeSlotCode');
    set @gate_code = "http_variable"('GateCode'); --12	
    set @shelf_code = "http_variable"('shelfCode') --12		
  end if;
  case @cIndex
  when 'dispatched_tray_details' then
    //http://10.89.209.19:49503/ws_st_outwawrd_tray_prediction?&cIndex=dispatched_tray_details&GodownCode=&gsbr=000&StageCode=&RackGrpCode=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=
    //      "count"(distinct(if "carton_mst"."n_carton_no" = 0 then "carton_mst"."c_tray_code" else '000000'+"left"("carton_mst"."n_carton_no",10) endif)) as "n_dipached_tray_cnt",
    select "count"(distinct(select "c_tray_code" from "tray_ledger"
        where "tray_ledger"."c_tray_code" = if "carton_mst"."n_carton_no" = 0 then "carton_mst"."c_tray_code" else "left"("carton_mst"."n_carton_no",6) endif
        group by "c_tray_code" having "sum"("n_qty") = 0)) as "n_dispatched_tray_cnt",
      "gdn_mst"."c_ref_br_code" as "br_code",
      "act_mst"."c_name",
      "act_route"."c_br_code" as "act_br_code",
      "act_route"."c_route_code",
      "route_mst"."c_name" as "c_zone_name",
      "act_mst"."c_contact_person" as "c_contact_person",
      "act_mst"."c_mobile" as "c_mobile_number",
      "act_mst"."c_email" as "c_email_id"
      from "gdn_mst" join "carton_mst" on "gdn_mst"."c_br_code" = "carton_mst"."c_br_code"
        and "gdn_mst"."c_year" = "carton_mst"."c_year"
        and "gdn_mst"."c_prefix" = "carton_mst"."c_prefix"
        and "gdn_mst"."n_srno" = "carton_mst"."n_srno"
        join "act_mst" on "act_mst"."c_code" = "gdn_mst"."c_ref_br_code"
        left outer join "slip_det" on "gdn_mst"."c_br_code" = "slip_det"."c_inv_br"
        and "gdn_mst"."c_year" = "slip_det"."c_inv_year"
        and "gdn_mst"."c_prefix" = "slip_det"."c_inv_prefix"
        and "gdn_mst"."n_srno" = "slip_det"."n_inv_no"
        and "slip_det"."n_cancel_flag" = 0
        left outer join "act_route" on "act_route"."c_br_code" = "gdn_mst"."c_ref_br_code"
        left outer join "route_mst" on "route_mst"."c_code" = "act_route"."c_route_code"
      --("gdn_mst"."d_date" >= uf_default_date()-30)  and
      where("gdn_mst"."d_date" <= "today"()) // '2019-10-19'
      group by "br_code","act_mst"."c_name","act_br_code","act_route"."c_route_code","c_zone_name","c_contact_person","c_mobile_number","c_email_id"
      having "n_dispatched_tray_cnt" <> 0 union
    //      "count"(distinct(if "carton_mst"."n_carton_no" = 0 then "carton_mst"."c_tray_code" else '000000'+"left"("carton_mst"."n_carton_no",10) endif)) as "n_dispatched_tray_cnt",
    select "count"(distinct(select "c_tray_code" from "tray_ledger"
        where "tray_ledger"."c_tray_code" = if "carton_mst"."n_carton_no" = 0 then "carton_mst"."c_tray_code" else "left"("carton_mst"."n_carton_no",6) endif
        group by "c_tray_code" having "sum"("n_qty") = 0)) as "n_dispatched_tray_cnt",
      "inv_mst"."c_cust_code" as "br_code",
      "act_mst"."c_name",
      "act_route"."c_br_code" as "act_br_code",
      "act_route"."c_route_code",
      "route_mst"."c_name" as "c_zone_name",
      "act_mst"."c_contact_person" as "c_contact_person",
      "act_mst"."c_mobile" as "c_mobile_number",
      "act_mst"."c_email" as "c_email_id"
      from "inv_mst" join "carton_mst" on "inv_mst"."c_br_code" = "carton_mst"."c_br_code"
        and "inv_mst"."c_year" = "carton_mst"."c_year"
        and "inv_mst"."c_prefix" = "carton_mst"."c_prefix"
        and "inv_mst"."n_srno" = "carton_mst"."n_srno"
        join "act_mst" on "act_mst"."c_code" = "inv_mst"."c_cust_code"
        left outer join "slip_det" on "inv_mst"."c_br_code" = "slip_det"."c_inv_br"
        and "inv_mst"."c_year" = "slip_det"."c_inv_year"
        and "inv_mst"."c_prefix" = "slip_det"."c_inv_prefix"
        and "inv_mst"."n_srno" = "slip_det"."n_inv_no"
        and "slip_det"."n_cancel_flag" = 0
        left outer join "act_route" on "act_route"."c_br_code" = "inv_mst"."c_cust_code"
        left outer join "route_mst" on "route_mst"."c_code" = "act_route"."c_route_code"
      --"inv_mst"."d_date" >= uf_default_date()-30  and 
      where "inv_mst"."d_date" <= "today"()
      group by "br_code","act_mst"."c_name","act_br_code","act_route"."c_route_code","c_zone_name","c_contact_person","c_mobile_number","c_email_id"
      having "n_dispatched_tray_cnt" <> 0 for xml raw,elements
  when 'route_wise_dispatched_trays' then
    //http://10.89.209.19:49503/ws_st_outwawrd_tray_prediction?&cIndex=route_wise_dispatched_trays&GodownCode=&gsbr=000&StageCode=&RackGrpCode=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=MYBOSS
    select "st_truck_allocation_plan"."d_date" as "d_date",
      "route_mst"."c_code" as "c_route_code",
      "route_mst"."c_name" as "c_route_name",
      "st_truck_allocation_plan"."c_time_slot_code" as "c_time_slot_code",
      "st_time_zone_mst"."c_name" as "time_slot_name",
      "st_time_zone_mst"."t_from_time" as "t_time",
      "st_time_zone_mst"."t_to_time" as "t_to_time",
      "st_truck_allocation_plan"."c_gate_code" as "c_gate_code",
      "st_gate_mst"."c_name" as "c_gate_name",
      if "c_time_slot_code" is null then 'UN-ALLOCATED'
      else if "c_time_slot_code" is not null and "c_delivery_slip_doc_no" is not null and "c_dispatch_user" is null then 'DISPATCH IN PROGRESS'
        else if "c_time_slot_code" is not null and "c_delivery_slip_doc_no" is not null and "c_dispatch_user" is not null then 'DISPATCHED'
          else 'ALLOCATED'
          endif
        endif
      endif as "c_status"
      from "route_mst"
        left outer join "st_truck_allocation_plan" on "route_mst"."c_code" = "st_truck_allocation_plan"."c_route_code" and "st_truck_allocation_plan"."d_date" = "today"()
        left outer join "st_time_zone_mst" on "st_time_zone_mst"."c_code" = "st_truck_allocation_plan"."c_time_slot_code"
        and "st_time_zone_mst"."c_br_code" = "st_truck_allocation_plan"."c_br_code"
        left outer join "st_gate_mst" on "st_gate_mst"."c_code" = "st_truck_allocation_plan"."c_gate_code"
        and "st_gate_mst"."c_br_code" = "st_truck_allocation_plan"."c_br_code"
      order by "st_truck_allocation_plan"."d_date" asc,"route_mst"."c_code" asc for xml raw,elements
  when 'route_list' then
    //http://10.89.209.19:49503/ws_st_outwawrd_tray_prediction?&cIndex=route_list&GodownCode=&gsbr=000&StageCode=&RackGrpCode=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=
    select "c_code" as "c_route_code",
      "c_Name" as "c_route_name",
      "c_sh_name",
      "n_route_no"
      from "route_mst" where "n_lock" = 0 and "c_route_code" <> '-' for xml raw,elements
  when 'route_schedule_list' then
    //http://10.89.209.19:49503/ws_st_outwawrd_tray_prediction?&cIndex=route_schedule_list&GodownCode=&gsbr=000&StageCode=&RackGrpCode=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=
    select "c_code",
      "c_name",
      "t_from_time",
      "t_to_time"
      from "st_time_zone_mst" for xml raw,elements
  when 'gate_list' then
    //http://10.89.209.19:49503/ws_st_outwawrd_tray_prediction?&cIndex=gate_list&GodownCode=&gsbr=000&StageCode=&RackGrpCode=&inOutFlag=0&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=
    select "C_CODE",
      "C_NAME",
      "N_IN_OUT_FLAG"
      from "st_gate_mst" where "n_cancel_flag" = 0 and "n_in_out_flag" = @in_out_flag for xml raw,elements
  when 'shelf_available' then
    //http://10.89.209.19:49503/ws_st_outwawrd_tray_prediction?&cIndex=shelf_available&GodownCode=&gsbr=000&StageCode=&RackGrpCode=&inOutFlag=0&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=
    select "st_gate_det"."c_code" as "c_gate_code",
      "st_gate_mst"."c_name" as "c_gate_name",
      "count"("rack_mst"."c_code")-(select "count"("c_shelf_code") from "st_shelf_det" where "st_shelf_det"."c_gate_code" = "st_gate_mst"."c_code" and "d_date" = "today"()) as "n_shelves_available"
      from "st_gate_det"
        left outer join "st_gate_mst" on "st_gate_mst"."c_code" = "st_gate_det"."c_code" and "st_gate_mst"."c_br_code" = "st_gate_det"."c_br_code"
        left outer join "rack_group_mst" on "rack_group_mst"."c_code" = "st_gate_det"."c_rack_grp_code" and "rack_group_mst"."c_br_code" = "st_gate_det"."c_br_code"
        left outer join "rack_mst" on "rack_mst"."c_br_code" = "rack_group_mst"."c_br_code" and "rack_mst"."c_rack_grp_code" = "rack_group_mst"."c_code"
      where "st_gate_mst"."n_in_out_flag" = 1 and "rack_mst"."n_type" = 3 and "st_gate_mst"."n_cancel_flag" = 0
      group by "st_gate_det"."c_code","st_gate_mst"."c_name","st_gate_mst"."c_code" for xml raw,elements
  when 'shelf_info' then
    //  http://172.16.18.19:49503/ws_st_outwawrd_tray_prediction?&cIndex=shelf_info&GateCode=GATE7&GodownCode=&gsbr=503&devID=a3dcfdf75bc646d105092019064846055&sKEY=sKey&UserId=MYBOSS    
    select "c_gate_code",
      "st_shelf_det"."c_route_code" as "c_route_code",
      "t_time_slot_code",
      "st_time_zone_mst"."t_from_time" as "t_schedule_booked",
      "route_mst"."c_name" as "c_route_name",
      "count"(distinct "c_shelf_code") as "shelf_space"
      from "st_shelf_det"
        left outer join "st_time_zone_mst" on "st_shelf_det"."t_time_slot_code" = "st_time_zone_mst"."c_code"
        left outer join "act_route" on "st_shelf_det"."c_cust_code" = "act_route"."c_br_code"
        and "st_shelf_det"."c_route_code" = "act_route"."c_route_code" and "act_route"."c_code" = "st_shelf_det"."c_br_code"
        left outer join "route_mst" on "route_mst"."c_code" = "act_route"."c_route_code"
      where "st_shelf_det"."d_date" = "today"() and "st_shelf_det"."c_gate_code" = @gate_code
      group by "c_gate_code","c_route_code","t_time_slot_code","t_schedule_booked","c_route_name"
      order by "t_schedule_booked" asc for xml raw,elements
  when 'truck_allocation_plan' then
    /*   http://10.89.209.19:49503/ws_st_outwawrd_tray_prediction?&cIndex=truck_allocation_plan&gsbr=000&RouteCode=RT0001&TimeSlotCode=TS0001&GateCode=GATE1&devID=bc4009171fdf58c115112018104912239&UserId=MYBOSS
*/
    if(select "COunt"() from "st_truck_allocation_plan" where "c_br_code" = "uf_get_br_code"(@gsBr) and "c_route_code" = @route_code and "c_time_slot_code" = @time_slot_code and "d_date" = "today"()) = 0 then
      insert into "st_truck_allocation_plan"
        ( "c_br_code","c_route_code","c_time_slot_code","c_gate_code","n_cancel_flag","c_device_id","c_user","d_ldate" ) values
        ( "uf_get_br_code"(@gsBr),@route_code,@time_slot_code,@gate_code,0,@devID,@UserId,"today"() ) ;
      if sqlstate = '00000' then
        commit work;
        select 1 as "c_status",
          'Success' as "c_message" for xml raw,elements
      else
        rollback work;
        select 0 as "c_status",
          'Failure' as "c_message" for xml raw,elements
      end if
    else select 0 as "c_status",
        'Failure: Already record exists for the Route: '+@route_code+' & the selected time slot '+@time_slot_code+'.' as "c_message" for xml raw,elements
    end if when 'timewise_pack_tray_prediction' then
    //http://10.89.209.19:49503/ws_st_outwawrd_tray_prediction?&cIndex=timewise_pack_tray_prediction&shelfCode=&GodownCode=&gsbr=000&StageCode=&RackGrpCode=&inOutFlag=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=myboss
    select 500 as "n_normal_hours_count",
      2500 as "n_peak_hours_count"
      from "dummy" for xml raw,elements
  when 'estimated_pick_tray_details' then
    //http://10.89.209.19:49503/ws_st_outwawrd_tray_prediction?&cIndex=estimated_pick_tray_details&shelfCode=&GodownCode=&gsbr=000&StageCode=&RackGrpCode=&inOutFlag=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=myboss
    select "isnull"("sum"("n_pick_tray_cnt"),0) as "n_estimated_pick_trays",
      "count"(distinct "doc_no") as "doc_count",
      "isnull"("sum"("n_item_cnt"),0) as "item_count",
      "count"(distinct "act_code") as "store_count",
      "count"(distinct "route_code") as "route_count",
      (select "count"(distinct "a"."c_code")
        from "st_tray_mst" as "a"
          join "st_tray_type_mst" as "c" on "a"."c_tray_type_code" = "c"."c_code"
          left outer join "st_track_in" as "b" on "a"."c_code" = "b"."c_tray_code"
          left outer join "st_track_tray_move" as "d" on "a"."c_code" = "d"."c_tray_code"
        where "b"."c_tray_code" is null and "d"."c_tray_code" is null
        and "a"."n_in_out_flag" in( 1,2 ) 
        and "a"."n_cancel_flag" = 0
        and "c"."n_cancel_flag" = 0) as "n_available_pick_trays",
      "isnull"(if("n_available_pick_trays"-"n_estimated_pick_trays") < 0 then "n_estimated_pick_trays"-"n_available_pick_trays" else 0 endif,0) as "n_shortage_pick_trays"
      from(select "order_det"."c_br_code",
          "order_det"."c_year",
          "order_det"."c_prefix",
          "order_det"."n_srno",
          "act_mst"."c_code" as "act_code",
          "act_mst"."c_name" as "act_name",
          "act_route"."c_Route_code" as "route_code",
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
            left outer join "act_route" on "act_mst"."c_code" = "act_route"."c_br_code"
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
          group by "order_det"."c_br_code","order_det"."c_year","order_det"."c_prefix","doc_no","order_det"."n_srno","order_det"."d_date","route_code",
          "st_store_stage_det"."c_stage_code","st_store_stage_mst"."c_stage_grp_code","act_code","act_name" union all
        select "ord_det"."c_br_code",
          "ord_det"."c_year",
          "ord_det"."c_prefix",
          "ord_det"."n_srno",
          "act_mst"."c_code" as "act_code",
          "act_mst"."c_name" as "act_name",
          "act_route"."c_Route_code" as "route_code",
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
            left outer join "act_route" on "act_mst"."c_code" = "act_route"."c_br_code"
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
          group by "ord_det"."c_br_code","ord_det"."c_year","ord_det"."c_prefix","doc_no","ord_det"."n_srno","ord_det"."d_date","route_code",
          "st_store_stage_det"."c_stage_code","st_store_stage_mst"."c_stage_grp_code","act_code","act_name" union all
        select "gdn_det"."c_br_code",
          "gdn_det"."c_year",
          "gdn_det"."c_prefix",
          "gdn_det"."n_srno",
          "act_mst"."c_code" as "act_code",
          "act_mst"."c_name" as "act_name",
          "act_route"."c_Route_code" as "route_code",
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
            left outer join "act_route" on "act_mst"."c_code" = "act_route"."c_br_code"
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
          group by "gdn_det"."c_br_code","gdn_det"."c_year","gdn_det"."c_prefix","doc_no","gdn_det"."n_srno","gdn_det"."d_date","route_code",
          "st_store_stage_det"."c_stage_code","st_store_stage_mst"."c_stage_grp_code","act_code","act_name" union all
        select "inv_det"."c_br_code",
          "inv_det"."c_year",
          "inv_det"."c_prefix",
          "inv_det"."n_srno",
          "act_mst"."c_code" as "act_code",
          "act_mst"."c_name" as "act_name",
          "act_route"."c_Route_code" as "route_code",
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
            left outer join "act_route" on "act_mst"."c_code" = "act_route"."c_br_code"
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
          group by "inv_det"."c_br_code","inv_det"."c_year","inv_det"."c_prefix","doc_no","inv_det"."n_srno","inv_det"."d_date","route_code",
          "st_store_stage_det"."c_stage_code","st_store_stage_mst"."c_stage_grp_code","act_code","act_name"
          order by "c_stage_code" asc,"n_item_cnt" asc) as "t" for xml raw,elements
  when 'estimated_pack_tray_details' then
    //http://10.89.209.19:49503/ws_st_outwawrd_tray_prediction?&cIndex=estimated_pack_tray_details&shelfCode=&GodownCode=&gsbr=000&StageCode=&RackGrpCode=&inOutFlag=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=myboss
    select "isnull"("ceil"("avg"("n_tray_count")),0) as "n_estimated_pack_trays",
      "isnull"("ceil"("avg"("n_carton_count")),0) as "n_estimated_cartons",
      "n_estimated_pack_trays"+"n_estimated_cartons" as "n_total_estimated_pack_trays",
      (select "count"(distinct "a"."c_code")
        from "st_tray_mst" as "a"
          join "st_tray_type_mst" as "c" on "a"."c_tray_type_code" = "c"."c_code"
          left outer join "st_track_in" as "b" on "a"."c_code" = "b"."c_tray_code"
          left outer join "st_track_tray_move" as "d" on "a"."c_code" = "d"."c_tray_code"
        where "b"."c_tray_code" is null and "d"."c_tray_code" is null
        and "a"."n_in_out_flag" = 0
        and "a"."n_cancel_flag" = 0
        and "c"."n_cancel_flag" = 0) as "n_available_pack_trays",
      (select "count"(distinct "a"."c_code")
        from "st_tray_mst" as "a"
          join "st_tray_type_mst" as "c" on "a"."c_tray_type_code" = "c"."c_code"
          left outer join "st_track_in" as "b" on "a"."c_code" = "b"."c_tray_code"
          left outer join "st_track_tray_move" as "d" on "a"."c_code" = "d"."c_tray_code"
        where "b"."c_tray_code" is null and "d"."c_tray_code" is null
        and "a"."n_in_out_flag" = 3
        and "a"."n_cancel_flag" = 0
        and "c"."n_cancel_flag" = 0) as "n_available_cartons",
      if("n_available_pack_trays"-"n_estimated_pack_trays") < 0 then "n_estimated_pack_trays"-"n_available_pack_trays" else 0 endif as "n_shortage_pack_trays",
      "n_available_cartons"-"n_estimated_cartons" as "n_shortage_cartons"
      from "st_day_wise_pack_summary"
      where "dayname"("d_date") = "dayname"("uf_default_date"()) and "d_date" >= "uf_default_date"()-15 for xml raw,elements
  when 'trays_to_collect' then
    //http://10.89.209.19:49503/ws_st_outwawrd_tray_prediction?&cIndex=trays_to_collect&GodownCode=&gsbr=503&devID=bc4009171fdf58c115112018104912239&UserId=myboss
    select "count"("c_tray_Code") as "n_trays_to_receive",
      (select "count"(distinct "c_route_code") as "n_delivery_scheduled_route"
        from "st_truck_allocation_plan" where "d_date" = "today"()) as "n_delivery_scheduled_route"
      from(select "c_tray_code","sum"("n_qty") as "ss" from "tray_ledger"
          group by "c_tray_code"
          having "ss" = 0) as "temp_table" for xml raw,elements
  when 'estimated_pick_tray_timewise' then
    //http://10.89.209.19:49503/ws_st_outwawrd_tray_prediction?&cIndex=estimated_pick_tray_timewise&shelfCode=&GodownCode=&gsbr=000&StageCode=&RackGrpCode=&inOutFlag=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=myboss
    select "c_code","c_name","t_from_time","t_to_time",
      if "c_code" = 'TZ001' then 500
      else if "c_code" = 'TZ002' then 650
        else if "c_code" = 'TZ003' then 450
          else if "c_code" = 'TZ004' then 200
            else if "c_code" = 'TZ005' then 700 endif
            endif
          endif
        endif
      endif as "n_total_trays" from "st_time_zone_mst" where "n_lock" = 0 for xml raw,elements
  end case
end;