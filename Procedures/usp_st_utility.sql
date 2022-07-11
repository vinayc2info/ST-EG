CREATE PROCEDURE "DBA"."usp_st_utility"( 
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
  declare @li_tray_cnt integer;
  declare @ColSep char(6);
  declare @RowSep char(6);
  declare @Pos integer;
  declare @ColPos integer;
  declare @RowPos integer;
  declare @ColMaxLen numeric(4);
  declare @RowMaxLen numeric(4);
  declare @Seq numeric(6);
  declare @BrCode char(6);
  declare @s_year char(6);
  declare @s_prefix char(6);
  declare @s_srno numeric(9);
  declare @act_code char(6);
  declare @d_br_code char(6);
  declare @d_srno numeric(9);
  declare @d_year char(6);
  declare @d_prefix char(6);
  declare local temporary table "temp_tray_list"(
    "n_seq" numeric(4) not null,
    "c_act_code" char(6) not null,
    "c_tray_code" char(6) null,) on commit preserve rows;
  declare @TrayList char(32767);
  declare @TrayCode char(6);
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
    set @TrayList = "http_variable"('TrayList'); --10
    set @GodownCode = "http_variable"('GodownCode') --11		
  end if;
  select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
  select "c_delim" into @RowSep from "ps_tab_delimiter" where "n_seq" = 1;
  set @ColMaxLen = "Length"(@ColSep);
  set @RowMaxLen = "Length"(@RowSep);
  set @BrCode = "uf_get_br_code"(@gsBr);
  //set @BrCode = uf_get_br_code('000');
  set @s_year = "right"("db_name"(),2);
  set @s_prefix = '157';
  -- SELECT  @d_item_bounce_count;
  case @cIndex
  when 'tray_inout_utility' then
    set @Seq = 1;
    while @TrayList <> '' loop
      select "Locate"(@TrayList,@ColSep) into @ColPos;
      set @TrayCode = "Trim"("Left"(@TrayList,@ColPos-1));
      set @TrayList = "SubString"(@TrayList,@ColPos+@ColMaxLen);
      select "Locate"(@TrayList,@RowSep) into @RowPos;
      set @TrayList = "SubString"(@TrayList,@RowPos+@RowMaxLen);
      //to get the recent inv/gdn number of the tray used
      select top 1 "c_br_code","c_year","c_prefix","n_srno" into @d_br_code,@d_year,@d_prefix,@d_srno
        from "tray_ledger" where "n_qty" = -1 and "c_tray_code" = @TrayCode order by "t_ltime" desc;
      //to get the cust_code
      select "c_ref_br_code" into @act_code from "gdn_mst" where "c_br_code" = @d_br_code and "c_year" = @d_year and "c_prefix" = @d_prefix and "n_srno" = @d_srno union all
      select "c_cust_code" from "inv_mst" where "c_br_code" = @d_br_code and "c_year" = @d_year and "c_prefix" = @d_prefix and "n_srno" = @d_srno;
      insert into "temp_tray_list"( "n_seq","c_act_code","c_tray_code" ) values( @Seq,@act_code,@TrayCode ) ;
      set @Seq = @Seq+1
    end loop;
    //to get the next srno
    update "prefix_serial_no" set "n_sr_number" = "n_sr_number"+1 where "c_br_code" = @BrCode and "c_year" = @s_year and "c_prefix" = @s_prefix;
    select "n_sr_number" into @s_srno from "prefix_serial_no" where "c_br_code" = @BrCode and "c_year" = @s_year and "c_prefix" = @s_prefix;
    insert into "ntgrn_mst"
      ( "c_br_code","c_year","c_prefix","n_srno","c_act_code","d_date","c_remark","d_ldate","t_ltime","n_cancel_flag","c_computer_name","c_sys_user","c_sys_ip","n_pk","c_user","c_modiuser" ) 
      select top 1 @BrCode,@s_year,@s_prefix,@s_srno,"c_act_code","today"(),'From NTGRN TAB Process',"today"(),"now"(),0,null,null,null,null,@UserId,@UserId
        from "temp_tray_list";
    insert into "ntgrn_det"
      ( "c_br_code","c_year","c_prefix","n_srno","n_type","c_code","n_qty","d_date","d_ldate","t_ltime","n_cancel_flag","n_seq","n_pk" ) 
      select @BrCode,@s_year,@s_prefix,@s_srno,3,"c_tray_code",1,"today"(),"today"(),"now"(),0,"n_seq",null
        from "temp_tray_list";
    if sqlstate = '00000' or sqlstate = '02000' then
      select 1 as "c_status",'Success' as "c_message" for xml raw,elements;
      commit work
    else -- 
      select 0 as "c_status",'Error On Transaction Save!!' as "c_message" for xml raw,elements;
      rollback work
    end if when 'validate_tray' then
    //http://172.16.18.20:19503/ws_st_utility?&cIndex=validate_tray&TrayList=56098&gsbr=503&devID=a3dcefdf75bc646d105092019064846055&UserId=s kamble
    select "COUNT"() into @li_tray_cnt from "st_tray_mst" where "c_code" = @TrayList;
    if @li_tray_cnt = 0 then
      select 'Error(117) : Tray '+@TrayList+' is not a Valid Tray !.' as "c_message" for xml raw,elements;
      return
    end if;
    set @li_tray_cnt = 0;
    select "COUNT"() into @li_tray_cnt from "st_tray_mst" where "c_code" = @TrayList and "n_in_out_flag" = 1;
    if @li_tray_cnt > 0 then
      select 'Error(110) : Tray '+@TrayList+' is an Internal Tray code.' as "c_message" for xml raw,elements;
      return
    end if;
    if(select "sum"("n_qty") from "tray_ledger" where "c_tray_code" = @TrayList) = 0 then
      select 'Error(119) TrayCode '+@TrayList+' is already Used.' as "c_message" for xml raw,elements;
      return
    end if;
    select 'Success' as "c_message" for xml raw,elements
  end case
end;