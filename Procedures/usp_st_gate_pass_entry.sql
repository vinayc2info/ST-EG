CREATE PROCEDURE "DBA"."usp_st_gate_pass_entry"( 
  in @gsBr char(6),
  in @devID char(200),
  in @cIndex char(30),
  in @UserId char(30) ) 
result( "is_xml_string" xml ) 
begin
  declare @pallet_tray_flag integer;
  declare @cut_variable integer;
  declare @doc_no char(50);
  declare @driver_name char(15);
  declare @driver_mob_no char(10);
  declare @vehicle_no char(10);
  declare @pallet_data char(32767);
  declare @Pallet_Det char(32767);
  declare @HdrData char(7000);
  declare @DetData char(32767);
  declare @hdr_data char(7000);
  declare @hdr_det char(32767);
  declare @c_user char(30);
  declare @c_gate_pass_Prefix char(5);
  declare @c_gate_pass_year numeric(2);
  declare @d_date date;
  declare @t_ltime char(25);
  --ipo 
  declare @br char(6);
  declare @yr char(2);
  declare @pfx char(4);
  declare @nsrno numeric(9);
  declare @sup_code char(6);
  declare @total numeric(12,2);
  declare @cnote char(100);
  declare @ddate date;
  declare @ttime time;
  declare @napprove numeric(1);
  declare @nshift numeric(1);
  declare @ncancelflag numeric(1);
  declare @dldate date;
  declare @tltime "datetime";
  declare @cuser char(10);
  declare @cmodiuser char(10);
  declare @nstoretrack numeric(1);
  declare @cmptrname char(40);
  declare @sysuser char(30);
  declare @sysip char(30);
  declare @chckdby char(100);
  declare @rcvdby char(100);
  declare @ctransporter char(100);
  declare @lrno char(100);
  declare @lrdate char(30);
  declare @caprove_user char(10);
  declare @caprove_time "datetime";
  declare @rcvd_date char(30);
  declare @n_gate_pass_Srno numeric(9);
  declare @nPrefixCount numeric(6);
  declare @seq numeric(4);
  declare @supp char(6);
  declare @supp_code char(6);
  declare @sup_bill_no char(30);
  declare @sup_bill_date char(30);
  declare @sup_total numeric(12,2);
  declare @item_cnt numeric(4);
  declare @cases numeric(4);
  declare @c_note char(100);
  declare @error_message char(100);
  declare @c_bin_no char(6);
  declare @trans char(6);
  declare local temporary table "temp_gate_pass_det"(
    "n_seq" numeric(4) not null,
    "supp_code" char(6) not null,
    "sup_bill_no" char(30) not null,
    "sup_bill_date" date null,
    "sup_total" numeric(12,2) not null default 0,
    "n_item_count" numeric(4) null default 0,
    "cases" numeric(4) null default 0,
    "c_note" char(100) null,
    "bin_code" char(6) null,
    ) on commit preserve rows;
  declare local temporary table "temp_gate_pass_pallet_det"(
    "n_seq" numeric(4) not null,
    "supp_code" char(6) not null,
    "sup_bill_no" char(30) not null,
    "cases" numeric(4) null default 0,
    "bin_code" char(6) null,
    "location_seq" numeric(4) null,
    primary key("n_seq" asc,"supp_code" asc,"sup_bill_no" asc),) on commit preserve rows;
  --Hdr_data 
  --common 
  declare @ColSep char(6);
  declare @RowSep char(6);
  declare @Pos integer;
  declare @ColPos integer;
  declare @RowPos integer;
  declare @ColMaxLen numeric(4);
  declare @RowMaxLen numeric(4);
  declare @location_seq numeric(4);
  select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
  select "c_delim" into @RowSep from "ps_tab_delimiter" where "n_seq" = 1;
  if @ColSep is null or @ColSep = '' then
    select '--------------------\x0D\x0ASQL error: usp_st_gate_pass_entry No Delimiter Defined';
    return
  end if;
  set @ColMaxLen = "Length"(@ColSep);
  set @RowMaxLen = "Length"(@RowSep);
  if @devID = '' or @devID is null then
    set @gsBr = "http_variable"('gsBr'); --1
    set @devID = "http_variable"('devID'); --2
    set @cIndex = "http_variable"('cIndex'); --3
    set @c_user = "HTTP_VARIABLE"('UserId'); --4
    set @doc_no = "http_variable"('DocNo')
  end if;
  set @HdrData = "http_variable"('HdrData');
  set @DetData = "http_variable"('DetData');
  set @Pallet_Det = "http_variable"('PalletDet');
  set @driver_name = "http_variable"('DriverName');
  set @driver_mob_no = "http_variable"('DriverMobNo');
  set @vehicle_no = "http_variable"('VehicleNo');
  set @supp_code = "http_variable"('SuppCode');
  set @pfx = '163';
  set @trans = 'GPASS';
  select "right"("db_name"(),2) into @yr;
  set @d_date = "DBA"."uf_default_date"();
  set @t_ltime = "left"("now"(),19);
  select "isnull"("n_active",0) into @pallet_tray_flag from "st_track_module_mst" where "c_code" = 'M00073';
  case @cIndex
  when 'get_check_id_active_status' then
    --http://172.16.18.38:18503/ws_st_gate_pass_entry?&cIndex=get_check_id_active_status&gsbr=503&devID=&UserId=myboss
    select if("c_val" = 0 or "para_user_group_rights"."n_cancel_flag" = 1) then 0 else 1 endif as "check_id_status"
      from "para_user_group_rights" join "para_window_mst" on "para_window_mst"."c_code" = "para_user_group_rights"."c_para_win_code"
      where "c_para_val_code" = 'P00017'
      and "c_para_win_code" = 'W00161'
      and "para_window_mst"."n_win_rights" = 1 for xml raw,elements
  when 'get_supp' then
    --http://172.16.18.201:18503/ws_st_gate_pass_entry?&cIndex=get_supp&gsbr=503&devID=&UserId=myboss
    select "act_mst"."c_name" as "Supp_name",
      "act_mst"."c_code" as "Supp_code"
      from "act_mst"
        ,"grp_mst"
      where("act_mst"."c_grp_no" = "grp_mst"."c_grp_no")
      and(if "act_mst"."n_roaming" in( 0,1 ) then 'xyz' else "act_mst"."c_branch_code" endif = 'xyz')
      and("act_mst"."c_code" not in( 'xyz','000','-VPAY','0000' ) )
      and(not "act_mst"."c_code" = any(select "c_br_code" from "br_tran_access_rights" where "c_code" = 'xyz' and "c_br_code" = "act_mst"."c_code" and "n_transfer" = 2 and "n_cancel_flag" = 0))
      and(("act_mst"."n_type" in( 2,3,5 ) )) union
    select "act_mst"."c_name" as "Supp_name",
      "act_mst"."c_code" as "Supp_code"
      from "act_mst","grp_mst","act_br_access"
      where("act_mst"."c_grp_no" = "grp_mst"."c_grp_no")
      and("act_br_access"."c_act_code" = "act_mst"."c_code")
      and("act_mst"."c_code" not in( 'xyz','000','-VPAY','0000' ) )
      and("act_mst"."n_roaming" = 0)
      and(not "act_mst"."c_code" = any(select "c_br_code" from "br_tran_access_rights" where "c_code" = 'xyz' and "c_br_code" = "act_mst"."c_code" and "n_transfer" = 2 and "n_cancel_flag" = 0))
      and("act_br_access"."n_cancel_flag" = 0)
      and(("act_br_access"."c_br_code" = 'xyz')
      and("act_mst"."n_type" in( 2,3,5 ) )) union
    select "act_mst"."c_name" as "Supp_name",
      "act_mst"."c_code" as "Supp_code"
      from "act_mst","grp_mst","act_br_access","branch_group_det"
      where("act_mst"."c_grp_no" = "grp_mst"."c_grp_no")
      and("act_br_access"."c_br_code" = "branch_group_det"."c_code")
      and("act_mst"."c_code" = "act_br_access"."c_act_code")
      and("act_mst"."c_code" not in( 'xyz','000','-VPAY','0000' ) )
      and("act_mst"."n_roaming" = 0)
      and(not "act_mst"."c_code" = any(select "c_br_code" from "br_tran_access_rights" where "c_code" = 'xyz' and "c_br_code" = "act_mst"."c_code" and "n_transfer" = 2 and "n_cancel_flag" = 0))
      and(("act_br_access"."n_cancel_flag" = 0)
      and("branch_group_det"."c_br_code" = "uf_get_br_code"('000')) --'xyz'
      and("act_mst"."n_type" in( 2,3,5 ) ))
      order by 2 asc for xml raw,elements
  when 'get_transport' then
    --http://172.16.18.201:18503/ws_st_gate_pass_entry?&cIndex=get_transport&gsbr=503&devID=&UserId=myboss
    select "transport_mst"."c_code" as "transport_code",
      "transport_mst"."c_name" as "transport_name"
      from "transport_mst" for xml raw,elements
  when 'get_gate_pass_mst_det' then
    set @hdr_data = @HdrData;
    set @hdr_det = @DetData;
    set @pallet_data = @Pallet_Det;
    set @hdrdata = @hdr_data;
    -- 1 
    select "Locate"(@hdrdata,@ColSep) into @ColPos;
    set @br = "Trim"("Left"(@hdrdata,@ColPos-1));
    set @hdrdata = "SubString"(@hdrdata,@ColPos+@ColMaxLen);
    --
    -- 2
    select "Locate"(@hdrdata,@ColSep) into @ColPos;
    set @nsrno = "Trim"("Left"(@hdrdata,@ColPos-1));
    set @hdrdata = "SubString"(@hdrdata,@ColPos+@ColMaxLen);
    set @nsrno = 0;
    --3
    select "Locate"(@hdrdata,@ColSep) into @ColPos;
    set @sup_code = "Trim"("Left"(@hdrdata,@ColPos-1));
    set @hdrdata = "SubString"(@hdrdata,@ColPos+@ColMaxLen);
    --4 total 
    select "Locate"(@hdrdata,@ColSep) into @ColPos;
    set @total = "Trim"("Left"(@hdrdata,@ColPos-1));
    set @hdrdata = "SubString"(@hdrdata,@ColPos+@ColMaxLen);
    --5 note 
    select "Locate"(@hdrdata,@ColSep) into @ColPos;
    set @cnote = "Trim"("Left"(@hdrdata,@ColPos-1));
    set @hdrdata = "SubString"(@hdrdata,@ColPos+@ColMaxLen);
    -- 6 c_user 
    select "Locate"(@hdrdata,@ColSep) into @ColPos;
    set @cuser = "Trim"("Left"(@hdrdata,@ColPos-1));
    set @hdrdata = "SubString"(@hdrdata,@ColPos+@ColMaxLen);
    -- 7 modiuser 
    select "Locate"(@hdrdata,@ColSep) into @ColPos;
    set @cmodiuser = "Trim"("Left"(@hdrdata,@ColPos-1));
    set @hdrdata = "SubString"(@hdrdata,@ColPos+@ColMaxLen);
    -- 8 sysip 
    select "Locate"(@hdrdata,@ColSep) into @ColPos;
    set @sysip = "Trim"("Left"(@hdrdata,@ColPos-1));
    set @hdrdata = "SubString"(@hdrdata,@ColPos+@ColMaxLen);
    -- 9 sysip 
    select "Locate"(@hdrdata,@ColSep) into @ColPos;
    set @rcvdby = "Trim"("Left"(@hdrdata,@ColPos-1));
    set @hdrdata = "SubString"(@hdrdata,@ColPos+@ColMaxLen);
    -- 10 checked by 
    select "Locate"(@hdrdata,@ColSep) into @ColPos;
    set @chckdby = "Trim"("Left"(@hdrdata,@ColPos-1));
    set @hdrdata = "SubString"(@hdrdata,@ColPos+@ColMaxLen);
    -- 11 transporter
    select "Locate"(@hdrdata,@ColSep) into @ColPos;
    set @ctransporter = "Trim"("Left"(@hdrdata,@ColPos-1));
    set @hdrdata = "SubString"(@hdrdata,@ColPos+@ColMaxLen);
    -- 12 Lrno
    select "Locate"(@hdrdata,@ColSep) into @ColPos;
    set @lrno = "Trim"("Left"(@hdrdata,@ColPos-1));
    set @hdrdata = "SubString"(@hdrdata,@ColPos+@ColMaxLen);
    -- 13 Lrdate 
    select "Locate"(@hdrdata,@ColSep) into @ColPos;
    set @lrdate = "Trim"("Left"(@hdrdata,@ColPos-1));
    set @hdrdata = "SubString"(@hdrdata,@ColPos+@ColMaxLen);
    -- 14 received date
    select "Locate"(@hdrdata,@ColSep) into @ColPos;
    --select trim("Left"(@hdrdata,@ColPos-1)) into a;
    set @rcvd_date = "trim"("Left"(@hdrdata,@ColPos-1));
    if(@rcvd_date = '' or "length"(@rcvd_date) = 0 or @rcvd_date = null or @rcvd_date = '0000-00-00') then
      set @rcvd_date = null
    end if;
    set @hdrdata = "SubString"(@hdrdata,@ColPos+@ColMaxLen);
    -- 15
    select "Locate"(@hdrdata,@ColSep) into @ColPos;
    set @napprove = "Trim"("Left"(@hdrdata,@ColPos-1));
    set @hdrdata = "SubString"(@hdrdata,@ColPos+@ColMaxLen);
    -- row
    select "Locate"(@hdrdata,@RowSep) into @RowPos;
    set @hdrdata = "SubString"(@hdrdata,@RowPos+@RowMaxLen);
    -- 1 
    select "Locate"(@doc_no,@ColSep) into @ColPos;
    set @cut_variable = "Trim"("Left"(@doc_no,@ColPos-1));
    set @doc_no = "SubString"(@doc_no,@ColPos+@ColMaxLen);
    if @cut_variable is null then
      set @cut_variable = 0
    end if;
    if @cut_variable = 1 then
      select "Locate"(@doc_no,@ColSep) into @ColPos;
      set @br = "Trim"("Left"(@doc_no,@ColPos-1));
      set @doc_no = "SubString"(@doc_no,@ColPos+@ColMaxLen);
      -- 2
      select "Locate"(@doc_no,@ColSep) into @ColPos;
      set @yr = "Trim"("Left"(@doc_no,@ColPos-1));
      set @doc_no = "SubString"(@doc_no,@ColPos+@ColMaxLen);
      --3
      select "Locate"(@doc_no,@ColSep) into @ColPos;
      set @pfx = "Trim"("Left"(@doc_no,@ColPos-1));
      set @doc_no = "SubString"(@doc_no,@ColPos+@ColMaxLen);
      --4 total 
      select "Locate"(@doc_no,@ColSep) into @ColPos;
      set @nsrno = "Trim"("Left"(@doc_no,@ColPos-1));
      set @doc_no = "SubString"(@doc_no,@ColPos+@ColMaxLen)
    end if;
    while @hdr_det <> '' loop
      --1
      select "Locate"(@hdr_det,@ColSep) into @ColPos;
      set @seq = "Trim"("Left"(@hdr_det,@ColPos-1));
      set @hdr_det = "SubString"(@hdr_det,@ColPos+@ColMaxLen);
      -- 2
      select "Locate"(@hdr_det,@ColSep) into @ColPos;
      set @supp = "Trim"("Left"(@hdr_det,@ColPos-1));
      set @hdr_det = "SubString"(@hdr_det,@ColPos+@ColMaxLen);
      -- 3 
      select "Locate"(@hdr_det,@ColSep) into @ColPos;
      set @sup_bill_no = "Trim"("Left"(@hdr_det,@ColPos-1));
      set @hdr_det = "SubString"(@hdr_det,@ColPos+@ColMaxLen);
      if(select "COUNT"("N_SRNO") from "GATE_PASS_DET" where "C_SUPP_CODE" = @SUPP and "C_REF_NO" = @sup_bill_no and "N_CANCEL_FLAG" = 0) = 0
        or(select "count"("n_srno") from "dba"."gate_pass_mst" where "c_br_code" = @br and "c_year" = @yr and "c_prefix" = @pfx and "n_srno" = @nsrno) = 1 then
        -- 4 
        select "Locate"(@hdr_det,@ColSep) into @ColPos;
        set @sup_bill_date = "Trim"("Left"(@hdr_det,@ColPos-1));
        if(@sup_bill_date = '' or "length"(@sup_bill_date) = 0 or @sup_bill_date = null or @sup_bill_date = '0000-00-00') then
          set @sup_bill_date = null
        end if;
        set @hdr_det = "SubString"(@hdr_det,@ColPos+@ColMaxLen);
        -- 5
        select "Locate"(@hdr_det,@ColSep) into @ColPos;
        set @item_cnt = "Trim"("Left"(@hdr_det,@ColPos-1));
        set @hdr_det = "SubString"(@hdr_det,@ColPos+@ColMaxLen);
        -- 6 
        select "Locate"(@hdr_det,@ColSep) into @ColPos;
        set @sup_total = "Trim"("Left"(@hdr_det,@ColPos-1));
        set @hdr_det = "SubString"(@hdr_det,@ColPos+@ColMaxLen);
        -- 7 
        select "Locate"(@hdr_det,@ColSep) into @ColPos;
        set @cases = "Trim"("Left"(@hdr_det,@ColPos-1));
        set @hdr_det = "SubString"(@hdr_det,@ColPos+@ColMaxLen);
        -- 8
        select "Locate"(@hdr_det,@ColSep) into @ColPos;
        set @c_note = "Trim"("Left"(@hdr_det,@ColPos-1));
        set @hdr_det = "SubString"(@hdr_det,@ColPos+@ColMaxLen);
        -- 9 
        select "Locate"(@hdr_det,@ColSep) into @ColPos;
        set @c_bin_no = "Trim"("Left"(@hdr_det,@ColPos-1));
        set @hdr_det = "SubString"(@hdr_det,@ColPos+@ColMaxLen);
        -- 10 
        select "Locate"(@hdr_det,@RowSep) into @RowPos;
        set @hdr_det = "SubString"(@hdr_det,@RowPos+@RowMaxLen);
        insert into "temp_gate_pass_det"
          ( "n_seq","supp_code","sup_bill_no","sup_bill_date","sup_total","n_item_count","cases","c_note","bin_code" ) values
          ( @seq,@sup_code,@sup_bill_no,@sup_bill_date,@sup_total,@item_cnt,@cases,@c_note,@c_bin_no ) 
      else
        set @hdr_det = '';
        set @error_message = 'Bill No :'+@sup_bill_no+' is Already Exists'
      end if
    end loop;
    select top 1 "c_location_code"
      into @location_seq
      from "st_pallet_move" where "c_destination_floor_code" = '-' and "n_pallet_assigned_screen_flag" = 1 order by "t_time" desc,"c_location_code" desc;
    if @location_seq is null then
      set @location_seq = 0
    end if;
    //vinay_test added to avoid pallet code entry on 01-03-21
    if @pallet_tray_flag = 1 then
      while @pallet_data <> '' loop
        select "Locate"(@pallet_data,@ColSep) into @ColPos;
        set @seq = "Trim"("Left"(@pallet_data,@ColPos-1));
        set @pallet_data = "SubString"(@pallet_data,@ColPos+@ColMaxLen);
        -- 2
        select "Locate"(@pallet_data,@ColSep) into @ColPos;
        set @supp_code = "Trim"("Left"(@pallet_data,@ColPos-1));
        set @pallet_data = "SubString"(@pallet_data,@ColPos+@ColMaxLen);
        -- 3 
        select "Locate"(@pallet_data,@ColSep) into @ColPos;
        set @sup_bill_no = "Trim"("Left"(@pallet_data,@ColPos-1));
        set @pallet_data = "SubString"(@pallet_data,@ColPos+@ColMaxLen);
        -- 4 
        select "Locate"(@pallet_data,@ColSep) into @ColPos;
        set @cases = "Trim"("Left"(@pallet_data,@ColPos-1));
        set @pallet_data = "SubString"(@pallet_data,@ColPos+@ColMaxLen);
        -- 5
        select "Locate"(@pallet_data,@ColSep) into @ColPos;
        set @c_bin_no = "Trim"("Left"(@pallet_data,@ColPos-1));
        set @pallet_data = "SubString"(@pallet_data,@ColPos+@ColMaxLen);
        -- 
        select "Locate"(@pallet_data,@RowSep) into @RowPos;
        set @pallet_data = "SubString"(@pallet_data,@RowPos+@RowMaxLen);
        set @location_seq = @location_seq+1;
        //&PalletDet=1^^S00012^^A/12^^15^^PP08^^||2^^S00012^^A/13^^4^^PP08^^||&VehicleNo=KA04444444
        insert into "temp_gate_pass_pallet_det"
          ( "n_seq","supp_code","sup_bill_no","cases","bin_code","location_seq" ) values
          ( @seq,@supp_code,@sup_bill_no,@cases,@c_bin_no,@location_seq ) 
      end loop
    end if;
    if "len"("trim"(@error_message)) = 0 or @error_message is null
      or(select "count"("n_srno") from "dba"."gate_pass_mst" where "c_br_code" = @br and "c_year" = @yr and "c_prefix" = @pfx and "n_srno" = @nsrno) = 1 then
      print 'if';
      if @nsrno = 0 then
        select "isnull"("n_sr_number",0)
          into @n_gate_pass_Srno from "prefix_serial_no"
          where "c_trans" = @trans
          and "c_year" = @yr
          and "c_br_code" = @gsBr;
        if @n_gate_pass_Srno is null or @n_gate_pass_Srno = 0 then
          set @n_gate_pass_Srno = 1
        end if; --
        select "count"("c_trans")
          into @nPrefixCount from "prefix_serial_no"
          where "c_trans" = @trans
          and "c_year" = @yr
          and "c_br_code" = @gsBr
          and "c_prefix" = @pfx;
        if(@nPrefixCount) <= 0 then --1 <=0
          insert into "prefix_serial_no"
            select @trans,
              @gsBr,
              @yr,
              @pfx,
              @n_gate_pass_Srno,
              null,
              0
        --gg
        end if end if;
      if(select "count"("n_srno") from "dba"."gate_pass_mst" where "c_br_code" = @br and "c_year" = @yr and "c_prefix" = @pfx and "n_srno" = @nsrno) = 0 then --for new record
        update "prefix_serial_no" set "n_sr_number" = @n_gate_pass_Srno+1
          where "c_trans" = @trans
          and "c_year" = @yr
          and "c_br_code" = @gsBr
          and "c_prefix" = @pfx;
        set @nsrno = @n_gate_pass_Srno;
        insert into "gate_pass_mst"
          ( "c_br_code","c_year","c_prefix","n_srno","c_supp_code","n_total","c_note","d_date","t_time","n_approved","n_shift","n_cancel_flag",
          "d_ldate","t_ltime","c_user","c_modiuser","n_store_track","c_computer_name","c_sys_user","c_sys_ip","c_rcvd_by","c_chkd_by",
          "c_transporter","c_lr_no","d_lr_date","c_approved_user","t_approved_time","d_rcvd_date","n_entry_type","c_driver_name","c_driver_mobile_no","c_vehicle_no" ) values
          ( @br,@yr,@pfx,@n_gate_pass_Srno,@sup_code,@total,@cnote,@d_date,@t_ltime,@napprove,0,0,
          @d_date,@t_ltime,@cuser,@cmodiuser,0,null,null,@sysip,@rcvdby,@chckdby,
          @ctransporter,@Lrno,@lrdate,(if @napprove = 1 then @cuser else null endif),(if @napprove = 1 then @t_ltime else null endif),@rcvd_date,1,@driver_name,@driver_mob_no,@vehicle_no ) ;
        insert into "gate_pass_det"
          ( "c_br_code","c_year","c_prefix","n_srno","n_seq","c_supp_code","c_ref_no","n_total","n_item_count","n_cases","c_note",
          "n_approved","n_shift","n_cancel_flag","d_date","d_ldate","t_ltime","n_store_track","d_bill_date","n_pk","n_po_pk" ) 
          select @br,@yr,@pfx,@n_gate_pass_Srno,"n_seq","supp_code","sup_bill_no","sup_total","n_item_count","cases","c_note",
            @napprove,0,0,@d_date,@d_date,@t_ltime,0,"sup_bill_date","uf_pk"(@br,@yr,@pfx,@n_gate_pass_Srno,0,''),0
            from "temp_gate_pass_det";
        insert into "bin_info"
          ( "c_br_code","c_year","c_prefix","n_srno","n_seq","c_bin_code" ) 
          select @br,@yr,@pfx,@n_gate_pass_Srno,"n_seq","bin_code" from "temp_gate_pass_det";
        if @pallet_tray_flag = 1 then
          insert into "gate_pass_pallet_det"
            ( "c_br_code","c_year","c_prefix","n_srno","n_seq","c_supp_code","c_ref_no","n_cases","c_pallet_code","n_approved","d_date" ) 
            select @br,@yr,@pfx,@n_gate_pass_Srno,"n_seq","supp_code","sup_bill_no","cases","bin_code",@napprove,"today"() from "temp_gate_pass_pallet_det";
          insert into "st_pallet_move"
            ( "c_pallet_code","c_location_code","c_rack_grp_code","c_floor_code","n_inout","n_status_flag","n_tray_count","n_merge_pallet_flag","n_capacity_status","d_date","t_time","c_user","c_destination_floor_code","n_pallet_assigned_screen_flag" ) 
            select distinct "max"("bin_code"),"max"("location_seq"),"max"("supp_code"),'-',1,1,0,0,0,"today"(),"now"(),'','-',1 from "temp_gate_pass_pallet_det";
          insert into "st_pallet_move_det"
            ( "c_pallet_code","c_tray_code","c_destination_rack_grp_code","n_inout","n_status","n_tray_flag","d_date","t_time","c_user","n_item_count","n_carton_flag","n_dynamic_tray_flag","n_tray_release_flag" ) on existing update defaults off
            select "bin_code","trim"("right"("sup_bill_no",6)),'-',1,0,0,"today"(),"now"(),'CSQ',0,0,0,1 from "temp_gate_pass_pallet_det"
        end if
      else set @n_gate_pass_Srno = @nsrno;
        insert into "gate_pass_mst"
          ( "c_br_code","c_year","c_prefix","n_srno","c_supp_code","n_total","c_note","d_date","t_time","n_approved","n_shift","n_cancel_flag",
          "d_ldate","t_ltime","c_user","c_modiuser","n_store_track","c_computer_name","c_sys_user","c_sys_ip","c_rcvd_by","c_chkd_by",
          "c_transporter","c_lr_no","d_lr_date","c_approved_user","t_approved_time","d_rcvd_date","n_entry_type","c_driver_name","c_driver_mobile_no","c_vehicle_no" ) on existing update defaults off values
          ( @br,@yr,@pfx,@n_gate_pass_Srno,@sup_code,@total,@cnote,@d_date,@t_ltime,@napprove,0,0,
          @d_date,@t_ltime,@cuser,@cmodiuser,0,null,null,@sysip,@rcvdby,@chckdby,
          @ctransporter,@Lrno,@lrdate,(if @napprove = 1 then @cuser else null endif),(if @napprove = 1 then @t_ltime else null endif),@rcvd_date,1,@driver_name,@driver_mob_no,@vehicle_no ) ;
        delete from "dba"."gate_pass_det" where "c_br_code" = @br and "c_year" = @yr and "c_prefix" = @pfx and "n_srno" = @nsrno;
        insert into "gate_pass_det"
          ( "c_br_code","c_year","c_prefix","n_srno","n_seq","c_supp_code","c_ref_no","n_total","n_item_count","n_cases","c_note",
          "n_approved","n_shift","n_cancel_flag","d_date","d_ldate","t_ltime","n_store_track","d_bill_date","n_pk","n_po_pk" ) 
          select @br,@yr,@pfx,@n_gate_pass_Srno,"n_seq","supp_code","sup_bill_no","sup_total","n_item_count","cases","c_note",
            @napprove,0,0,@d_date,@d_date,@t_ltime,0,"sup_bill_date","uf_pk"(@br,@yr,@pfx,@n_gate_pass_Srno,0,''),0
            from "temp_gate_pass_det";
        if @pallet_tray_flag = 1 then
          delete from "dba"."gate_pass_pallet_det" where "c_br_code" = @br and "c_year" = @yr and "c_prefix" = @pfx and "n_srno" = @nsrno;
          insert into "gate_pass_pallet_det"
            ( "c_br_code","c_year","c_prefix","n_srno","n_seq","c_supp_code","c_ref_no","n_cases","c_pallet_code","n_approved","d_date" ) 
            select @br,@yr,@pfx,@n_gate_pass_Srno,"n_seq","supp_code","sup_bill_no","cases","bin_code",@napprove,"today"() from "temp_gate_pass_pallet_det";
          delete from "st_pallet_move_det" from "st_pallet_move_det" join "temp_gate_pass_pallet_det" on "temp_gate_pass_pallet_det"."bin_code" = "st_pallet_move_det"."c_pallet_code"
            where "st_pallet_move_det"."c_pallet_code" = "temp_gate_pass_pallet_det"."bin_code";
          //and st_pallet_move_det.c_tray_code = "right"("temp_gate_pass_pallet_det"."sup_bill_no",6);
          insert into "st_pallet_move" on existing update defaults off
            select distinct "max"("bin_code"),"max"("location_seq"),"max"("supp_code"),'-',1,1,0,0,0,"today"(),"now"(),'','-',1,null from "temp_gate_pass_pallet_det";
          insert into "st_pallet_move_det" on existing update defaults off
            select "bin_code","right"("sup_bill_no",6),'-',1,0,0,"today"(),"now"(),'CSQ',0,0,0,1,null,null,null,null from "temp_gate_pass_pallet_det"
        end if end if;
      if sqlstate = '00000' or sqlstate = '02000' then
        select 'Success' as "c_status",@br+'/'+@yr+'/'+@pfx+'/'+"string"(@n_gate_pass_Srno) as "Gate_Pass_No" for xml raw,elements;
        commit work
      else -- 
        select 'Error' as "c_status",'Error On Transaction Save!!' as "c_message" for xml raw,elements;
        rollback work
      end if
    else select 'Validation Error' as "c_status",@error_message as "c_message" for xml raw,elements;
      return
    end if when 'get_last_transaction' then
    --http://172.16.18.19:49503/ws_st_gate_pass_entry?&cIndex=get_last_transaction&GodownCode=&gsbr=503&devID=a3dcfdf75bc646d105092019064846055&sKEY=sKey&UserId=s kamble
    select top 1
      "gate_pass_mst"."c_br_code","gate_pass_mst"."c_year","gate_pass_mst"."c_prefix","gate_pass_mst"."n_srno",
      "gate_pass_mst"."c_supp_code","act_mst"."c_name",
      "gate_pass_mst"."d_lr_date","gate_pass_mst"."n_total","gate_pass_mst"."d_date","gate_pass_mst"."t_time",
      "gate_pass_mst"."c_driver_name","gate_pass_mst"."c_driver_mobile_no","gate_pass_mst"."c_vehicle_no",
      "gate_pass_mst"."c_rcvd_by","gate_pass_mst"."c_chkd_by","gate_pass_mst"."c_transporter","gate_pass_mst"."c_lr_no"
      from "gate_pass_mst"
        join "act_mst" on "act_mst"."c_code" = "gate_pass_mst"."c_supp_code" order by "gate_pass_mst"."n_srno" desc for xml raw,elements
  when 'unposted_records' then
    select "gate_pass_mst"."c_br_code",
      "gate_pass_mst"."c_year",
      "gate_pass_mst"."c_prefix",
      "gate_pass_mst"."n_srno",
      "gate_pass_mst"."c_br_code"+'/'+"gate_pass_mst"."c_year"+'/'+"gate_pass_mst"."c_prefix"+'/'+"trim"("str"("gate_pass_mst"."n_srno")) as "transaction_number",
      "act_mst"."c_name" as "supp_name",
      "gate_pass_mst"."c_supp_code" as "supp_code",
      "gate_pass_mst"."d_date" as "d_date",
      "gate_pass_mst"."n_total" as "invoice_total",
      "gate_pass_mst"."c_user" as "created_by",
      "gate_pass_mst"."c_modiuser" as "modified_user",
      "gate_pass_mst"."t_time" as "t_time"
      from "gate_pass_mst"
        join "act_mst" on "act_mst"."c_code" = "gate_pass_mst"."c_supp_code"
      where "gate_pass_mst"."n_approved" = 0 and "gate_pass_mst"."n_cancel_flag" = 0
      order by "gate_pass_mst"."n_srno" desc for xml raw,elements
  when 'fetch_driver_details' then
    --http://172.16.18.19:49503/ws_st_gate_pass_entry?&cIndex=fetch_driver_details&SuppCode=S00001&gsbr=503&devID=a3dcfdf75bc646d105092019064846055&sKEY=sKey&UserId=s kamble
    select "order_trans_mst_det"."c_br_code",
      "order_trans_mst_det"."c_year",
      "order_trans_mst_det"."c_prefix",
      "order_trans_mst_det"."n_srno",
      "isnull"("order_trans_mst_det"."c_name","order_trans_det"."c_driver_name") as "c_driver_name",
      "isnull"("order_trans_mst_det"."c_mobile_no","order_trans_det"."c_driver_mobile_no") as "c_mobile_no",
      "isnull"("order_trans_mst_det"."c_lr_no","order_trans_det"."c_lr_no") as "c_vehicle_no"
      from "order_trans_mst_det"
        join "order_trans_det" on "order_trans_det"."c_br_code" = "order_trans_mst_det"."c_br_code"
        and "order_trans_det"."c_year" = "order_trans_mst_det"."c_year"
        and "order_trans_det"."c_prefix" = "order_trans_mst_det"."c_prefix"
        and "order_trans_det"."n_srno" = "order_trans_mst_det"."n_srno"
        join "order_mst" on "order_trans_mst_det"."c_br_code" = "order_mst"."c_br_code"
        and "order_trans_mst_det"."c_year" = "order_mst"."c_year"
        and "order_trans_mst_det"."c_prefix" = "order_mst"."c_prefix"
        and "order_trans_mst_det"."n_srno" = "order_mst"."n_srno"
      where "order_trans_det"."d_date" <= "today"()
      and "t_in_time" is not null
      and "t_out_time" is null and "order_mst"."c_cust_code" = @supp_code for xml raw,elements
  when 'gate_pass_mst_fetch' then
    --http://172.16.18.19:19503/ws_st_gate_pass_entry?&cIndex=gate_pass_mst_fetch&devID=--&UserId=myboss&DocNo=503^^19^^163^^6526^^
    -- 1 
    select "Locate"(@doc_no,@ColSep) into @ColPos;
    set @br = "Trim"("Left"(@doc_no,@ColPos-1));
    set @doc_no = "SubString"(@doc_no,@ColPos+@ColMaxLen);
    -- 2
    select "Locate"(@doc_no,@ColSep) into @ColPos;
    set @yr = "Trim"("Left"(@doc_no,@ColPos-1));
    set @doc_no = "SubString"(@doc_no,@ColPos+@ColMaxLen);
    set @nsrno = 0;
    --3
    select "Locate"(@doc_no,@ColSep) into @ColPos;
    set @pfx = "Trim"("Left"(@doc_no,@ColPos-1));
    set @doc_no = "SubString"(@doc_no,@ColPos+@ColMaxLen);
    --4 total 
    select "Locate"(@doc_no,@ColSep) into @ColPos;
    set @nsrno = "Trim"("Left"(@doc_no,@ColPos-1));
    set @doc_no = "SubString"(@doc_no,@ColPos+@ColMaxLen);
    select "c_approved_user","c_br_code","c_chkd_by","c_computer_name","c_driver_mobile_no",
      "c_driver_name","c_lr_no","c_modiuser","c_note","c_prefix",
      "c_print_format_code","c_rcvd_by","c_supp_code","c_sys_ip",
      "c_sys_user","c_transporter","c_user","c_vehicle_no","c_year",
      "d_date","d_ldate","d_lr_date","d_rcvd_date","n_approved","n_cancel_flag",
      "n_entry_type","n_pk","n_shift","n_srno","n_store_track","n_total",
      "t_approved_time","t_ltime","t_time"
      from "gate_pass_mst" where "c_br_code" = @br and "c_year" = @yr and "c_prefix" = @pfx and "n_srno" = @nsrno for xml raw,elements
  when 'gate_pass_det_fetch' then
    --http://172.16.18.19:55555/ws_st_gate_pass_entry?&cIndex=gate_pass_det_fetch&devID=--&UserId=myboss&DocNo=EY07^^20^^163^^1^^
    -- 1 
    select "Locate"(@doc_no,@ColSep) into @ColPos;
    set @br = "Trim"("Left"(@doc_no,@ColPos-1));
    set @doc_no = "SubString"(@doc_no,@ColPos+@ColMaxLen);
    -- 2
    select "Locate"(@doc_no,@ColSep) into @ColPos;
    set @yr = "Trim"("Left"(@doc_no,@ColPos-1));
    set @doc_no = "SubString"(@doc_no,@ColPos+@ColMaxLen);
    set @nsrno = 0;
    --3
    select "Locate"(@doc_no,@ColSep) into @ColPos;
    set @pfx = "Trim"("Left"(@doc_no,@ColPos-1));
    set @doc_no = "SubString"(@doc_no,@ColPos+@ColMaxLen);
    --4 total 
    select "Locate"(@doc_no,@ColSep) into @ColPos;
    set @nsrno = "Trim"("Left"(@doc_no,@ColPos-1));
    set @doc_no = "SubString"(@doc_no,@ColPos+@ColMaxLen);
    select "gate_pass_det"."c_br_code","gate_pass_det"."c_year","gate_pass_det"."c_prefix","gate_pass_det"."n_srno",
      "gate_pass_det"."d_ldate","gate_pass_det"."d_date","gate_pass_det"."d_bill_date","gate_pass_det"."c_supp_code","gate_pass_det"."c_ref_no","gate_pass_det"."c_note",
      "gate_pass_det"."t_ltime","gate_pass_det"."n_total",
      "gate_pass_det"."n_seq","gate_pass_det"."n_item_count","isnull"("gate_pass_pallet_det"."n_cases","gate_pass_det"."n_cases") as "n_cases",
      "gate_pass_pallet_det"."c_pallet_code",
      "gate_pass_det"."n_store_track","gate_pass_det"."n_po_pk","gate_pass_det"."n_cancel_flag","gate_pass_det"."n_approved","gate_pass_det"."n_pk","gate_pass_det"."n_shift"
      from "gate_pass_det"
        left outer join "gate_pass_pallet_det" on "gate_pass_pallet_det"."c_br_code" = "gate_pass_det"."c_br_code"
        and "gate_pass_pallet_det"."c_year" = "gate_pass_det"."c_year"
        and "gate_pass_pallet_det"."c_prefix" = "gate_pass_det"."c_prefix"
        and "gate_pass_pallet_det"."n_srno" = "gate_pass_det"."n_srno"
        and "gate_pass_pallet_det"."n_seq" = "gate_pass_det"."n_seq"
      where "gate_pass_det"."n_cancel_flag" = 0 and "gate_pass_det"."c_br_code" = @br and "gate_pass_det"."c_year" = @yr
      and "gate_pass_det"."c_prefix" = @pfx and "gate_pass_det"."n_srno" = @nsrno for xml raw,elements
  when 'reprint_gate_pass_det' then
    --http://172.16.18.20:19503/ws_st_gate_pass_entry?&cIndex=reprint_gate_pass_det&DocNo=503^^19^^163^^5002^^&gsbr=503&devID=&UserId=myboss
    -- 1 brcode
    select "Locate"(@doc_no,@ColSep) into @ColPos;
    set @br = "Trim"("Left"(@doc_no,@ColPos-1));
    set @doc_no = "SubString"(@doc_no,@ColPos+@ColMaxLen);
    -- 2 year
    select "Locate"(@doc_no,@ColSep) into @ColPos;
    set @yr = "Trim"("Left"(@doc_no,@ColPos-1));
    set @doc_no = "SubString"(@doc_no,@ColPos+@ColMaxLen);
    set @nsrno = 0;
    --3 prefix
    select "Locate"(@doc_no,@ColSep) into @ColPos;
    set @pfx = "Trim"("Left"(@doc_no,@ColPos-1));
    set @doc_no = "SubString"(@doc_no,@ColPos+@ColMaxLen);
    --4 srno 
    select "Locate"(@doc_no,@ColSep) into @ColPos;
    set @nsrno = "Trim"("Left"(@doc_no,@ColPos-1));
    set @doc_no = "SubString"(@doc_no,@ColPos+@ColMaxLen);
    select "gpd"."c_ref_no" as "Refno",
      "gpd"."d_bill_date" as "BillDate",
      "gpd"."n_total" as "BillTotal",
      "gpd"."n_cases" as "Cases",
      "am"."c_name" as "Supplier",
      "gpm"."n_total" as "Total",
      "gpd"."c_br_code" as "Br_Code",
      "gpd"."c_year" as "Year",
      "gpd"."c_prefix" as "prifix",
      "gpm"."n_srno" as "Srno",
      "gpd"."c_supp_code" as "Supp_Code",
      "ISNULL"("gpd"."c_note",'') as "note",
      "gpm"."d_date" as "Date",
      "gpm"."t_ltime" as "time",
      "gpm"."n_approved",
      "gpm"."n_shift",
      "gpm"."n_cancel_flag",
      "gpm"."d_ldate",
      "gpm"."t_ltime",
      "gpm"."c_user",
      "gpm"."c_modiuser",
      "gpm"."n_store_track",
      "gpm"."c_computer_name",
      "gpd"."n_item_count" as "itemcount",
      "ISNULL"("gpd"."c_note",'') as "c_note",
      "gpm"."c_rcvd_by",
      "gpd"."n_seq" as "gatepass_seq"
      from "gate_pass_mst" as "gpm"
        join "gate_pass_det" as "gpd" on "gpm"."n_srno" = "gpd"."n_srno"
        left outer join "act_mst" as "am" on "am"."c_code" = "gpd"."c_supp_code"
      where "gpm"."n_cancel_flag" = 0 and "gpm"."n_approved" = 1
      and "gpd"."c_br_code" = @br
      and "gpd"."c_year" = @yr
      and "gpd"."c_prefix" = @pfx
      and "gpd"."n_srno" = @nsrno for xml raw,elements
  when 'reprint_gate_pass_mst' then
    --http://172.16.18.20:19503/ws_st_gate_pass_entry?&cIndex=reprint_gate_pass_mst&gsbr=503&devID=&UserId=myboss
    select "gate_pass_mst"."c_br_code",
      "gate_pass_mst"."c_year",
      "gate_pass_mst"."c_prefix",
      "gate_pass_mst"."n_srno",
      "gate_pass_mst"."c_br_code"+'/'+"gate_pass_mst"."c_year"+'/'+"gate_pass_mst"."c_prefix"+'/'+"trim"("str"("gate_pass_mst"."n_srno")) as "transaction_number",
      "act_mst"."c_name" as "supp_name",
      "gate_pass_mst"."c_supp_code" as "supp_code",
      "gate_pass_mst"."d_date" as "d_date",
      "gate_pass_mst"."n_total" as "invoice_total",
      "gate_pass_mst"."c_user" as "created_by",
      "gate_pass_mst"."c_modiuser" as "modified_user",
      "gate_pass_mst"."t_time" as "t_time"
      from "gate_pass_mst"
        join "act_mst" on "act_mst"."c_code" = "gate_pass_mst"."c_supp_code"
      where "gate_pass_mst"."n_cancel_flag" = 0 and "gate_pass_mst"."n_approved" = 1
      order by "gate_pass_mst"."n_srno" desc for xml raw,elements
  end case
end;