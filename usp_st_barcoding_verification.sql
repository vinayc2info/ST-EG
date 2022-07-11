CREATE PROCEDURE "DBA"."usp_st_barcoding_verification"( 
  /* Issues Resolved
1. Scanning pick tray, counter list sorting
2. Stacking store wise det displying
3. Partially Barcoded Pop up message display
*/
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
  declare @temp_shelf_code char(6);
  declare @table_code char(6);
  declare @route_name char(25);
  declare @s_srno numeric(12);
  declare @log_out_cnt numeric(10);
  declare @s_user_name char(10);
  declare @n_barcode_print_flag integer;
  declare @n_partial_barcode_print_flag integer;
  declare @n_status integer;
  declare @old_unknown integer;
  declare @pack_tray_count numeric(4);
  declare @rack_grp_code char(6);
  declare @cust_code char(6);
  declare @act_route_code char(6);
  declare @NextTray char(20);
  declare @BrCode char(6);
  declare @TranBrCode char(6);
  declare @TranPrefix char(4);
  declare @TranYear char(2);
  declare @TranSrno numeric(6);
  declare @rackGrp char(6);
  declare @ColSep char(6);
  declare @RowSep char(6);
  declare @Pos integer;
  declare @ColPos integer;
  declare @RowPos integer;
  declare @ColMaxLen numeric(4);
  declare @RowMaxLen numeric(4);
  declare @d_item_pick_count numeric(8);
  declare @HdrData_Set_Selected_Tray char(7000);
  declare @hdr_data varchar(32767);
  declare @hdr_det varchar(7000);
  declare @RackGrpList char(7000);
  declare local temporary table "temp_rack_grp_list"(
    "c_rack_grp_code" char(6) null,
    "c_stage_code" char(6) null,
    "n_seq" numeric(6) null,) on commit preserve rows;
  declare @tmp char(20);
  declare @CurrentGrp char(6);
  declare @CurrentTray char(20);
  declare @ItemCode char(6);
  declare @BatchNo char(20);
  declare @t_pick_time char(25);
  declare @DocNo char(25);
  declare @InOutFlag numeric(1);
  declare @Qty numeric(11);
  declare @Seq numeric(6);
  declare @OrgSeq numeric(6);
  declare @HoldFlag numeric(1);
  declare @cReason char(10);
  declare @cNote char(100);
  declare @RackCode char(10);
  declare @ItemNotFound integer;
  declare @ItemsInDetail integer;
  declare @nTrayFull integer;
  declare @nTrayInCurrRG integer;
  declare @nIter bigint;
  declare @tray_move_doc_no char(25);
  declare @n_approve_flag numeric(1);
  declare @tray_pending_in_track_in char(50);
  declare @tray_code char(15);
  declare @c_year char(6);
  declare @c_prefix char(6);
  declare @n_srno numeric(18);
  declare @c_cust_code char(6);
  declare @c_route_code char(6);
  declare @c_shelf_code char(6);
  declare @c_gate_code char(6);
  declare @t_time_slot_code char(6);
  declare @carton_no char(6);
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
    set @tray_code = "http_variable"('trayCode'); --11
    set @c_year = "http_variable"('TrYear');
    set @c_prefix = "http_variable"('TrPrefix');
    set @n_srno = "http_variable"('TrSrno');
    set @c_cust_code = "http_variable"('CustCode');
    set @c_route_code = "http_variable"('RouteCode');
    set @c_shelf_code = "http_variable"('ShelfCode');
    set @c_gate_code = "http_variable"('gateCode');
    set @t_time_slot_code = "http_variable"('timeSlotCode');
    set @GodownCode = "http_variable"('GodownCode') --12		
  end if;
  select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
  select "c_delim" into @RowSep from "ps_tab_delimiter" where "n_seq" = 1;
  set @ColMaxLen = "Length"(@ColSep);
  set @RowMaxLen = "Length"(@RowSep);
  set @BrCode = "uf_get_br_code"(@gsBr);
  case @cIndex
  when 'item_details' then
    //http://10.89.209.19:49503/ws_st_barcoding_verification?&cIndex=item_details&GodownCode=&gsbr=000&StageCode=&RackGrpCode=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=
    select '125412' as "c_tray_code",
      '001/19/O/1234' as "c_doc_no",
      '25412' as "c_rack",
      'I12541' as "c_item_code",
      'DOLO 650-150MG' as "c_item_name",
      'MT15412' as "c_batch_no",
      '2025-04-01' as "exp_date",
      '55.00' as "n_mrp",
      15 as "n_qty",
      'P15A' as "c_rack_grp_code",
      'P15' as "c_stage_code",
      '1' as "n_barcode_flag", // 0 is for barcode not required , 1 for barcode required , 2 for pre barcoded.
      1 as "n_pick_seq",
      1 as "n_approve_flag" //1 approved, 0 default, 2 rejected
      from "dummy" for xml raw,elements
  when 'scan_tray_details' then
    //  http://10.89.209.19:49503/ws_st_barcoding_verification?&cIndex=scan_tray_details&trayCode=11502&GodownCode=&gsbr=000&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=CSQ
    select "c_doc_no" into @tray_move_doc_no from "st_track_tray_move" where "c_tray_code" = @tray_code;
    select top 1 "c_cust_code","st_route_table_mapping"."c_table_code","route_mst"."c_code","route_mst"."c_name" into @cust_code,@table_code,@act_route_code,@route_name
      from "st_track_mst"
        join "act_mst" on "act_mst"."c_code" = "st_track_mst"."c_cust_code"
        left outer join "act_route" on "act_route"."c_br_code" = "st_track_Mst"."c_cust_code" and "act_route"."c_code" = "st_track_mst"."c_br_code"
        left outer join "st_route_table_mapping" on "st_route_table_mapping"."c_route_code" = "act_Route"."c_route_code"
        and "st_route_table_mapping"."c_br_code" = "uf_get_br_code"(@gsBr)
        left outer join "route_mst" on "route_mst"."c_code" = "act_Route"."c_route_code"
      where "st_track_mst"."c_doc_no" = @tray_move_doc_no order by "st_route_table_mapping"."c_table_code" asc;
    (select "MAX"("N_SRNO")
      into @s_srno
      from "logon_det"
        join "terminal_det" on "terminal_det"."c_computer_name" = "logon_det"."c_computer_name"
        and "terminal_det"."c_ipno" = "logon_det"."c_nodeaddress"
        and "terminal_det"."c_br_code" = "logon_det"."c_br_code"
        left outer join "st_table_mst" on "st_table_mst"."c_br_code" = "terminal_det"."c_br_code"
        and "st_table_mst"."c_terminal_code" = "terminal_det"."c_code"
      where "st_table_mst"."c_code" = @table_code and "N_TYPE" = 0);
    select "logon_det"."c_user" into @s_user_name from "logon_det" where "n_srno" = @s_srno;
    select "count"("logon_det"."C_USER") into @log_out_cnt from "logon_det"
        join "terminal_det" on "terminal_det"."c_computer_name" = "logon_det"."c_computer_name"
        and "terminal_det"."c_ipno" = "logon_det"."c_nodeaddress"
        and "terminal_det"."c_br_code" = "logon_det"."c_br_code"
        left outer join "st_table_mst" on "st_table_mst"."c_br_code" = "terminal_det"."c_br_code"
        and "st_table_mst"."c_terminal_code" = "terminal_det"."c_code"
      where "st_table_mst"."c_code" = @table_code and "N_TYPE" = 1 and "N_SRNO" > @s_srno and "logon_det"."c_user" = @s_user_name;
    select @tray_code as "c_tray_code",
      "isnull"("max"("tray_move"."counter_code"),"isnull"(@table_code,'-')) as "c_counter_code",
      @act_route_code as "route_code",
      @route_name as "route_name",
      "st_track_mst"."c_cust_code" as "c_store_code",
      "act_mst"."c_name" as "c_store_name",
      "doc_no" as "c_doc_no",
      "sum"("conveyer_tray_cnt") as "n_trays_on_conveyer",
      "sum"("pending_pick_tray_cnt") as "n_pending_pick_tray_cnt",
      //       sum(trays_assigned_to_counter) as n_trays_assigned_to_counter,
      "count"(distinct "counter_code") as "n_trays_assigned_to_counter",
      if @log_out_cnt = 0 then
        @s_user_name else 'NA' endif as "c_scanning_system_user"
      from(select "st_track_tray_move"."c_doc_no" as "doc_no",
          "st_track_tray_move"."c_tray_code" as "tray_code",
          "st_counter_det"."c_counter_code" as "counter_code",
          "st_counter_det"."c_user" as "counter_user",
          if "st_track_tray_move"."n_flag" >= 4 then 1 else 0 endif as "conveyer_tray_cnt",
          if "st_track_tray_move"."n_flag" < 4 then 1 else 0 endif as "pending_pick_tray_cnt",
          "count"(distinct "st_counter_det"."c_counter_code") as "trays_assigned_to_counter"
          from "st_track_Tray_Move"
            left outer join "st_counter_det" on "st_counter_det"."c_doc_no" = "st_track_Tray_Move"."c_doc_no" and "st_track_Tray_Move"."c_tray_code" = "st_counter_det"."c_tray_code"
            left outer join "st_counter_det" as "cd" on "cd"."c_doc_no" = "st_track_Tray_Move"."c_doc_no" and "st_track_Tray_Move"."c_tray_code" = "cd"."c_tray_code"
          where "st_track_tray_move"."c_doc_no" = @tray_move_doc_no
          group by "pending_pick_tray_cnt","conveyer_tray_cnt","counter_user","tray_code","doc_no","counter_user","counter_code") as "tray_move"
        join "st_track_mst" on "st_track_mst"."c_doc_no" = "tray_move"."doc_no"
        join "act_mst" on "act_mst"."c_code" = "st_track_mst"."c_cust_code"
      group by "c_store_code","c_store_name","c_doc_no" for xml raw,elements
  /*  select "c_doc_no" into @tray_move_doc_no from "st_track_tray_move" where "c_tray_code" = @tray_code;
select top 1 "c_cust_code","st_route_table_mapping"."c_table_code","route_mst"."c_code","route_mst"."c_name" into @cust_code,@table_code,@act_route_code,@route_name
from "st_track_mst"
join "act_mst" on "act_mst"."c_code" = "st_track_mst"."c_cust_code"
left outer join "act_route" on "act_route"."c_br_code" = "st_track_Mst"."c_cust_code" and "act_route"."c_code" = "st_track_mst"."c_br_code"
left outer join "st_route_table_mapping" on "st_route_table_mapping"."c_route_code" = "act_Route"."c_route_code"
and "st_route_table_mapping"."c_br_code" = "uf_get_br_code"(@gsBr)
left outer join "route_mst" on "route_mst"."c_code" = "act_Route"."c_route_code"
where "st_track_mst"."c_doc_no" = @tray_move_doc_no order by "st_route_table_mapping"."c_table_code" asc;
(select "MAX"("N_SRNO")
into @s_srno
from "logon_det"
join "terminal_det" on "terminal_det"."c_computer_name" = "logon_det"."c_computer_name"
and "terminal_det"."c_ipno" = "logon_det"."c_nodeaddress"
and "terminal_det"."c_br_code" = "logon_det"."c_br_code"
left outer join "st_table_mst" on "st_table_mst"."c_br_code" = "terminal_det"."c_br_code"
and "st_table_mst"."c_terminal_code" = "terminal_det"."c_code"
where "st_table_mst"."c_code" = @table_code and "N_TYPE" = 0);
select "logon_det"."c_user" into @s_user_name from "logon_det" where "n_srno" = @s_srno;
select "count"("logon_det"."C_USER") into @log_out_cnt from "logon_det"
join "terminal_det" on "terminal_det"."c_computer_name" = "logon_det"."c_computer_name"
and "terminal_det"."c_ipno" = "logon_det"."c_nodeaddress"
and "terminal_det"."c_br_code" = "logon_det"."c_br_code"
left outer join "st_table_mst" on "st_table_mst"."c_br_code" = "terminal_det"."c_br_code"
and "st_table_mst"."c_terminal_code" = "terminal_det"."c_code"
where "st_table_mst"."c_code" = @table_code and "N_TYPE" = 1 and "N_SRNO" > @s_srno and "logon_det"."c_user" = @s_user_name;
select top 1
@tray_code as "c_tray_code",
"isnull"("max"("tray_move"."counter_code"),"isnull"(@table_code,'-')) as "c_counter_code",
@act_route_code as "route_code",
@route_name as "route_name",
"st_track_mst"."c_cust_code" as "c_store_code",
"act_mst"."c_name" as "c_store_name",
"doc_no" as "c_doc_no",
"sum"("conveyer_tray_cnt") as "n_trays_on_conveyer",
(select "count"() from "st_counter_det" as "cd" where "cd"."c_counter_code" = "counter_code" and "cd"."d_date" = "today"()) as "n_trays_assigned_to_counter",
"sum"("pending_pick_tray_cnt") as "n_pending_pick_tray_cnt",
if @log_out_cnt = 0 then
@s_user_name else 'NA' endif as "c_scanning_system_user",
"tray_move"."counter_time"
from(select distinct "st_track_tray_move"."c_doc_no" as "doc_no","st_track_tray_move"."c_tray_code" as "tray_code",
"st_counter_det"."c_counter_code" as "counter_code","st_counter_det"."c_user" as "counter_user",
if "st_track_tray_move"."n_flag" >= 4 then 1 else 0 endif as "conveyer_tray_cnt",
if "st_track_tray_move"."n_flag" < 4 then 1 else 0 endif as "pending_pick_tray_cnt","st_counter_det"."t_time" as "counter_time"
from "st_track_Tray_Move"
left outer join "st_counter_det" on "st_counter_det"."c_doc_no" = "st_track_Tray_Move"."c_doc_no"
where "st_track_tray_move"."c_doc_no" = @tray_move_doc_no) as "tray_move"
join "st_track_mst" on "st_track_mst"."c_doc_no" = "tray_move"."doc_no"
join "act_mst" on "act_mst"."c_code" = "st_track_mst"."c_cust_code"
group by "c_store_code","c_store_name","c_doc_no","counter_code","tray_move"."counter_time"
order by "tray_move"."counter_time" desc for xml raw,elements*/
  when 'counter_list' then
    //  http://10.89.209.19:49503/ws_st_barcoding_verification?&cIndex=counter_list&GodownCode=&gsbr=000&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=VKS
    select cast("c_code" as integer) as "table_code","c_name" as "table_name" from "st_table_mst" where "n_lock" = 0 order by "table_code" asc for xml raw,elements
  when 'assign_counter' then
    //  http://10.89.209.19:49503/ws_st_barcoding_verification?&cIndex=assign_counter&trayCode=11502&HdrData=133/19/O/2380&DetData=16A&GodownCode=&gsbr=000&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=VKS
    insert into "st_counter_det" on existing update defaults on
      select "st_track_tray_move"."c_doc_no" as "c_doc_no",
        "st_track_tray_move"."c_Tray_code" as "c_tray_code",
        "st_track_Tray_Move"."c_stage_code" as "c_stage_code",
        "st_track_mst"."c_cust_code" as "c_store_code",
        "isnull"("route_mst"."c_code",'') as "route_code",
        @DetData as "c_counter_code",
        null as "c_computer_name",
        null as "c_sys_user",
        null as "c_sys_ip",
        0 as "n_complete",
        @UserId as "c_user",
        "today"() as "d_date",
        "now"() as "t_time",
        @UserId as "c_luser",
        "today"() as "d_ldate",
        "now"() as "t_ltime"
        from "st_track_Tray_Move"
          left outer join "st_counter_det" on "st_counter_det"."c_doc_no" = "st_track_Tray_Move"."c_doc_no"
          join "st_track_mst" on "st_track_mst"."c_doc_no" = "st_track_tray_move"."c_doc_no"
          join "act_mst" on "act_mst"."c_code" = "st_track_mst"."c_cust_code"
          left outer join "act_route" on "act_route"."c_br_code" = "st_track_Mst"."c_cust_code" and "act_route"."c_code" = "st_track_mst"."c_br_code"
          left outer join "route_mst" on "route_mst"."c_code" = "act_Route"."c_route_code"
        where "st_track_tray_move"."c_doc_no" = @HdrData and "c_tray_code" = @tray_code;
    if sqlstate = '00000' then
      commit work;
      select 1 as "c_status",
        'Success' as "c_message" for xml raw,elements
    else
      rollback work;
      select 0 as "c_status",
        'Failure' as "c_message" for xml raw,elements
    end if when 'counterwise_pending_cnt' then
    //http://10.89.209.19:49503/ws_st_barcoding_verification?&cIndex=counterwise_pending_cnt&trayCode=10251&GodownCode=&gsbr=000&StageCode=&RackGrpCode=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=myboss
    select "c_doc_no" into @tray_move_doc_no from "st_track_tray_move" where "c_tray_code" = @tray_code;
    select top 1 "c_cust_code","st_route_table_mapping"."c_table_code","route_mst"."c_code","route_mst"."c_name" into @cust_code,@table_code,@act_route_code,@route_name
      from "st_track_mst"
        join "act_mst" on "act_mst"."c_code" = "st_track_mst"."c_cust_code"
        left outer join "act_route" on "act_route"."c_br_code" = "st_track_Mst"."c_cust_code" and "act_route"."c_code" = "st_track_mst"."c_br_code"
        left outer join "st_route_table_mapping" on "st_route_table_mapping"."c_route_code" = "act_Route"."c_route_code"
        and "st_route_table_mapping"."c_br_code" = "uf_get_br_code"(@gsBr)
        left outer join "route_mst" on "route_mst"."c_code" = "act_Route"."c_route_code"
      where "st_track_mst"."c_doc_no" = @tray_move_doc_no order by "st_route_table_mapping"."c_table_code" asc;
    select "isnull"("st_route_table_mapping"."c_table_code",'-') as "c_counter_code",
      "isnull"("act_route"."c_route_code",'-') as "c_route_code",
      "st_track_pick"."c_user" as "c_user_name",
      "count"(distinct "st_track_pick"."c_tray_code") as "n_pending_pick_tray_cnt",
      "count"("st_track_det"."c_item_code") as "n_pending_item_cnt",
      (select "ceil"("ceil"("sum"("n_avg_time_in_seconds_to_pick")/"count"("n_avg_time_in_seconds_to_pick"))/"ceil"("sum"("n_item_count")/"count"("n_item_count")))
        from "st_employee_efficiency_detail" where "c_User" = "st_track_pick"."c_user") as "n_avg_picking_time_in_secs",
      "n_avg_picking_time_in_secs"*"n_pending_item_cnt" as "n_tot_time_secs",
      cast("n_tot_time_secs"/86400 as integer) as "t_etc_days",
      cast("mod"("n_tot_time_secs",86400)/3600 as integer) as "t_etc_hours",
      cast("mod"("mod"("n_tot_time_secs",86400),3600)/60 as integer) as "t_etc_minutes",
      cast("mod"("mod"("mod"("n_tot_time_secs",86400),3600),60) as integer) as "t_etc_seconds",
      if "t_etc_days" = 0 then "replicate"('0',2) else if "len"("t_etc_days") = 1 then '0'+"trim"("str"("t_etc_days")) else "trim"("str"("t_etc_days")) endif endif+':'
      +if "t_etc_hours" = 0 then "replicate"('0',2) else if "len"("t_etc_hours") = 1 then '0'+"trim"("str"("t_etc_hours")) else "trim"("str"("t_etc_hours")) endif endif+':'
      +if "t_etc_minutes" = 0 then "replicate"('0',2) else if "len"("t_etc_minutes") = 1 then '0'+"trim"("str"("t_etc_minutes")) else "trim"("str"("t_etc_minutes")) endif endif+':'
      +if "t_etc_seconds" = 0 then "replicate"('0',2) else if "len"("t_etc_seconds") = 1 then '0'+"trim"("str"("t_etc_seconds")) else "trim"("str"("t_etc_seconds")) endif endif+'.000' as "t_estimated_time"
      from "st_track_det"
        join "st_track_mst" on "st_track_mst"."c_doc_no" = "st_track_det"."c_doc_no" and "st_track_mst"."n_inout" = "st_Track_det"."n_inout"
        join "st_track_pick" on "st_track_pick"."c_Doc_no" = "st_track_det"."c_Doc_no" and "st_track_pick"."n_inout" = "st_track_det"."n_inout" and "st_track_pick"."c_item_code" = "st_track_det"."c_item_code" and "st_track_det"."n_seq" = "st_track_pick"."n_org_seq"
        left outer join "act_route" on "act_route"."c_br_code" = "st_track_mst"."c_cust_code"
        left outer join "st_route_table_mapping" on "st_route_table_mapping"."c_br_code" = "act_route"."c_code" and "st_route_table_mapping"."c_route_code" = "act_route"."c_route_code"
      where "st_track_det"."n_complete" in( 1,2 ) and "st_track_det"."n_inout" = 0 and "st_track_det"."c_tray_code" is not null and "st_track_det"."c_doc_no" not like '%/162/%'
      and("st_track_pick"."n_qty"-("st_track_pick"."n_confirm_qty"+"st_track_pick"."n_reject_qty")) > 0 and @act_route_code = "c_route_code"
      group by "act_route"."c_route_code","st_route_table_mapping"."c_table_code","st_track_pick"."c_user" for xml raw,elements
  when 'stacking_pack_tray_det' then
    //http://10.89.209.19:49503/ws_st_barcoding_verification?&cIndex=stacking_pack_tray_det&trayCode=&GodownCode=&gsbr=000&StageCode=&RackGrpCode=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=myboss
    select top 1 "c_br_code","c_year","c_prefix","n_srno" into @BrCode,@c_year,@c_prefix,@n_srno
      from "carton_mst"
      where("n_carton_no" = @tray_code or "c_tray_code" = @tray_code) and "carton_mst"."d_ldate" = "uf_default_date"()
      order by "n_srno" desc;
    // to find the cust_code/br_cde of the inv/gdn
    select "c_ref_br_code"
      into @cust_code
      from "gdn_mst" where "c_br_code" = @BrCode and "c_year" = @c_year and "c_prefix" = @c_prefix and "n_srno" = @n_srno union all
    select "c_cust_code" from "inv_mst" where "c_br_code" = @BrCode and "c_year" = @c_year and "c_prefix" = @c_prefix and "n_srno" = @n_srno;
    // query for api response
    select distinct "carton_mst"."c_br_code"+'/'+"carton_mst"."c_year"+'/'+"carton_mst"."c_prefix"+'/'+"trim"("str"("carton_mst"."n_srno")) as "c_doc_no",
      "carton_mst"."n_carton_no","carton_mst"."c_tray_code",
      "st_shelf_det"."c_shelf_code" as "c_shelf_code",
      if "st_shelf_det"."c_br_code" is null then 'STACKING PENDING' else 'STACKING COMPLETED' endif as "c_status"
      from "carton_mst"
        left outer join "gdn_mst" on "gdn_mst"."c_br_code" = "carton_mst"."c_br_code"
        and "gdn_mst"."c_year" = "carton_mst"."c_year"
        and "gdn_mst"."c_prefix" = "carton_mst"."c_prefix"
        and "gdn_mst"."n_srno" = "carton_mst"."n_srno"
        left outer join "Inv_mst" on "Inv_mst"."c_br_code" = "carton_mst"."c_br_code"
        and "Inv_mst"."c_year" = "carton_mst"."c_year"
        and "Inv_mst"."c_prefix" = "carton_mst"."c_prefix"
        and "Inv_mst"."n_srno" = "carton_mst"."n_srno"
        left outer join "st_shelf_det"
        on "st_shelf_det"."c_br_code" = "carton_mst"."c_br_code"
        and "st_shelf_det"."c_year" = "carton_mst"."c_year"
        and "st_shelf_det"."c_prefix" = "carton_mst"."c_prefix"
        and "st_shelf_det"."n_srno" = "carton_mst"."n_srno"
        and "st_shelf_det"."c_tray_code" = "carton_mst"."c_tray_code"
        and "st_shelf_det"."n_carton_no" = "carton_mst"."n_carton_no"
      where "carton_mst"."d_ldate" = "uf_default_date"() and("gdn_mst"."c_ref_br_code" = @cust_code or "inv_mst"."c_cust_code" = @cust_code)
      order by "c_status" desc for xml raw,elements
  when 'stacking_pack_tray' then
    //http://10.89.209.19:49503/ws_st_barcoding_verification?&cIndex=stacking_pack_tray&trayCode=52288&GodownCode=&gsbr=000&StageCode=&RackGrpCode=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=myboss
    select top 1 "c_br_code","c_year","c_prefix","n_srno","n_carton_no","c_tray_code" into @TranBrCode,@TranYear,@TranPrefix,@TranSrno,@carton_no,@tray_code
      from "carton_mst" where("c_tray_code" = @tray_code or "n_carton_no" = @tray_code) order by "t_ltime" desc;
    if @tray_code = '000000' then
      set @tray_code = @carton_no
    end if;
    select "count"(distinct(if "n_carton_no" = 0 then "c_tray_code" else "n_carton_no" endif))
      into @pack_tray_count
      from "carton_mst" where "carton_mst"."c_br_code" = @TranBrCode and "carton_mst"."c_prefix" = @TranPrefix and "carton_mst"."c_year" = @TranYear and "carton_mst"."n_srno" = @TranSrno;
    select "inv_mst"."c_cust_code","act_route"."c_route_code" into @cust_code,@act_route_code
      from "inv_mst" left outer join "act_route" on "act_Route"."c_br_code" = "inv_mst"."c_cust_code" and "inv_mst"."c_br_code" = "act_route"."c_code"
      where "inv_mst"."c_br_code" = @TranBrCode
      and "inv_mst"."c_year" = @TranYear
      and "inv_mst"."c_prefix" = @TranPrefix
      and "inv_mst"."n_srno" = @TranSrno union all
    select "gdn_mst"."c_ref_br_code","act_route"."c_route_code"
      from "gdn_mst"
        join "act_route" on "act_Route"."c_br_code" = "gdn_mst"."c_ref_br_code" and "gdn_mst"."c_br_code" = "act_route"."c_code"
      where "gdn_mst"."c_br_code" = @TranBrCode
      and "gdn_mst"."c_year" = @TranYear
      and "gdn_mst"."c_prefix" = @TranPrefix
      and "gdn_mst"."n_srno" = @TranSrno;
    select top 1 "st_shelf_det"."c_shelf_code" into @temp_shelf_code from "st_shelf_det"
      where "st_shelf_det"."c_route_code" = @act_route_code
      order by "t_time" desc,"st_shelf_det"."c_gate_code" asc,"st_shelf_det"."n_srno" asc;
    select top 1
      @TranBrCode as "c_br_code",
      @TranYear as "c_year",
      @TranPrefix as "c_prefix",
      @TranSrno as "n_srno",
      @TranBrCode+'/'+@TranYear+'/'+@TranPrefix+'/'+"trim"("str"(@TranSrno)) as "c_doc_no",
      @tray_code as "c_pack_tray_code",
      "isnull"((select top 1 "rack_mst"."c_code" from "rack_mst"
          left outer join "st_shelf_det" on "rack_mst"."c_code" = "st_shelf_Det"."c_shelf_code" and "rack_mst"."c_br_code" = "st_shelf_det"."c_br_code"
        where "rack_mst"."n_type" = 3 and "rack_mst"."c_rack_Grp_code" = "rack_group_mst"."c_code" /*and "st_shelf_det"."c_br_code" is null (commented to allow the shelf even if that is not released)*/
        order by "rack_mst"."c_code" asc),@temp_shelf_code) as "c_shelf_code",
      "rack_group_mst"."c_code" as "c_rack_grp_code",
      "tap"."c_gate_code" as "c_gate_code",
      @cust_code as "c_cust_code",
      @act_route_code as "c_route_code",
      "isnull"("tap"."c_time_slot_code",'NA') as "t_time_slot_code",
      @pack_tray_count as "n_pack_tray_count",
      "act_mst"."c_name" as "c_cust_name"
      from "st_truck_allocation_plan" as "tap"
        left outer join "st_gate_det" on "st_gate_det"."c_br_code" = "tap"."c_br_code" and "st_gate_det"."c_code" = "tap"."c_gate_code"
        left outer join "rack_group_mst" on "rack_group_mst"."c_code" = "st_gate_det"."c_rack_grp_code" and "rack_group_mst"."c_br_code" = "st_gate_det"."c_br_code"
        left outer join "st_shelf_det" on "tap"."c_route_code" = "st_shelf_det"."c_route_code" and "tap"."c_br_code" = "st_shelf_det"."c_br_code"
        left outer join "act_mst" on "act_mst"."c_code" = @cust_code
      where "tap"."c_route_COde" = @act_route_code and "t_dispatch_time" is null and "tap"."d_date" = "today"() for xml raw,elements /*"tap"."d_date" = '2020-05-28' and */ /*uf_default_date()*/
  when 'tray_validation' then
    //http://10.89.209.19:49503/ws_st_barcoding_verification?&cIndex=tray_validation&trayCode=80264&gsbr=000&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=myboss
    if(select "count"() from "st_tray_mst" join "st_tray_type_mst" on "st_tray_type_mst"."c_code" = "st_tray_mst"."c_tray_type_code" where "st_tray_type_mst"."n_tray_type" = 0 and "st_tray_mst"."c_code" = @tray_code) = 1 then
      if(select "count"("c_tray_code") from "st_track_tray_move" where "c_tray_code" = @tray_code) <> 1 then
        select 'Warning! : Tray not assigned to any  Document. Please Check!' as "c_message" for xml raw,elements;
        return
      else
        set @tray_pending_in_track_in = null;
        select top 1 "c_doc_no"
          into @tray_pending_in_track_in from "St_track_in"
          where "c_tray_code" = @tray_code and "n_confirm" = 1;
        if @tray_pending_in_track_in is not null or "trim"(@tray_pending_in_track_in) <> '' then
          select 'Tray can not be assigned as it is already in use for document '+@tray_pending_in_track_in as "c_message" for xml raw,elements;
          return
        else
          select 'Success' as "c_message" for xml raw,elements
        end if
      end if
    else select 'Tray code '+@tray_code+' not found in masters.' as "c_message" for xml raw,elements
    end if when 'barcode_done' then
    /*
http://10.89.209.19:49503/ws_st_barcoding_verification?&cIndex=barcode_done&HdrData=1^^038^^19^^O^^846^^-nulltray-^^0^^0^^~~^^||&DetData=0^^4^^78^^241585^^AT1923^^1^^1^^-^^-^^10245^^12105^^P12A^^0^^2020-05-29%2010:06:45^^-1^^1^^1^^||0^^3^^132^^257938^^1900378^^1^^1^^-^^-^^10245^^12103^^P12A^^0^^2020-05-29%2010:06:41^^-1^^1^^1^^||0^^2^^210^^350410^^GJ90529^^1^^1^^-^^-^^10245^^12083^^P12A^^0^^2020-05-29%2010:06:36^^-1^^1^^1^^||0^^1^^229^^328965^^GL40^^1^^1^^-^^-^^10245^^12013^^P12A^^0^^2020-05-29%2010:06:31^^-1^^1^^0^^||&ExpBatch=&godown_item_detail=&excess_rack_list=&RackGrpCode=P12A^^&StageCode=P12&GodownCode=-&gsbr=503&devID=a3dcfdf75bc646d105092019064846055&sKEY=sKey&UserId=MYBOSS
*/
    --1 ItemsInDetail
    set @hdr_data = @HdrData;
    set @hdr_det = @DetData;
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @ItemsInDetail = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --2 Tranbrcode
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @Tranbrcode = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --3 TranYear
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranYear = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --4 TranPrefix
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranPrefix = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --5 TranSrno
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranSrno = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --6 CurrentTray(= -nulltray- if FirstInStage = 1 )
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @CurrentTray = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --7 InOutFlag
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @InOutFlag = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --8 nTrayFull
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @nTrayFull = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --9 @HdrData_Set_Selected_Tray 
    select "Locate"(@HdrData,'~') into @ColPos;
    set @HdrData = "SubString"(@HdrData,@ColPos+1);
    select "Locate"(@HdrData,'~') into @ColPos;
    set @HdrData_Set_Selected_Tray = "Trim"("Left"(@HdrData,@ColPos-1));
    select "Locate"(@HdrData,'~') into @ColPos;
    if @HdrData_Set_Selected_Tray is null or "trim"(@HdrData_Set_Selected_Tray) = '' then
      set @NextTray = ''
    else
      set @NextTray = '1'
    end if;
    set @DocNo = @Tranbrcode+'/'+@TranYear+'/'+@TranPrefix+'/'+"string"(@TranSrno);
    if @DetData = '' and @nTrayFull = 1 and @CurrentTray <> '-nulltray-' then
      select "count"("c_tray_code")
        into @nOldTrayItemCountPick from "DBA"."st_track_pick"
        where "c_tray_code" = @CurrentTray
        and "c_doc_no" = @DocNo
    end if;
    set @RackGrpList = @RackGrpCode;
    if @CurrentTray = '-nulltray-' then
      select top 1 "det"."c_tray_code"
        into @CurrentTray from "st_track_det" as "det"
        where "det"."c_doc_no" = @DocNo
        and "det"."c_stage_code" = @StageCode
        and "det"."c_godown_code" = @GodownCode;
      if @CurrentTray is null or @CurrentTray = '-nulltray-' then
        select 'Warning!! : No Tray assigned for Document - '+"string"(@DocNo) as "c_message" for xml raw,elements;
        return
      end if end if;
    while @RackGrpList <> '' loop
      --1 RackGrpList
      select "Locate"(@RackGrpList,@ColSep) into @ColPos;
      set @tmp = "Trim"("Left"(@RackGrpList,@ColPos-1));
      set @RackGrpList = "SubString"(@RackGrpList,@ColPos+@ColMaxLen);
      if(select "COUNT"("C_CODE") from "RACK_GROUP_MST" where "C_CODE" = @tmp) > 0 then --valid rack group selection 
        select "n_pos_seq" into @Seq from "st_store_stage_det" where "c_rack_grp_code" = @tmp;
        insert into "temp_rack_grp_list"( "c_rack_grp_code","c_stage_code","n_seq" ) values( @tmp,@StageCode,@Seq ) 
      end if
    end loop;
    set @nIter = 0;
    while @DetData <> '' and @ItemsInDetail = 1 loop
      set @nIter = @nIter+1;
      -- DocNo		
      --1 InOutFlag
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @InOutFlag = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --2 Seq
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @Seq = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --3 OrgSeq
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @OrgSeq = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --4 ItemCode
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @ItemCode = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --5 BatchNo
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @BatchNo = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --6 Qty
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @Qty = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --7 HoldFlag
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @HoldFlag = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --8 cReason
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @cReason = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --9 cNote
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @cNote = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --10
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @CurrentTray = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --11 RackCode
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @RackCode = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --12 CurrentGrp
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @CurrentGrp = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --13 ItemNotFound
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @ItemNotFound = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --14 ItemNotFound
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @t_pick_time = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --print @t_pick_time;
      if "trim"(@t_pick_time) = '' or @t_pick_time is null then
        set @t_pick_time = "left"("now"(),19)
      end if;
      --15 @old_unknown
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @old_unknown = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --14 n_status
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @n_status = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --14 partial_barcode_print
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @n_partial_barcode_print_flag = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      select "Locate"(@DetData,@RowSep) into @RowPos;
      set @DetData = "SubString"(@DetData,@RowPos+@RowMaxLen);
      if @ItemNotFound = 0 then
        set @d_item_pick_count = @d_item_pick_count+1;
        insert into "st_track_barcode_verification"
          ( "c_doc_no","n_inout","n_seq","n_org_seq","c_item_code","c_batch_no","n_qty","n_hold_flag","c_reason_code","c_note","c_user","t_time","c_tray_code",
          "c_device_id","c_rack","c_rack_grp_code","c_stage_code","c_godown_code","n_status","n_barcode_print_flag" ) on existing update defaults off values
          ( @DocNo,@InOutFlag,@Seq,@OrgSeq,@ItemCode,@BatchNo,@Qty,@HoldFlag,@cReason,@cNote,@UserId,@t_pick_time,@CurrentTray,
          @devID,@RackCode,@CurrentGrp,@StageCode,@GodownCode,@n_status,@n_partial_barcode_print_flag ) 
      else
      end if
    end loop;
    if(select "count"("n_barcode_print_flag") from "st_track_barcode_verification" where "n_barcode_print_flag" = 0 and "c_doc_no" = @DocNo and "c_tray_code" = @CurrentTray) <> 0 then
      set @n_barcode_print_flag = 0
    else
      set @n_barcode_print_flag = 1
    end if;
    //    if(select "n_pos_seq" from "st_store_stage_det" where "c_stage_code" = @StageCode and "c_rack_grp_code" = @CurrentGrp) = 1 then
    insert into "st_track_partial_barcode_tray"
      ( "c_doc_no","n_inout","c_tray_code","c_stage_code","n_flag","c_godown_code","t_time","c_user" ) on existing update defaults off values
      ( @DocNo,@InOutFlag,@CurrentTray,@StageCode,@n_barcode_print_flag,@GodownCode,"now"(),@UserId ) ;
    //    else
    //      update "st_track_partial_barcode_tray" set "n_flag" = @n_barcode_print_flag where "c_doc_no" = @DocNo and "c_tray_code" = @CurrentTray
    //    end if;
    if sqlstate = '00000' then
      commit work;
      select 1 as "c_status",
        'Success' as "c_message" for xml raw,elements
    else
      rollback work;
      select 0 as "c_status",
        'Failure' as "c_message" for xml raw,elements
    end if when 'stacking_confirm' then
    //http://10.89.209.19:49503/ws_st_barcoding_verification?&cIndex=stacking_confirm&trayCode=52288&GodownCode=&gsbr=503&RackGrpCode=VKS1&gateCode=GATE1&TrYear=19&TrPrefix=N&TrSrno=152588&CustCode=017&ShelfCode=LSS1&timeSlotCode=SCH013&RouteCode=RT0002&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=myboss
    if(select "count"("c_code") from "rack_mst" where "n_type" = 3 and "c_code" = @c_shelf_code) = 1 then
      select top 1 "c_br_code","c_year","c_prefix","n_srno","n_carton_no","c_tray_code" into @TranBrCode,@TranYear,@TranPrefix,@TranSrno,@carton_no,@tray_code
        from "carton_mst" where("c_tray_code" = @tray_code or "n_carton_no" = @tray_code) order by "t_ltime" desc;
      if(select "count"() from "st_shelf_det" where "c_br_code" = @BrCode and "c_year" = @c_year and "c_prefix" = @c_prefix and "n_srno" = @n_srno and "c_tray_code" = @tray_code and "n_carton_no" = @carton_no and "c_route_code" = @c_route_code) = 0 then /*and "c_shelf_code" = @c_shelf_code*/
        insert into "st_shelf_det"
          ( "c_br_code","c_year","c_prefix","n_srno","c_cust_code","c_tray_code","n_carton_no","c_route_code","c_shelf_code",
          "c_rack_grp_code","c_gate_code","t_time_slot_code","c_user","t_time","d_date","d_ldate","t_ltime","c_luser" ) values
          ( @BrCode,@c_year,@c_prefix,@n_srno,@c_cust_code,@tray_code,@carton_no,@c_route_code,@c_shelf_code,
          @RackGrpCode,@c_gate_code,@t_time_slot_code,@UserId,"now"(),"today"(),"today"(),"now"(),@UserId ) ;
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
          'Failure: Already Tray Placed in the shelf. Please check.' as "c_message" for xml raw,elements
      end if
    else select 0 as "c_status",
        'Failure: Shelf does not exist in Masters.' as "c_message" for xml raw,elements
    end if when 'counter_assigned_det' then
    //http://172.16.18.19:19503/ws_st_barcoding_verification?&cIndex=counter_assigned_det&HdrData=133/19/O/2380&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=myboss
    set @DocNo = @HdrData;
    select "st_track_mst"."c_cust_code" as "cust_code",
      "isnull"("st_counter_det"."c_counter_code",'U/A') as "counter_code",
      "isnull"("st_counter_det"."c_user",'U/A') as "c_counter_user",
      "count"("st_track_tray_move"."c_tray_code") as "n_trays_assigned",
      "list"("st_track_tray_move"."c_tray_code") as "c_tray_list"
      from "st_track_tray_move"
        left outer join "st_track_mst" on "st_track_mst"."c_doc_no" = "st_track_tray_move"."c_doc_no"
        left outer join "st_counter_det" on "st_track_tray_move"."c_doc_no" = "st_counter_det"."c_doc_no" and "st_track_tray_move"."c_tray_code" = "st_counter_det"."c_tray_code"
      where "st_track_tray_move"."c_doc_no" = @DocNo
      group by "counter_code","c_counter_user","cust_code" for xml raw,elements
  end case
end;