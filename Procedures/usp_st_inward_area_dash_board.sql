CREATE PROCEDURE "DBA"."usp_st_inward_area_dash_board"( 
  --call usp_st_expiry_tray_status('get_tray_list','503','a92ac96084d3dc7f13042017021954995','5033','15082')
  in @gsBr char(6), --1
  in @devID char(200), --2
  in @sKey char(20), --3
  in @UserId char(20), --4
  in @cIndex char(30), --5
  in @GodownCode char(6), --6
  in @HdrData char(32767) )  --7
result( "is_xml_string" xml ) 
begin
  /*
Author 		: Saneesh C G
Procedure	: usp_st_inward_area_dash_board
SERVICE		: ws_st_inward_area_dash_board
Date 		: 23-01-2017
modified by : Saneesh C G 
Ldate 		: 23-01-2017
Purpose		: 
Input		: gsBr~devID~sKey~UserId~cIndex~GodownCode~HdrData
call usp_st_inward_area_dash_board
Service Call (Format): 

*/
  declare @BrCode char(6);
  declare @t_ltime char(25);
  declare @d_ldate char(20);
  declare @nUserValid integer;
  declare @RackGrpList char(7000);
  --common >>
  declare @ColSep char(6);
  declare @RowSep char(6);
  declare @traycode char(6);
  declare @flag numeric(4);
  declare @Pos integer;
  declare @ColPos integer;
  declare @RowPos integer;
  declare @ColMaxLen numeric(4);
  declare @RowMaxLen numeric(4);
  declare @s_parm char(10);
  if @devID = '' or @devID is null then
    set @gsBr = "http_variable"('gsBr'); --1
    set @devID = "http_variable"('devID'); --2
    set @sKey = "http_variable"('sKey'); --3
    set @UserId = "http_variable"('UserId'); --4
    set @cIndex = "http_variable"('cIndex'); --5
    set @GodownCode = "http_variable"('GodownCode'); --6
    set @HdrData = "http_variable"('HdrData') --7
  end if;
  //  if(select "count"() from "block_api") >= 1 then
  //    return
  //  end if;
  /*  insert into "API_LOG"
( "c_api_name","c_index","t_start_time","c_remark","c_note","c_user","n_n1" ) values
( 'usp_st_inward_area_dash_board',@cIndex,"GETDATE"(),@HdrData,@devID,@UserId,"connection_property"('NUMBER') ) ;
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
  set @s_parm = "http_variable"('s_parm');
  --select 'sani ' as a for xml raw,elements  ;
  --http://172.16.18.200:16503/ws_st_inward_area_dash_board?cIndex=doc_list&UserId=MYBOSS
  case @cIndex
  when 'get_data_traywise' then
    select "st_track_in"."c_doc_no",
      "st_track_in"."c_item_code",
      "item_mst"."c_name",
      "st_track_in"."c_batch_no",
      "st_track_in"."n_qty",
      "st_track_in"."n_send_qty",
      ("st_track_in"."n_qty"-"st_track_in"."n_send_qty") as "Pend_qty",
      "st_track_in"."c_tray_code",
      "st_track_in"."t_time",
      "st_track_in"."c_godown_code",
      "st_track_in"."c_user",
      "mfac_mst"."c_name"+'['+"item_mst"."c_mfac_code"+']' as "mfac",
      "pack_mst"."c_name"+'['+"item_mst"."c_pack_code"+']' as "pack",
      if "st_track_in"."c_godown_code" = '-' then
        (select "c_rack" from "item_mst_br_info"
          where "item_mst_br_info"."c_br_code" = "left"("st_track_in"."c_doc_no",3)
          and "item_mst_br_info"."c_code" = "st_track_in"."c_item_code"
          and "item_mst_br_info"."c_br_code" = @BrCode)
      else
        (select "c_rack" from "item_mst_br_info_godown"
          where "item_mst_br_info_godown"."c_br_code" = "left"("st_track_in"."c_doc_no",3)
          and "item_mst_br_info_godown"."c_code" = "st_track_in"."c_item_code"
          and "item_mst_br_info_godown"."c_godown_code" = "st_track_in"."c_godown_code"
          and "item_mst_br_info_godown"."c_br_code" = @BrCode)
      endif as "c_rk_code",
      (select "c_rack_grp_code" from "rack_mst"
        where "rack_mst"."c_code" = "c_rk_code"
        and "rack_mst"."c_br_code" = "left"("st_track_in"."c_doc_no",3)
        and "rack_mst"."c_br_code" = @BrCode) as "c_rk_grp_code",
      if "st_track_in"."n_confirm" = 0 then
        'Pending To Inward Assignment'
      else
        if "st_track_in"."n_confirm" = 1 then
          'Tray Assigned'
        else
          if "st_track_in"."n_complete" = 9 then
            'Send Tray'
          else
            ''
          endif
        endif
      endif as "cstatus"
      from "st_track_in"
        join "item_mst" on "item_mst"."c_code" = "st_track_in"."c_item_code"
        join "pack_mst" on "pack_mst"."c_code" = "item_mst"."c_pack_code"
        join "mfac_mst" on "mfac_mst"."c_code" = "item_mst"."c_mfac_code"
      where "st_track_in"."c_tray_code" = @s_parm
      order by "c_doc_no" asc,"c_tray_code" asc,"c_item_code" asc for xml raw,elements
  when 'get_data_itemwise' then
    select "st_track_in"."c_doc_no",
      "st_track_in"."c_item_code",
      "item_mst"."c_name",
      "st_track_in"."c_batch_no",
      "st_track_in"."n_qty",
      "st_track_in"."n_send_qty",
      ("st_track_in"."n_qty"-"st_track_in"."n_send_qty") as "Pend_qty",
      "st_track_in"."c_tray_code",
      "st_track_in"."t_time",
      "st_track_in"."c_godown_code",
      "st_track_in"."c_user",
      "mfac_mst"."c_name"+'['+"item_mst"."c_mfac_code"+']' as "mfac",
      "pack_mst"."c_name"+'['+"item_mst"."c_pack_code"+']' as "pack",
      if "st_track_in"."c_godown_code" = '-' then
        (select "c_rack" from "item_mst_br_info"
          where "item_mst_br_info"."c_br_code" = "left"("st_track_in"."c_doc_no",3)
          and "item_mst_br_info"."c_code" = "st_track_in"."c_item_code"
          and "item_mst_br_info"."c_br_code" = @BrCode)
      else
        (select "c_rack" from "item_mst_br_info_godown"
          where "item_mst_br_info_godown"."c_br_code" = "left"("st_track_in"."c_doc_no",3)
          and "item_mst_br_info_godown"."c_code" = "st_track_in"."c_item_code"
          and "item_mst_br_info_godown"."c_godown_code" = "st_track_in"."c_godown_code"
          and "item_mst_br_info_godown"."c_br_code" = @BrCode)
      endif as "c_rk_code",
      (select "c_rack_grp_code" from "rack_mst"
        where "rack_mst"."c_code" = "c_rk_code"
        and "rack_mst"."c_br_code" = "left"("st_track_in"."c_doc_no",3)
        and "rack_mst"."c_br_code" = @BrCode) as "c_rk_grp_code",
      if "st_track_in"."n_confirm" = 0 then
        'Pending To Inward Assignment'
      else
        if "st_track_in"."n_confirm" = 1 then
          'Tray Assigned'
        else
          if "st_track_in"."n_complete" = 9 then
            'Send Tray'
          else
            ''
          endif
        endif
      endif as "cstatus"
      from "st_track_in"
        join "item_mst" on "item_mst"."c_code" = "st_track_in"."c_item_code"
        join "pack_mst" on "pack_mst"."c_code" = "item_mst"."c_pack_code"
        join "mfac_mst" on "mfac_mst"."c_code" = "item_mst"."c_mfac_code"
      where "st_track_in"."c_item_code" = @s_parm
      order by "c_doc_no" asc,"c_tray_code" asc,"c_item_code" asc for xml raw,elements
  when 'get_data_docwise' then
    if "right"(@s_parm,1) <> '%' then
      set @s_parm = @s_parm+'%'
    end if;
    select "st_track_in"."c_doc_no",
      "st_track_in"."c_item_code",
      "item_mst"."c_name",
      "st_track_in"."c_batch_no",
      "st_track_in"."n_qty",
      "st_track_in"."n_send_qty",
      ("st_track_in"."n_qty"-"st_track_in"."n_send_qty") as "Pend_qty",
      "st_track_in"."c_tray_code",
      "st_track_in"."t_time",
      "st_track_in"."c_godown_code",
      "st_track_in"."c_user",
      "mfac_mst"."c_name"+'['+"item_mst"."c_mfac_code"+']' as "mfac",
      "pack_mst"."c_name"+'['+"item_mst"."c_pack_code"+']' as "pack",
      if "st_track_in"."c_godown_code" = '-' then
        (select "c_rack" from "item_mst_br_info"
          where "item_mst_br_info"."c_br_code" = "left"("st_track_in"."c_doc_no",3)
          and "item_mst_br_info"."c_code" = "st_track_in"."c_item_code"
          and "item_mst_br_info"."c_br_code" = @BrCode)
      else
        (select "c_rack" from "item_mst_br_info_godown"
          where "item_mst_br_info_godown"."c_br_code" = "left"("st_track_in"."c_doc_no",3)
          and "item_mst_br_info_godown"."c_code" = "st_track_in"."c_item_code"
          and "item_mst_br_info_godown"."c_godown_code" = "st_track_in"."c_godown_code"
          and "item_mst_br_info_godown"."c_br_code" = @BrCode)
      endif as "c_rk_code",
      (select "c_rack_grp_code" from "rack_mst"
        where "rack_mst"."c_code" = "c_rk_code"
        and "rack_mst"."c_br_code" = "left"("st_track_in"."c_doc_no",3)
        and "rack_mst"."c_br_code" = @BrCode) as "c_rk_grp_code",
      if "st_track_in"."n_confirm" = 0 then
        'Pending To Inward Assignment'
      else
        if "st_track_in"."n_confirm" = 1 then
          'Tray Assigned'
        else
          if "st_track_in"."n_complete" = 9 then
            'Send Tray'
          else
            ''
          endif
        endif
      endif as "cstatus"
      from "st_track_in"
        join "item_mst" on "item_mst"."c_code" = "st_track_in"."c_item_code"
        join "pack_mst" on "pack_mst"."c_code" = "item_mst"."c_pack_code"
        join "mfac_mst" on "mfac_mst"."c_code" = "item_mst"."c_mfac_code"
      where "st_track_in"."c_doc_no" like @s_parm
      order by "c_doc_no" asc,"c_tray_code" asc,"c_item_code" asc for xml raw,elements
  when 'get_data_userwise' then
    select "count"() into @nUserValid from "user_mst" where "c_user_id" = @s_parm;
    if @nUserValid = 0 then
      select @s_parm+' Is not a valid User ID' as "c_message" for xml raw,elements;
      return
    end if;
    select "st_track_in"."c_doc_no",
      "st_track_in"."c_item_code",
      "item_mst"."c_name",
      "st_track_in"."c_batch_no",
      "st_track_in"."n_qty",
      "st_track_in"."n_send_qty",
      ("st_track_in"."n_qty"-"st_track_in"."n_send_qty") as "Pend_qty",
      "st_track_in"."c_tray_code",
      "st_track_in"."t_time",
      "st_track_in"."c_godown_code",
      "st_track_in"."c_user",
      "mfac_mst"."c_name"+'['+"item_mst"."c_mfac_code"+']' as "mfac",
      "pack_mst"."c_name"+'['+"item_mst"."c_pack_code"+']' as "pack",
      if "st_track_in"."c_godown_code" = '-' then
        (select "c_rack" from "item_mst_br_info"
          where "item_mst_br_info"."c_br_code" = "left"("st_track_in"."c_doc_no",3)
          and "item_mst_br_info"."c_code" = "st_track_in"."c_item_code"
          and "item_mst_br_info"."c_br_code" = @BrCode)
      else
        (select "c_rack" from "item_mst_br_info_godown"
          where "item_mst_br_info_godown"."c_br_code" = "left"("st_track_in"."c_doc_no",3)
          and "item_mst_br_info_godown"."c_code" = "st_track_in"."c_item_code"
          and "item_mst_br_info_godown"."c_godown_code" = "st_track_in"."c_godown_code"
          and "item_mst_br_info_godown"."c_br_code" = @BrCode)
      endif as "c_rk_code",
      (select "c_rack_grp_code" from "rack_mst"
        where "rack_mst"."c_code" = "c_rk_code"
        and "rack_mst"."c_br_code" = "left"("st_track_in"."c_doc_no",3)
        and "rack_mst"."c_br_code" = @BrCode) as "c_rk_grp_code",
      if "st_track_in"."n_confirm" = 0 then
        'Pending To Inward Assignment'
      else
        if "st_track_in"."n_confirm" = 1 then
          'Tray Assigned'
        else
          if "st_track_in"."n_complete" = 9 then
            'Send Tray'
          else
            ''
          endif
        endif
      endif as "cstatus"
      from "st_track_in"
        join "item_mst" on "item_mst"."c_code" = "st_track_in"."c_item_code"
        join "pack_mst" on "pack_mst"."c_code" = "item_mst"."c_pack_code"
        join "mfac_mst" on "mfac_mst"."c_code" = "item_mst"."c_mfac_code"
      where "st_track_in"."c_user" = @s_parm
      order by "c_doc_no" asc,"c_tray_code" asc,"c_item_code" asc for xml raw,elements
  when 'get_data_rackgrpwise' then
    select "st_track_in"."c_doc_no",
      "st_track_in"."c_item_code",
      "item_mst"."c_name",
      "st_track_in"."c_batch_no",
      "st_track_in"."n_qty",
      "st_track_in"."n_send_qty",
      ("st_track_in"."n_qty"-"st_track_in"."n_send_qty") as "Pend_qty",
      "st_track_in"."c_tray_code",
      "st_track_in"."t_time",
      "st_track_in"."c_godown_code",
      "st_track_in"."c_user",
      "mfac_mst"."c_name"+'['+"item_mst"."c_mfac_code"+']' as "mfac",
      "pack_mst"."c_name"+'['+"item_mst"."c_pack_code"+']' as "pack",
      if "st_track_in"."c_godown_code" = '-' then
        (select "c_rack" from "item_mst_br_info"
          where "item_mst_br_info"."c_br_code" = "left"("st_track_in"."c_doc_no",3)
          and "item_mst_br_info"."c_code" = "st_track_in"."c_item_code"
          and "item_mst_br_info"."c_br_code" = @BrCode)
      else
        (select "c_rack" from "item_mst_br_info_godown"
          where "item_mst_br_info_godown"."c_br_code" = "left"("st_track_in"."c_doc_no",3)
          and "item_mst_br_info_godown"."c_code" = "st_track_in"."c_item_code"
          and "item_mst_br_info_godown"."c_godown_code" = "st_track_in"."c_godown_code"
          and "item_mst_br_info_godown"."c_br_code" = @BrCode)
      endif as "c_rk_code",
      (select "c_rack_grp_code" from "rack_mst"
        where "rack_mst"."c_code" = "c_rk_code"
        and "rack_mst"."c_br_code" = "left"("st_track_in"."c_doc_no",3)
        and "rack_mst"."c_br_code" = @BrCode) as "c_rk_grp_code",
      if "st_track_in"."n_confirm" = 0 then
        'Pending To Inward Assignment'
      else
        if "st_track_in"."n_confirm" = 1 then
          'Tray Assigned'
        else
          if "st_track_in"."n_complete" = 9 then
            'Send Tray'
          else
            ''
          endif
        endif
      endif as "cstatus"
      from "st_track_in"
        join "item_mst" on "item_mst"."c_code" = "st_track_in"."c_item_code"
        join "pack_mst" on "pack_mst"."c_code" = "item_mst"."c_pack_code"
        join "mfac_mst" on "mfac_mst"."c_code" = "item_mst"."c_mfac_code"
      where "c_rk_grp_code" = @s_parm
      order by "c_doc_no" asc,"c_tray_code" asc,"c_item_code" asc for xml raw,elements
  end case
end;