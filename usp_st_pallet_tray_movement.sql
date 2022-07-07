ALTER PROCEDURE "DBA"."usp_st_pallet_tray_movement"( 
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
  declare @pigeon_flag integer;
  declare @max_pallet_capacity numeric(8);
  declare @cnt_trays_on_pallet numeric(8);
  declare @search_doc char(25);
  declare @rack_code char(6);
  declare @rack_grp_code char(6);
  declare @stage_code char(6);
  declare @dynamic_flag numeric(1);
  declare @ColSep char(6);
  declare @new_tray char(6);
  declare @new_pallet_code char(6);
  declare @pallet_code char(6);
  declare @location_code char(6);
  declare @floor_code char(6);
  declare @tmp_location char(6);
  declare @tray_code char(6);
  declare @ColMaxLen numeric(4);
  declare @ColPos integer;
  declare @trayList char(250);
  declare @TraysList char(250);
  declare @capacity_flag numeric(1);
  declare @pallet_flag numeric(1);
  declare @screen_flag numeric(1);
  declare @loctn_code char(6);
  declare @n_dynamic_flag numeric(1);
  declare @destination_floor_code char(30);
  declare @pallet_dstn_floor_code char(6);
  declare @c_br_code char(6);
  declare @c_year char(2);
  declare @c_prefix char(4);
  declare @n_srno numeric(9);
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
    set @pallet_code = "http_variable"('PalletCode');
    set @location_code = "http_variable"('LocationCode');
    set @floor_code = "http_variable"('FloorCode');
    set @tray_code = "http_variable"('TrayCode');
    set @trayList = "http_variable"('trayList');
    set @new_pallet_code = "http_variable"('newPalletCode');
    set @capacity_flag = "http_variable"('capacityFlag');
    set @pallet_flag = "http_variable"('Palletflag');
    set @screen_flag = "http_variable"('screenFlag');
    set @dynamic_flag = "http_variable"('dynamicFlag');
    set @GodownCode = "http_variable"('GodownCode');
    set @pigeon_flag = "http_variable"('pigeon_flag')
  end if;
  case @cIndex
  when 'location_details' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=location_details&gsbr=000&LocationCode=L1&PalletCode=PM0002&FloorCode=FM0001&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    select "st_store_floor_det"."c_floor_code" as "c_floor_code",
      "st_store_floor_mst"."c_name" as "c_floor_name",
      "n_row_no" as "n_row_no",
      "st_store_floor_det"."c_rack_code" as "c_location_code",
      "st_store_floor_det"."n_pos_seq"
      from "st_store_floor_det"
        join "st_store_floor_mst" on "st_store_floor_mst"."c_code" = "st_store_floor_det"."c_floor_code"
        and "st_store_floor_mst"."c_br_code" = "st_store_floor_det"."c_br_code"
        join "rack_mst" on "rack_mst"."c_code" = "st_store_floor_det"."c_rack_code"
      where "n_type" in( 1,2 ) and "st_store_floor_det"."c_rack_code" = @location_code for xml raw,elements
  when 'assign_pallet_location' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=assign_pallet_location&gsbr=000&LocationCode=L1&PalletCode=PM0002&FloorCode=FM0001&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    if(select "count"() from "st_tray_mst"
          join "st_tray_type_mst" on "st_tray_mst"."c_tray_type_code" = "st_tray_type_mst"."c_code"
          left outer join "st_pallet_move" on "st_tray_mst"."c_code" = "st_pallet_move"."c_pallet_code"
        where "n_tray_type" = 1 and "st_tray_mst"."n_cancel_flag" = 0 and "st_tray_mst"."c_code" = @pallet_code) = 0 then
      select 0 as "c_status",
        'Pallet Not Found in the Masters!' as "c_message" for xml raw,elements
    else
      if(select "count"() from "rack_mst" where "n_type" = 1 and "c_code" = @location_code) = 0 then
        select 0 as "c_status",
          'Location number Not Found!.' as "c_message" for xml raw,elements
      else
        if(select "count"() from "st_pallet_move" where "c_pallet_code" = @pallet_code) = 0 then
          if(select "count"() from "st_pallet_move" where "c_location_code" = @location_code) = 0 then
            insert into "st_pallet_move"
              ( "c_pallet_code","c_location_code","c_rack_grp_code","c_floor_code","n_inout","n_status_flag","n_tray_count","n_merge_pallet_flag","n_capacity_status","d_date","t_time","c_user" ) values
              ( @pallet_code,@location_code,'-',@floor_code,1,0,0,0,0,"today"(),"now"(),@UserId ) ;
            select 1 as "c_status",
              'Pallet '+@pallet_code+' is assigned to '+@location_code+' location.' as "c_message" for xml raw,elements
          else
            select "c_Pallet_code" into @tmp_location from "st_pallet_move" where "c_location_code" = @location_code;
            select 0 as "c_status",
              'Location '+@location_code+' is already assigned to "'+@tmp_location+'" pallet. Please recheck!!' as "c_message" for xml raw,elements
          end if
        else if(select "count"() from "st_pallet_move" where "c_pallet_code" = @pallet_code and "n_pallet_assigned_screen_flag" = 1) = 1 then
            update "st_pallet_move" set "c_location_code" = @location_code,"C_FLOOR_CODE" = @FLOOR_CODE,
              "n_pallet_assigned_screen_flag" = 0,"d_date" = "today"(),"t_time" = "now"(),"c_User" = @UserId where "c_pallet_code" = @pallet_code and "n_pallet_assigned_screen_flag" = 1;
            select 1 as "c_status",
              'Pallet '+@pallet_code+' is assigned to '+@location_code+' location.' as "c_message" for xml raw,elements
          else
            select "c_location_code" into @tmp_location from "st_pallet_move" where "c_pallet_code" = @pallet_code;
            select 0 as "c_status",
              'Pallet '+@pallet_code+' is already assigned to "'+@tmp_location+'" location. Please recheck!!' as "c_message" for xml raw,elements
          end if end if end if end if 
    when 'pallet_detail' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=pallet_detail&gsbr=000&TrayCode=5196&LocationCode=&PalletCode=&FloorCode=FM0001&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
//    select top 1
//      "item_receipt_entry"."n_dynamic_flag",
//      "item_receipt_entry"."c_tray_code", --"st_store_stage_det"."c_rack_grp_code",
//      "item_receipt_entry"."n_carton_no",
//      "item_mst_br_info"."n_self_barcode_req",
//      "item_receipt_entry"."n_carton_print",
//      "rack_group_mst"."c_code" as "c_rack_grp_code",
//      if "item_receipt_entry"."n_dynamic_flag" =1 then 
//        "st_store_stage_mst"."c_code"  
//     else 
//        "st_store_stage_mst"."c_code" 
//     end if as "c_stage_location_code",
//    if "item_receipt_entry"."n_dynamic_flag" =1 then 
//        "st_store_stage_mst"."c_floor_code" 
//    else 
//      "st_store_stage_mst"."c_floor_code"
//    end if as c_floor_code,
//      "st_store_floor_mst"."c_name"
//      from "item_receipt_entry"
//        left outer join "item_mst_br_info" on "item_mst_br_info"."c_code" = "item_receipt_entry"."c_item_code"
//        and "item_mst_br_info"."c_br_code" = "item_receipt_entry"."c_br_code"
//        left outer join "item_mst_br_info_godown" on "item_mst_br_info_godown"."c_code" = "item_receipt_entry"."c_item_code"
//        and "item_mst_br_info_godown"."c_br_code" = "item_receipt_entry"."c_br_code" and "item_mst_br_info_godown"."c_godown_code" = "item_mst_br_info"."c_default_godown_code"
//        join "pur_det" on "pur_det"."c_br_code" = "item_receipt_entry"."c_pur_br_code"
//        and "pur_det"."c_year" = "item_receipt_entry"."c_pur_year"
//        and "pur_det"."c_prefix" = "item_receipt_entry"."c_pur_prefix"
//        and "pur_det"."n_srno" = "item_receipt_entry"."n_pur_srno"
//        and "pur_det"."n_seq" = "item_receipt_entry"."n_pur_seq"
//        left outer join "rack_mst" on "rack_mst"."c_code" = if "pur_det"."c_godown_code" = '-' then "item_mst_br_info"."c_rack" else "item_mst_br_info_godown"."c_rack" endif
//        and "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
//        left outer join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code" and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
//        left outer join "st_store_stage_det" on "st_store_stage_det"."c_rack_grp_code" 
//         = if "item_receipt_entry"."n_dynamic_flag" <> 1 then "rack_group_mst"."c_code" else '-' endif
//        and if "item_receipt_entry"."n_dynamic_flag" <> 1 then "rack_group_mst"."c_br_code" else "uf_get_br_code"('000') endif = "st_store_stage_det"."c_br_code"
//        left outer join "st_store_stage_mst" on "st_store_stage_det"."c_stage_code" = "st_store_stage_mst"."c_code" and "st_store_stage_mst"."c_br_code" = "st_store_stage_det"."c_br_code"
//        left outer join "st_store_floor_mst" on "st_store_floor_mst"."c_br_code" = "st_store_stage_mst"."c_br_code" and "st_store_floor_mst"."c_code" = "st_store_stage_mst"."c_floor_code"
//      where("item_receipt_entry"."c_tray_code" = @tray_code or "item_receipt_entry"."n_carton_no" = @tray_code)
//      and "pur_det"."c_godown_code" = if "pur_det"."c_godown_code" <> '-' then "item_mst_br_info_godown"."c_godown_code" else '-' endif
//      order by "item_receipt_entry"."n_srno" desc 
    select top 1
      "item_receipt_entry"."n_dynamic_flag",
      "item_receipt_entry"."c_tray_code", --"ssd"."c_rack_grp_code",
      "item_receipt_entry"."n_carton_no",
      "item_mst_br_info"."n_self_barcode_req",
      "item_receipt_entry"."n_carton_print",
      "rack_group_mst"."c_code" as "c_rack_grp_code",
          if "item_receipt_entry"."n_dynamic_flag" =1 then 
            'DYN'
         else 
            ssm.c_code 
         end if as "c_stage_location_code",
        if "item_receipt_entry"."n_dynamic_flag" =1 then 
            ssm.c_dynamic_floor_code
        else 
          "ssm"."c_floor_code"
        end if as c_floor_code,
      "st_store_floor_mst"."c_name"
      from "item_receipt_entry"
        left outer join "item_mst_br_info" on "item_mst_br_info"."c_code" = "item_receipt_entry"."c_item_code"
        and "item_mst_br_info"."c_br_code" = "item_receipt_entry"."c_br_code"
        left outer join "item_mst_br_info_godown" on "item_mst_br_info_godown"."c_code" = "item_receipt_entry"."c_item_code"
        and "item_mst_br_info_godown"."c_br_code" = "item_receipt_entry"."c_br_code" and "item_mst_br_info_godown"."c_godown_code" = "item_mst_br_info"."c_default_godown_code"
        join "pur_det" on "pur_det"."c_br_code" = "item_receipt_entry"."c_pur_br_code"
        and "pur_det"."c_year" = "item_receipt_entry"."c_pur_year"
        and "pur_det"."c_prefix" = "item_receipt_entry"."c_pur_prefix"
        and "pur_det"."n_srno" = "item_receipt_entry"."n_pur_srno"
        and "pur_det"."n_seq" = "item_receipt_entry"."n_pur_seq"
        left outer join "rack_mst" on "rack_mst"."c_code" = if "pur_det"."c_godown_code" = '-' then "item_mst_br_info"."c_rack" else "item_mst_br_info_godown"."c_rack" endif
        and "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
        left outer join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code" and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
        left outer join st_store_stage_det as "ssd" on "ssd"."c_rack_grp_code" ="rack_group_mst"."c_code" 
            and "ssd"."c_br_code" = "rack_group_mst"."c_br_code"
        left outer join st_store_stage_mst as "ssm" on "ssd"."c_stage_code" = "ssm"."c_code" 
            and "ssm"."c_br_code" = "ssd"."c_br_code"
        left outer join "st_store_floor_mst" on "st_store_floor_mst"."c_br_code" = "ssm"."c_br_code" 
                and "st_store_floor_mst"."c_code" = "c_floor_code"
      where ("item_receipt_entry"."c_tray_code" = @tray_code or "item_receipt_entry"."n_carton_no" = @tray_code)
      and "pur_det"."c_godown_code" = if "pur_det"."c_godown_code" <> '-' then "item_mst_br_info_godown"."c_godown_code" else '-' endif
      order by "item_receipt_entry"."n_srno" desc for xml raw,elements
  when 'floor_pallet_detail' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=floor_pallet_detail&gsbr=000&TrayCode=1212&FloorCode=FM0001&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    select "st_pallet_move"."c_pallet_code",
      "st_store_floor_det"."n_row_no",
      "st_pallet_move"."c_location_code",
      "st_store_floor_det"."n_pos_seq",
      "st_pallet_move"."c_floor_code" as "c_current_floor_code",
      "st_pallet_move"."c_destination_floor_code" as "c_floor_code"
      from "st_pallet_move"
        join "st_store_floor_det" on "st_store_floor_det"."c_floor_code" = "st_pallet_move"."c_floor_code"
        and "st_store_floor_det"."c_rack_code" = "st_pallet_move"."c_location_code"
      where "n_status_flag" < 2 and "st_pallet_move"."c_destination_floor_code" = @floor_code
      order by "st_pallet_move"."c_pallet_code" asc for xml raw,elements
  when 'assign_tray_pallet' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=assign_tray_pallet&gsbr=000&TrayCode=5142&LocationCode=&PalletCode=PM0002&FloorCode=FM0001&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    select "st_tray_mst"."n_max_capacity"
      into @max_pallet_capacity
      from "st_tray_mst" join "st_Tray_type_mst" on "st_tray_type_mst"."c_code" = "st_tray_mst"."c_tray_type_code"
      where "st_tray_type_mst"."n_tray_type" = 1 and "st_tray_mst"."c_code" = @pallet_code;
    select "count"("c_pallet_code") into @cnt_trays_on_pallet from "st_pallet_move_det" where "c_pallet_code" = @pallet_code;
    select top 1
      "ssd"."c_rack_grp_code",
         if "item_receipt_entry"."n_dynamic_flag" =1 then 
            ssm.c_dynamic_floor_code
        else 
          "ssm"."c_floor_code"
        end if,
        "item_receipt_entry"."n_dynamic_flag",
        "item_receipt_entry"."c_br_code",
        "item_receipt_entry"."c_year",
        "item_receipt_entry"."c_prefix",
        "item_receipt_entry"."n_srno"
      into @tmp_location,@destination_floor_code,@n_dynamic_flag,@c_br_code,@c_year,@c_prefix,@n_srno
      from "item_receipt_entry"
        left outer join "item_mst_br_info" on "item_mst_br_info"."c_code" = "item_receipt_entry"."c_item_code"
        and "item_mst_br_info"."c_br_code" = "item_receipt_entry"."c_br_code"
        left outer join "item_mst_br_info_godown" on "item_mst_br_info_godown"."c_code" = "item_receipt_entry"."c_item_code"
        and "item_mst_br_info_godown"."c_br_code" = "item_receipt_entry"."c_br_code" and "item_mst_br_info_godown"."c_godown_code" = "item_mst_br_info"."c_default_godown_code"
        join "pur_det" on "pur_det"."c_br_code" = "item_receipt_entry"."c_pur_br_code"
        and "pur_det"."c_year" = "item_receipt_entry"."c_pur_year"
        and "pur_det"."c_prefix" = "item_receipt_entry"."c_pur_prefix"
        and "pur_det"."n_srno" = "item_receipt_entry"."n_pur_srno"
        and "pur_det"."n_seq" = "item_receipt_entry"."n_pur_seq"
        left outer join "rack_mst" on "rack_mst"."c_code" = if "pur_det"."c_godown_code" = '-' then "item_mst_br_info"."c_rack" else "item_mst_br_info_godown"."c_rack" endif
        and "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
        left outer join "rack_group_mst" on "rack_group_mst"."c_code" = "rack_mst"."c_rack_grp_code" and "rack_group_mst"."c_br_code" = "rack_mst"."c_br_code"
        left outer join st_store_stage_det as "ssd" on "ssd"."c_rack_grp_code" ="rack_group_mst"."c_code" 
            and "ssd"."c_br_code" = "rack_group_mst"."c_br_code"
        left outer join st_store_stage_mst as "ssm" on "ssd"."c_stage_code" = "ssm"."c_code" 
            and "ssm"."c_br_code" = "ssd"."c_br_code"
        left outer join "st_store_floor_mst" on "st_store_floor_mst"."c_br_code" = "ssm"."c_br_code" 
                and "st_store_floor_mst"."c_code" = "c_floor_code"
      where ("item_receipt_entry"."c_tray_code" = @tray_code or "item_receipt_entry"."n_carton_no" = @tray_code)
      and "pur_det"."c_godown_code" = if "pur_det"."c_godown_code" <> '-' then "item_mst_br_info_godown"."c_godown_code" else '-' endif
      order by "item_receipt_entry"."n_srno" desc;
    select "n_capacity_status" into @capacity_flag from "st_pallet_move" where "c_pallet_Code" = @pallet_code;
    if(select "count"() from "st_pallet_move_det" where "c_pallet_code" = @pallet_code) = 0 then
      update "st_pallet_move" set "n_status_flag" = 1 where "c_pallet_code" = @pallet_code
    end if;
    if @capacity_flag <> 2 then
      if(@cnt_trays_on_pallet < @max_pallet_capacity) or(@max_pallet_capacity = 0) then
        if(select "count"("c_pallet_code") from "st_pallet_move" where "c_pallet_code" = @pallet_code and "c_floor_code" = @floor_code) = 1 then
          if(select "count"("c_tray_code") from "st_pallet_move_det" where "c_tray_code" = @tray_code) = 0 then
            select "c_destination_floor_code" into @pallet_dstn_floor_code from "st_pallet_move" where "c_pallet_code" = @pallet_code;
            if(select "count"("c_pallet_code") from "st_pallet_move_det" where "c_pallet_code" = @pallet_code) = 0 then
              update "st_pallet_move" set "c_destination_floor_code" = @destination_floor_code where "c_pallet_code" = @pallet_code
            end if;
            if(@destination_floor_code = @pallet_dstn_floor_code) or((select "count"() from "st_pallet_move_det" where "c_pallet_code" = @pallet_code) = 0) then
              update "st_pallet_move" set "n_tray_count" = "n_tray_count"+1 where "c_pallet_Code" = @pallet_code;
              insert into "st_pallet_move_det"
                ( "c_pallet_code","c_tray_code","c_destination_rack_grp_code","n_inout","n_status","n_tray_flag","d_date","t_time","c_user","n_carton_flag","n_item_count","n_dynamic_tray_flag","c_br_code","c_year","c_prefix","n_srno" ) values
                ( @pallet_code,@tray_code,"isnull"(@tmp_location,'-'),1,0,if(select "count"() from "st_tray_mst" where "n_in_out_flag" = 3 and "c_code" = @tray_code) = 0 then 1 else 0 endif,"today"(),"now"(),@UserId,
                if(select "count"() from "st_tray_mst" where "n_in_out_flag" = 3 and "c_code" = @tray_code) = 1 then 1 else 0 endif,1,@n_dynamic_flag,@c_br_code,@c_year,@c_prefix,@n_srno ) ;
              select 1 as "c_status",
                'Success: Tray Code '+@tray_code+' is assigned to '+@pallet_code+' pallet.' as "c_message" for xml raw,elements
            else
              select 1 as "c_status",
                'Failure: Tray Desination '+@destination_floor_code+' and Pallet Desination '+@pallet_dstn_floor_code+' does not match' as "c_message" for xml raw,elements
            end if
          else select "c_pallet_code" into @tmp_location from "st_pallet_move_det" where "c_tray_code" = @tray_code;
            select 0 as "c_status",
              'Tray '+@tray_code+' is already assigned to "'+@tmp_location+'" Pallet. Please recheck!!' as "c_message" for xml raw,elements
          end if
        else select 0 as "c_status",
            'Failure: Pallet '+@pallet_code+' Not found in current floor code.'+@floor_Code as "c_message" for xml raw,elements
        end if
      else select 0 as "c_status",
          'Failure: Pallet '+@pallet_code+' exceeded its maximum limit. '+"trim"("str"(@max_pallet_capacity))+' Cannot assign '+@tray_code+' Tray Code.' as "c_message" for xml raw,elements
      end if
    else select 0 as "c_status",
        'Failure: Pallet '+@pallet_code+' is marked as Full. Cannot assign '+@tray_code+' Tray Code.' as "c_message" for xml raw,elements
    end if when 'pallet_tray_details' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=pallet_tray_details&gsbr=000&TrayCode=&LocationCode=&PalletCode=PM0002&FloorCode=FM0001&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    select "st_pallet_move_det"."c_tray_code" from "st_pallet_move_det"
        join "st_pallet_move" on "st_pallet_move"."c_pallet_code" = "st_pallet_move_det"."c_pallet_code"
      where "st_pallet_move_det"."c_pallet_code" = @pallet_code for xml raw,elements
  when 'pallet_merge' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=pallet_merge&gsbr=000&trayList=5196^^5142^^&PalletCode=PM0002&newPalletCode=PM0003&FloorCode=FM0001&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    set @TraysList = @trayList;
    select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
    set @ColMaxLen = "Length"(@ColSep);
    if(select "count"("c_pallet_Code") from "st_pallet_move" where "c_pallet_Code" = @new_pallet_code) = 1 then
      if(select "count"("c_pallet_code") from "st_pallet_move" where "c_pallet_code" = @new_pallet_code and "n_capacity_status" <> 2) = 1 then
        select "c_destination_floor_code" into @destination_floor_code from "st_pallet_move" where "c_pallet_Code" = @new_pallet_code;
        select "c_destination_floor_code" into @pallet_dstn_floor_code from "st_pallet_move" where "c_pallet_Code" = @pallet_code;
        if @pallet_dstn_floor_code = @destination_floor_code then
          while @TraysList <> '' loop
            select "Locate"(@TraysList,@ColSep) into @ColPos;
            set @new_tray = "Trim"("Left"(@TraysList,@ColPos-1));
            set @TraysList = "SubString"(@TraysList,@ColPos+@ColMaxLen);
            update "st_pallet_move_det" set "c_pallet_code" = @new_pallet_code where "c_pallet_code" = @pallet_code and "c_tray_code" = @new_tray and "n_status" = 0
          end loop;
          update "st_pallet_move" set "n_merge_pallet_flag" = 1 where "c_pallet_code" = @new_pallet_code;
          if(select "n_active" from "st_track_module_mst" where "c_code" = 'M00094') = 1 then
            if(select "count"("c_pallet_code") from "st_pallet_move_det" where "c_pallet_code" = @pallet_code) = 0 then
              delete from "st_pallet_move" where "c_pallet_code" = @pallet_code
            end if end if;
          insert into "st_tray_merge_list"
            ( "n_inout","c_doc_no","c_base_tray_code","c_tray_list","d_ldate","t_ltime","c_user" ) values
            ( 3,@pallet_code,@new_pallet_code,@trayList,"today"(),"now"(),@UserId ) ;
          if sqlstate = '00000' then
            commit work;
            set @trayList = "replace"(@trayList,'^^',',');
            select 1 as "c_status",
              'Total: '+"trim"("str"("LEN"(@trayList)-"LEN"("REPLACE"(@trayList,',',''))))+' Trays from '+@pallet_code+' pallet merged with '+@new_pallet_code+' pallet.' as "c_message" for xml raw,elements
          else
            rollback work;
            select 0 as "c_status",
              'Failure' as "c_message" for xml raw,elements
          end if
        else select 0 as "c_status",
            'From Pallet destinatnion code '+@pallet_dstn_floor_code+' is not matching with the to Pallet destination code '+@destination_floor_code as "c_message" for xml raw,elements
        end if
      else select 0 as "c_status",
          'Pallet '+@new_pallet_code+' is Marked as Full. Cannot Merge the Pallet' as "c_message" for xml raw,elements
      end if
    else select 0 as "c_status",
        @new_pallet_code+' Not assigned to location.. Please check!!' as "c_message" for xml raw,elements
    end if when 'pallet_location_det' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=pallet_location_det&gsbr=000&PalletCode=PM0002&FloorCode=FM0001&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    select "st_pallet_move"."c_pallet_code",
      "st_store_floor_det"."n_row_no",
      "st_pallet_move"."c_location_code",
      "st_store_floor_det"."n_pos_seq",
      "st_pallet_move"."c_floor_code" as "c_current_floor_code",
      "st_store_floor_mst"."c_name" as "c_current_floor_name",
      "st_pallet_move"."c_user" as "c_assigned_by",
      "st_pallet_move"."t_time" as "t_assigned_time",
      "ST_PALLET_move"."c_destination_floor_code" as "c_destination_floor_code",
      "flr_mst"."c_name" as "c_destination_floor_name"
      from "st_pallet_move"
        left outer join "st_store_floor_det" on "st_store_floor_det"."c_floor_code" = "st_pallet_move"."c_floor_code"
        and "st_store_floor_det"."c_rack_code" = if "st_pallet_move"."c_location_code" = '-' then "st_pallet_move"."c_location_code_bkp" else "st_pallet_move"."c_location_code" endif
        left outer join "st_store_floor_mst" on "st_store_floor_mst"."c_code" = "st_store_floor_det"."c_floor_code" and "st_store_floor_mst"."c_br_code" = "st_store_floor_det"."c_br_code"
        left outer join "st_store_floor_mst" as "flr_mst" on "flr_mst"."c_code" = "st_pallet_move"."c_destination_floor_code"
      where "st_pallet_move"."c_pallet_code" = @pallet_code
      order by "st_pallet_move"."c_pallet_code" asc for xml raw,elements
  when 'search_pallet' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=search_pallet&gsbr=000&PalletCode=PM0002&FloorCode=FM0001&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    select "st_pallet_move_det"."c_pallet_code","st_pallet_move_det"."c_tray_code","st_pallet_move_det"."n_item_count",
      "st_pallet_move_det"."n_carton_flag","st_pallet_move"."c_destination_floor_code" as "c_destination_floor_code","st_store_floor_mst"."c_name" as "c_destination_floor_name"
      from "st_pallet_move_det"
        join "st_pallet_move" on "st_pallet_move"."c_pallet_code" = "st_pallet_move_det"."c_pallet_code"
        join "st_store_floor_mst" on "st_store_floor_mst"."c_code" = "st_pallet_move"."c_floor_code"
        and "st_store_floor_mst"."c_br_code" = "uf_get_br_code"('')
      where "n_tray_release_flag" = 0 and "st_pallet_move_det"."c_pallet_code" = @pallet_code for xml raw,elements
  when 'move_pallet' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=move_pallet&gsbr=000&PalletCode=PM0002&FloorCode=FM0001&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    if(select "count"() from "st_pallet_move" where "st_pallet_move"."c_pallet_code" = @pallet_code and "n_status_flag" >= 2) = 1 then
      select 0 as "c_status",
        'Pallet "'+@pallet_code+'" already Moved.' as "c_message" for xml raw,elements
    else
      if(select "count"() from "st_pallet_move" where "st_pallet_move"."c_pallet_code" = @pallet_code and "n_status_flag" < 1) = 1 then
        select 0 as "c_status",
          'Pallet "'+@pallet_code+'" has no trays.' as "c_message" for xml raw,elements
      else
        update "st_pallet_move" set "n_status_flag" = 2,"c_location_code_bkp" = "c_location_code",
          "c_location_code" = '-',"c_user" = @UserId,
          "d_date" = "today"(),"t_time" = "now"()
          where "st_pallet_move"."c_pallet_code" = @pallet_code and "st_pallet_move"."c_floor_code" = @floor_code;
        if sqlstate = '00000' then
          commit work;
          select 1 as "c_status",
            'Pallet code '+@pallet_code+' has been moved successfully.' as "c_message" for xml raw,elements
        else
          rollback work;
          select 0 as "c_status",
            'Failure' as "c_message" for xml raw,elements
        end if end if end if when 'mark_pallet' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=mark_pallet&gsbr=000&capacityFlag=1&PalletCode=PM0002&FloorCode=FM0001&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ  
    // 0 not marked, 1 partial, 2 full, 3 released
    if @capacity_flag <> 3 then
      if(select "count"() from "st_pallet_move_det" where "c_pallet_code" = @pallet_code) <> 0 then
        update "st_pallet_move" set "n_capacity_status" = @capacity_flag,"c_user" = @UserId,"d_date" = "today"(),"t_time" = "now"() where "c_pallet_code" = @pallet_code and "st_pallet_move"."c_floor_code" = @floor_code;
        if sqlstate = '00000' or sqlstate = '02000' then
          commit work;
          select 1 as "c_status",
            'Pallet code '+@pallet_code+' has been marked as '+if @capacity_flag = 1 then 'Partial' else 'Full' endif as "c_message" for xml raw,elements
        else
          rollback work;
          select 0 as "c_status",
            'Failure, pLease check the pallet and current floor code. Current floor code is  '+@floor_code as "c_message" for xml raw,elements
        end if
      else select 0 as "c_status",
          'No Trays has been assigned for the Pallet: '+@pallet_code as "c_message" for xml raw,elements
      end if
    else if(select "count"("c_pallet_code") from "st_pallet_move" where "n_pallet_assigned_screen_flag" = 2 and "c_pallet_code" = @pallet_code) = 1 then
        delete from "st_pallet_move" where "c_pallet_code" = @pallet_code;
        if sqlstate = '00000' or sqlstate = '02000' then
          commit work;
          select 1 as "c_status",
            'Pallet code '+@pallet_code+' has been released Successfully.' as "c_message" for xml raw,elements
        else
          rollback work;
          select 0 as "c_status",
            'Failure' as "c_message" for xml raw,elements
        end if
      else if(select "count"() from "st_pallet_move_det" where "c_pallet_code" = @pallet_code and "n_tray_release_flag" = 0) = 0 then
          delete from "st_pallet_move" where "c_pallet_code" = @pallet_code;
          delete from "st_pallet_move_det" where "c_pallet_code" = @pallet_code;
          if sqlstate = '00000' or sqlstate = '02000' then
            commit work;
            select 1 as "c_status",
              'Pallet code '+@pallet_code+' has been released Successfully.' as "c_message" for xml raw,elements
          else
            rollback work;
            select 0 as "c_status",
              'Failure' as "c_message" for xml raw,elements
          end if
        else select 1 as "c_status",
            'Few Trays are pending on the Pallet. Please recheck!!' as "c_message" for xml raw,elements
        end if end if end if when 'receive_pallet' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=receive_pallet&gsbr=000&PalletCode=PM0002&FloorCode=FM0001&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    ------------------------
    if(select "count"() from "st_pallet_move" where "st_pallet_move"."c_pallet_code" = @pallet_code and "n_status_flag" >= 3) = 1 then
      select 0 as "c_status",
        'Pallet "'+@pallet_code+'" already Received.' as "c_message" for xml raw,elements
    else
      if(select "count"() from "st_pallet_move" where "st_pallet_move"."c_pallet_code" = @pallet_code and "n_status_flag" < 2) = 1 then
        select 0 as "c_status",
          'Pallet "'+@pallet_code+'" has not moved.' as "c_message" for xml raw,elements
      else
        update "st_pallet_move" set "n_status_flag" = 3,"c_user" = @UserId,"d_date" = "today"(),"t_time" = "now"() where "st_pallet_move"."c_pallet_code" = @pallet_code and "st_pallet_move"."c_destination_floor_code" = @floor_code;
        if sqlstate = '00000' or sqlstate = '02000' then
          commit work;
          select 1 as "c_status",
            'Pallet code '+@pallet_code+' has been received successfully.' as "c_message" for xml raw,elements
        else
          rollback work;
          select "st_pallet_move"."c_destination_floor_code" into @destination_floor_code from "st_pallet_move"
            where "st_pallet_move"."c_pallet_code" = @pallet_code;
          select "c_name" into @destination_floor_code from "st_store_floor_mst" where "c_code" = @destination_floor_code;
          select 0 as "c_status",
            'Failure: Please Login to the respective floor i.e '+@destination_floor_code+' to perform this activity.' as "c_message" for xml raw,elements
        /* if(select "count"() from "st_pallet_move" where "st_pallet_move"."c_pallet_code" = @pallet_code and "n_status_flag" >= 3) = 1 then
select 0 as "c_status",
'Pallet "'+@pallet_code+'" already Received.' as "c_message" for xml raw,elements
else
if(select "count"() from "st_pallet_move" where "st_pallet_move"."c_pallet_code" = @pallet_code and "n_status_flag" < 2) = 1 then
select 0 as "c_status",
'Pallet "'+@pallet_code+'" has not moved.' as "c_message" for xml raw,elements
else
update "st_pallet_move" set "n_status_flag" = 3,"c_user" = @UserId,"d_date" = "today"(),"t_time" = "now"() where "st_pallet_move"."c_pallet_code" = @pallet_code and "st_pallet_move"."c_destination_floor_code" = @floor_code;
if sqlstate = '00000' then
commit work;
select 1 as "c_status",
'Pallet code '+@pallet_code+' has been received successfully.' as "c_message" for xml raw,elements
else
rollback work;
select 0 as "c_status",
'Failure: Please Login to the respective floor to perform this activity.' as "c_message" for xml raw,elements
end if end if end if */
        end if end if end if when 'available_location' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=available_location&gsbr=000&PalletCode=&FloorCode=FM0001&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    select "st_store_floor_det"."c_rack_code" as "c_location_code","sfd"."n_row_no","sfd"."n_pos_seq","sfd"."c_floor_code"
      from "st_store_floor_det"
        left outer join "st_pallet_move" on "st_pallet_move"."c_location_code" = "st_store_floor_det"."c_rack_code" and "st_pallet_move"."c_floor_code" = "st_store_floor_det"."c_floor_code"
        left outer join "st_store_floor_det" as "sfd" on "sfd"."c_rack_code" = "st_store_floor_det"."c_rack_code"
      where "st_pallet_move"."c_location_code" is null and "sfd"."c_floor_code" = @floor_code for xml raw,elements
  when 'receive_tray' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=receive_tray&gsbr=000&TrayCode=10040&LocationCode=9991&dynamicFlag=1&FloorCode=FM0001&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    if(select "n_Active" from "st_track_module_mst" where "c_code" = 'M00070') = 0 then
      select 0 as "c_status",
        'RECEIVE TRAY Module "M00070" Not enabled. Please contact Admin.' as "c_message" for xml raw,elements
    else
      if(select "count"() from "st_pallet_move_det" where "c_tray_code" = @tray_code) = 1 then
        if(select "count"() from "st_pallet_move_det" where "n_tray_release_flag" = 0 and "c_tray_code" = @tray_code) = 1 then
          if(select "n_active" from "st_track_module_mst" where "c_code" = 'M00094' and "c_menu_id" = '1') = 1 then
            select "c_pallet_code" into @tmp_location from "st_pallet_move_det" where "c_tray_code" = @tray_code;
            delete from "st_pallet_move_det" where "c_tray_code" = @tray_code;
            if(select "count"("c_pallet_code") from "st_pallet_move_det" where "c_pallet_code" = @tmp_location) = 0 then
              delete from "st_pallet_move" where "c_pallet_code" = @tmp_location
            end if
          else update "st_pallet_move_det" set "n_tray_release_flag" = 1,"d_date" = "today"(),"t_time" = "now"(),"c_user" = @UserId where "c_tray_code" = @tray_code;
            select "c_pallet_code" into @tmp_location from "st_pallet_move_det" where "c_tray_code" = @tray_code;
            if(select "count"() from "st_pallet_move_det" where "c_pallet_code" = @tmp_location and "n_tray_release_flag" = 0) = 0 then
              update "st_pallet_move" set "n_status_flag" = 5,"c_floor_code" = @floor_code,"d_date" = "today"(),"t_time" = "now"(),"c_user" = @UserId where "c_pallet_COde" = @tmp_location
            end if end if;
          if @dynamic_flag = 1 then
            select "rack_mst"."c_code","rack_group_mst"."c_Code","st_store_stage_mst"."c_code" into @rack_code,@rack_grp_code,@stage_code from "rack_mst"
                join "rack_group_mst" on "rack_GROup_mst"."c_code" = "rack_mst"."c_rack_grp_code" and "rack_mst"."c_br_code" = "rack_GROup_mst"."c_Br_code"
                join "ST_STORE_STAGE_DET" on "ST_STORE_STAGE_DET"."c_br_code" = "rack_GROup_mst"."c_Br_code" and "ST_STORE_STAGE_DET"."c_rack_grp_code" = "rack_group_mst"."c_code"
                join "ST_STORE_STAGE_MST" on "ST_STORE_STAGE_DET"."c_br_code" = "ST_STORE_STAGE_MST"."c_Br_code" and "ST_STORE_STAGE_MST"."c_code" = "ST_STORE_STAGE_det"."c_stage_code" and "st_store_stage_mst"."n_dynamic_flag" = 1
              where "rack_mst"."c_code" = @location_Code;
            insert into "st_dynamic_item_det"
              select top 1
                "item_receipt_entry"."c_pur_br_code"+'/'+"item_receipt_entry"."c_pur_year"+'/'+"item_receipt_entry"."c_pur_prefix"+'/'+"trim"("str"("item_receipt_entry"."n_pur_srno")) as "c_doc_no",
                1 as "n_inout",
                "item_receipt_entry"."n_pur_seq",
                "item_receipt_entry"."c_item_code",
                "item_receipt_entry"."c_batch_No",
                "item_receipt_entry"."n_qty",
                "pur_det"."n_qty_per_box",
                @rack_code as "rack_code",
                @rack_grp_code as "rack_grp_code",
                @stage_code as "stage_code",
                0 as "n_complete",
                "item_receipt_entry"."c_tray_code" as "c_tray_code",
                "item_receipt_entry"."n_carton_no" as "n_carton_no",
                (select "C_MENU_ID" from "st_track_module_mst" where "c_code" = 'M00071') as "godown_code",
                @UserId as "c_user",
                "today"() as "d_date",
                "now"() as "t_time"
                from "item_receipt_entry"
                  left outer join "item_mst_br_info" on "item_mst_br_info"."c_code" = "item_receipt_entry"."c_item_code"
                  and "item_mst_br_info"."c_br_code" = "item_receipt_entry"."c_br_code"
                  left outer join "item_mst_br_info_godown" on "item_mst_br_info_godown"."c_code" = "item_receipt_entry"."c_item_code"
                  and "item_mst_br_info_godown"."c_br_code" = "item_receipt_entry"."c_br_code" and "item_mst_br_info_godown"."c_godown_code" = "item_mst_br_info"."c_default_godown_code"
                  join "pur_det" on "pur_det"."c_br_code" = "item_receipt_entry"."c_pur_br_code"
                  and "pur_det"."c_year" = "item_receipt_entry"."c_pur_year"
                  and "pur_det"."c_prefix" = "item_receipt_entry"."c_pur_prefix"
                  and "pur_det"."n_srno" = "item_receipt_entry"."n_pur_srno"
                  and "pur_det"."n_seq" = "item_receipt_entry"."n_pur_seq"
                where("item_receipt_entry"."c_tray_code" = @tray_code or "item_receipt_entry"."n_carton_no" = @tray_code)
                and "pur_det"."c_godown_code" = if "pur_det"."c_godown_code" <> '-' then "item_mst_br_info_godown"."c_godown_code" else '-' endif
                order by "item_receipt_entry"."n_srno" desc
          end if;
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
            'Failure: Tray code '+@tray_code+' already received.' as "c_message" for xml raw,elements
        end if
      else select 0 as "c_status",
          'Failure: Tray code '+@tray_code+' not assigned to any pallet.' as "c_message" for xml raw,elements
      end if end if when 'dock_pallet_check' then
    //http://172.16.18.19:19503/ws_st_pallet_tray_movement?&cIndex=dock_pallet_check&gsbr=503&FloorCode=DYFC01&devID=bc4009171fdf58c115112018104912239&UserId=CSQ
    if @floor_code = any(select "c_code" from "st_store_floor_mst" where "n_dynamic_flag" = 1 and "c_br_code" = @gsbr) then
      select 1 as "c_status",
        'Success' as "c_message" for xml raw,elements
    else select 0 as "c_status",
        'Failure: Docking cannot be performed in this floor. Please Login to Dynamic Floor' as "c_message" for xml raw,elements
    end if when 'dock_pallet' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=dock_pallet&gsbr=000&PalletCode=PM0002&LocationCode=L5&FloorCode=FM0002&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    if(select "count"() from "st_pallet_move" where "st_pallet_move"."c_pallet_code" = @pallet_code and "n_status_flag" = 6) = 1 then
      select 0 as "c_status",
        'Pallet "'+@pallet_code+'" already docked.' as "c_message" for xml raw,elements
    else
      if(select "count"() from "st_pallet_move" where "st_pallet_move"."c_pallet_code" = @pallet_code and "n_status_flag" < 3) = 1 then
        select 0 as "c_status",
          'Pallet "'+@pallet_code+'" has not received yet.' as "c_message" for xml raw,elements
      else
        insert into "DBA"."st_dynamic_item_det"( "c_doc_no","n_inout",
          "n_pur_seq","c_item_code","c_batch_no","n_qty","n_qty_per_box",
          "c_rack","c_rack_grp_code","c_stage_code","n_complete","c_tray_code","n_carton_no","c_godown_code","c_user","d_date","t_time" ) with
          "cte" as(select *,"ROW_NUMBER"() over(partition by "c_tray_code","n_carton_no" order by "n_srno" desc) as "rn"
            from "item_receipt_entry")
          select "c"."c_pur_br_code"+'/'+"c"."c_pur_year"+'/'+"c"."c_pur_prefix"+'/'+"trim"("str"("c"."n_pur_srno")) as "c_doc_no",1 as "n_inout",
            "c"."n_pur_seq","c"."c_item_code","c"."c_batch_no","c"."n_qty","item_mst"."n_qty_per_box",
            @location_code,@location_code,@location_code,0 as "n_complete","c"."c_tray_code","c"."n_carton_no",
            (select "c_menu_id" from "st_track_module_mst" where "c_code" = 'M00071' and "n_active" = 1) as "c_godown_code",@UserId,"today"(),"now"()
            from "cte" as "c"
              join "st_pallet_Move_det" as "pmd" on("pmd"."c_tray_code" = "c"."c_tray_code" or "pmd"."c_tray_code" = "c"."n_carton_no")
              join "st_pallet_move" on "st_pallet_move"."c_pallet_code" = "pmd"."c_pallet_code"
              join "item_mst" on "item_mst"."c_code" = "c"."c_item_code"
            where "rn" = 1 and "pmd"."c_pallet_code" = @pallet_code and "st_pallet_move"."c_destination_floor_code" = @floor_code;
        update "st_pallet_move" set "st_pallet_move"."n_status_flag" = 6,"st_pallet_move"."c_location_code" = @location_code,"st_pallet_move"."c_floor_code" = @floor_code,"st_pallet_move"."c_user" = @UserId,
          "st_pallet_move"."d_date" = "today"(),"st_pallet_move"."t_time" = "now"()
          where "st_pallet_move"."c_pallet_code" = @pallet_code and "st_pallet_move"."c_destination_floor_code" = @floor_code;
        delete from "st_pallet_move_det" where "st_pallet_move_det"."c_pallet_code" = @pallet_code;
        if sqlstate = '00000' then
          commit work;
          select 1 as "c_status",
            'Pallet code '+@pallet_code+' has been docked successfully.' as "c_message" for xml raw,elements
        else
          rollback work;
          select 0 as "c_status",
            'Failure' as "c_message" for xml raw,elements
        end if end if end if when 'floor_det_pallet' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=floor_det_pallet&gsbr=000&Palletflag=1&FloorCode=FM0001&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    if @pallet_flag in( 1,2 ) then
      select "st_store_floor_det"."c_floor_code" as "c_floor_code",
        "st_store_floor_mst"."c_name" as "c_floor_name",
        "st_pallet_move"."c_pallet_code" as "c_pallet_code",
        "st_store_floor_det"."n_pos_seq",
        "n_row_no",
        "c_rack_code" as "c_location_code",
        "st_pallet_move"."n_capacity_status" as "capacity_status",
        "st_pallet_move"."c_destination_floor_code",
        '' as "c_destination_floor_name"
        from "st_store_floor_det"
          join "st_store_floor_mst" on "st_store_floor_mst"."c_br_code" = "st_store_floor_det"."c_br_code"
          and "st_store_floor_det"."c_floor_code" = "st_store_floor_mst"."c_code"
          left outer join "rack_mst" on "rack_mst"."c_code" = "st_store_floor_det"."c_rack_code" and "rack_mst"."c_br_code" = "st_store_floor_det"."c_br_code"
          left outer join "st_pallet_move" on "st_pallet_move"."c_floor_code" = "st_store_floor_det"."c_floor_code" and "st_store_floor_det"."c_rack_code" = "st_pallet_move"."c_location_code"
        where "rack_mst"."n_type" = @pallet_flag and "st_store_floor_mst"."c_code" = @floor_code for xml raw,elements
    else
      select 0 as "c_status",
        'Failure: Check the pallet flag' as "c_message" for xml raw,elements
    end if when 'floor_dashboard' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=floor_dashboard&gsbr=000&Palletflag=1&FloorCode=FM0001&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    select "st_pallet_move"."c_pallet_code" as "c_pallet_code",
      "st_pallet_move"."n_capacity_status" as "c_pallet_capacity_status",
      "isnull"(if "n_tray_release_flag" = 0 then "sum"("isnull"("n_tray_flag",0)) endif,0) as "n_tray_count",
      "isnull"(if "n_tray_release_flag" = 0 then "sum"("isnull"("n_carton_flag",0)) endif,0) as "n_carton_count",
      "st_pallet_move"."c_floor_code" as "c_floor_code",
      if "st_pallet_move"."n_status_flag" < 2 then 'GRE IN PROGRESS'
      else if "st_pallet_move"."n_status_flag" = 2 then 'PALLET MOVED'
        else if "st_pallet_move"."n_status_flag" = 3 then 'PALLET RECEIVED'
          else if "st_pallet_move"."n_status_flag" = 5 then 'TRAYS RECEIVED'
            else if "st_pallet_move"."n_status_flag" = 6 then 'PALLET DOCKED' endif
            endif
          endif
        endif
      endif as "c_pallet_status",
      "st_pallet_move"."c_destination_floor_code" as "c_destin_floor_code",
      "st_store_floor_mst"."c_name" as "c_destin_floor_name"
      from "st_pallet_move"
        left outer join "st_pallet_move_det" on "st_pallet_move"."c_pallet_code" = "st_pallet_move_det"."c_pallet_code"
        left outer join "st_store_floor_mst" on "st_store_floor_mst"."c_code" = "st_pallet_move"."c_destination_floor_code" and "st_store_floor_mst"."c_br_code" = "uf_get_br_code"(@gsBr)
      where 1 = 1 and((@pallet_flag = 0 or @pallet_flag is null) or(if "st_pallet_move"."n_status_flag" <= 2 then "st_pallet_move"."c_floor_code"
      else "st_pallet_move"."c_destination_floor_code" //@pallet_flag = 0 for pallet_details ,@pallet_flag = 1 for floor_dashboard
      endif) = @floor_code)
      group by "c_pallet_code","c_pallet_status","c_floor_code","c_pallet_capacity_status","n_tray_release_flag","c_destin_floor_code","c_destin_floor_name" for xml raw,elements
  when 'pallet_tray_carton_cnt' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=pallet_tray_carton_cnt&gsbr=000&PalletCode=PM0002&FloorCode=FM0001&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    select "st_pallet_move"."c_pallet_code" as "c_pallet_code",
      "st_pallet_move"."n_capacity_status" as "c_pallet_capacity_status",
      "isnull"("sum"("n_tray_flag"),0) as "n_tray_count",
      "trim"("str"("isnull"("sum"("n_carton_flag"),0)))+'/'+"trim"("str"("isnull"("sum"("item_receipt_entry"."n_carton_print"),0))) as "n_carton_count",
      "st_pallet_move"."c_floor_code" as "c_floor_code"
      from "st_pallet_move"
        left outer join "st_pallet_move_det" on "st_pallet_move"."c_pallet_code" = "st_pallet_move_det"."c_pallet_code"
        left outer join "item_receipt_entry" on "item_receipt_entry"."c_br_code" = "st_pallet_move_det"."c_br_code"
        and "item_receipt_entry"."c_year" = "st_pallet_move_det"."c_year"
        and "item_receipt_entry"."c_prefix" = "st_pallet_move_det"."c_prefix"
        and "item_receipt_entry"."n_srno" = "st_pallet_move_det"."n_srno"
        and "isnull"("item_receipt_entry"."c_tray_code",cast("item_receipt_entry"."n_carton_no" as char(15))) = "st_pallet_move_det"."c_tray_code"
      where "st_pallet_move_det"."c_pallet_code" = @pallet_code
      group by "c_pallet_code","c_floor_code","c_pallet_capacity_status" for xml raw,elements
  when 'validate_pallete' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=validate_pallete&gsbr=000&PalletCode=PM0003&screenFlag=0&FloorCode=FM0001&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ17
    select "st_tray_mst"."n_max_capacity"
      into @max_pallet_capacity
      from "st_tray_mst" join "st_Tray_type_mst" on "st_tray_type_mst"."c_code" = "st_tray_mst"."c_tray_type_code"
      where "st_tray_type_mst"."n_tray_type" = 1 and "st_tray_mst"."c_code" = @pallet_code;
    select "count"("c_pallet_code") into @cnt_trays_on_pallet from "st_pallet_move_det" where "c_pallet_code" = @pallet_code;
    if(select "count"() from "st_tray_mst" join "st_tray_type_mst" on "st_tray_mst"."c_tray_type_code" = "st_tray_type_mst"."c_code" where "n_tray_type" = 1 and "st_tray_mst"."n_cancel_flag" = 0 and "st_tray_mst"."c_code" = @pallet_code) = 0 then
      select 0 as "c_status",
        'Pallet Not Found in the Masters!' as "c_message" for xml raw,elements
    else
      if(select "count"() from "st_pallet_move" where "c_pallet_code" = @pallet_code) = 1 then
        //print 'v1';
        if "isnull"(@screen_flag,0) = 0 then
          //print 'v2';
          select 1 as "c_status",
            'Success' as "c_message",
            @max_pallet_capacity as "n_pallet_max_capacity",
            "abs"(@max_pallet_capacity-@cnt_trays_on_pallet) as "n_trays_can_scan" for xml raw,elements
        else
          //print 'v3';
          if(select "count"("c_pallet_code") from "st_pallet_move" where "c_pallet_code" = @pallet_code and "n_pallet_assigned_screen_flag" = 1) = 0 then
            //print 'v4';
            select 1 as "c_status",
              'Success' as "c_message",
              @max_pallet_capacity as "n_pallet_max_capacity",
              "abs"(@max_pallet_capacity-@cnt_trays_on_pallet) as "n_trays_can_scan" for xml raw,elements
          else
            //print 'v5';
            select if "c_location_code" = '-' then "c_location_code_bkp" else "c_location_code" endif into @tmp_location from "st_pallet_move" where "c_pallet_code" = @pallet_code;
            select 0 as "c_status",
              'Pallet '+@pallet_code+' is already assigned to "'+@tmp_location+'" location. Please recheck!!' as "c_message" for xml raw,elements
          //print 'v6';
          end if
        end if
      else if "isnull"(@screen_flag,0) = 1 then
          //print 'v7';
          select 1 as "c_status",
            'Success' as "c_message",
            @max_pallet_capacity as "n_pallet_max_capacity",
            @max_pallet_capacity-@cnt_trays_on_pallet as "n_trays_can_scan" for xml raw,elements
        else
          //print 'v8';
          select 0 as "c_status",
            @pallet_code+' not assigned to location.. Please check!!' as "c_message" for xml raw,elements
        end if end if end if when 'validate_location' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=validate_location&gsbr=000&LocationCode=L1&FloorCode=FM0001&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    if(select "count"() from "rack_mst" where "n_type" = 1 and "c_code" = @location_code) = 0 then
      select 0 as "c_status",
        'Location number Not Found!.' as "c_message" for xml raw,elements
    else
      select "c_Pallet_code" into @tmp_location from "st_pallet_move" where "c_location_code" = @location_code;
      if(select "count"("c_location_code") from "st_pallet_move" where "c_location_code" = @location_code) = 0 then
        if(select "count"() from "st_store_floor_det" where "c_rack_code" = @location_code and "c_floor_code" = @floor_code) = 1 then
          select 1 as "c_status",
            'Success' as "c_message" for xml raw,elements
        else
          select 0 as "c_status",
            'Location Code '+@location_code+' does not exist in the current floor '+@floor_code as "c_message" for xml raw,elements
        end if
      else select 0 as "c_status",
          'Location Code '+@location_code+' already assigned to pallet: '+@tmp_location as "c_message" for xml raw,elements
      end if end if when 'validate_pigeon_location' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=validate_pigeon_location&gsbr=000&LocationCode=PB1&FloorCode=FM0001&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    if(select "count"("c_code") from "rack_mst" where "n_type" = 2 and "c_code" = @location_code) = 0 then
      select 0 as "c_status",
        'Rack location code Not Found!.' as "c_message" for xml raw,elements
    else
      if(select "count"("c_rack_code") from "st_store_floor_det" where "c_rack_code" = @location_code and "c_floor_code" = @floor_code) = 1 then
        select 1 as "c_status",
          'Success' as "c_message" for xml raw,elements
      else
        select 0 as "c_status",
          'Rack location Code '+@location_code+' does not exist in the current floor '+@floor_code as "c_message" for xml raw,elements
      end if end if when 'validate_tray' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=validate_tray&pigeon_flag=1&gsbr=000&TrayCode=10040&FloorCode=FM0001&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    if(select "count"("c_pallet_code") from "st_pallet_move" where "c_pallet_code" = @tray_code) = 1 then
      set @pigeon_flag = 1
    end if;
    if @pigeon_flag is null or @pigeon_flag = '' then
      set @pigeon_flag = 0
    end if;
    if(select "count"() from "st_tray_mst" where "c_code" = @tray_code) = 1 then
      if @pigeon_flag = 0 then
        if(select "count"() from "st_pallet_move_det" where "c_tray_code" = @tray_code) = 1 then
          select 1 as "c_status",
            'Success' as "c_message" for xml raw,elements
        else
          select 0 as "c_status",
            @tray_code+' not assigned any pallet. Please recheck!!' as "c_message" for xml raw,elements
        end if
      else select 1 as "c_status",
          'Success' as "c_message" for xml raw,elements
      end if
    else select 0 as "c_status",
        @tray_code+' not found in masters. Please recheck!!' as "c_message" for xml raw,elements
    end if when 'validate_rack' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=validate_rack&gsbr=000&TrayCode=&LocationCode=9991&FloorCode=FM0001&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    if(select "count"() from "rack_mst"
          join "rack_group_mst" on "rack_GROup_mst"."c_code" = "rack_mst"."c_rack_grp_code" and "rack_mst"."c_br_code" = "rack_GROup_mst"."c_Br_code"
          join "ST_STORE_STAGE_DET" on "ST_STORE_STAGE_DET"."c_br_code" = "rack_GROup_mst"."c_Br_code" and "ST_STORE_STAGE_DET"."c_rack_grp_code" = "rack_group_mst"."c_code"
          join "ST_STORE_STAGE_MST" on "ST_STORE_STAGE_DET"."c_br_code" = "ST_STORE_STAGE_MST"."c_Br_code" and "ST_STORE_STAGE_MST"."c_code" = "ST_STORE_STAGE_det"."c_stage_code" and "st_store_stage_mst"."n_dynamic_flag" = 1
        where "rack_mst"."c_code" = @location_code) = 0 then
      select 0 as "c_status",
        'Rack Code: '+@location_code+' does not found in dynamic location.' as "c_message" for xml raw,elements
    else
      select 1 as "c_status",
        'Success' as "c_message" for xml raw,elements
    end if when 'send_tray_floor_validation' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=send_tray_floor_validation&gsbr=000&TrayCode=5143&FloorCode=FM0001&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    select "c_pallet_code" into @tmp_location from "st_pallet_move_det" where "c_tray_code" = @tray_code;
    if @tmp_location is null or @tmp_location = '' then
      select "c_location_code" into @tmp_location from "st_pallet_move" where "c_pallet_code" = @tray_code
    end if;
    if(select "count"() from "st_pallet_move_det" where "c_tray_code" = @tray_code) = 1 then
      select "c_destination_floor_code" into @destination_floor_code from "st_pallet_move" where "c_pallet_code" = @tmp_location;
      if @destination_floor_code <> @floor_code then
        select 0 as "c_status",
          'Cannot send/receive tray: '+@tray_code+', destination floor code '+@destination_floor_code+' is not matching with current floor '+@floor_code as "c_message" for xml raw,elements
      else
        select 1 as "c_status",
          'Success' as "c_message" for xml raw,elements
      end if
    else if(select "count"("c_pallet_code") from "st_pallet_move" where "c_pallet_code" = @tray_code) = 1 then
        select 1 as "c_status",
          'Success' as "c_message" for xml raw,elements
      else
        select 0 as "c_status",
          'Tray Code: '+@tray_code+', not assigned to pallet/pigeon rack location '+@tmp_location+'.' as "c_message" for xml raw,elements
      end if end if when 'floor_selection' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=floor_selection&gsbr=000&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    select "c_code","c_name" from "st_store_floor_mst" for xml raw,elements
  when 'available_pallets' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=available_pallets&gsbr=000&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    select "a"."c_code" as "c_pallet_code",
      "a"."c_name" as "c_pallet_name" from "st_tray_mst" as "a"
        join "st_tray_type_mst" as "b" on "a"."c_tray_type_code" = "b"."c_code"
        left outer join "st_pallet_move" as "c" on "c"."c_pallet_code" = "a"."c_code"
      where "b"."n_tray_type" = 1 and "c"."c_pallet_code" is null order by "a"."c_code" asc for xml raw,elements
  when 'tray_converyer_detail' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=tray_converyer_detail&gsbr=000&TrayCode=25319&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    --select * from st_track_partial_barcode_tray
    select "st_track_mst"."c_br_code" as "br_code",
      "st_track_mst"."c_doc_no" as "doc_no",
      "st_track_tray_move"."c_tray_code" as "tray_code",
      "st_track_mst"."c_cust_code" as "cust_code",
      "act_mst"."c_name" as "cust_name",
      "act_route"."c_route_code" as "route_code",
      "route_mst"."c_name" as "route_name",
      "route_mst"."n_route_no" as "route_no",
      "st_conveyer_mst"."c_code" as "conveyer_code",
      "st_conveyer_mst"."c_name" as "conveyer_name",
      "isnull"("st_conveyer_mst"."c_colour_code","st_conveyer_mst"."c_note") as "converyer_RGB_colour_code",
      "st_conveyer_mst"."c_note" as "c_note",
      "st_conveyer_det"."n_exit_seq" as "conveyer_exit_seq",
      (select "count"(distinct "n_barcode_print") from "st_track_pick"
        where "st_track_tray_move"."c_doc_no" = "st_track_pick"."c_doc_no"
        and "st_track_tray_move"."c_tray_code" = "st_track_pick"."c_tray_code"
        and "st_track_tray_move"."c_stage_code" = "st_track_pick"."c_stage_code"
        and "st_track_pick"."n_qty"-("st_track_pick"."n_confirm_qty"+"st_track_pick"."n_reject_qty") > 0) as "n_distinct_barcode_cnt",
      if "n_distinct_barcode_cnt" > 1 then 0 else if("n_distinct_barcode_cnt" = 1 and(select distinct "n_barcode_print" from "st_track_pick"
          where "st_track_tray_move"."c_doc_no" = "st_track_pick"."c_doc_no"
          and "st_track_tray_move"."c_tray_code" = "st_track_pick"."c_tray_code"
          and "st_track_tray_move"."c_stage_code" = "st_track_pick"."c_stage_code"
          and "st_track_pick"."n_qty"-("st_track_pick"."n_confirm_qty"+"st_track_pick"."n_reject_qty") > 0) = 1) then 1 else 0 endif endif as "partial_barcode_tray_flag"
      from "st_track_mst"
        join "st_track_tray_move" on "st_track_tray_move"."c_doc_no" = "st_track_mst"."c_doc_no"
        //        left outer join "st_track_partial_barcode_tray" on "st_track_tray_move"."c_doc_no" = "st_track_partial_barcode_tray"."c_doc_no"
        //        and "st_track_tray_move"."c_tray_code" = "st_track_partial_barcode_tray"."c_tray_code"
        //        and "st_track_tray_move"."c_stage_code" = "st_track_partial_barcode_tray"."c_stage_code"
        join "act_mst" on "act_mst"."c_code" = "st_track_mst"."c_cust_code"
        left outer join "act_route" on "act_route"."c_code" = "st_track_mst"."c_br_code" and "act_route"."c_br_code" = "st_track_mst"."c_cust_code"
        left outer join "route_mst" on "route_mst"."c_code" = "act_route"."c_route_code"
        left outer join "st_conveyer_det" on "st_conveyer_det"."c_route_code" = "act_route"."c_route_code" and "st_conveyer_det"."c_br_code" = "act_route"."c_code"
        left outer join "st_conveyer_mst" on "st_conveyer_mst"."c_code" = "st_conveyer_det"."c_code"
        and "st_conveyer_mst"."c_br_code" = "st_conveyer_det"."c_br_code"
      where "st_track_tray_move"."c_tray_code" = @tray_code and "st_track_tray_move"."n_inout" = 9
      and "st_track_tray_move"."c_rack_grp_code" = '-' for xml raw,elements
  when 'tray_item_detail' then
    //http://10.89.209.19:49503/ws_st_pallet_tray_movement?&cIndex=tray_item_detail&gsbr=000&TrayCode=25319&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    select "st_track_tray_move"."c_doc_no" into @search_doc from "st_track_tray_move"
      where "st_track_tray_move"."n_inout" = 9 and "st_track_tray_move"."c_rack_grp_code" = '-' and "st_track_tray_move"."c_tray_code" = @tray_code;
    select "st_track_pick"."c_doc_no" as "doc_no",
      "st_track_pick"."n_inout",
      "st_track_pick"."c_item_code" as "item_code",
      "item_mst"."c_name" as "item_name",
      "st_track_pick"."c_batch_no",
      "st_track_pick"."n_qty",
      "st_track_pick"."c_tray_code",
      "st_track_pick"."c_rack_grp_code",
      "st_track_pick"."c_stage_code",
      "st_track_pick"."c_godown_code",
      "st_track_barcode_verification"."n_barcode_print_flag" as "partial_barcode_tray_flag"
      from "st_track_pick"
        join "st_track_barcode_verification" on "st_track_pick"."c_doc_no" = "st_track_barcode_verification"."c_doc_no"
        and "st_track_barcode_verification"."n_inout" = "st_track_pick"."n_inout"
        and "st_track_barcode_verification"."n_seq" = "st_track_pick"."n_seq"
        and "st_track_barcode_verification"."n_org_seq" = "st_track_pick"."n_org_seq"
        and "st_track_barcode_verification"."c_item_code" = "st_track_pick"."c_item_code"
        join "item_mst" on "item_mst"."c_code" = "st_track_pick"."c_item_code"
      where "st_track_pick"."c_doc_no" = @search_doc and "st_track_pick"."c_tray_code" = @tray_code
      order by "st_track_barcode_verification"."n_barcode_print_flag" asc,"item_name" asc for xml raw,elements
  when 'assign_tray_pigeon_location' then
    if(select "count"("st_tray_mst"."c_code") from "st_tray_mst"
          join "st_tray_type_mst" on "st_tray_mst"."c_tray_type_code" = "st_tray_type_mst"."c_code"
          left outer join "st_pallet_move" on "st_tray_mst"."c_code" = "st_pallet_move"."c_pallet_code"
        where "n_tray_type" = 0 and "st_tray_mst"."n_cancel_flag" = 0 and "st_tray_mst"."c_code" = @tray_code) = 0 then
      select 0 as "c_status",
        'Tray Not Found in the Masters!' as "c_message" for xml raw,elements
    else
      if(select "count"("c_pallet_code") from "st_pallet_move" where "c_pallet_code" = @tray_code) = 0 then
        if(select "count"("c_code") from "rack_mst" where "n_type" = 2 and "c_code" = @location_code) = 0 then
          select 0 as "c_status",
            'Pigeon Location number Not Found!.' as "c_message" for xml raw,elements
        else
          if(select "count"("c_location_code") from "st_pallet_move" where "c_location_code" = @location_code) = 0 then
            insert into "DBA"."st_pallet_move"
              ( "c_pallet_code","c_location_code","c_rack_grp_code","c_floor_code","n_inout","n_status_flag","n_tray_count","n_merge_pallet_flag",
              "n_capacity_status","d_date","t_time","c_user","c_destination_floor_code","n_pallet_assigned_screen_flag" ) values
              ( @tray_code,@location_code,'-',@floor_code,0,1,1,0,1,"today"(),"now"(),@UserId,null,2 ) ;
            select 1 as "c_status",
              'Success' as "c_message" for xml raw,elements
          else
            select "c_Pallet_code" into @tmp_location from "st_pallet_move" where "c_location_code" = @location_code;
            select 0 as "c_status",
              ' Pigeon location '+@location_code+' is already assigned to "'+@tmp_location+'" Tray. Please recheck!!' as "c_message" for xml raw,elements
          end if
        end if
      else select "c_location_code" into @tmp_location from "st_pallet_move" where "c_pallet_code" = @tray_code;
        select 0 as "c_status",
          'Tray code '+@pallet_code+' is already assigned to "'+@tmp_location+'" pigeon location. Please recheck!!' as "c_message" for xml raw,elements
      end if end if when 'tray_validate_in_gre' then
    //http://172.16.17.208:21503/ws_st_pallet_tray_movement?&cIndex=tray_validate_in_gre&gsbr=000&TrayCode=1005&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    if(select "count"("c_tray_code") from "st_pallet_move_det" where "c_tray_code" = @tray_code) = 0 then
      select 1 as "c_status",
        'Success' as "c_message" for xml raw,elements
    else
      select "c_pallet_code" into @tmp_location from "st_pallet_move_det" where "c_tray_code" = @tray_code;
      select 0 as "c_status",
        'Tray '+@tray_code+' is already assigned to "'+@tmp_location+'" Pallet. Please recheck!!' as "c_message" for xml raw,elements
    end if
  end case
end