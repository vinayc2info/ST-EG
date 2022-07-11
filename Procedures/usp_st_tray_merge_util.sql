CREATE PROCEDURE "DBA"."usp_st_tray_merge_util"( 
  in @gsBr char(6),
  in @devID char(200),
  in @UserId char(20),
  in @cIndex char(30),
  in @trayList char(7000),
  in @tray_code char(6) ) 
result( "is_xml_string" xml ) 
begin
  declare @max_seq numeric(4);
  declare @enable_log numeric(1);
  declare @BrCode char(6);
  declare @ire_srno numeric(18);
  declare @ColSep char(6);
  declare @ColMaxLen numeric(4);
  declare @ColPos integer;
  declare @TraysList char(250);
  declare @new_tray char(6);
  declare @GodownCode char(6);
  declare @base_doc_no char(25);
  declare @new_doc_no char(25);
  declare local temporary table "temp_tray_merge_status"(
    "c_doc_no" char(25) null,
    "c_tray_code" char(6) null,
    "c_status" numeric(1) null,
    "c_message" char(1000) null,
    "t_time" time null,) on commit preserve rows;
  if @devID = '' or @devID is null then
    set @gsBr = "http_variable"('gsBr');
    set @trayList = "http_variable"('trayList');
    set @devID = "http_variable"('devID');
    set @UserId = "http_variable"('UserId');
    set @cIndex = "http_variable"('cIndex');
    set @tray_code = "http_variable"('trayCode')
  end if;
  select "n_active" into @enable_log from "st_track_module_mst" where "st_track_module_mst"."c_code" = 'M00039';
  if @enable_log is null then
    set @enable_log = 0
  end if;
  set @BrCode = "uf_get_br_code"(@gsBr);
  case @cIndex
  when 'line_item_tray_list' then
    //http://172.16.18.100:19503/ws_st_tray_merge_util?&cIndex=line_item_tray_list&gsbr=503&trayCode=20001&devID=&UserId=MYBOSS
    select "t"."c_tray_code" as "c_tray_code",
      "sum"("n_item_count") as "n_item_count",
      "c_rack_grp_list",
      "c_rack_grp_code",
      "max"("t"."t_last_modi_time") as "t_last_modi_time",
      "c_godown_code" as "c_godown_code"
      from(select "c_tray_code",
          "count"("c_item_code") as "n_item_count",
          "list"(distinct "c_rack_grp_code") as "c_rack_grp_list",
          (if "isnull"("st_track_in"."c_godown_code",'-') = '-' then "item_mst_br_info"."c_rack" else "item_mst_br_info_godown"."c_rack" endif) as "c_rack",
          "rack_group_mst"."c_code" as "c_rack_grp_code",
          "max"("t_time") as "t_last_modi_time",
          "st_track_in"."c_godown_code"
          from "DBA"."st_track_in"
            left outer join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = ("left"("st_track_in"."c_doc_no","locate"("st_track_in"."c_doc_no",'/')-1))
            and "item_mst_br_info"."c_code" = "st_track_in"."c_item_code"
            left outer join "item_mst_br_det" on "item_mst_br_det"."c_br_code" = ("left"("st_track_in"."c_doc_no","locate"("st_track_in"."c_doc_no",'/')-1))
            and "item_mst_br_det"."c_code" = "st_track_in"."c_item_code"
            left outer join "item_mst_br_info_godown" on "item_mst_br_info_godown"."c_br_code" = ("left"("st_track_in"."c_doc_no","locate"("st_track_in"."c_doc_no",'/')-1))
            and "item_mst_br_info_godown"."c_code" = "st_track_in"."c_item_code"
            and "item_mst_br_info_godown"."c_godown_code" = "isnull"("st_track_in"."c_godown_code",'-')
            left outer join "rack_mst" on "rack_mst"."c_br_code" = "left"("st_track_in"."c_doc_no",3)
            and "rack_mst"."c_code" = "c_rack"
            left outer join "rack_group_mst" on "rack_mst"."c_br_code" = "rack_group_mst"."c_br_code"
            and "rack_mst"."c_rack_grp_code" = "rack_group_mst"."c_code"
          where "n_complete" not in( 9 ) and "c_tray_code" is not null
          group by "c_tray_code","c_rack","st_track_in"."c_godown_code","c_rack_grp_code") as "T"
      where "c_rack_grp_code" = (select top 1 "rack_group_mst"."c_code" as "c_rack_grp_code"
        from "DBA"."st_track_in"
          left outer join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = ("left"("st_track_in"."c_doc_no","locate"("st_track_in"."c_doc_no",'/')-1))
          and "item_mst_br_info"."c_code" = "st_track_in"."c_item_code"
          left outer join "item_mst_br_det" on "item_mst_br_det"."c_br_code" = ("left"("st_track_in"."c_doc_no","locate"("st_track_in"."c_doc_no",'/')-1))
          and "item_mst_br_det"."c_code" = "st_track_in"."c_item_code"
          left outer join "item_mst_br_info_godown" on "item_mst_br_info_godown"."c_br_code" = ("left"("st_track_in"."c_doc_no","locate"("st_track_in"."c_doc_no",'/')-1))
          and "item_mst_br_info_godown"."c_code" = "st_track_in"."c_item_code"
          and "item_mst_br_info_godown"."c_godown_code" = "isnull"("st_track_in"."c_godown_code",'-')
          left outer join "rack_mst" on "rack_mst"."c_br_code" = "left"("st_track_in"."c_doc_no",3)
          and "rack_mst"."c_code" = (if "isnull"("st_track_in"."c_godown_code",'-') = '-' then "item_mst_br_info"."c_rack" else "item_mst_br_info_godown"."c_rack" endif)
          left outer join "rack_group_mst" on "rack_mst"."c_br_code" = "rack_group_mst"."c_br_code"
          and "rack_mst"."c_rack_grp_code" = "rack_group_mst"."c_code"
        where "n_complete" not in( 9 ) and "c_tray_code" is not null and "c_tray_code" = @tray_code)
      group by "t"."c_tray_code","c_rack_grp_list","c_rack_grp_code","c_godown_code"
      order by "c_tray_code" asc for xml raw,elements
  when 'shift_in_trays' then
    //http://172.16.18.100:19503/ws_st_tray_merge_util?&cIndex=shift_in_trays&gsbr=503&trayCode=20001&trayList=20011^^20022^^20033^^&devID=&UserId=MYBOSS
    set @TraysList = @trayList;
    select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
    set @ColMaxLen = "Length"(@ColSep);
    while @TraysList <> '' loop
      select "Locate"(@TraysList,@ColSep) into @ColPos;
      set @new_tray = "Trim"("Left"(@TraysList,@ColPos-1));
      set @TraysList = "SubString"(@TraysList,@ColPos+@ColMaxLen);
      select top 1 "st_track_in"."c_doc_no" into @new_doc_no from "st_track_in" where "n_complete" = 0 and "c_tray_code" = @new_tray;
      update "st_track_in" set "c_tray_code" = @tray_code where "n_complete" = 0 and "c_tray_code" = @new_tray
    end loop;
    insert into "st_tray_merge_list"
      ( "n_inout","c_doc_no","c_base_tray_code","c_tray_list","d_ldate","t_ltime","c_user" ) values
      ( 1,@new_doc_no,@tray_code,@trayList,"today"(),"now"(),@UserId ) ;
    if sqlstate = '00000' then
      commit work;
      select 1 as "c_status",
        'Success: Base Tray is- '+@tray_code+' and Tray(s) merged- '+"reverse"("substr"("reverse"("replace"(@trayList,'^^',',')),2)) as "c_message" for xml raw,elements
    else
      rollback work;
      select 0 as "c_status",
        'Failure' as "c_message" for xml raw,elements
    end if when 'store_out_trays_list' then
    //http://172.16.18.100:19503/ws_st_tray_merge_util?&cIndex=store_out_trays_list&gsbr=503&trayCode=10236&devID=&UserId=MYBOSS
    if @GodownCode is null or @GodownCode = '' then
      set @GodownCode = '-'
    end if;
    select "tray_move"."c_doc_no" as "c_doc_no",
      "cust"."c_code" as "c_cust_code",
      "cust"."c_name" as "c_cust_name",
      "area_mst"."c_name" as "c_area_name",
      (select "count"(distinct "c_tray_code") from "st_track_tray_move" where "c_doc_no" = "tray_move"."c_doc_no") as "n_total_trays",
      (if "tray_move"."n_inout" = 9 then 1 else 0 endif) as "n_completed",
      "tray_move"."c_tray_code" as "c_tray",
      (select "c_name"+'['+"c_code"+']' as "c_stage" from "st_store_stage_mst" where "c_code" = "tray_move"."c_stage_code") as "c_stage",
      "isnull"("route_mst"."c_name",'') as "c_route",
      "tray_move"."n_flag" as "n_tray_state",
      "isnull"("st_track_mst"."c_system_name",'') as "c_counter",
      "st_track_mst"."d_date" as "d_recv_date",
      "st_track_mst"."c_sort" as "c_route_sort",
      "st_track_mst"."n_urgent" as "n_urgent",
      (select "count"("c_item_code") from "st_track_pick" where "st_track_pick"."c_doc_no" = "tray_move"."c_doc_no" and "c_tray_code" = "tray_move"."c_tray_code") as "item_count"
      from "st_track_tray_move" as "tray_move"
        join "st_track_mst" on "tray_move"."c_doc_no" = "st_track_mst"."c_doc_no"
        join "act_mst" as "cust" on "cust"."c_code" = "isnull"("st_track_mst"."c_cust_code",'GC01')
        left outer join "act_route" as "route" on "route"."c_br_code" = "st_track_mst"."c_cust_code" and "route"."c_code" = "st_track_mst"."c_br_code"
        left outer join "route_mst" on "isnull"("route"."c_route_code",'-') = "route_mst"."c_code"
        join "area_mst" on "area_mst"."c_code" = "cust"."c_area_code"
      where "route_mst"."c_code" = (if '' = '' then "route_mst"."c_code" else '' endif)
      and "isnull"("tray_move"."c_godown_code",'-') = @GodownCode
      and "st_track_mst"."c_doc_no" = (select "st_track_mst"."c_doc_no" from "st_track_tray_move" as "tray_move"
          join "st_track_mst" on "tray_move"."c_doc_no" = "st_track_mst"."c_doc_no"
        where "isnull"("tray_move"."c_godown_code",'-') = '-'
        and "tray_move"."n_inout" not in( 1,8 ) and "tray_move"."n_flag" >= 4 and "tray_move"."n_flag" < 7 and "TRAY_MOVE"."C_TRAY_CODE" = @tray_code)
      and "tray_move"."n_inout" not in( 1,8 ) and "tray_move"."n_flag" >= 4 and "tray_move"."n_flag" < 7 for xml raw,elements
  when 'shift_out_trays' then
    --    http://172.16.18.100:19503/ws_st_tray_merge_util?&cIndex=shift_out_trays&gsbr=503&trayCode=11377&trayList=11595^^11365^^&devID=&UserId=MYBOSS
    set @TraysList = @trayList;
    select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
    set @ColMaxLen = "Length"(@ColSep);
    while @TraysList <> '' loop
      select "Locate"(@TraysList,@ColSep) into @ColPos;
      set @new_tray = "Trim"("Left"(@TraysList,@ColPos-1));
      set @TraysList = "SubString"(@TraysList,@ColPos+@ColMaxLen);
      select "c_doc_no" into @base_doc_no from "st_track_tray_move" where "st_track_tray_move"."c_tray_code" = @tray_code and "st_track_tray_move"."n_flag" < 7;
      select "c_doc_no" into @new_doc_no from "st_track_tray_move" where "st_track_tray_move"."c_tray_code" = @new_tray and "st_track_tray_move"."n_flag" < 7;
      if @base_doc_no <> @new_doc_no then
        insert into "temp_tray_merge_status"
          ( "c_doc_no","c_tray_code","c_status","c_message","t_time" ) 
          select @new_doc_no,@new_tray,0 as "c_status",
            'Failure' as "c_message","now"() from "dummy"
      else
        select "max"("st_track_pick"."n_seq") into @max_seq from "st_track_pick" where "st_track_pick"."c_tray_code" = @new_tray and "st_track_pick"."c_doc_no" = @base_doc_no;
        update "st_track_pick" set "st_track_pick"."n_seq" = @max_seq+"number"() where "st_track_pick"."c_tray_code" = @new_tray and "st_track_pick"."c_doc_no" = @base_doc_no;
        update "st_track_det" set "c_tray_code" = @tray_code where "c_tray_code" = @new_tray and "c_doc_no" = @base_doc_no;
        update "st_track_pick" set "c_tray_code" = @tray_code where "c_tray_code" = @new_tray and "c_doc_no" = @base_doc_no;
        delete from "st_track_tray_move" where "c_tray_code" = @new_tray and "c_doc_no" = @base_doc_no;
        if sqlstate = '00000' then
          commit work;
          insert into "temp_tray_merge_status"
            ( "c_doc_no","c_tray_code","c_status","c_message","t_time" ) 
            select @new_doc_no,@new_tray,1 as "c_status",
              'Success' as "c_message","now"() from "dummy"
        else
          rollback work;
          insert into "temp_tray_merge_status"
            ( "c_doc_no","c_tray_code","c_status","c_message","t_time" ) 
            select @new_doc_no,@new_tray,0 as "c_status",
              'Failure' as "c_message","now"() from "dummy";
          return
        end if
      end if
    end loop;
    insert into "st_tray_merge_list"
      ( "n_inout","c_doc_no","c_base_tray_code","c_tray_list","d_ldate","t_ltime","c_user" ) values
      ( 0,@new_doc_no,@tray_code,@trayList,"today"(),"now"(),@UserId ) ;
    select 'Success: Base Tray is- '+@tray_code+' and Tray(s) merged- '+"list"("c_tray_code") as "c_message" from "temp_tray_merge_status" for xml raw,elements
  end case
end;