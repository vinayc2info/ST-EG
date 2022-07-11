CREATE PROCEDURE "DBA"."usp_st_dispatch_area_dash_board"( 
  in @gsBr char(6), --1
  in @devID char(200), --2
  in @sKey char(20), --3
  in @UserId char(20), --4
  in @cIndex char(30), --5
  in @GodownCode char(6), --6
  in @HdrData char(7000) )  --7
result( "is_xml_string" xml ) 
begin
  /*
Author 		: Saneesh C G
Procedure	: usp_st_dispatch_area_dash_board
SERVICE		: ws_st_dispatch_area_dash_board
Date 		: 15-07-2015
modified by : Saneesh C G 
Ldate 		: 15-07-2015
Purpose		: Dispatch Area Dashboard
Input		: gsBr~devID~sKey~UserId~cIndex~GodownCode~HdrData
call usp_st_dispatch_area_dash_board()
Service Call (Format): 
http://192.168.1.69:15503/ws_st_dispatch_area_dash_board?devID=devID&sKey=KEY&UserId=MYBOSS&cIndex=get_data
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
  //  declare local temporary table "uas_list"(
  //    "c_stage_code" char(6) null,
  //    "c_doc_no" char(50) null,
  //    "c_cust_code" char(6) null,
  //    "c_cust_name" char(100) null,
  //    "n_completed" numeric(6) null,
  //    "c_tray" char(50) null,
  //    "c_route" char(50) null,
  //    "c_route_code" char(6) null,) on commit preserve rows;
  //  declare local temporary table "packing_done"(
  //    "c_tray" char(6) null,
  //    "c_doc_no" char(50) null,
  //    "c_cust_code" char(6) null,
  //    "c_cust_name" char(100) null,
  //    "n_completed" numeric(6) null,
  //    "c_route" char(50) null,
  //    "c_route_code" char(6) null,
  //    "n_tray_state" numeric(6) null,
  //    ) on commit preserve rows;
  if @devID = '' or @devID is null then
    set @gsBr = "http_variable"('gsBr'); --1
    set @devID = "http_variable"('devID'); --2
    set @sKey = "http_variable"('sKey'); --3
    set @UserId = "http_variable"('UserId'); --4
    set @cIndex = "http_variable"('cIndex'); --5
    set @GodownCode = "http_variable"('GodownCode'); --6
    set @HdrData = "http_variable"('HdrData') --7
  end if;
  /*insert into "API_LOG"
( "c_api_name","c_index","t_start_time","c_remark","c_note","c_user","n_n1" ) values
( 'usp_st_dispatch_area_dash_board',@cIndex,"GETDATE"(),@HdrData,@devID,@UserId,"connection_property"('NUMBER') ) ;
commit work;
*/
  select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
  select "c_delim" into @RowSep from "ps_tab_delimiter" where "n_seq" = 1;
  set @ColMaxLen = "Length"(@ColSep);
  set @RowMaxLen = "Length"(@RowSep);
  set @GodownCode = '-';
  set @BrCode = "uf_get_br_code"(@gsBr);
  set @t_ltime = "left"("now"(),19);
  set @d_ldate = "uf_default_date"();
  //      if(select "count"() from "block_api") >= 1 then
  //        return
  //      end if;
  --select 'sani ' as a for xml raw,elements  ;
  case @cIndex
  when 'get_data' then
    --insert into Serv_log  (c_name,t_ltime) values('start ',now());
    //        insert into "uas_list"
    //          select distinct "st_track_det"."c_stage_code" as "c_stage_code",
    //            "st_track_mst"."c_doc_no" as "c_doc_no",
    //            "cust"."c_code" as "c_cust_code",
    //            "cust"."c_name" as "c_cust_name",
    //            0 as "n_completed",
    //            'UA-'+"isnull"("c_stage_code",'NULL') as "c_tray",
    //            ("route_mst"."c_name") as "c_route",
    //            "route_mst"."c_code" as "c_route_code"
    //            from "st_track_mst"
    //              join "DBA"."st_track_det" on "st_track_det"."c_doc_no" = "st_track_mst"."c_doc_no" and "st_track_det"."n_inout" = "st_track_mst"."n_inout"
    //              join "act_mst" as "cust" on "cust"."c_code" = "isnull"("st_track_mst"."c_cust_code",'GC01')
    //              left outer join "st_track_tray_move" as "tray_move" on "tray_move"."c_doc_no" = "st_track_mst"."c_doc_no"
    //              left outer join "act_route" as "route" on "route"."c_br_code" = "st_track_mst"."c_cust_code" and "route"."c_code" = "st_track_mst"."c_br_code"
    //              left outer join "route_mst" on "isnull"("route"."c_route_code",'-') = "route_mst"."c_code"
    //            where "st_track_det"."c_tray_code" is null
    //            and "isnull"("st_track_det"."c_godown_code",'-') = '-'
    //            and "st_track_mst"."n_confirm" = 1
    //            and "st_track_mst"."n_inout" not in( 1,8 ) ;
    //        insert into "packing_done"
    //          select distinct "st_track_pick"."c_tray_code" as "c_tray",
    //            "st_track_pick"."c_doc_no" as "c_doc_no",
    //            "cust"."c_code" as "c_cust_code",
    //            "cust"."c_name" as "c_cust_name",
    //            2 as "n_completed",
    //            "isnull"("route_mst"."c_name",'') as "c_route",
    //            "route_mst"."c_code" as "c_route_code",
    //            0 as "n_tray_state"
    //            from "DBA"."st_track_pick" left outer join "st_track_complete_date" on "st_track_pick"."c_doc_no" = "st_track_complete_date"."c_doc_no"
    //              and "st_track_pick"."c_tray_code" = "st_track_complete_date"."c_tray_code"
    //              join "st_track_mst" on "st_track_pick"."c_doc_no" = "st_track_mst"."c_doc_no" and "st_track_pick"."n_inout" = "st_track_mst"."n_inout"
    //              join "act_mst" as "cust" on "cust"."c_code" = "isnull"("st_track_mst"."c_cust_code",'GC01')
    //              left outer join "act_route" as "route" on "route"."c_br_code" = "st_track_mst"."c_cust_code" and "route"."c_code" = "st_track_mst"."c_br_code"
    //              left outer join "route_mst" on "isnull"("route"."c_route_code",'-') = "route_mst"."c_code"
    //            where "date"("isnull"("st_track_complete_date"."t_time","st_track_pick"."t_time")) = "DBA"."uf_default_date"()
    //            and "isnull"("n_confirm_qty",0)+"isnull"("n_reject_qty",0) > 0;
    ------------------------------------------------------------------------
    //        select "tray_move"."c_doc_no" as "c_doc_no",
    //          "cust"."c_code" as "c_cust_code",
    //          "cust"."c_name" as "c_cust_name",
    //          (if "tray_move"."n_inout" = 9 then 1 else 0 endif) as "n_completed",
    //          "tray_move"."c_tray_code" as "c_tray",
    //          "route_mst"."c_code" as "c_route_code",
    //          "isnull"("route_mst"."c_name",'') as "c_route_name",
    //          "tray_move"."n_flag" as "n_tray_state"
    //          from "st_track_tray_move" as "tray_move"
    //            join "st_track_mst" on "tray_move"."c_doc_no" = "st_track_mst"."c_doc_no" --AND st_track_mst.n_complete <> 9
    //            join "act_mst" as "cust" on "cust"."c_code" = "isnull"("st_track_mst"."c_cust_code",'GC01')
    //            left outer join "act_route" as "route" on "route"."c_br_code" = "st_track_mst"."c_cust_code" and "route"."c_code" = "st_track_mst"."c_br_code"
    //            left outer join "route_mst" on "isnull"("route"."c_route_code",'-') = "route_mst"."c_code"
    //          where "isnull"("tray_move"."c_godown_code",'-') = '-'
    //          and "tray_move"."n_inout" not in( 1,8 ) union
    //        select "packing_done"."c_doc_no",
    //          "packing_done"."c_cust_code",
    //          "packing_done"."c_cust_name" as "c_cust_name",
    //          "packing_done"."n_completed" as "n_completed",
    //          "packing_done"."c_tray" as "c_tray",
    //          "packing_done"."c_route_code" as "c_route_code",
    //          "isnull"("packing_done"."c_route",'') as "c_route_name",
    //          0 as "n_tray_state"
    //          from "packing_done" union
    //        select "uas_list"."c_doc_no",
    //          "uas_list"."c_cust_code",
    //          "uas_list"."c_cust_name" as "c_cust_name",
    //          "uas_list"."n_completed" as "n_completed",
    //          "uas_list"."c_tray" as "c_tray",
    //          "uas_list"."c_route_code" as "c_route_code",
    //          "isnull"("uas_list"."c_route",'') as "c_route_name",
    //          0 as "n_tray_state"
    //          from "uas_list"
    //          order by "c_route_name" asc,"c_doc_no" asc for xml raw,elements
    select "tray_move"."c_doc_no" as "c_doc_no",
      "cust"."c_code" as "c_cust_code",
      "cust"."c_name" as "c_cust_name",
      (if "tray_move"."n_inout" = 9 then 1 else 0 endif) as "n_completed",
      "tray_move"."c_tray_code" as "c_tray",
      "route_mst"."c_code" as "c_route_code",
      "isnull"("route_mst"."c_name",'') as "c_route_name",
      "tray_move"."n_flag" as "n_tray_state"
      from "st_track_tray_move" as "tray_move"
        join "st_track_mst" on "tray_move"."c_doc_no" = "st_track_mst"."c_doc_no" --AND st_track_mst.n_complete <> 9
        join "act_mst" as "cust" on "cust"."c_code" = "isnull"("st_track_mst"."c_cust_code",'GC01')
        left outer join "act_route" as "route" on "route"."c_br_code" = "st_track_mst"."c_cust_code" and "route"."c_code" = "st_track_mst"."c_br_code"
        left outer join "route_mst" on "isnull"("route"."c_route_code",'-') = "route_mst"."c_code"
      where "isnull"("tray_move"."c_godown_code",'-') = '-'
      and "tray_move"."n_inout" not in( 1,8 ) union
    select distinct "st_track_pick"."c_doc_no" as "c_doc_no","cust"."c_code" as "c_cust_code","cust"."c_name" as "c_cust_name",2 as "n_completed",
      "st_track_pick"."c_tray_code" as "c_tray","route_mst"."c_code" as "c_route_code","isnull"("route_mst"."c_name",'') as "c_route_name",0 as "n_tray_state"
      from "DBA"."st_track_pick" left outer join "st_track_complete_date" on "st_track_pick"."c_doc_no" = "st_track_complete_date"."c_doc_no"
        and "st_track_pick"."c_tray_code" = "st_track_complete_date"."c_tray_code"
        join "st_track_mst" on "st_track_pick"."c_doc_no" = "st_track_mst"."c_doc_no" and "st_track_pick"."n_inout" = "st_track_mst"."n_inout"
        join "act_mst" as "cust" on "cust"."c_code" = "isnull"("st_track_mst"."c_cust_code",'GC01')
        left outer join "act_route" as "route" on "route"."c_br_code" = "st_track_mst"."c_cust_code" and "route"."c_code" = "st_track_mst"."c_br_code"
        left outer join "route_mst" on "isnull"("route"."c_route_code",'-') = "route_mst"."c_code"
      where "date"("isnull"("st_track_complete_date"."t_time","st_track_pick"."t_time")) = "DBA"."uf_default_date"()
      and "isnull"("n_confirm_qty",0)+"isnull"("n_reject_qty",0) > 0 union
    select distinct "st_track_mst"."c_doc_no" as "c_doc_no","cust"."c_code" as "c_cust_code","cust"."c_name" as "c_cust_name",0 as "n_completed",
      'UA-'+"isnull"("st_track_det"."c_stage_code",'NULL') as "c_tray","route_mst"."c_code" as "c_route_code",("route_mst"."c_name") as "c_route_name",0 as "n_tray_state"
      from "st_track_mst"
        join "DBA"."st_track_det" on "st_track_det"."c_doc_no" = "st_track_mst"."c_doc_no" and "st_track_det"."n_inout" = "st_track_mst"."n_inout"
        join "act_mst" as "cust" on "cust"."c_code" = "isnull"("st_track_mst"."c_cust_code",'GC01')
        left outer join "st_track_tray_move" as "tray_move" on "tray_move"."c_doc_no" = "st_track_mst"."c_doc_no"
        left outer join "act_route" as "route" on "route"."c_br_code" = "st_track_mst"."c_cust_code" and "route"."c_code" = "st_track_mst"."c_br_code"
        left outer join "route_mst" on "isnull"("route"."c_route_code",'-') = "route_mst"."c_code"
      where "st_track_det"."c_tray_code" is null
      and "isnull"("st_track_det"."c_godown_code",'-') = '-'
      and "st_track_mst"."n_confirm" = 1
      and "st_track_mst"."n_inout" not in( 1,8 ) for xml raw,elements
  --insert into Serv_log  (c_name,t_ltime) values('End',now());	  
  when 'get_current_tray_position' then
    select "tray_out"."c_tray_code",
      "carton_mst"."c_doc_no"
      from(select "c_tray_code",
          "sum"("n_qty") as "qty"
          from "tray_ledger" join "st_tray_mst" on "tray_ledger"."c_tray_code" = "st_tray_mst"."c_code"
            and "st_tray_mst"."c_tray_type_code" = 'TT0003'
          group by "c_tray_code" having "qty" <= 0) as "tray_out"
        join(select "c_tray_code",
          "max"("d_ldate") as "dt"
          from "carton_mst"
          where "n_flag" = -1 and "c_tray_code" <> '000000'
          group by "c_tray_code") as "tr"
        on "tr"."c_tray_code" = "tray_out"."c_tray_code"
        join(select distinct "c_tray_code",
          "c_br_code"+'/'+"c_year"+'/'+"c_prefix"+'/'+cast("n_srno" as char(30)) as "c_doc_no",
          "d_ldate"
          from "carton_mst"
          where "c_tray_code" <> '000000'
          and "carton_mst"."d_ldate" >= "DBA"."uf_default_date"()-cast(@HdrData as numeric(8))) as "carton_mst"
        on "carton_mst"."c_tray_code" = "tr"."c_tray_code" and "tr"."dt" = "carton_mst"."d_ldate"
      order by 1 asc for xml raw,elements
  end case
end;