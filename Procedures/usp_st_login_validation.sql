CREATE PROCEDURE "DBA"."usp_st_login_validation"( 
  in @gsBr char(6),
  in @devID char(200),
  in @UserId char(20),
  in @UserPass char(10),
  in @cIndex char(30),
  in @PhaseCode char(6),
  in @StageCode char(6),
  in @RackGrpCode char(300),
  in @cNote char(75),
  in @GodownCode char(6) ) 
result( "is_xml_string" xml ) 
begin
  /*
Author 		: Anup
Procedure	: usp_update_item_details
SERVICE		: ws_update_item_details
Date 		: 
Modified By : Saneesh CG 
Ldate 		: 25-03-2016
Purpose		: 
Input		: 
Note		:
cIndex : login,logout,dev_reg, verify_supervisor,validate_tray
Changes  :st_track_module_mst Table Added ,Expiry Module Added 
*/
  --http://192.168.7.12:13000/ws_st_login_validation?gsBr=&devID=devID&sKey=KEY&UserId=MYBOSS&UserPass=1&cIndex=login
  --http://192.168.7.12:13000/ws_st_login_validation?gsBr=&devID=devID&sKey=KEY&UserId=MYBOSS&UserPass=1&cIndex=logout&PhaseCode=&StageCode=&RackGrpCode=
  declare @BrCode char(6);
  declare @nUserValid integer;
  --login>>
  declare @nDevLocked integer;
  declare @enableTrayStatus integer;
  declare @enableDashboard integer;
  declare @enableStockAudit integer;
  declare @enablestorein integer;
  declare @cMenuID char(6);
  declare @sApplicationID char(6);
  declare "ENABLED_DEFAULT" numeric(1);
  declare "DISABLED_DEFAULT" numeric(1);
  declare @HdrData char(100);
  declare @li_add numeric(1);
  declare @li_modi numeric(1);
  declare @li_del numeric(1);
  declare @LDate date;
  declare @RestrictFlag integer;
  declare @n_inout integer;
  declare local temporary table "temp_rack_grp_list"(
    "c_rack_grp_code" char(6) null,
    "c_stage_code" char(6) null, --login<<
    "n_seq" numeric(6) null,) on commit preserve rows;declare @Seq integer;
  --logout>>
  declare @RackGrpList char(7000);
  declare @tmp char(20);
  --logout<<
  --common >>
  declare @ColSep char(6);
  declare @RowSep char(6);
  declare @Pos integer;
  declare @ColPos integer;
  declare @RowPos integer;
  declare @ColMaxLen numeric(4);
  declare @RowMaxLen numeric(4);
  --common <<
  --dev_reg>>
  declare @iDevNo integer;
  declare @cDevID char(50);
  declare @RegDate date;
  declare @CancelFlag integer;
  declare @ADate date;
  declare @LDateTime timestamp;
  declare @nPendingApproval integer;
  declare @nDevExists integer;
  --dev_reg<<
  --cIndex login_status>>
  declare @loginRGCount integer;
  declare @tmRGcount integer;
  declare @stageRGcount integer;
  declare @seltmRGcount integer;
  declare @DocNo char(25);
  declare @CurrentTray char(20);
  --cIndex login_status<<
  --cIndex set_login>>
  declare @LoginStatus char(500);
  --cIndex set_login<<
  --cIndex util_login>>
  declare @loginMode char(100);
  declare @doc_no_msg char(100);
  declare @n_allow_store_track integer;
  --cIndex util_login<<
  if @devID = '' or @devID is null then
    set @gsBr = "http_variable"('gsBr'); --1
    set @devID = "http_variable"('devID'); --2
    set @UserId = "http_variable"('UserId'); --3
    set @UserPass = "http_variable"('UserPass'); --4
    set @cIndex = "http_variable"('cIndex'); --5
    set @PhaseCode = "http_variable"('PhaseCode'); --6		
    set @RackGrpCode = "http_variable"('RackGrpCode'); --7	
    set @StageCode = "http_variable"('StageCode'); --8
    set @cNote = "http_variable"('cNote'); --9
    set @GodownCode = "http_variable"('GodownCode'); --10				
    set @n_inout = "http_variable"('inout'); --10	
    set @HdrData = "http_variable"('HdrData') --10						
  end if;
  set @sApplicationID = '006';
  if @n_inout is null then
    set @n_inout = 0
  end if;
  select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
  select "c_delim" into @RowSep from "ps_tab_delimiter" where "n_seq" = 1;
  --    set @BrCode = uf_get_br_code();	
  set @ColMaxLen = "Length"(@ColSep);
  set @RowMaxLen = "Length"(@RowSep);
  --devid
  set "ENABLED_DEFAULT" = 1;
  set "DISABLED_DEFAULT" = 0;
  set @cMenuID = '000016';
  select "uf_get_menu_rights"(@sApplicationID,@cMenuID,@UserId,"ENABLED_DEFAULT")
    into @enableTrayStatus;
  set @cMenuID = '000017';
  select "uf_get_menu_rights"(@sApplicationID,@cMenuID,@UserId,"ENABLED_DEFAULT")
    into @enableDashboard;
  set @cMenuID = '000030';
  select "uf_get_menu_rights"(@sApplicationID,@cMenuID,@UserId,"ENABLED_DEFAULT")
    into @enablestorein;
  set @cMenuID = '000193';
  select "uf_get_menu_rights"('001',@cMenuID,@UserId,"ENABLED_DEFAULT")
    into @EnableStockAudit;
  set @BrCode = "uf_get_br_code"(@gsBr);
  set @loginMode = "HTTP_VARIABLE"('loginMode');
  if(select "count"("c_code") from "act_mst" where "c_code" = @BrCode and "n_type" = 3) = 0 then
    select 'Error!: Branch Code - '+"string"(@BrCode)+' is not valid' as "c_message" for xml raw,elements
  end if;
  set @LDateTime = "left"("now"(),19);
  set @LDate = "uf_default_date"();
  case @cIndex
  when 'tray_is_numeric' then
    select '1' as "n_flag" for xml raw,elements
  when 'get_latest_version' then
    select "c_br_Code","c_app_code","n_cur_ver_no","c_cur_ver_name","c_apk_location","n_download_flag","c_log_location","n_log_flag","c_log_server_user_id","c_log_server_user_pwd","c_apk_server_user_id","c_apk_server_user_pwd","isnull"("download_link_from_server",'http://liveorder.in/apkdownload/123_1/storetrack.apk') as "download_link_from_server"
      from "apk_info"
      where "c_app_code" = 'ST' for xml raw,elements
  when 'Get_setup' then -----------------------------------------------------------------------
    --HdrData ==M00033^^
    call "uf_get_module_mst_value_multi"(@HdrData,@ColPos,@ColMaxLen,@ColSep);
    return
  when 'login' then
    /*
n_success_flag :
0 - failure
1 - success
2 - Unregistered
3 - Approval Pending      
4 - Device Locked 
*/
    select "count"("c_device_id")
      into @nDevExists from "st_device_mst"
      where "c_device_id" = @devID
      and "c_br_code" = @BrCode;
    //    print '@BrCode';
    //    print @BrCode;
    //    print '@devID';
    //    print @devID;
    //    print '@nDevExists';
    //    print @nDevExists;
    if @nDevExists = 0 then
      //      print 'V1';
      select '2' as "n_success_flag", --unregistered
        '' as "c_mode",
        @LDateTime as "t_timestamp" for xml raw,elements;
      return
    end if;
    select "count"("c_device_id")
      --Approval Pending
      into @nPendingApproval from "st_device_mst"
      where "c_device_id" = @devID
      and "n_cancel_flag" = 9
      and "c_br_code" = @BrCode;
    //    print '@nPendingApproval';
    //    print @nPendingApproval;
    if @nPendingApproval >= 1 then
      //      print 'V2';
      select '3' as "n_success_flag",
        '' as "c_mode",
        @LDateTime as "t_timestamp" for xml raw,elements;
      return
    end if;
    select "count"("c_device_id")
      --Approval Pending
      into @nDevLocked from "st_device_mst"
      where "c_device_id" = @devID
      and "n_cancel_flag" = 1
      and "c_br_code" = @BrCode;
    //    print '@nDevLocked';
    //    print @nDevLocked;
    if @nDevLocked >= 1 then
      //      print 'V3';
      select '4' as "n_success_flag",
        '' as "c_mode",
        @LDateTime as "t_timestamp" for xml raw,elements;
      return
    end if;
    select "count"("c_user_id")
      into @nUserValid from "user_mst"
      where "c_user_id" = @userId
      and "c_user_pass" = @UserPass;
    //    print '@nUserValid';
    //    print @nUserValid;
    if @nUserValid = 0 then
      //      print 'V4';
      select '0' as "n_success_flag",
        'Invalid User Id or Password !!' as "c_mode",
        @LDateTime as "t_timestamp" for xml raw,elements;
      return
    end if;
    select "isnull"("n_allow_store_track",1) into @n_allow_store_track from "user_mst"
      where "c_user_id" = @userId
      and "c_user_pass" = @UserPass;
    if @nUserValid > 0 then
      //      print 'V5';
      if @n_allow_store_track = 0 then
        //        print 'V6';
        select '0' as "n_success_flag",
          'StoreTrack Module Is Not Eanbled for User '+@userId+'; Please Contact Supervisor !!  ' as "c_mode",
          @LDateTime as "t_timestamp" for xml raw,elements
      else
        //        print 'V6 else';
        select "mode_list"."n_success_flag" as "n_success_flag",
          "mode_list"."c_mode" as "c_mode",
          @LDateTime as "t_timestamp",
          "isnull"("st_track_setup"."n_max_tray_items",40) as "n_max_tray_items",
          0 as "n_idle_timeout",
          "isnull"("st_track_setup"."n_get_notif_refresh_time",60) as "n_get_notif_refresh_time",
          "isnull"("st_track_setup"."n_tray_status_refresh_time",60) as "n_tray_status_refresh_time",
          if "charindex"('\\UAT\\',"DB_PROPERTY"('file')) > 0 then 1 else 0 endif as "uat_flag",
          "isnull"("st_track_setup"."n_max_tray_item_exp",50) as "n_max_tray_item_exp",
          if "left"("DB_NAME"(),3) = '05U' then
            --Pharmeasy Required Auto bounce 
            1
          else
            0
          endif as "n_auto_bounce",
          "isnull"("st_track_setup"."n_max_tray_items_inward",40) as "n_max_tray_items_inward"
          from(select '1' as "n_success_flag",
              "c_module_name" as "c_mode",
              if "n_validate_user_right" = 0 then
                "n_active"
              else
                if "c_module_name" = 'Stock Audit' or "c_module_name" = 'GATE PASS ENTRY' then
                  "uf_get_menu_rights"('001',"c_menu_id",@UserId,"ENABLED_DEFAULT")
                else
                  "uf_get_menu_rights"(@sApplicationID,"c_menu_id",@UserId,"ENABLED_DEFAULT")
                endif
              endif as "n_enable",
              "n_seq" as "n_ord",
              "c_br_code"
              from "st_track_module_mst" where "st_track_module_mst"."n_hide" = 0
              and not "st_track_module_mst"."c_code" = any(select "c_module_code" from "st_userwise_module_setup"
                where "n_lock" = 1 and "n_cancel_flag" = 0 and "c_user_id" = @userId)) as "mode_list","st_track_setup"
          where "mode_list"."n_enable" = 1
          and "st_track_setup"."c_br_Code" = "mode_list"."c_br_code"
          order by "mode_list"."n_ord" asc for xml raw,elements
      //    print 'V7';
      end if
    else select '0' as "n_success_flag",
        'Invalid User Id or Password !!' as "c_mode",
        @LDateTime as "t_timestamp" for xml raw,elements
    end if when 'dev_reg' then
    set @BrCode = "uf_get_br_code"(@gsBr);
    select "ISNULL"("max"("n_device_no")+1,1)
      into @iDevNo from "st_device_mst" where "c_br_code" = @BrCode;
    set @cDevID = @devID;
    set @RegDate = "uf_default_date"();
    --set @cNote = '';
    set @CancelFlag = 9;
    set @ADate = "uf_default_date"();
    set @LDateTime = "left"("now"(),19);
    insert into "st_device_mst"
      ( "c_br_code","n_device_no","c_device_id","d_registered_date","c_note","n_cancel_flag","d_adate","t_ltime" ) values
      ( @BrCode,@iDevNo,@DevID,@RegDate,@cNote,@CancelFlag,@ADate,@LDateTime ) ;
    if sqlstate = '00000' then
      commit work;
      select 'Success : Request Sucessfully placed for Device ID : '+@DevID+@ColSep+'Server Generated Serial No : '+"string"(@iDevNo)+@ColSep+'Details : '+@cNote as "c_message" for xml raw,elements
    else
      select 'Failure : Request for Device ID : '+@DevID+' Failed '+@ColSep+'Please try again later' as "c_message" for xml raw,elements;
      rollback work
    end if when 'set_login' then
    set @RackGrpList = @RackGrpCode;
    while @RackGrpList <> '' loop
      --1 RackGrpList
      select "Locate"(@RackGrpList,@ColSep) into @ColPos;
      set @tmp = "Trim"("Left"(@RackGrpList,@ColPos-1));
      set @RackGrpList = "SubString"(@RackGrpList,@ColPos+@ColMaxLen);
      --message 'RackGrpList '+@tmp type warning to client;			
      if(select "COUNT"("C_CODE") from "RACK_GROUP_MST" where "n_lock" = 0 and "C_CODE" = @tmp) > 0 then --valid rack group selection 				
        select "n_pos_seq" into @Seq from "st_store_stage_det" where "c_rack_grp_code" = @tmp;
        insert into "temp_rack_grp_list"( "c_rack_grp_code","c_stage_code","n_seq" ) values( @tmp,@StageCode,@Seq ) 
      end if
    end loop;
    select "count"()
      into @loginRGCount from "temp_rack_grp_list";
    if(select "count"("c_rack_grp_code") from "st_track_tray_move" where "c_stage_code" = @StageCode and "n_inout" = 0) > 0 then
      select top 1 "c_doc_no","c_tray_code","count"("c_rack_grp_code") as "rg_cnt"
        into @DocNo,@CurrentTray,@tmRGcount
        from "st_track_tray_move"
        where "n_inout" = 0
        and "c_stage_code" = @StageCode
        group by "c_doc_no","c_tray_code"
        having "rg_cnt" <> @loginRGCount;
      if @tmRGcount is null and @loginRGCount > 1 then
        select top 1 "count"("tm"."c_rack_grp_code")
          into @seltmRGcount from "st_track_tray_move" as "tm"
            join "temp_rack_grp_list" as "rg" on "tm"."c_rack_grp_code" = "rg"."c_rack_grp_code" and "tm"."c_stage_code" = "rg"."c_stage_code"
          where "tm"."c_stage_code" = @StageCode and "tm"."n_inout" = 0 group by "tm"."c_doc_no","c_tray_code";
        select top 1 "count"("tm"."c_rack_grp_code")
          into @stageRGcount from "st_track_tray_move" as "tm"
          where "tm"."c_stage_code" = @StageCode and "tm"."n_inout" = 0 group by "tm"."c_doc_no","c_tray_code"
      end if end if;
    if @loginRGCount > 1 and(@seltmRGcount <> @stageRGcount or @tmRGcount is not null) then
      select 'Error! : Cannot login to the selected rack groups '+@ColSep+' Please process the pending documents' as "c_message" for xml raw,elements;
      return
    end if;
    set @RackGrpList = @RackGrpCode;
    while @RackGrpList <> '' loop
      --1 RackGrpList
      select "Locate"(@RackGrpList,@ColSep) into @ColPos;
      set @tmp = "Trim"("Left"(@RackGrpList,@ColPos-1));
      set @RackGrpList = "SubString"(@RackGrpList,@ColPos+@ColMaxLen);
      --message 'RackGrpList '+@tmp type warning to client;			
      --saneesh on 20-04-2017
      select "uf_st_login_status"(@BrCode,@tmp,1,@UserId,@devID,@n_inout) /*@LoginFlag*/
        --
        into @LoginStatus;
      if "length"(@LoginStatus) > 1 then
        select @LoginStatus as "c_message" for xml raw,elements;
        return
      -- need to add login restriction 
      /*
@RestrictFlag - 0 Default 
1 With Permission
2 Denied
*/
      end if
    end loop;
    select "count"("a"."c_user_id")
      into @RestrictFlag from "st_store_login_restriction" as "a"
        join "temp_rack_grp_list" as "b" on "a"."c_rack_grp_code" = "b"."c_rack_grp_code"
      where "a"."c_user_id" = @UserId;
    --and n_flag = 0,1,2
    if(select "count"("c_user_id") from "st_store_login_det" where "c_br_code" = @BrCode and "c_user_id" = @UserId and "c_device_id" = @devID and "n_inout" = @n_inout) > 0 then
      delete from "st_store_login_det"
        where "c_br_code" = @BrCode
        and "c_user_id" = @UserId
        and "c_device_id" = @devID
        and "n_inout" = @n_inout;
      if sqlstate = '00000' then
        commit work
      else
        rollback work
      end if end if;
    insert into "st_store_login"( "c_br_code","c_user_id","c_phase_code","c_device_id","t_login_time","t_action_start","c_godown_code","c_user_2","c_note","n_inout" ) on existing update defaults off values
      --t_action_start - starts operating after few minutes of login 
      ( @BrCode,@UserId,'PH0001',@devID,@LDateTime,@LDateTime,@GodownCode,null,'RACK OPERATIONS',@n_inout ) ;
    insert into "st_store_login_det"
      ( "c_br_code","c_user_id","c_stage_code","c_rack_grp_code","c_device_id","t_login_time","d_adate","t_ltime","c_user_2","n_inout" ) 
      select @BrCode,@UserId,"c_stage_code","c_rack_grp_code",@devID,@LDateTime,@LDate,@LDateTime,null,@n_inout
        from "temp_rack_grp_list";
    --sani to update login_time
    call "uf_update_login_time"(@BrCode,@devID,@UserId,'PH0001',"isnull"(@loginMode,'RACK OPERATIONS'),@GodownCode,1);
    if sqlstate = '00000' then
      select '' as "c_message",
        "n_in_barcode_print" as "in_barcode_print_flag",
        "n_out_barcode_print" as "out_barcode_print_flag"
        from "st_store_stage_det" where "c_stage_code" = @StageCode
        and "c_rack_grp_code" = @tmp for xml raw,elements;
      commit work
    else
      select 'FAILURE' as "c_message" for xml raw,elements;
      rollback work
    end if when 'util_login' then
    /*
util_login
function : login for utilities like : barcode, tray status, dashboard
i/p : @gsBr,@UserId,  @devID, @GodownCode, loginMode
*/
    insert into "st_store_login"( "c_br_code","c_user_id","c_phase_code","c_device_id","t_login_time","t_action_start","c_godown_code","c_user_2","c_note","n_inout" ) on existing update defaults off values
      --t_action_start - starts operating after few minutes of login 
      ( @BrCode,@UserId,'PH0001',@devID,@LDateTime,@LDateTime,@GodownCode,null,@loginMode,@n_inout ) ;
    --sani 
    call "uf_update_login_time"(@BrCode,@devID,@UserId,'PH0001',@loginMode,@GodownCode,1);
    if sqlstate = '00000' then
      select '' as "c_message" for xml raw,elements;
      commit work
    else
      select 'FAILURE' as "c_message" for xml raw,elements;
      rollback work
    end if when 'dashboard_login' then
    select '1' as "n_success_flag",
      "c_module_name" as "c_mode",
      "n_active" as "n_enable",
      "n_seq" as "n_ord",
      "c_br_code"
      from "st_track_dashboard_module_mst"
      where "n_enable" = 1 order by "n_ord" asc for xml raw,elements
  when 'logout' then
    update "st_store_login"
      set "t_login_time" = null
      where "c_phase_code" = 'PH0001'
      and "c_user_id" = @UserId
      and "c_device_id" = @devID
      and "n_inout" = @n_inout;
    update "st_store_login_det"
      set "t_login_time" = null
      where "c_stage_code" = @StageCode
      and "c_user_id" = @UserId
      and "c_device_id" = @devID
      and "n_inout" = @n_inout;
    --sani to update login_time
    call "uf_update_login_time"(@BrCode,@devID,@UserId,'PH0001','',@GodownCode,0);
    commit work;
    select '1' as "c_message" for xml raw,elements
  end case
end;