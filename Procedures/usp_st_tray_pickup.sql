CREATE PROCEDURE "DBA"."usp_st_tray_pickup"( 
  //select * from block_api
  in @gsBr char(6),
  in @devID char(200),
  in @sKey char(20),
  in @UserId char(20),
  in @PhaseCode char(6),
  in @StageCode char(6),
  in @RackGrpCode char(6),
  in @cIndex char(30),
  in @HdrData char(7000),
  in @DetData char(7000),
  in @GodownCode char(6) ) 
result( "is_xml_string" xml ) 
begin
  /*
Author 		: Anup 
Procedure	: usp_st_tray_pickup
SERVICE		: ws_storetrack
Date 		: 25-09-2014
modified by : Saneesh C G 
Ldate 		: 15-06-2015
Purpose		: Store Track TRANSACTION to TAB/DESKTOP
Input		: devID~sKey~UserId~PhaseCode~RackGrpCode~StageCode~cIndex~HdrData~DetData
IndexDetails: get_store_stage, get_rack_group
Note		:
Service Call (Format): http://192.168.7.12:13000/ws_st_tray_pickup?devID=devID&sKey=KEY&UserId=MYBOSS&PhaseCode=&RackGrpCode=&StageCode=&cIndex=&HdrData=&DetData=
*/
  declare @BrCode char(6);
  declare @t_ltime char(25);
  declare @d_ldate char(20);
  declare @nUserValid integer;
  declare @RackGrpList char(7000);
  --common >>
  declare @ColSep char(6);
  declare @RowSep char(6);
  declare @Pos integer;
  declare @ColPos integer;
  declare @RowPos integer;
  declare @ColMaxLen numeric(4);
  declare @RowMaxLen numeric(4);
  --common <<
  --cIndex get_doc_list >>
  declare @tmp char(20);
  declare local temporary table "temp_rack_grp_list"(
    "c_rack_grp_code" char(6) null,) on commit delete rows; --cIndex get_doc_list <<
  --cIndex get_cust_tray_list>>
  declare @RegionCode char(6);
  declare @nStoreIn integer;
  --cIndex get_cust_tray_list<<
  --cIndex set_selected_tray >>
  declare @StageHdr char(7000);
  declare @StageDet char(7000);
  declare @cUser char(20);
  declare @DocNo char(25);
  declare @StartGrp char(6);
  declare @CurrentGrp char(6);
  declare @EndGrp char(6);
  declare @nStatus integer;
  declare @nClosed integer;
  declare @nOut integer;
  declare @TranBrCode char(6);
  declare @TranPrefix char(4);
  declare @TranYear char(2);
  declare @TranSrno numeric(6);
  declare @CurrentTray char(6);
  --declare @RackGrpList char(7000);
  --cIndex set_selected_tray <<
  --cIndex get_batch_list <<
  declare @ItemCode char(6);
  declare @BatchNo char(20);
  --cIndex get_batch_list <<
  --cIndex setCounter >>
  declare @Counter char(100);
  --cIndex setCounter <<
  declare local temporary table "last_rack_grp"(
    "c_stage_code" char(6) null, --get_tray_items>>	
    "c_rack_grp_code" char(6) null,) on commit preserve rows;declare @Tray char(6);
  declare @nPickCount integer;
  declare @nInOutFlag integer;
  declare @nTrayType integer;
  declare @nCarton integer;
  //declare local temporary table temp_item_receipt_entry (
  //	"c_br_code" CHAR(6) NOT NULL,
  //	"c_year" CHAR(2) NOT NULL,
  //	"c_prefix" CHAR(4) NOT NULL,
  //	"n_srno" NUMERIC(9,0) NOT NULL,
  //	"n_seq" NUMERIC(4,0) NOT NULL DEFAULT 0,
  //	"c_tray_code" CHAR(6) NULL,
  //	"n_carton_no" NUMERIC(6,0) NULL DEFAULT 0,
  //	"t_end_time" "datetime" NULL,
  //	"d_posted_date" "datetime" NULL,) on commit preserve rows;
  declare local temporary table "temp_item_receipt_entry"(
    "i_br_code" char(6) null,
    "i_year" char(2) null,
    "i_prefix" char(4) null,
    "i_srno" numeric(9) null,
    "i_seq" numeric(4) null,
    "c_tray_code" char(6) null,
    "c_doc_no" char(25) null,
    "c_stage_code" char(6) null,
    "n_item_count" numeric(6) null,
    "n_item_processed_count" numeric(6) null,
    "n_tray_age" numeric(3) null,) on commit preserve rows;
  --get_tray_items<<
  --assign_to_counter>>
  declare "i" bigint;
  declare @nState integer;
  --assign_to_counter<<
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
    set @nStoreIn = "http_variable"('nStoreIn')
  end if;
  //  insert into "API_LOG"
  //    ( "c_api_name","c_index","t_start_time","c_remark","c_note","c_user","n_n1" ) values
  //    ( 'usp_st_tray_pickup',@cIndex,"GETDATE"(),@HdrData,@DetData,@UserId,"connection_property"('NUMBER') ) ;
  //  commit work;
  if(select "count"() from "block_api") >= 1 then
    return
  end if;
  /*
insert into "API_LOG"
( "c_api_name","c_index","t_start_time","c_remark","c_note","c_user","n_n1" ) values
( 'usp_st_tray_pickup',@cIndex,"GETDATE"(),@HdrData,@devID,@UserId,"connection_property"('NUMBER') ) ;
commit work;
*/
  select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
  select "c_delim" into @RowSep from "ps_tab_delimiter" where "n_seq" = 1;
  set @ColMaxLen = "Length"(@ColSep);
  set @RowMaxLen = "Length"(@RowSep);
  set @BrCode = "uf_get_br_code"(@gsBr);
  set @t_ltime = "left"("now"(),19);
  set @d_ldate = "uf_default_date"();
  select top 1 "c_user" into @cUser from "logon_det" order by "n_srno" desc;
  case @cIndex
  when 'replica_details' then
    //http://192.168.0.105:22503/ws_st_tray_pickup?&cIndex=replica_details&UserId=S KAMBLE
    select "c_ip" as "replica_ip",
      "n_http_port" as "replica_http_port"
      from "mirror_db_details" for xml raw,elements
  when 'get_cust_tray_list' then
    --http://192.168.7.12:13000/ws_st_tray_pickup?devID=devID&sKey=KEY&UserId=MYBOSS&PhaseCode=PH0003&RackGrpCode=&StageCode=&cIndex=get_cust_tray_list&HdrData=&DetData=
    if(select "count"() from "block_api") = 0 then
      if @GodownCode = '-' then
        select "tray_move"."c_doc_no" as "c_doc_no",
          "cust"."c_code" as "c_cust_code",
          "cust"."c_name" as "c_cust_name",
          "area_mst"."c_name" as "c_area_name",
          (select "count"(distinct "c_tray_code") from "st_track_tray_move" where "c_doc_no" = "tray_move"."c_doc_no") as "n_total_trays", -- excluding Unassigned trays
          (if "tray_move"."n_inout" = 9 then 1 else 0 endif) as "n_completed",
          "tray_move"."c_tray_code" as "c_tray",
          "st_store_stage_mst"."c_name"+'['+"st_store_stage_mst"."c_code"+']' as "c_stage",
          "isnull"("route_mst"."c_name",'') as "c_route",
          "tray_move"."n_flag" as "n_tray_state",
          "isnull"("st_track_mst"."c_system_name",'') as "c_counter",
          "st_track_mst"."d_date" as "d_recv_date",
          "st_track_mst"."c_sort" as "c_route_sort",
          "st_track_mst"."n_urgent" as "n_urgent"
          from "st_track_tray_move" as "tray_move"
            left outer join "st_store_stage_mst" on "st_store_stage_mst"."c_code" = "tray_move"."c_stage_code"
            join "st_track_mst" on "tray_move"."c_doc_no" = "st_track_mst"."c_doc_no" --AND st_track_mst.n_complete <> 9
            join "act_mst" as "cust" on "cust"."c_code" = "isnull"("st_track_mst"."c_cust_code",'GC01')
            left outer join "act_route" as "route" on "route"."c_br_code" = "st_track_mst"."c_cust_code" and "route"."c_code" = "st_track_mst"."c_br_code"
            left outer join "route_mst" on "isnull"("route"."c_route_code",'-') = "route_mst"."c_code"
            join "area_mst" on "area_mst"."c_code" = "cust"."c_area_code"
          where "route_mst"."c_code" = (if @HdrData = '' then "route_mst"."c_code" else @HdrData endif)
          and "isnull"("tray_move"."c_godown_code",'-') = @GodownCode --and st_track_mst.c_doc_no = @DocNo  
          and "tray_move"."n_inout" not in( 1,8 ) union
        -- tray unassigned documents
        select "uas_list"."c_doc_no",
          "uas_list"."c_cust_code",
          "uas_list"."c_cust_name" as "c_cust_name",
          "uas_list"."c_area_name" as "c_area_name",
          "uas_list"."n_total_trays" as "n_total_trays",
          "uas_list"."n_completed" as "n_completed",
          "uas_list"."c_tray" as "c_tray",
          "stage_name"+'['+"uas_list"."c_stage_code"+']' as "c_stage",
          "isnull"("uas_list"."c_route",'') as "c_route",
          0 as "n_tray_state",
          "uas_list"."c_counter" as "c_counter",
          "uas_list"."d_date" as "d_recv_date",
          "uas_list"."c_sort" as "c_route_sort",
          "uas_list"."n_urgent" as "n_urgent"
          --and isnull(st_track_det.c_godown_code,'-') = @GodownCode
          --and st_track_mst.c_doc_no = @DocNo
          from(select distinct "st_track_det"."c_stage_code" as "c_stage_code",
              "st_track_mst"."c_doc_no" as "c_doc_no",
              "cust"."c_code" as "c_cust_code",
              "cust"."c_name" as "c_cust_name",
              "area_mst"."c_name" as "c_area_name",
              (select "count"(distinct "c_tray_code") from "st_track_tray_move" where "c_doc_no" = "tray_move"."c_doc_no") as "n_total_trays",
              0 as "n_completed",
              'UA-'+"isnull"("c_stage_code",'NULL') as "c_tray",
              ("route_mst"."c_name") as "c_route",
              "isnull"("st_track_mst"."c_system_name",'') as "c_counter",
              "st_track_mst"."d_date" as "d_date",
              "st_track_mst"."c_sort" as "c_sort",
              "st_track_mst"."n_urgent" as "n_urgent",
              "st_store_stage_mst"."c_name" as "stage_name"
              from "st_track_mst"
                left outer join "st_track_tray_move" as "tray_move" on "tray_move"."c_doc_no" = "st_track_mst"."c_doc_no"
                join "act_mst" as "cust" on "cust"."c_code" = "isnull"("st_track_mst"."c_cust_code",'GC01')
                left outer join "act_route" as "route" on "route"."c_br_code" = "st_track_mst"."c_cust_code" and "route"."c_code" = "st_track_mst"."c_br_code"
                left outer join "route_mst" on "isnull"("route"."c_route_code",'-') = "route_mst"."c_code"
                join "area_mst" on "area_mst"."c_code" = "cust"."c_area_code"
                join "DBA"."st_track_det" on "st_track_det"."c_doc_no" = "st_track_mst"."c_doc_no"
                and "st_track_det"."n_inout" = "st_track_mst"."n_inout"
                left outer join "st_store_stage_det" on "st_store_stage_det"."c_rack_grp_code" = "st_track_det"."c_rack_grp_code" and "st_store_stage_det"."c_stage_code" = "st_track_det"."c_stage_code"
                left outer join "st_store_stage_mst" on "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
              where "route_mst"."c_code" = (if @HdrData = '' then "route_mst"."c_code" else @HdrData endif)
              and "st_track_det"."c_tray_code" is null
              and "isnull"("st_track_det"."c_godown_code",'-') = @GodownCode
              and "st_track_mst"."n_confirm" = 1
              and "st_track_mst"."n_inout" not in( 1,8 ) ) as "uas_list"
          order by 13 asc,14 asc,11 desc,6 desc,7 asc for xml raw,elements
      else
        --union godown assigned trays
        select distinct "tray_move"."c_doc_no" as "c_doc_no",
          "cust"."c_code" as "c_cust_code",
          "cust"."c_name" as "c_cust_name",
          '' as "c_area_name",
          (select "count"(distinct "c_tray_code") from "st_track_tray_move" where "c_doc_no" = "tray_move"."c_doc_no") as "n_total_trays", -- excluding Unassigned trays
          (if "tray_move"."n_inout" = 9 then 1 else 0 endif) as "n_completed",
          "tray_move"."c_tray_code" as "c_tray",
          "st_store_stage_mst"."c_name"+'['+"st_store_stage_mst"."c_code"+']' as "c_stage",
          '' as "c_route",
          "tray_move"."n_flag" as "n_tray_state",
          "isnull"("st_track_mst"."c_system_name",'') as "c_counter",
          "st_track_mst"."d_date" as "d_recv_date",
          "st_track_mst"."c_sort" as "c_route_sort",
          "st_track_mst"."n_urgent" as "n_urgent"
          from "st_track_tray_move" as "tray_move"
            left outer join "st_store_stage_mst" on "st_store_stage_mst"."c_code" = "tray_move"."c_stage_code"
            join "st_track_mst" on "tray_move"."c_doc_no" = "st_track_mst"."c_doc_no"
            join "godown_mst" as "cust" on "cust"."c_code" = "isnull"("tray_move"."c_godown_code",'-') and "cust"."c_ref_br_code" in( '000',@gsBr ) 
          where "isnull"("tray_move"."c_godown_code",'-') = @GodownCode
          and "tray_move"."n_inout" not in( 1,8 ) union
        -- godown unassigned trays
        select "uas_list"."c_doc_no", --1
          "uas_list"."c_cust_code", --2
          "uas_list"."c_cust_name" as "c_cust_name", --3
          "uas_list"."c_area_name" as "c_area_name", --4
          "uas_list"."n_total_trays" as "n_total_trays", -- 5 
          "uas_list"."n_completed" as "n_completed", --6
          "uas_list"."c_tray" as "c_tray", --7
          "stage_name"+'['+"uas_list"."c_code"+']' as "c_stage", --8
          "isnull"("uas_list"."c_route",'') as "c_route", --9
          0 as "n_tray_state", --10
          "uas_list"."c_counter" as "c_counter", --11
          "uas_list"."d_date" as "d_recv_date", --12
          "uas_list"."c_sort" as "c_route_sort", --13
          "uas_list"."n_urgent" as "n_urgent" --14
          from(select distinct "st_track_det"."c_stage_code" as "c_stage_code",
              "st_track_mst"."c_doc_no" as "c_doc_no",
              "cust"."c_code" as "c_cust_code",
              "cust"."c_name" as "c_cust_name",
              '' as "c_area_name",
              0 as "n_total_trays",
              0 as "n_completed",
              'UA-'+"c_stage_code" as "c_tray",
              '-' as "c_route",
              "isnull"("st_track_mst"."c_system_name",'') as "c_counter",
              "st_track_mst"."d_date" as "d_date",
              "st_track_mst"."c_sort" as "c_sort",
              "st_track_mst"."n_urgent" as "n_urgent",
              "st_store_stage_mst"."c_name" as "stage_name"
              from "st_track_mst"
                join "DBA"."st_track_det" on "st_track_det"."c_doc_no" = "st_track_mst"."c_doc_no"
                and "st_track_det"."n_inout" = "st_track_mst"."n_inout"
                and "isnull"("st_track_det"."c_godown_code",'-') = @GodownCode
                left outer join "st_store_stage_det" on "st_store_stage_det"."c_rack_grp_code" = "st_track_det"."c_rack_grp_code" and "st_store_stage_det"."c_stage_code" = "st_track_det"."c_stage_code"
                left outer join "st_store_stage_mst" on "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
                join "godown_mst" as "cust" on "cust"."c_code" = "isnull"("st_track_det"."c_godown_code",'-') and "cust"."c_ref_br_code" in( '000',@gsBr ) 
              where "st_track_det"."c_tray_code" is null
              and "isnull"("st_track_det"."c_godown_code",'-') = @GodownCode
              and "st_track_mst"."n_confirm" = 1
              and "st_track_mst"."n_inout" not in( 1,8 ) ) as "uas_list"
          order by 13 asc,14 asc,11 desc,6 desc,7 asc for xml raw,elements
      end if end if when 'search_tray' then
    --http://192.168.7.12:13000/ws_st_tray_pickup?devID=devID&sKey=KEY&UserId=MYBOSS&PhaseCode=PH0003&RackGrpCode=&StageCode=&cIndex=search_tray&HdrData=&DetData=T00001
    --i/p : @DetData = Tray code, nStoreIn = 1 - store in tray , 0 - other 
    --
    if(select "count"() from "block_api") = 0 then
      if @nStoreIn = 0 then
        select top 1 "tm"."c_tray_code" as "c_tray_no",
          (select(if "n_in_out_flag" = 1 then 'INTERNAL' else(if "n_in_out_flag" = 0 then 'EXTERNAL' else(if "n_in_out_flag" = 2 then 'INTERNAL/EXTERNAL' else 'TEMPORARY TRAY' endif) endif) endif) from "st_tray_mst" where "c_code" = "tm"."c_tray_code") as "c_tray_type",
          (select "list"("c_rack_grp_code") from "st_track_tray_move" where "c_tray_code" = "tm"."c_tray_code") as "rack_grp_code",
          --,(select c_name from rack_group_mst where c_code = tm.c_rack_grp_code) as rack_grp_name
          "tm"."c_user" as "curr_user",
          (if "tm"."n_inout" = 9 then 1 else 0 endif) as "n_completed",
          "tm"."c_doc_no" as "c_doc_no",
          "tm"."c_stage_code" as "c_stage_code"
          from "st_track_tray_move" as "tm"
          where "tm"."c_tray_code" = @DetData
          --group by c_doc_no,c_tray_no,c_tray_name,rack_grp_code,rack_grp_name,curr_user
          order by "n_completed" desc for xml raw,elements
      else
        if(select "count"() from "st_track_tray_move" as "tm" where "c_tray_code" = @DetData) > 0 then
          select top 1 "tm"."c_tray_code" as "c_tray_no",
            (select(if "n_in_out_flag" = 1 then 'INTERNAL' else(if "n_in_out_flag" = 0 then 'EXTERNAL' else(if "n_in_out_flag" = 2 then 'INTERNAL/EXTERNAL' else 'TEMPORARY TRAY' endif) endif) endif) from "st_tray_mst" where "c_code" = "tm"."c_tray_code") as "c_tray_type",
            (select "list"("c_rack_grp_code") from "st_track_tray_move" where "c_tray_code" = "tm"."c_tray_code") as "rack_grp_code",
            --,(select c_name from rack_group_mst where c_code = tm.c_rack_grp_code) as rack_grp_name
            "isnull"("tm"."c_user",'') as "curr_user",
            (if "tm"."n_inout" = 9 then 1 else 0 endif) as "n_completed",
            "tm"."c_doc_no" as "c_doc_no",
            "tm"."c_stage_code" as "c_stage_code"
            from "st_track_tray_move" as "tm"
            where "tm"."c_tray_code" = @DetData
            --group by c_doc_no,c_tray_no,c_tray_name,rack_grp_code,rack_grp_name,curr_user
            order by "n_completed" desc for xml raw,elements
        else
          select top 1 "tm"."c_tray_code" as "c_tray_no",
            (select(if "n_in_out_flag" = 1 then 'INTERNAL' else(if "n_in_out_flag" = 0 then 'EXTERNAL' else(if "n_in_out_flag" = 2 then 'INTERNAL/EXTERNAL' else 'TEMPORARY TRAY' endif) endif) endif) from "st_tray_mst" where "c_code" = "tm"."c_tray_code") as "c_tray_type",
            "list"(distinct "c_rack_grp_code") as "rack_grp_code",
            --,(select c_name from rack_group_mst where c_code = tm.c_rack_grp_code) as rack_grp_name
            "isnull"("tm"."c_user",'') as "curr_user",
            "tm"."n_complete" as "n_completed",
            "tm"."c_doc_no" as "c_doc_no",
            "tm"."c_stage_code" as "c_stage_code"
            from "st_track_det" as "tm"
            where "tm"."c_tray_code" = @DetData and "n_complete" = 0
            group by "c_doc_no","c_tray_no","c_tray_type","curr_user","c_stage_code","n_completed"
            order by "n_completed" desc for xml raw,elements
        end if end if end if when 'route_mst' then
    select "c_name",
      "c_code",
      "n_route_no"
      from "route_mst" for xml raw,elements
  when 'get_doc_tray_list' then
    --http://192.168.7.12:14109/ws_st_tray_pickup?GodownCode=-devID=devID&sKey=KEY&UserId=MYBOSS&PhaseCode=PH0003&RackGrpCode=&StageCode=&cIndex=get_doc_tray_list&HdrData=109**14**S**146127**&DetData=
    --@HdrData  : 1 Tranbrcode~2 TranYear~3 TranPrefix~4 TranSrno
    --1 Tranbrcode
    if(select "count"() from "block_api") = 1 then
      select "Locate"(@HdrData,@ColSep) into @ColPos;
      set @Tranbrcode = "Trim"("Left"(@HdrData,@ColPos-1));
      set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
      --message 'Tranbrcode '+@Tranbrcode type warning to client;
      --2 TranYear
      select "Locate"(@HdrData,@ColSep) into @ColPos;
      set @TranYear = "Trim"("Left"(@HdrData,@ColPos-1));
      set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
      --message 'TranYear '+@TranYear type warning to client;	
      --3 TranPrefix
      select "Locate"(@HdrData,@ColSep) into @ColPos;
      set @TranPrefix = "Trim"("Left"(@HdrData,@ColPos-1));
      set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
      --message 'TranPrefix '+@TranPrefix type warning to client;		
      --4 TranSrno
      select "Locate"(@HdrData,@ColSep) into @ColPos;
      set @TranSrno = "Trim"("Left"(@HdrData,@ColPos-1));
      set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
      --message 'TranSrno '+string(@TranSrno ) type warning to client;			
      set @DocNo = @Tranbrcode+'/'+@TranYear+'/'+@TranPrefix+'/'+"string"(@TranSrno);
      select "tray_move"."c_doc_no" as "c_doc_no",
        "cust"."c_code" as "c_cust_code",
        "cust"."c_name" as "c_cust_name",
        "area_mst"."c_name" as "c_area_name",
        (select "count"(distinct "c_tray_code") from "st_track_tray_move" where "c_doc_no" = "tray_move"."c_doc_no") as "n_total_trays", -- excluding Unassigned trays
        (if "tray_move"."n_inout" = 9 then 1 else 0 endif) as "n_completed",
        "tray_move"."c_tray_code" as "c_tray",
        "region_mst"."c_name" as "c_region_name",
        "zone_mst"."c_name" as "c_zone_name",
        (select "c_name"+'['+"c_code"+']' as "c_stage" from "st_store_stage_mst" where "c_code" = "tray_move"."c_stage_code") as "c_stage",
        (if "st_track_mst"."n_complete" = 9 then 1 else 0 endif) as "n_packing_completed"
        from "st_track_tray_move" as "tray_move"
          join "st_track_mst" on "tray_move"."c_doc_no" = "st_track_mst"."c_doc_no" --AND st_track_mst.n_complete <> 9
          join "act_mst" as "cust" on "cust"."c_code" = "isnull"("st_track_mst"."c_cust_code",'GC01')
          join "area_mst" on "area_mst"."c_code" = "cust"."c_area_code"
          join "region_mst" on "area_mst"."c_region_code" = "region_mst"."c_code"
          join "zone_mst" on "zone_mst"."c_code" = "region_mst"."c_zone_code"
        where "st_track_mst"."c_doc_no" = @DocNo
        and "tray_move"."c_godown_code" = @GodownCode for xml raw,elements
    end if when 'get_route' then
    update "st_track_tray_move" set "n_flag" = 4,"t_time" = "now"()
      where "c_tray_code" = @HdrData;
    commit work;
    select "isnull"("route_mst"."n_route_no",0) as "n_route_no"
      from "st_track_mst"
        join "st_track_tray_move" as "tray_move" on "tray_move"."c_doc_no" = "st_track_mst"."c_doc_no" and "c_tray_code" = @HdrData --TrayCode			
        left outer join "act_route" as "route" on "route"."c_code" = "st_track_mst"."c_br_code" and "route"."c_br_code" = "st_track_mst"."c_cust_code"
        left outer join "route_mst" on "isnull"("route"."c_route_code",'-') = "route_mst"."c_code" for xml raw,elements
  when 'storein_tray_status' then
    --http://192.168.250.162:14153/ws_st_tray_pickup?GodownCode=-&devID=devID&sKey=KEY&UserId=MYBOSS&PhaseCode=PH0003&RackGrpCode=&StageCode=&cIndex=storein_tray_status&HdrData=&DetData=
    if(select "count"() from "block_api") = 0 then
      select distinct "c_doc_no",
        "c_tray_code",
        "c_stage_code",
        "n_tray_age",
        "c_stin_ref_no"
        from(select "st_track_det"."c_doc_no" as "c_doc_no",
            "st_track_det"."c_tray_code" as "c_tray_code",
            "st_track_det"."c_stage_code" as "c_stage_code",
            "abs"("max"("isnull"("DATEDIFF"("day","isnull"("item_receipt_entry"."d_posted_date","st_inward_track"."d_store_in_done_date"),"uf_default_date"()),0))) as "n_tray_age",
            if("left"("substr"("substring"("left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))),"charindex"('/',"left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))))+1),"charindex"('/',"substring"("left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))),"charindex"('/',"left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))))+1))+1),"charindex"('/',"substr"("substring"("left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))),"charindex"('/',"left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))))+1),"charindex"('/',"substring"("left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))),"charindex"('/',"left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))))+1))+1))-1)) = '162' then 1 else 0 endif as "c_stin_ref_no"
            from "st_track_det"
              left outer join "st_track_tray_move" as "tray_move" on "tray_move"."c_doc_no" = "st_track_det"."c_doc_no"
              left outer join "item_receipt_entry" on "item_receipt_entry"."c_pur_br_code" = "left"(("c_stin_ref_no"),"charindex"('/',("c_stin_ref_no"))-1)
              and "item_receipt_entry"."c_pur_year" = "left"("substring"("left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))),"charindex"('/',"left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))))+1),"charindex"('/',"substring"("left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))),"charindex"('/',"left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))))+1))-1)
              and "item_receipt_entry"."c_pur_prefix" = "left"("substr"("substring"("left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))),"charindex"('/',"left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))))+1),"charindex"('/',"substring"("left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))),"charindex"('/',"left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))))+1))+1),"charindex"('/',"substr"("substring"("left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))),"charindex"('/',"left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))))+1),"charindex"('/',"substring"("left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))),"charindex"('/',"left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))))+1))+1))-1)
              and "item_receipt_entry"."n_pur_srno" = "reverse"("left"("substring"("left"("reverse"("c_stin_ref_no"),("length"("reverse"("c_stin_ref_no"))-("charindex"('/',"reverse"("reverse"("c_stin_ref_no")))-1))),"charindex"('/',"left"("reverse"("c_stin_ref_no"),("length"("reverse"("c_stin_ref_no"))-("charindex"('/',"reverse"("reverse"("c_stin_ref_no")))-1))))+1),"charindex"('/',"substring"("left"("reverse"("c_stin_ref_no"),("length"("reverse"("c_stin_ref_no"))-("charindex"('/',"reverse"("reverse"("c_stin_ref_no")))-1))),"charindex"('/',"left"("reverse"("c_stin_ref_no"),("length"("reverse"("c_stin_ref_no"))-("charindex"('/',"reverse"("reverse"("c_stin_ref_no")))-1))))+1))-1))
              and "item_receipt_entry"."n_pur_seq" = "reverse"("left"("reverse"("c_stin_ref_no"),"charindex"('/',("reverse"("c_stin_ref_no")))-1))
              left outer join "st_inward_track" on "st_inward_track"."c_br_code" = "left"(("c_stin_ref_no"),"charindex"('/',("c_stin_ref_no"))-1)
              and "st_inward_track"."c_year" = "left"("substring"("left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))),"charindex"('/',"left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))))+1),"charindex"('/',"substring"("left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))),"charindex"('/',"left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))))+1))-1)
              and "st_inward_track"."c_prefix" = "left"("substr"("substring"("left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))),"charindex"('/',"left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))))+1),"charindex"('/',"substring"("left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))),"charindex"('/',"left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))))+1))+1),"charindex"('/',"substr"("substring"("left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))),"charindex"('/',"left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))))+1),"charindex"('/',"substring"("left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))),"charindex"('/',"left"("c_stin_ref_no",("length"("c_stin_ref_no")-("charindex"('/',"reverse"("c_stin_ref_no"))-1))))+1))+1))-1)
              and "st_inward_track"."n_srno" = "reverse"("left"("substring"("left"("reverse"("c_stin_ref_no"),("length"("reverse"("c_stin_ref_no"))-("charindex"('/',"reverse"("reverse"("c_stin_ref_no")))-1))),"charindex"('/',"left"("reverse"("c_stin_ref_no"),("length"("reverse"("c_stin_ref_no"))-("charindex"('/',"reverse"("reverse"("c_stin_ref_no")))-1))))+1),"charindex"('/',"substring"("left"("reverse"("c_stin_ref_no"),("length"("reverse"("c_stin_ref_no"))-("charindex"('/',"reverse"("reverse"("c_stin_ref_no")))-1))),"charindex"('/',"left"("reverse"("c_stin_ref_no"),("length"("reverse"("c_stin_ref_no"))-("charindex"('/',"reverse"("reverse"("c_stin_ref_no")))-1))))+1))-1))
              and "st_inward_track"."n_seq" = "reverse"("left"("reverse"("c_stin_ref_no"),"charindex"('/',("reverse"("c_stin_ref_no")))-1))
            where "isnull"("st_track_det"."c_godown_code",'-') = '-'
            and "st_track_det"."n_inout" = 1
            and "st_track_det"."n_complete" not in( 8,2 ) 
            group by "c_doc_no","c_tray_code","c_stage_code","c_stin_ref_no") as "store_in_trays"
        order by "c_stage_code" asc for xml raw,elements
    end if when 'set_counter' then
    --@HdrData  : 1 DocNo~4 TranSrno
    --1 DocNo
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @DocNo = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --message 'DocNo '+@DocNo type warning to client;
    --2 Counter
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @Counter = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --message 'Counter '+string(@Counter ) type warning to client;
    --set @DocNo = @Tranbrcode+'/'+@TranYear+'/'+@TranPrefix+'/'+string(@TranSrno);
    if(select "count"("c_doc_no") from "st_track_mst" where "c_doc_no" = @DocNo) > 0 then
      update "st_track_mst" set "c_system_name" = @Counter where "c_doc_no" = @DocNo;
      commit work;
      select 'Success' as "c_message" for xml raw,elements
    else
      select 'Warning!! : Invalid Doc No.' as "c_message" for xml raw,elements
    end if when 'get_tray_items' then
    if(select "count"() from "block_api") = 0 then
      --@HdrData : Tray 
      --@DetData : Carton flag (0/1)
      set @Tray = @HdrData;
      set @nCarton = @DetData;
      if(select "count"("c_code") from "st_tray_mst" where "c_code" = @Tray and "n_cancel_flag" = 0) = 0 and @nCarton = 0 then
        select 'Invalid Tray!!' as "c_message" for xml raw,elements;
        return
      else
        if @nCarton = 1 then
          set @nTrayType = 0
        else
          select "n_in_out_flag" -- 1- internal , 0 - external, 2 - temporary
            into @nTrayType from "st_tray_mst" where "c_code" = @Tray
        end if;
        if @nTrayType = 0 then --external tray
          if @nCarton = 1 then --CARTON
            select top 1 "c_br_code"+'/'+"c_year"+'/'+"c_prefix"+'/'+"string"("n_srno") as "c_doc_no"
              into @DocNo from "carton_mst" where "n_carton_no" <> 0 order by "t_ltime" desc;
            select "c_br_code"+'/'+"c_year"+'/'+"c_prefix"+'/'+"string"("n_srno") as "c_doc_no",
              "c_item_code" as "c_item_code",
              "c_batch_no" as "c_batch_no",
              "n_qty" as "n_qty",
              "n_qty_per_box" as "n_qty_per_box",
              "item_mst"."c_name"+"uf_st_get_pack_name"("pack_mst"."c_name") as "c_item_name",
              'CARTON' as "c_tray_type"
              from "carton_mst"
                join "item_mst" on "c_item_code" = "item_mst"."c_code"
                join "pack_mst" on "pack_mst"."c_code" = "item_mst"."c_pack_code"
              where "n_carton_no" = @Tray
              and "c_br_code" = "left"((@DocNo),"charindex"('/',(@DocNo))-1)
              and "c_year" = "left"("substring"("left"(@DocNo,("length"(@DocNo)-("charindex"('/',"reverse"(@DocNo))-1))),"charindex"('/',"left"(@DocNo,("length"(@DocNo)-("charindex"('/',"reverse"(@DocNo))-1))))+1),"charindex"('/',"substring"("left"(@DocNo,("length"(@DocNo)-("charindex"('/',"reverse"(@DocNo))-1))),"charindex"('/',"left"(@DocNo,("length"(@DocNo)-("charindex"('/',"reverse"(@DocNo))-1))))+1))-1)
              and "c_prefix" = "reverse"("left"("reverse"(@DocNo),"charindex"('/',("reverse"(@DocNo)))-1))
              and "n_srno" = "left"("substr"("substring"("left"(@DocNo,("length"(@DocNo)-("charindex"('/',"reverse"(@DocNo))-1))),"charindex"('/',"left"(@DocNo,("length"(@DocNo)-("charindex"('/',"reverse"(@DocNo))-1))))+1),"charindex"('/',"substring"("left"(@DocNo,("length"(@DocNo)-("charindex"('/',"reverse"(@DocNo))-1))),"charindex"('/',"left"(@DocNo,("length"(@DocNo)-("charindex"('/',"reverse"(@DocNo))-1))))+1))+1),"charindex"('/',"substr"("substring"("left"(@DocNo,("length"(@DocNo)-("charindex"('/',"reverse"(@DocNo))-1))),"charindex"('/',"left"(@DocNo,("length"(@DocNo)-("charindex"('/',"reverse"(@DocNo))-1))))+1),"charindex"('/',"substring"("left"(@DocNo,("length"(@DocNo)-("charindex"('/',"reverse"(@DocNo))-1))),"charindex"('/',"left"(@DocNo,("length"(@DocNo)-("charindex"('/',"reverse"(@DocNo))-1))))+1))+1))-1) for xml raw,elements
          else
            -- EXTERNAL TRAY
            select top 1 "c_br_code"+'/'+"c_year"+'/'+"c_prefix"+'/'+"string"("n_srno") as "c_doc_no"
              into @DocNo from "carton_mst" order by "t_ltime" desc;
            select "c_br_code"+'/'+"c_year"+'/'+"c_prefix"+'/'+"string"("n_srno") as "c_doc_no",
              "c_item_code" as "c_item_code",
              "c_batch_no" as "c_batch_no",
              "n_qty" as "n_qty",
              "n_qty_per_box" as "n_qty_per_box",
              "item_mst"."c_name"+"uf_st_get_pack_name"("pack_mst"."c_name") as "c_item_name",
              'EXTERNAL' as "c_tray_type"
              from "carton_mst"
                join "item_mst" on "c_item_code" = "item_mst"."c_code"
                join "pack_mst" on "pack_mst"."c_code" = "item_mst"."c_pack_code"
              where "c_tray_code" = @Tray
              and "c_br_code" = "left"((@DocNo),"charindex"('/',(@DocNo))-1)
              and "c_year" = "left"("substring"("left"(@DocNo,("length"(@DocNo)-("charindex"('/',"reverse"(@DocNo))-1))),"charindex"('/',"left"(@DocNo,("length"(@DocNo)-("charindex"('/',"reverse"(@DocNo))-1))))+1),"charindex"('/',"substring"("left"(@DocNo,("length"(@DocNo)-("charindex"('/',"reverse"(@DocNo))-1))),"charindex"('/',"left"(@DocNo,("length"(@DocNo)-("charindex"('/',"reverse"(@DocNo))-1))))+1))-1)
              and "c_prefix" = "reverse"("left"("reverse"(@DocNo),"charindex"('/',("reverse"(@DocNo)))-1))
              and "n_srno" = "left"("substr"("substring"("left"(@DocNo,("length"(@DocNo)-("charindex"('/',"reverse"(@DocNo))-1))),"charindex"('/',"left"(@DocNo,("length"(@DocNo)-("charindex"('/',"reverse"(@DocNo))-1))))+1),"charindex"('/',"substring"("left"(@DocNo,("length"(@DocNo)-("charindex"('/',"reverse"(@DocNo))-1))),"charindex"('/',"left"(@DocNo,("length"(@DocNo)-("charindex"('/',"reverse"(@DocNo))-1))))+1))+1),"charindex"('/',"substr"("substring"("left"(@DocNo,("length"(@DocNo)-("charindex"('/',"reverse"(@DocNo))-1))),"charindex"('/',"left"(@DocNo,("length"(@DocNo)-("charindex"('/',"reverse"(@DocNo))-1))))+1),"charindex"('/',"substring"("left"(@DocNo,("length"(@DocNo)-("charindex"('/',"reverse"(@DocNo))-1))),"charindex"('/',"left"(@DocNo,("length"(@DocNo)-("charindex"('/',"reverse"(@DocNo))-1))))+1))+1))-1) for xml raw,elements
          --internal  tray
          end if
        else select top 1 "c_doc_no"
            into @DocNo from "st_track_tray_move" where "c_tray_code" = @Tray;
          --print(@DocNo);
          select top 1 "n_inout"
            into @nInOutFlag from "st_track_tray_move" where "c_tray_code" = @Tray;
          if @nInOutFlag is null and(select "count"() from "st_track_in" where "c_tray_code" = @Tray) > 0 then
            set @nInOutFlag = 1
          end if;
          select "count"("c_doc_no")
            into @nPickCount from "st_track_pick" where "c_doc_no" = @DocNo and "c_tray_code" = @Tray;
          if @nPickCount = 0 and @nInOutFlag = 1 then --store in tray
            if @DocNo is null then
              select "st_track_in"."c_doc_no" as "c_doc_no",
                1 as "n_inout",
                "item_mst"."c_code" as "c_item_code",
                "isnull"("st_track_in"."c_batch_no",'') as "c_batch_no",
                "st_track_in"."n_seq" as "n_seq",
                "TRIM"("STR"("TRUNCNUM"("st_track_in"."n_qty",3),10,0)) as "n_qty",
                "TRIM"("STR"("TRUNCNUM"("st_track_in"."n_qty",3),10,0)) as "n_bal_qty",
                "st_track_in"."c_rack_code" as "c_rack",
                "st_track_in"."c_rack_grp_code" as "c_rack_grp_code",
                (select "max"("c_stage_code") from "st_store_stage_det" where "c_rack_grp_code" = "c_rack_grp_code") as "c_stage_code",
                0 as "n_completed",
                "st_track_in"."c_tray_code" as "c_tray_code",
                "item_mst"."c_name"+"uf_st_get_pack_name"("pack_mst"."c_name") as "c_item_name",
                '' as "d_exp_dt",
                0 as "n_mrp",
                "item_mst"."n_qty_per_box" as "n_qty_per_box",
                '' as "c_message",
                '' as "c_mov_user",
                "st_track_in"."c_user" as "c_picked_user",
                'INTERNAL' as "c_tray_type"
                from "st_track_in"
                  join "item_mst" on "st_track_in"."c_item_code" = "item_mst"."c_code"
                  join "pack_mst" on "pack_mst"."c_code" = "item_mst"."c_pack_code"
                where "st_track_in"."c_tray_code" = @Tray
                --and st_track_in.n_complete = 0 
                order by "c_rack" asc for xml raw,elements
            else
              select "st_track_det"."c_doc_no" as "c_doc_no",
                "st_track_det"."n_inout" as "n_inout",
                "item_mst"."c_code" as "c_item_code",
                "isnull"("st_track_det"."c_batch_no",'') as "c_batch_no",
                "st_track_det"."n_seq" as "n_seq",
                "TRIM"("STR"("TRUNCNUM"("st_track_det"."n_qty",3),10,0)) as "n_qty",
                "TRIM"("STR"("TRUNCNUM"("st_track_det"."n_bal_qty",3),10,0)) as "n_bal_qty",
                "st_track_det"."c_rack" as "c_rack",
                "st_track_det"."c_rack_grp_code" as "c_rack_grp_code",
                "st_track_det"."c_stage_code" as "c_stage_code",
                0 as "n_completed",
                "st_track_det"."c_tray_code" as "c_tray_code",
                "item_mst"."c_name"+"uf_st_get_pack_name"("pack_mst"."c_name") as "c_item_name",
                '' as "d_exp_dt",
                0 as "n_mrp",
                "item_mst"."n_qty_per_box" as "n_qty_per_box",
                '' as "c_message",
                '' as "c_mov_user",
                "st_track_det"."c_user" as "c_picked_user",
                'INTERNAL' as "c_tray_type"
                from "st_track_det"
                  join "item_mst" on "st_track_det"."c_item_code" = "item_mst"."c_code"
                  join "pack_mst" on "pack_mst"."c_code" = "item_mst"."c_pack_code"
                where "st_track_det"."c_doc_no" = @DocNo
                and "st_track_det"."c_tray_code" = @Tray
                --and st_track_det.n_complete = 0 
                order by "c_rack" asc for xml raw,elements
            --store out tray 
            end if
          elseif @nPickCount > 0 then
            select "st_track_pick"."c_doc_no" as "c_doc_no",
              "st_track_pick"."n_inout" as "n_inout",
              "item_mst"."c_code" as "c_item_code",
              "isnull"("st_track_pick"."c_batch_no",'') as "c_batch_no",
              "st_track_pick"."n_seq" as "n_seq",
              "TRIM"("STR"("TRUNCNUM"("st_track_pick"."n_qty",3),10,0)) as "n_qty",
              "st_track_pick"."c_rack" as "c_rack",
              "st_track_pick"."c_rack_grp_code" as "c_rack_grp_code",
              "st_track_pick"."c_stage_code" as "c_stage_code",
              (if "tray_move"."n_inout" = 9 then 1 else 0 endif) as "n_completed",
              "st_track_pick"."c_tray_code" as "c_tray_code",
              "item_mst"."c_name"+"uf_st_get_pack_name"("pack_mst"."c_name") as "c_item_name",
              "date"("isnull"("stock_mst"."d_exp_dt",'')) as "d_exp_dt",
              "TRIM"("STR"("TRUNCNUM"("stock_mst"."n_mrp",3),10,3)) as "n_mrp",
              "item_mst"."n_qty_per_box" as "n_qty_per_box",
              '' as "c_message",
              "tray_move"."c_user" as "c_mov_user",
              "st_track_pick"."c_user" as "c_picked_user",
              'INTERNAL' as "c_tray_type"
              from "st_track_pick"
                join "item_mst" on "st_track_pick"."c_item_code" = "item_mst"."c_code"
                join "pack_mst" on "pack_mst"."c_code" = "item_mst"."c_pack_code"
                join "stock_mst" on "st_track_pick"."c_item_code" = "stock_mst"."c_item_code"
                and "st_track_pick"."c_batch_no" = "stock_mst"."c_batch_no"
                join "st_track_tray_move" as "tray_move"
                on "tray_move"."c_tray_code" = "st_track_pick"."c_tray_code"
                and "tray_move"."c_doc_no" = "st_track_pick"."c_doc_no"
                //and "tray_move"."c_stage_code" = "st_track_pick"."c_stage_code" --commented to show the different stage items after tray merge Dt: 02-01-20
                ,"item_mst"
              where "st_track_pick"."c_doc_no" = @DocNo
              and "st_track_pick"."c_tray_code" = @Tray
              order by "c_rack" asc for xml raw,elements
          else
            select 'No items are confirmed for the tray : '+@Tray as "c_message" for xml raw,elements
          end if end if end if end if when 'assign_to_counter' then
    set "i" = 1;
    while "HTTP_VARIABLE"('HdrData',"i") is not null or "HTTP_VARIABLE"('HdrData',"i") <> '' loop
      set @Tray = "HTTP_VARIABLE"('HdrData',"i");
      set @nState = "HTTP_VARIABLE"('nState',"i");
      update "st_track_tray_move"
        set "n_flag" = @nState,
        "t_time" = "now"(),
        "c_user" = @UserId
        where "c_tray_code" = @Tray;
      set "i" = "i"+1
    end loop;
    if sqlstate = '00000' then
      commit work;
      select 'SUCCESS' as "c_message" for xml raw,elements
    else
      rollback work;
      select 'FAILURE' as "c_message" for xml raw,elements
    end if when 'pack_tray_status' then
    if(select "count"() from "block_api") = 0 then
      select distinct "carton_mst"."c_br_code"+'/'+"carton_mst"."c_year"+'/'+"carton_mst"."c_prefix"+'/'+"trim"("str"("carton_mst"."n_srno")) as "doc_no",
        "tran_mst"."cust_code" as "customer_code",
        "act_mst"."c_name" as "cust_name",
        "act_mst"."c_area_code" as "area_code",
        "area_mst"."c_name" as "area_name",
        "act_route"."c_route_code" as "route_code",
        "route_mst"."c_name" as "route_name",
        "count"("carton_mst"."c_item_code") as "item_count","carton_mst"."c_tray_code","carton_mst"."n_carton_no",
        if("delivery_slip"."ds_br_code"+'/'+"delivery_slip"."ds_year"+'/'+"delivery_slip"."ds_prefix"+'/'+"trim"("str"("delivery_slip"."ds_srno"))) = '///' then ''
        else "delivery_slip"."ds_br_code"+'/'+"delivery_slip"."ds_year"+'/'+"delivery_slip"."ds_prefix"+'/'+"trim"("str"("delivery_slip"."ds_srno"))
        endif as "delivery_doc_no","delivery_slip"."dman_code" as "dman_code",
        "delivery_slip"."dman_name" as "dman_name",
        "delivery_slip"."sman_code" as "sman_code",
        "delivery_slip"."transport_name" as "transport_name",
        "delivery_slip"."lr_no" as "lr_no",
        if "delivery_doc_no" is null or "delivery_doc_no" = '' then 'PACKING COMPLETED'
        else 'DELIVERY SLIP GENERATED'
        endif as "c_delivery_status" from "carton_mst"
          join(select "inv_mst"."c_br_code","inv_mst"."c_year","inv_mst"."c_prefix","inv_mst"."n_srno","inv_mst"."c_cust_code" as "cust_code" from "inv_mst"
            where "inv_mst"."d_date" = "uf_default_date"() union all
          select "gdn_mst"."c_br_code","gdn_mst"."c_year","gdn_mst"."c_prefix","gdn_mst"."n_srno","gdn_mst"."c_ref_br_code" as "cust_code" from "gdn_mst"
            where "gdn_mst"."d_date" = "uf_default_date"()) as "tran_mst" on "tran_mst"."c_br_code" = "carton_mst"."c_br_code"
          and "tran_mst"."c_year" = "carton_mst"."c_year"
          and "tran_mst"."c_prefix" = "carton_mst"."c_prefix"
          and "tran_mst"."n_srno" = "carton_mst"."n_srno"
          left outer join(select "slip_det"."c_br_code" as "ds_br_code","slip_det"."c_year" as "ds_year","slip_det"."c_prefix" as "ds_prefix","slip_det"."n_srno" as "ds_srno",
            "slip_det"."c_inv_br" as "trans_br","slip_det"."c_inv_year" as "trans_year","slip_det"."c_inv_prefix" as "trans_preifx","slip_det"."n_inv_no" as "trans_srno",
            "slip_det"."c_cust_code" as "custo_code","slip_mst"."c_dman_code" as "dman_code","delivery_mst"."c_name" as "dman_name","slip_mst"."c_sman_code" as "sman_code",
            "slip_mst"."c_transport" as "transport_code","transport_mst"."c_name" as "transport_name","slip_mst"."c_lr_no" as "lr_no"
            from "slip_det"
              join "slip_mst" on "slip_mst"."c_br_code" = "slip_det"."c_br_code"
              and "slip_mst"."c_year" = "slip_det"."c_year"
              and "slip_det"."c_prefix" = "slip_mst"."c_prefix"
              and "slip_mst"."n_srno" = "slip_det"."n_srno"
              left outer join "delivery_mst" on "delivery_mst"."c_code" = "slip_mst"."c_dman_code"
              left outer join "transport_mst" on "transport_mst"."c_code" = "slip_mst"."c_transport"
            where "slip_det"."d_date" = "uf_default_date"()) as "delivery_slip" on "delivery_slip"."trans_br" = "carton_mst"."c_br_code"
          and "delivery_slip"."trans_year" = "carton_mst"."c_year"
          and "delivery_slip"."trans_preifx" = "carton_mst"."c_prefix"
          and "delivery_slip"."trans_srno" = "carton_mst"."n_srno"
          left outer join "act_mst" on "act_mst"."c_code" = "tran_mst"."cust_code"
          left outer join "act_route" on "act_route"."c_br_code" = "tran_mst"."cust_code" and "act_route"."c_code" = "tran_mst"."c_br_code"
          left outer join "route_mst" on "route_mst"."c_code" = "act_route"."c_route_code"
          left outer join "area_mst" on "area_mst"."c_code" = "act_mst"."c_area_code"
        where "carton_mst"."d_ldate" = "uf_default_date"()
        group by "carton_mst"."c_tray_code","carton_mst"."n_carton_no","doc_no",
        "cust_code","act_mst"."c_name","act_route"."c_route_code","route_mst"."c_name","act_mst"."c_area_code","area_mst"."c_name",
        "dman_code","sman_code","transport_name","lr_no","delivery_doc_no","c_delivery_status","dman_name" for xml raw,elements
    end if
  end case
end;