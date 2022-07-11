CREATE PROCEDURE "DBA"."usp_st_retail_stock_removal"( 
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
  /*
Author          : Saneesh 
Procedure       : usp_st_retail_stock_removal
SERVICE         : ws_st_retail_stock_removal
Date            : 
Purpose         : 
Input           : 
IndexDetails    : 
Tags            : 
Note            :
Revision 	    : 
*/
  --common >>
  declare @removed_doc_flag numeric(1);
  declare @display_base integer;
  declare @itemcount integer;
  declare @log_seq numeric(30);
  declare @enable_log numeric(1);
  declare @hdr_data varchar(32767);
  declare @hdr_det varchar(7000);
  declare @bounce_cnt numeric(4);
  declare @tray_in_progress numeric(9);
  declare @tray_move_doc char(25);
  declare @barcode_item_code char(6);
  declare @barcode_batch_no char(15);
  declare @batch_key char(100);
  declare @BrCode char(6);
  declare @t_ltime char(25);
  declare @t_tray_move_time char(25);
  declare @t_pick_time char(25);
  declare @t_preserve_ltime char(25);
  declare @d_ldate char(20);
  declare @nUserValid integer;
  declare @RackGrpList char(7000);
  declare @rackGrp char(6);
  declare @ColSep char(6);
  declare @RowSep char(6);
  declare @assigned_user char(10);
  declare @Pos integer;
  declare @ColPos integer;
  declare @RowPos integer;
  declare @ColMaxLen numeric(4);
  declare @RowMaxLen numeric(4);
  declare @TrayUpdate numeric(1);
  --common <<
  declare @nSingleUser integer;
  --cIndex get_rack_group>>
  declare @ValidateRG integer;
  declare @ValidRGUser char(20);
  declare @rgCount integer;
  --cIndex get_rack_group<<
  --cIndex login_status>>
  declare @loginRGCount integer;
  declare @tmRGcount integer;
  declare @stageRGcount integer;
  declare @seltmRGcount integer;
  declare @n_pick_count integer;
  --cIndex login_status<<
  --cIndex get_doc_list >>	
  declare @LoginFlag char(1);
  declare @FirstRackGroup char(6);
  declare @FirstEmpInStage char(10);
  declare @t_s_time time;
  declare @t_e_time time;
  declare @next_rack_user char(10);
  declare @n_eb_flag integer;
  declare local temporary table "temp_rack_grp_list"(
    "c_rack_grp_code" char(6) null,
    "c_stage_code" char(6) null,
    "n_seq" numeric(6) null,) on commit preserve rows;
  declare @tmp char(20);
  -------Chnaged By Saneesh 
  declare local temporary table "tray_list"(
    "c_tray_code" char(6) null,
    "n_first_in_stage" numeric(1) null,
    "c_doc_no" char(25) null,
    "n_inout" numeric(1) null,
    "t_time" "datetime" null,
    "c_message" char(100) null,
    "n_item_count" numeric(6) null,
    "n_max_seq" numeric(6) null,
    "n_confirm" numeric(1) null,
    "n_urgent" numeric(1) null,
    "c_sort" char(10) null,
    "c_user" char(10) null,) on commit delete rows;
  --###
  -------Chnaged By Saneesh 			
  declare local temporary table "doc_list"(
    "c_doc_no" char(25) null,
    "n_first_in_stage" numeric(1) null,
    "c_doc_name" char(25) null,
    "c_tray_code" char(10) null,
    "n_inout" numeric(1) null,
    "c_message" char(100) null,
    "t_time_in" timestamp null,
    "tray_count" numeric(9) null,
    "n_item_count" numeric(9) null,
    "n_items_in_stage" numeric(9) null,
    "c_user" char(20) null,) on commit delete rows;
  -------Chnaged By Saneesh 	
  declare local temporary table "document_list"(
    "c_doc_no" char(25) null,
    "n_first_in_stage" numeric(1) null,
    "c_doc_name" char(25) null,
    "c_ref_no" char(25) null,
    "n_inout" numeric(1) null,
    "c_message" char(200) null,
    "t_time_in" timestamp null,
    "tray_count_rg" numeric(9) null,
    "tray_count_stage" numeric(9) null,
    "n_item_count" numeric(9) null,
    "n_items_in_stage" numeric(9) null,
    "n_confirm" numeric(9) null,
    "n_urgent" numeric(1) null,
    "c_sort" char(100) null,
    "c_user" char(20) null,
    "d_date" date null,
    "c_godown_code" char(6) null,
    "n_exp_doc" numeric(1) null,
    "c_note" char(100) null,
    "n_allow_not_found" numeric(1) null,
    "sr" numeric(9) null,
    "c_display_tray_no" char(4) null,
    ) on commit delete rows;
  declare local temporary table "batch_list"(
    "c_item_code" char(6) null,
    "c_batch_no" char(25) null,
    "n_mrp" numeric(11,3) null,
    "n_sale_rate" numeric(11,3) null,
    "d_exp_dt" date null,
    "n_act_stock_qty" numeric(11,3) null,
    "n_stock_qty" numeric(11,3) null,
    "n_issue_qty" numeric(11,3) null,
    "n_tran_exp_days" numeric(11,3) null,
    "n_godown_qty" numeric(11,3) null,
    ) on commit delete rows;
  declare @LastRGSeq integer;
  declare @CurrentRGSeq integer;
  declare @PrevRackGrp char(6);
  declare @RestrictFlag integer;
  declare @ValidateDevId char(50);
  declare @isLoggedOut integer;
  declare @LoginStatus char(5000);
  declare @IncompleteTray char(6);
  declare @nNotfoundItemCount integer;
  declare @nQtyMisMatchWOPick integer;
  declare @nQtyMisMatchWPick integer;
  --cIndex get_doc_list <<
  --cIndex set_selected_tray >>	
  declare @HdrData_Set_Selected_Tray char(7000);
  declare @cUser char(20);
  declare @DocNo char(25);
  declare @StartGrp char(6);
  declare @CurrentGrp char(6);
  declare @EndGrp char(6);
  declare @TranBrCode char(6);
  declare @TranPrefix char(4);
  declare @TranYear char(2);
  declare @TranSrno numeric(6);
  declare @CurrentTray char(20);
  declare @NextTray char(20);
  declare @ValidateTray numeric(1);
  declare @TrayExistsInRackGrp integer;
  declare @TrayExistsInTrackMove integer;
  declare @Tray_in_pick_list char(5000);
  declare @DocInTrackMove char(20);
  declare @LoginTime timestamp;
  declare @ActionStart timestamp;
  declare @isSoPo integer;
  declare @OldTray char(6);
  declare @nOldTrayItemCountPick integer;
  declare @nOldTrayItemCountDet integer;
  declare @cDocAlreadyAssignedToUser char(20);
  declare @cTrayAssigned char(6);
  declare @UnprocessedTray char(6);
  declare @UnprocessedDoc char(15);
  declare @UnmovedTray char(6);
  declare @nTrayAssigned integer;
  declare @nVerifyDocUser integer;
  declare @nFilterNoBatchItems integer;
  --cIndex set_selected_tray <<
  --cIndex get_batch_list <<
  declare @ItemCode char(6);
  declare @BatchNo char(20);
  declare @tranExpDays numeric(3);
  --cIndex get_batch_list <<
  --cIndex ItemDone
  declare @ForwardFlag numeric(1);
  declare @PickedQty integer;
  declare @RemainingQty integer;
  declare @ReasonCode char(6);
  --cIndex ItemDone<<
  --cIndex document_done>>
  declare @FirstInStage numeric(1);
  declare @Qty numeric(11);
  declare @Seq numeric(6);
  declare @OrgSeq numeric(6);
  declare @InOutFlag numeric(1);
  declare @HoldFlag numeric(1);
  declare @cReason char(10);
  declare @cNote char(100);
  declare @RackCode char(10);
  declare @DetSuccessFlag integer;
  declare @ItemNotFound integer;
  declare @ItemsInDetail integer;
  declare @nextRackGrp char(6);
  declare @maxSeq integer;
  declare @maxRackGrp char(6);
  declare @nDocItemCount integer;
  declare @nDocItemNotFoundCount integer;
  declare @nTrayFull integer;
  declare @nTrayInCurrRG integer;
  declare @nIter bigint;
  --godown request 
  declare @godownTo char(6);
  declare @godownFrom char(6);
  declare @NewSrno numeric(9);
  declare @nPrefixCount integer;
  --cIndex document_done<<    
  --cIndex change_tray>>
  declare @NewTray char(20);
  declare @AssignedDocNo char(20);
  declare @AssignedStageCode char(6);
  --cIndex change_tray<<
  --<< cIndex get_notif
  declare @storeInNotifNeeded integer;
  declare @storeInCount integer;
  declare @msgCount integer;
  --cIndex get_notif >>
  declare @li_gdn_count numeric(8);
  declare @d_gdn_qty numeric(8);
  declare @n_type integer;
  declare @CustCode char(6);
  declare @d_item_pick_count numeric(8);
  declare @d_item_bounce_count numeric(8);
  declare @d_qtp numeric(8);
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
    set @GodownCode = "http_variable"('GodownCode') --11		
  end if;
  select "n_active" into @enable_log from "st_track_module_mst" where "st_track_module_mst"."c_code" = 'M00039' and "st_track_module_mst"."c_br_code" = @gsBr;
  select "c_menu_id" into @display_base from "st_track_module_mst" where "st_track_module_mst"."n_active" = 1 and "st_track_module_mst"."c_code" = 'M00050' and "st_track_module_mst"."c_br_code" = @gsBr;
  if @display_base is null then
    set @display_base = 0
  end if;
  if @enable_log is null then
    set @enable_log = 0
  end if;
  select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
  select "c_delim" into @RowSep from "ps_tab_delimiter" where "n_seq" = 1;
  set @ColMaxLen = "Length"(@ColSep);
  set @RowMaxLen = "Length"(@RowSep);
  set @BrCode = "uf_get_br_code"(@gsBr);
  set @t_ltime = "left"("now"(),19);
  set @t_tray_move_time = "left"("now"(),19);
  set @d_ldate = "uf_default_date"();
  select top 1 "c_user" into @cUser from "logon_det" order by "n_srno" desc;
  --//select n_flag into @nSingleUser from st_store_stage_mst where c_code = @StageCode;
  --//For M00044<login @nSingleUser will be 1
  set @nSingleUser = 1;
  set @d_item_pick_count = 0;
  set @d_qtp = 1;
  set @d_item_bounce_count = 0;
  case @cIndex
  when 'get_store_stage' then -----------------------------------------------------------------------
    if(select "count"("c_code") from "st_store_stage_mst" where "n_cancel_flag" = 0) = 0 then
      select '' as "c_stage_code",
        '' as "c_stage_name",
        0 as "n_single_user",
        'Warning!! : No Stage found or All Stages are Locked' as "c_message" for xml raw,elements
    else
      select "st_store_stage_mst"."c_code" as "c_stage_code",
        "st_store_stage_mst"."c_name" as "c_stage_name",
        "st_store_stage_mst"."n_flag" as "n_single_user",
        "st_store_stage_mst"."n_pick_mode" as "n_pick_mode",
        '' as "c_message"
        from(select distinct '-' as "c_godown_code","c_stage_code" from "st_store_stage_det" as "st"
              ,(select distinct "c_rack_grp_code" from "item_mst_br_info","rack_mst"
                where "c_rack" = "rack_mst"."c_Code") as "x"
            where "x"."c_rack_grp_code" = "st"."c_rack_grp_code" and @GodownCode = '-' union
          select distinct "c_godown_Code","c_stage_code" from "st_store_stage_det" as "st"
              ,(select distinct "c_godown_Code","c_rack_grp_code" from "item_mst_br_info_godown","rack_mst"
                where "c_rack" = "rack_mst"."c_Code") as "x"
            where "x"."c_rack_grp_code" = "st"."c_rack_grp_code" and "x"."c_godown_code" = @GodownCode) as "stage_mst"
          join "st_store_stage_mst" on "stage_mst"."c_stage_code" = "st_store_stage_mst"."c_code"
        where "st_store_stage_mst"."n_cancel_flag" = 0
        order by 1 asc for xml raw,elements
    end if when 'get_rack_group' then -----------------------------------------------------------------------
    --STORE STAGE WISE RACK GROUP SELECTION
    select "rack_group_mst"."c_code" as "c_rack_grp_code",
      "rack_group_mst"."c_name" as "c_rack_grp_name",
      '' as "c_message"
      from "rack_group_mst"
        join "st_store_stage_det" on "rack_group_mst"."c_code" = "st_store_stage_det"."c_rack_grp_code"
        and "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
      --st_store_stage_det.c_stage_code = @StageCode
      where "rack_group_mst"."n_lock" = 0
      order by "st_store_stage_det"."n_pos_seq" asc for xml raw,elements
  when 'godown_mst' then -----------------------------------------------------------------------
    if(select "count"("c_code") from "godown_mst" where "n_lock" = 0) = 0 then
      select '' as "c_godown_code",
        '' as "c_godown_name",
        'Warning!! : No Godown found or All Godowns are Locked' as "c_message" for xml raw,elements
    else
      select "c_code" as "c_godown_code",
        "c_name" as "c_godown_name",
        '' as "c_message"
        from "godown_mst"
        where "n_lock" = 0
        order by 1 asc for xml raw,elements
    end if when 'get_doc_list' then -----------------------------------------------------------------------
    --DetData = LoginFlag**__ 	
    --1 LoginFlag //1 for the first call and 0 for consequent
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @LoginFlag = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --message 'LoginFlag '+@LoginFlag type warning to client;
    if @LoginFlag = '' then
      set @LoginFlag = 0
    end if;
    -----Changed By Saneesh 
    insert into "document_list"
      select "st_track_det"."c_doc_no" as "c_doc_no",
        1 as "n_first_in_stage",
        "st_track_det"."c_doc_no" as "c_doc_name",
        "st_track_det"."c_doc_no" as "c_ref_no",
        "st_track_det"."n_inout" as "n_inout",
        '' as "c_message",
        "st_track_mst"."t_time_in" as "t_time_in",
        (select "count"("c_doc_no") from "st_track_tray_move" where "c_doc_no" = "st_track_det"."c_doc_no") as "tray_count_rg",
        (select "count"("c_doc_no") from "st_track_tray_move" where "c_doc_no" = "st_track_det"."c_doc_no") as "tray_count_stage",
        "sum"(if "isnull"("st_track_det"."c_rack_grp_code",'') <> '' and "st_track_det"."n_complete" = 0 then 1 else 0 endif) as "n_item_count",
        "sum"(if "st_track_det"."n_complete" = 0 then 1 else 0 endif) as "n_items_in_stage",
        "st_track_mst"."n_confirm" as "n_confirm",
        if "isnull"("st_track_urgent_doc"."n_urgent",0) <> 4 then "st_track_mst"."n_urgent" else "st_track_urgent_doc"."n_urgent" endif as "n_urgent",
        "st_track_mst"."c_sort" as "c_sort",
        --(if @nSingleUser = 0 then st_track_det.c_user else '-' endif) as c_user,
        "max"("st_track_det"."c_user") as "c_user",
        "st_track_mst"."d_date" as "d_date",
        "st_track_det"."c_godown_code",
        "isnull"("godown_tran_mst"."n_eb_flag",0) as "n_exp_doc",
        "trim"("substring"("godown_tran_mst"."c_note","charindex"(':',"godown_tran_mst"."c_note")+1)) as "c_note",
        if "len"("trim"("isnull"("st_track_mst"."c_order_id",''))) <> 0 then
          0
        else
          1
        endif as "n_allow_not_found",
        "substr"("substr"("substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1),"charindex"('/',"substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1))+1),"charindex"('/',"substr"("substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1),"charindex"('/',"substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1))+1))+1) as "sr",
        if @display_base <> 0 then "right"('0'+"string"(cast("mod"("right"("string"("sr"),2),@display_base) as numeric(2))),2) else '' endif as "c_display_tray_no"
        from "st_track_det"
          join "st_track_mst" on "st_track_det"."c_doc_no" = "st_track_mst"."c_doc_no"
          and "st_track_det"."n_inout" = "st_track_mst"."n_inout"
          left outer join "godown_tran_mst"
          on "godown_tran_mst"."c_br_code" = "left"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")-1)
          and "godown_tran_mst"."c_year" = "left"("substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1),"charindex"('/',"substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1))-1)
          and "godown_tran_mst"."c_prefix" = "left"("substring"("substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1),"charindex"('/',"substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1),"charindex"('/',"substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1))+1))-1)
          and "godown_tran_mst"."n_srno" = "reverse"("left"("reverse"("st_track_det"."c_doc_no"),"charindex"('/',"reverse"("st_track_det"."c_doc_no"))-1))
          left outer join "st_track_urgent_doc" on "st_track_urgent_doc"."c_doc_no" = "st_track_det"."c_doc_no"
          and "st_track_urgent_doc"."n_inout" = "st_track_det"."n_inout"
        where "st_track_mst"."n_confirm" = 1 and "st_track_det"."n_inout" = 0
        and "st_track_det"."c_godown_code" = @GodownCode
        group by "st_track_det"."c_doc_no","st_track_det"."c_doc_no","st_track_det"."c_doc_no","st_track_det"."n_inout",
        "st_track_mst"."t_time_in","st_track_mst"."n_confirm","st_track_mst"."c_sort","st_track_mst"."d_date","st_track_det"."c_godown_code","n_urgent","n_exp_doc","c_note","n_allow_not_found";
    select
      "isnull"(
      (select "max"("c_tray_code")
        from "st_track_det"
        where "st_track_det"."c_doc_no" = "document_list"."c_doc_no"
        and "st_track_det"."n_complete" = 0
        and "st_track_det"."c_godown_code" = @GodownCode),
      '') as "c_tray_code",
      "n_first_in_stage",
      "c_doc_no",
      "n_inout",
      "c_message",
      "n_item_count",
      0 as "n_max_seq",
      "t_time_in" as "t_time",
      "tray_count_rg","tray_count_stage",
      "n_items_in_stage",
      "n_exp_doc",
      "c_note",
      "n_allow_not_found",
      "document_list"."c_user" as "c_user",
      "c_display_tray_no"
      --user_wise_doc_selection.c_user as nuser
      from "document_list" left outer join "user_wise_doc_selection"
        on "document_list"."c_doc_no" = "user_wise_doc_selection"."c_br_code"+'/'+"user_wise_doc_selection"."c_year"+'/'+"user_wise_doc_selection"."c_prefix"+'/'+"string"("user_wise_doc_selection"."n_srno")
      where(select "count"("sd"."c_doc_no")
        from "st_track_det" as "sd"
        where "sd"."c_doc_no" = "document_list"."c_doc_no"
        and("sd"."c_rack" is null or "sd"."c_stage_code" is null or "sd"."c_rack_grp_code" is null)
        and "sd"."c_godown_code" = @GodownCode) = 0
      --and isnull(document_list.c_user,'-') = (if @nSingleUser = 0 then(if document_list.c_user is null then isnull(document_list.c_user,'-') else @UserId endif) else isnull(document_list.c_user,'-') endif)
      --and (document_list.c_user is null or  document_list.c_user = @UserId)
      and("user_wise_doc_selection"."c_user" is null or "user_wise_doc_selection"."c_user" = @UserId)
      and "document_list"."n_inout" = 0
      and("tray_count_rg" > 0 or "tray_count_stage" = 0 or "n_item_count" > 0)
      and "n_items_in_stage" > 0
      order by(if "c_tray_code" = '' then 'zzzzzz' else "c_tray_code" endif) asc,"document_list"."n_urgent" desc,"document_list"."d_date" asc,"c_sort" asc,"document_list"."t_time_in" asc,"document_list"."c_doc_no" asc for xml raw,elements
  when 'set_selected_tray' then -----------------------------------------------------------------------
    --@HdrData  : 1 Tranbrcode~2 TranYear~3 TranPrefix~4 TranSrno~5 CurrentTray~6 FirstInStage~7 OldTray~8 nVerifyDocUser~9 nFilterNoBatchItems
    --@DetData : ValidateTray**__
    --(validateTray : 1 - new tray assigned ,
    --	- to retrieve the items in the existing tray)
    --call usp_set_selected_tray(@UserId,@HdrData,@DetData,@RackGrpCode,@StageCode,@GodownCode,@gsBr,@t_preserve_ltime);
    --return
    --HdrData
    --1 Tranbrcode~2 TranYear~3 TranPrefix~4 TranSrno~5 CurrentTray~6 FirstInStage~7 OldTray
    --1 Tranbrcode
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @Tranbrcode = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --2 TranYear
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranYear = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --3 TranPrefix
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranPrefix = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --4 TranSrno
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranSrno = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --5 CurrentTray
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @CurrentTray = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --6 FirstInStage (1/0)
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @FirstInStage = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --7 OldTray
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @OldTray = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --8 nVerifyDocUser
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @nVerifyDocUser = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --9 nFilterNoBatchItems
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @nFilterNoBatchItems = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --@DetData : ValidateTray**TrayUpdate**@nTrayFull**__
    --1 ValidateTray
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @ValidateTray = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --1 TrayUpdate
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @TrayUpdate = cast("Trim"("Left"(@DetData,@ColPos-1)) as numeric(1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    set @DocNo = @Tranbrcode+'/'+@TranYear+'/'+@TranPrefix+'/'+"string"(@TranSrno);
    select top 1 "c_user" into @assigned_user from "St_track_det" where "c_doc_no" = @DocNo and "c_user" <> @UserId;
    if @assigned_user is null or "trim"(@assigned_user) = '' then
    else
      select 'Document Number '+@DocNo+' is already taken By the User '+@assigned_user as "c_message" for xml raw,elements;
      return
    end if;
    --Update  the user id for the selected doc 
    update "st_track_det" set "c_user" = @UserId where "c_doc_no" = @DocNo;
    if @TranPrefix = '6' or @TranPrefix = 'O' or @TranPrefix = '162' then
      select "st_track_det"."c_doc_no" as "c_doc_no",
        "st_track_det"."n_inout" as "n_inout",
        "item_mst"."c_code" as "c_item_code",
        "isnull"("st_track_det"."c_batch_no",'') as "c_batch_no",
        "st_track_det"."n_seq" as "n_seq",
        "TRIM"("STR"("TRUNCNUM"("st_track_det"."n_qty",3),10,0)) as "n_qty",
        "TRIM"("STR"("TRUNCNUM"("st_track_det"."n_bal_qty",3),10,0)) as "n_bal_qty",
        "st_track_det"."c_note" as "c_note",
        "st_track_det"."c_rack" as "c_rack",
        "st_track_det"."c_rack_grp_code" as "c_rack_grp_code",
        "st_track_det"."c_stage_code" as "c_stage_code",
        "st_track_det"."n_complete" as "n_complete",
        "st_track_det"."c_reason_code" as "c_reason",
        "st_track_det"."n_hold_flag" as "n_hold_flag",
        "st_track_det"."c_tray_code" as "c_tray_code",
        "item_mst"."c_name"+"uf_st_get_pack_name"("pack_mst"."c_name") as "c_item_name",
        "pack_mst"."c_name" as "c_pack_name",
        (select "c_name" from "rack_mst" where "c_code" = "st_track_det"."c_rack" and "rack_mst"."c_br_code" = @BrCode) as "c_rack_name",
        '' as "d_exp_dt",
        0 as "n_mrp",
        (select "c_name" from "st_tray_mst" where "c_code" = "st_track_det"."c_tray_code") as "c_tray_name",
        "item_mst"."n_qty_per_box" as "n_qty_per_box",
        'Success' as "c_message",
        "isnull"("item_mst"."c_barcode"+',','')+"isnull"((select "list"("c_barcode") from "item_multi_barcode_det" where "c_item_code" = "st_track_det"."c_item_code"),'') as "c_barcode_list",
        "isnull"("n_inner_pack_lot",0) as "n_inner_pack_lot",
        --isnull((select count(c_item_code) from st_track_pick where c_doc_no = @DocNo and c_tray_code = @CurrentTray and st_track_pick.n_confirm_qty+st_track_pick.n_reject_qty = 0),0) as n_tray_item_count,
        "isnull"((select "count"("c_item_code") from "st_track_pick" where "c_doc_no" = @DocNo and "st_track_pick"."n_confirm_qty"+"st_track_pick"."n_reject_qty" = 0),0) as "n_tray_item_count",
        (select "list"("win_meet_note"."c_note")
          from "win_meet_note"
          where "win_meet_note"."c_key" = "item_mst"."c_code"
          and "win_meet_note"."c_win_name" = 'w_ITEM_MST'
          and "win_meet_note"."n_cancel_flag" = 0
          and "win_meet_note"."c_note_type" = 'TALRTO') as "c_alert_msg",
        if "st_track_item_error"."c_item_code" is null then 0 else 1 endif as "n_error_mark",
        "reason_mst"."c_name" as "c_error_type",
        "st_phase_mst"."c_name" as "c_phase_name",
        "st_track_item_error"."c_marked_user" as "c_error_marked_by",
        "st_track_item_error"."c_pik_user" as "c_piked_user",
        "st_track_item_error"."c_remark" as "c_err_remark",
        "st_track_item_error"."t_time" as "t_error_time",
        if "len"("trim"("isnull"("st_track_mst"."c_order_id",''))) <> 0 then
          0
        else
          1
        endif as "n_allow_not_found",
        (if(select "isnull"("sum"("item_mst_br_info_excess"."n_qty"),0) from "item_mst_br_info_excess" where "item_mst_br_info_excess"."c_br_code" = @gsBr and "st_track_det"."c_item_code" = "item_mst_br_info_excess"."c_code") > 0 then 1 else 0 endif) as "n_multiple_rack_flag",
        (select "list"("bin_shift_log"."c_temp_rack",',')
          from "bin_shift_log"
          where "bin_shift_log"."c_br_code" = cast(@gsBr as char(6))
          and "bin_shift_log"."c_item_code" = "item_mst"."c_code"
          and "isnull"("bin_shift_log"."c_bin_shift_user",'') = '') as "c_temprack",
        if @display_base <> 0 then
          "right"('0'+"string"(cast("mod"("right"("string"("substr"("substr"("substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1),
          "charindex"('/',"substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1))+1),
          "charindex"('/',"substr"("substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1),
          "charindex"('/',"substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1))+1))+1)),2),@display_base) as numeric(2))),2)
        else ''
        endif as "c_display_tray_no","mfac_mst"."c_sh_name"+@ColSep+"mfac_mst"."c_name" as "mfac_name"
        from "st_track_det"
          join "st_track_mst" on "st_track_mst"."c_doc_no" = "st_track_det"."c_doc_no"
          and "st_track_mst"."n_inout" = "st_track_det"."n_inout"
          join "item_mst" on "st_track_det"."c_item_code" = "item_mst"."c_code"
          ,"item_mst" join "pack_mst" on "pack_mst"."c_code" = "item_mst"."c_pack_code"
          join "mfac_mst" on "mfac_mst"."c_code" = "item_mst"."c_mfac_code"
          left outer join "st_track_item_error" on "st_track_item_error"."c_item_code" = "item_mst"."c_code"
          left outer join "reason_mst" on "st_track_item_error"."c_reason_code" = "reason_mst"."c_code"
          left outer join "st_phase_mst" on "st_phase_mst"."c_code" = "st_track_item_error"."c_phase_code"
        where "st_track_det"."c_doc_no" = @DocNo --'024/13/S/1'
        --and st_track_det.c_tray_code = @CurrentTray --(if @FirstInStage = 1 then st_track_det.c_tray_code else @CurrentTray endif)
        and "st_track_det"."c_godown_code" = @GodownCode
        and "st_track_det"."n_complete" = 0
        order by "c_rack" asc for xml raw,elements
    else
      select "st_track_det"."c_doc_no" as "c_doc_no",
        "st_track_det"."n_inout" as "n_inout",
        "item_mst"."c_code" as "c_item_code",
        "isnull"("stock"."c_batch_no",'') as "c_batch_no",
        "st_track_det"."n_seq" as "n_seq",
        "TRIM"("STR"("TRUNCNUM"("st_track_det"."n_qty",3),10,0)) as "n_qty",
        "TRIM"("STR"("TRUNCNUM"("st_track_det"."n_bal_qty",3),10,0)) as "n_bal_qty",
        "st_track_det"."c_note" as "c_note",
        "st_track_det"."c_rack" as "c_rack",
        "st_track_det"."c_rack_grp_code" as "c_rack_grp_code",
        "st_track_det"."c_stage_code" as "c_stage_code",
        "st_track_det"."n_complete" as "n_complete",
        "st_track_det"."c_reason_code" as "c_reason",
        "st_track_det"."n_hold_flag" as "n_hold_flag",
        "st_track_det"."c_tray_code" as "c_tray_code",
        "item_mst"."c_name"+"uf_st_get_pack_name"("pack_mst"."c_name") as "c_item_name",
        "pack_mst"."c_name" as "c_pack_name",
        (select "c_name" from "rack_mst" where "c_code" = "st_track_det"."c_rack" and "rack_mst"."c_br_code" = @BrCode) as "c_rack_name",
        "isnull"("stock_mst"."d_exp_dt",null) as "d_exp_dt",
        "TRIM"("STR"("TRUNCNUM"("stock_mst"."n_mrp",3),10,3)) as "n_mrp",
        (select "c_name" from "st_tray_mst" where "c_code" = "st_track_det"."c_tray_code") as "c_tray_name",
        "item_mst"."n_qty_per_box" as "n_qty_per_box",
        'Success' as "c_message",
        "isnull"("item_mst"."c_barcode"+',','')+"isnull"((select "list"("c_barcode") from "item_multi_barcode_det" where "c_item_code" = "st_track_det"."c_item_code"),'') as "c_barcode_list",
        "isnull"("n_inner_pack_lot",0) as "n_inner_pack_lot",
        "isnull"((select "count"("c_item_code") from "st_track_pick" where "c_doc_no" = @DocNo and "c_tray_code" = @CurrentTray and "st_track_pick"."n_confirm_qty"+"st_track_pick"."n_reject_qty" = 0),0) as "n_tray_item_count",
        (select "list"("win_meet_note"."c_note")
          from "win_meet_note"
          where "win_meet_note"."c_key" = "item_mst"."c_code"
          and "win_meet_note"."c_win_name" = 'w_ITEM_MST'
          and "win_meet_note"."n_cancel_flag" = 0
          and "win_meet_note"."c_note_type" = 'TALRTO') as "c_alert_msg",
        if "st_track_item_error"."c_item_code" is null then 0 else 1 endif as "n_error_mark",
        "reason_mst"."c_name" as "c_error_type",
        "st_phase_mst"."c_name" as "c_phase_name",
        "st_track_item_error"."c_marked_user" as "c_error_marked_by",
        "st_track_item_error"."c_pik_user" as "c_piked_user",
        "st_track_item_error"."c_remark" as "c_err_remark",
        "st_track_item_error"."t_time" as "t_error_time",
        if "len"("trim"("isnull"("st_track_mst"."c_order_id",''))) <> 0 then
          0
        else
          1
        endif as "n_allow_not_found",
        ---------->>>>  SYAM
        (if(select "isnull"("sum"("item_mst_br_info_excess"."n_qty"),0) from "item_mst_br_info_excess" where "item_mst_br_info_excess"."c_br_code" = @gsBr and "st_track_det"."c_item_code" = "item_mst_br_info_excess"."c_code") > 0 then 1 else 0 endif) as "n_multiple_rack_flag",
        (select "list"("bin_shift_log"."c_temp_rack",',')
          from "bin_shift_log"
          where "bin_shift_log"."c_br_code" = cast(@gsBr as char(6))
          and "bin_shift_log"."c_item_code" = "item_mst"."c_code"
          and "isnull"("bin_shift_log"."c_bin_shift_user",'') = '') as "c_temprack",
        if @display_base <> 0 then
          "right"('0'+"string"(cast("mod"("right"("string"("substr"("substr"("substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1),
          "charindex"('/',"substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1))+1),
          "charindex"('/',"substr"("substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1),
          "charindex"('/',"substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1))+1))+1)),2),@display_base) as numeric(2))),2)
        else ''
        endif as "c_display_tray_no","mfac_mst"."c_sh_name"+@ColSep+"mfac_mst"."c_name" as "mfac_name"
        ---------->>>>      
        from "st_track_det"
          join "st_track_mst" on "st_track_mst"."c_doc_no" = "st_track_det"."c_doc_no"
          and "st_track_mst"."n_inout" = "st_track_det"."n_inout"
          join "item_mst" on "st_track_det"."c_item_code" = "item_mst"."c_code"
          left outer join "stock" on "stock"."c_item_code" = "st_track_det"."c_item_code"
          and "stock"."c_batch_no" = "st_track_det"."c_batch_no"
          and "stock"."c_br_code" = @TranBrCode
          ,"stock"
          left outer join "stock_mst" on "stock"."c_item_code" = "stock_mst"."c_item_code"
          and "stock"."c_batch_no" = "stock_mst"."c_batch_no"
          ,"item_mst" join "pack_mst" on "pack_mst"."c_code" = "item_mst"."c_pack_code"
          join "mfac_mst" on "mfac_mst"."c_code" = "item_mst"."c_mfac_code"
          left outer join "st_track_item_error" on "st_track_item_error"."c_item_code" = "item_mst"."c_code"
          left outer join "reason_mst" on "st_track_item_error"."c_reason_code" = "reason_mst"."c_code"
          left outer join "st_phase_mst" on "st_phase_mst"."c_code" = "st_track_item_error"."c_phase_code"
        where "st_track_det"."c_doc_no" = @DocNo --'024/13/S/1'
        and "st_track_det"."c_tray_code" = @CurrentTray --(if @FirstInStage = 1 then st_track_det.c_tray_code else @CurrentTray endif)
        and "st_track_det"."n_complete" = 0
        and "st_track_det"."c_godown_code" = @GodownCode
        order by "c_rack" asc for xml raw,elements
    end if when 'get_batch_list' then -----------------------------------------------------------------------
    --DetData = @ItemCode**@BatchNo**__
    --HdrData
    --1 Tranbrcode~2 TranYear~3 TranPrefix~4 TranSrno
    --1 Tranbrcode
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @Tranbrcode = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --2 TranYear
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranYear = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --3 TranPrefix
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranPrefix = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --4 TranSrno
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranSrno = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --DetData = @ItemCode**@BatchNo**__
    --1 ItemCode
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @ItemCode = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --2 BatchNo
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @BatchNo = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    set @DocNo = @Tranbrcode+'/'+@TranYear+'/'+@TranPrefix+'/'+"string"(@TranSrno);
    set @tranExpDays = 0;
    case(@TranPrefix)
    when 'S' then
      set @tranExpDays
         = "isnull"(
        (select "n_sale_exp_days" as "n_sale_exp_days"
          from "item_group_mst"
            join "item_mst" on "item_group_mst"."c_code" = "item_mst"."c_group_code"
          where "item_mst"."c_code" = @ItemCode
          and @TranPrefix = 'S'),
        50)
    when 'T' then
      set @tranExpDays
         = "isnull"(
        (select "n_sale_exp_days" as "n_sale_exp_days"
          from "item_group_mst"
            join "item_mst" on "item_group_mst"."c_code" = "item_mst"."c_group_code"
          where "item_mst"."c_code" = @ItemCode
          and @TranPrefix = 'T'),
        50)
    when 'N' then
      set @tranExpDays
         = "isnull"(
        (select "n_gdn_exp_days" as "n_gdn_exp_days"
          from "item_group_mst"
            join "item_mst" on "item_group_mst"."c_code" = "item_mst"."c_group_code"
          where "item_mst"."c_code" = @ItemCode
          and @TranPrefix = 'N'),
        50)
    when '6' then
      set @tranExpDays
         = "isnull"(
        (select "n_gdn_exp_days" as "n_gdn_exp_days"
          from "item_group_mst"
            join "item_mst" on "item_group_mst"."c_code" = "item_mst"."c_group_code"
          where "item_mst"."c_code" = @ItemCode
          and @TranPrefix = '6'),
        50)
    when 'O' then
      select "c_cust_code" into @CustCode from "st_track_mst" where "c_doc_no" = @DocNo;
      select "n_type" into @n_type from "act_mst" where "act_mst"."c_code" = @CustCode;
      if @n_type = 3 then --Gdn
        set @tranExpDays
           = "isnull"(
          (select "n_gdn_exp_days" as "n_gdn_exp_days"
            from "item_group_mst"
              join "item_mst" on "item_group_mst"."c_code" = "item_mst"."c_group_code"
            where "item_mst"."c_code" = @ItemCode
            and @TranPrefix = 'O'),
          50)
      else
        if @n_type = 2 then --Inv 
          set @tranExpDays
             = "isnull"(
            (select "n_sale_exp_days" as "n_sale_exp_days"
              from "item_group_mst"
                join "item_mst"
                on "item_group_mst"."c_code" = "item_mst"."c_group_code"
              where "item_mst"."c_code" = @ItemCode and @TranPrefix = 'O'),
            50)
        else
          set @tranExpDays = 50
        -----------------------
        end if
      end if
    end case;
    select "n_eb_flag" into @n_eb_flag from "godown_tran_mst"
      where "c_br_code" = @Tranbrcode
      and "c_year" = @TranYear
      and "c_prefix" = @TranPrefix
      and "n_srno" = @TranSrno;
    if @n_eb_flag = 1 then --For Stock removal of Expiry Items in Pick/pack 
      insert into "batch_list"
        select "stock_mst"."c_item_code" as "c_item_code",
          "stock_mst"."c_batch_no" as "c_batch_no",
          "stock_mst"."n_mrp" as "n_mrp",
          "stock_mst"."n_sale_rate" as "n_sale_rate",
          "stock_mst"."d_exp_dt" as "d_exp_dt",
          (("stock"."n_bal_qty"-"stock"."n_hold_qty"-"Isnull"("stock"."n_dc_inv_qty",0)-(if "n_godown_qty" < 0 then 0 else "n_godown_qty" endif))) as "n_act_stock_qty",
          (if @GodownCode = '-' then
            ("stock"."n_bal_qty"-"stock"."n_hold_qty"-"Isnull"("stock"."n_dc_inv_qty",0)-(if "n_godown_qty" < 0 then 0 else "n_godown_qty" endif))
          else
            if "n_act_stock_qty" < 0 then "n_godown_qty"-"abs"("n_act_stock_qty") else "n_godown_qty" endif
          endif) as "n_stock_qty",
          0 as "n_issue_qty",
          0 as "n_tran_exp_days",
          "isnull"((select "sum"("n_qty"-"n_hold_qty") from "stock_godown" where "c_br_code" = @BrCode and "c_item_code" = @ItemCode and "c_batch_no" = "stock"."c_batch_no" and "c_godown_code" = (if @GodownCode = '-' then "c_godown_code" else @GodownCode endif)),0) as "n_godown_qty"
          from "stock"
            join "stock_mst" on "stock"."c_item_code" = "stock_mst"."c_item_code"
            and "stock"."c_batch_no" = "stock_mst"."c_batch_no"
          where "stock"."c_br_code" = @BrCode
          and "stock"."c_item_code" = @ItemCode
          --and stock.n_bal_qty > 0
          --and n_act_stock_qty > 0 
          and "n_stock_qty" > 0
    else --They will remove future expiry items also 
      --and stock_mst.d_exp_dt < uf_default_date()
      insert into "batch_list"
        select "stock_mst"."c_item_code" as "c_item_code1",
          "stock_mst"."c_batch_no" as "c_batch_no",
          "stock_mst"."n_mrp" as "n_mrp",
          "stock_mst"."n_sale_rate" as "n_sale_rate",
          "stock_mst"."d_exp_dt" as "d_exp_dt",
          (("stock"."n_bal_qty"-"stock"."n_hold_qty"-"Isnull"("stock"."n_dc_inv_qty",0)-(if "n_godown_qty" < 0 then 0 else "n_godown_qty" endif))) as "n_act_stock_qty",
          (if @GodownCode = '-' then
            ("stock"."n_bal_qty"-"stock"."n_hold_qty"-"Isnull"("stock"."n_dc_inv_qty",0)-(if "n_godown_qty" < 0 then 0 else "n_godown_qty" endif))
          else
            if "n_act_stock_qty" < 0 then "n_godown_qty"-"abs"("n_act_stock_qty") else "n_godown_qty" endif
          endif) as "n_stock_qty",
          0 as "n_issue_qty",
          @tranExpDays as "n_tran_exp_days",
          "isnull"((select "sum"("n_qty"-"n_hold_qty") from "stock_godown" where "c_br_code" = @BrCode and "c_item_code" = @ItemCode and "c_batch_no" = "stock"."c_batch_no" and "c_godown_code" = (if @GodownCode = '-' then "c_godown_code" else @GodownCode endif)),0) as "n_godown_qty"
          from "stock"
            join "stock_mst" on "stock"."c_item_code" = "stock_mst"."c_item_code"
            and "stock"."c_batch_no" = "stock_mst"."c_batch_no"
          where "stock"."c_br_code" = @BrCode
          and "stock"."c_item_code" = @ItemCode
          and "stock"."n_bal_qty" > 0
          --and dateadd(day,(-1)*n_tran_exp_days,stock_mst.d_exp_dt) >= uf_default_date() union all
          and "dateadd"("day",(-1)*"n_tran_exp_days","ymd"("year"("stock_mst"."d_exp_dt"),"right"('00'+"string"("month"("stock_mst"."d_exp_dt")),2),1)) >= "uf_default_date"() union all
        select "st_track_det"."c_item_code" as "c_item_code",
          "st_track_det"."c_batch_no" as "c_batch_no",
          "stock_mst"."n_mrp" as "n_mrp",
          "stock_mst"."n_sale_rate" as "n_sale_rate",
          "stock_mst"."d_exp_dt" as "d_exp_dt",
          0 as "n_act_stock_qty",
          0 as "n_stock_qty",
          (if "st_track_det"."n_complete" = 2 and "st_track_det"."n_bal_qty" < "st_track_det"."n_qty" then "st_track_det"."n_bal_qty" else "st_track_det"."n_qty" endif) as "n_issue_qty",
          0 as "n_tran_exp_days",
          0 as "n_godown_qty"
          from "st_track_det"
            left outer join "stock_mst" on "stock_mst"."c_item_code" = "st_track_det"."c_item_code"
            and "stock_mst"."c_batch_no" = "st_track_det"."c_batch_no"
            -- and stock_mst.d_exp_dt >= uf_default_date()
            and "ymd"("year"("stock_mst"."d_exp_dt"),"right"('00'+"string"("month"("stock_mst"."d_exp_dt")),2),1) >= "uf_default_date"()
          where "st_track_det"."c_item_code" = @ItemCode
          and "st_track_det"."c_batch_no" is not null
          and "st_track_det"."n_hold_flag" = 0
          and "n_issue_qty" > 0
          and "st_track_det"."n_inout" = 0
          and "st_track_det"."n_complete" not in( 1,9 ) 
          and "st_track_det"."c_godown_code" = @GodownCode
    end if;
    select "batch_list"."c_batch_no",
      "max"("batch_list"."n_mrp") as "n_mrp",
      "max"("batch_list"."n_sale_rate") as "n_sale_rate",
      "date"("max"("batch_list"."d_exp_dt")) as "d_exp_dt",
      "TRIM"("STR"("TRUNCNUM"("sum"("batch_list"."n_stock_qty")+"sum"("batch_list"."n_issue_qty"),3),10,0)) as "n_bal_qty",
      "item_mst"."n_qty_per_box" as "n_qty_per_box",
      "TRIM"("STR"("TRUNCNUM"("sum"("batch_list"."n_stock_qty"),3),10,0)) as "n_eg_stock"
      from "batch_list"
        join "item_mst" on "item_mst"."c_code" = "batch_list"."c_item_code"
      where "item_mst"."c_code" = @ItemCode
      group by "batch_list"."c_batch_no","n_qty_per_box"
      having "n_bal_qty" > 0
      order by 4 asc for xml raw,elements
  when 'document_done' then -----------------------------------------------------------------------
    /*
@HdrData :  1 ItemsInDetail~2 Tranbrcode~3 TranYear~4 TranPrefix~5 TranSrno
~6 @CurrentTray~7 InOutFlag 8 ~nTrayFull 
If @HdrData Contains the @HdrData arg  vals of Set_selected_Tray Index  ,@NextTray  = 1 ,else NextTray =0 
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
    --print('@HdrData_Set_Selected_Tray' + @HdrData_Set_Selected_Tray);
    select "Locate"(@HdrData,'~') into @ColPos;
    if @HdrData_Set_Selected_Tray is null or "trim"(@HdrData_Set_Selected_Tray) = '' then
      set @NextTray = ''
    else
      set @NextTray = '1'
    end if;
    set @DocNo = @Tranbrcode+'/'+@TranYear+'/'+@TranPrefix+'/'+"string"(@TranSrno);
    if @removed_doc_flag = 2 then
      select 'Success' as "c_message" for xml raw,elements;
      return
    end if;
    if @DetData = '' and @nTrayFull = 1 and @CurrentTray <> '-nulltray-' then
      --second RACK GRP USER in the sequence if clicks on tray full validate if no items in tray 
      --if item_count in tray = 0 then error 
      select "count"("c_tray_code")
        into @nOldTrayItemCountPick from "DBA"."st_track_pick"
        where "c_tray_code" = @CurrentTray
        and "c_doc_no" = @DocNo
    end if;
    set @RackGrpList = @RackGrpCode;
    if @enable_log = 1 then
      insert into "st_doc_done_log"
        ( "c_doc","c_tray","c_stage","c_hdr","c_det","c_rg","n_item_det_flag","n_item_count","n_bounce_cnt","n_tray_full","t_s_time" ) values
        ( @DocNo,"LEFT"(@CurrentTray,6),'',@hdr_data,@hdr_det,@RackGrpCode,@ItemsInDetail,null,null,if @NextTray = '1' then 1 else 0 endif,"getdate"() ) ;
      set @log_seq = @@identity
    end if;
    if @CurrentTray = '-nulltray-' then
      select top 1 "det"."c_tray_code"
        into @CurrentTray from "st_track_det" as "det"
        where "det"."c_doc_no" = @DocNo
        and "det"."c_godown_code" = @GodownCode;
      if @CurrentTray is null or @CurrentTray = '-nulltray-' then
        if @enable_log = 1 then
          insert into "st_log_ret"
            ( "c_doc_no","c_tray","c_stage","c_rg","n_flag","t_time" ) values
            ( @DocNo,@CurrentTray,@StageCode,'Not Tray '+"isnull"("RackGrpCode",':'),2,"getdate"() ) ;
          update "st_doc_done_log" set "n_delete" = 3 where "n_seq" = @log_seq
        end if;
        select 'Warning!! : No Tray assigned for Document - '+"string"(@DocNo) as "c_message" for xml raw,elements;
        return
      end if end if;
    --EXTRACT USER SELECTED RACK GROUPS			
    --set @RackGrpList = @RackGrpCode; --shifted above
    while @RackGrpList <> '' loop
      --1 RackGrpList
      --RackGrpList = RG0001**RG0002**__
      select "Locate"(@RackGrpList,@ColSep) into @ColPos;
      set @tmp = "Trim"("Left"(@RackGrpList,@ColPos-1));
      set @RackGrpList = "SubString"(@RackGrpList,@ColPos+@ColMaxLen);
      if(select "COUNT"("C_CODE") from "RACK_GROUP_MST" where "C_CODE" = @tmp) > 0 then --valid rack group selection 
        select "n_pos_seq" into @Seq from "st_store_stage_det" where "c_rack_grp_code" = @tmp;
        insert into "temp_rack_grp_list"( "c_rack_grp_code","c_stage_code","n_seq" ) values( @tmp,@StageCode,@Seq ) 
      end if
    end loop;
    set @nIter = 0;
    /*//Shifted from down by Dileep
select c_rack_grp_code
into @nextRackGrp from st_store_stage_det
where c_stage_code = @StageCode and n_pos_seq = any(select top 1 n_seq+1 as n_seq from temp_rack_grp_list
order by n_seq desc); */
    set @nextRackGrp = '';
    while @DetData <> '' and @ItemsInDetail = 1 loop
      /*
@DetData : 1 InOutFlag~2 Seq~3 OrgSeq~4 ItemCode~5 BatchNo
~6 Qty~7 HoldFlag~8 cReason~9 cNote~10 CurrentTray
~11 RackCode~12 CurrentGrp~13 ItemNotFound ~14 t_pick_time
*/
      --saneesh
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
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @CurrentTray = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      if @nIter = 1 then --check for server response error
        --//Added on 02/11/16 by Dileep to avoid double document_done 
        --//###-----------------------------------------------------###
        select "sum"("isnull"("n_tray_flag",0))
          into @tray_in_progress from "st_track_tray_move","temp_rack_grp_list"
          where "temp_rack_grp_list"."c_rack_grp_code" = "st_track_tray_move"."c_rack_grp_code"
          and "st_track_tray_move"."c_doc_no" = @DocNo
          and "st_track_tray_move"."c_tray_code" = @CurrentTray;
        if @tray_in_progress is null then
          set @tray_in_progress = 0
        end if;
        if @tray_in_progress = 0 then
          if(select "count"() from "st_track_tray_move"
              where "c_doc_no" = @DocNo
              and "c_tray_code" = @CurrentTray
              --and c_stage_code = @StageCode
              and "c_rack_grp_code" = "isnull"(@nextRackGrp,'-')) = 0 then
            update "st_track_tray_move" set "n_tray_flag" = 1 from "temp_rack_grp_list"
              where "temp_rack_grp_list"."c_rack_grp_code" = "st_track_tray_move"."c_rack_grp_code"
              and "st_track_tray_move"."c_doc_no" = @DocNo
              and "st_track_tray_move"."c_tray_code" = @CurrentTray
          else
            //DebugLog
            if @enable_log = 1 then
              insert into "st_log_ret"
                ( "c_doc_no","c_tray","c_stage","c_rg","n_flag","t_time" ) values
                ( @DocNo,@CurrentTray,@StageCode,'Tray alrdy moved',0,"getdate"() ) 
            end if;
            --select 'Tray & Document Already Moved/Processed '+@CurrentTray+' & '+@DocNo as c_message for xml raw,elements;
            select 'Success' as "c_message" for xml raw,elements;
            return
          //DebugLog
          end if
        else if @enable_log = 1 then
            insert into "st_log_ret"
              ( "c_doc_no","c_tray","c_stage","c_rg","n_flag","t_time" ) values
              ( @DocNo,@CurrentTray,@StageCode,'Tray in process',1,"getdate"() ) 
          end if;
          --select 'Tray & Document Already in inprogress '+@CurrentTray+' & '+@DocNo as c_message for xml raw,elements;
          select 'Success' as "c_message" for xml raw,elements;
          return
        end if;
        //###-----------------------------------------------------###
        select "count"("c_tray_code")
          into @nTrayInCurrRG from "st_track_tray_move" as "tm"
            join "temp_rack_grp_list" as "rg" on "tm"."c_rack_grp_code" = "rg"."c_rack_grp_code"
          where "tm"."c_tray_code" = @CurrentTray;
        if(@nTrayInCurrRG) = 0 then
          -- INCASE OF DUPLICATE DOCUMENT DONE CALL
          --tray is already moved to next rack group or the tray being moved, is not present in tray move table
          select "max"("st_track_pick"."n_seq") as "n_max_seq"
            into @maxSeq from "st_track_pick"
              join "temp_rack_grp_list" on "st_track_pick"."c_rack_grp_code" = "temp_rack_grp_list"."c_rack_grp_code"
            where "st_track_pick"."c_doc_no" = @DocNo
            --and st_track_pick.c_stage_code = @StageCode
            and "st_track_pick"."c_godown_code" = @GodownCode;
          select 'Success' as "c_message",@maxSeq as "n_max_seq" for xml raw,elements;
          return
        end if end if;
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
      select "Locate"(@DetData,@RowSep) into @RowPos;
      set @DetData = "SubString"(@DetData,@RowPos+@RowMaxLen);
      --Saneesh 11 oct 2018
      if @ItemNotFound = 1 and @TranPrefix = '6' then
        select "count"()
          into @li_gdn_count from "ord_ledger"
          where "ord_ledger"."c_br_code" = @TranBrCode
          and "ord_ledger"."c_year" = @TranYear
          and "ord_ledger"."c_prefix" = @TranPrefix
          and "ord_ledger"."n_srno" = @TranSrno
          and "ord_ledger"."n_seq" = @OrgSeq
          and "ord_ledger"."c_item_code" = @ItemCode;
        if @li_gdn_count = 0 then --Insert
          select "n_qty_per_box" into @d_qtp from "item_mst" where "c_code" = @ItemCode;
          if @d_qtp is null then
            set @d_qtp = 1
          end if;
          insert into "ord_ledger"
            ( "c_br_code","c_year","c_prefix","n_srno","n_seq",
            "c_item_code","n_qty","n_issue_qty","n_cancel_qty",
            "n_rate","n_sch_qty","c_ref_br_code","n_pk" ) on existing skip
            select @TranBrCode,@TranYear,@TranPrefix,@TranSrno,"st_track_det"."n_seq",
              @ItemCode,@Qty*@d_qtp,0,@Qty*@d_qtp,
              "ord_det"."n_rate",0,@TranBrCode,''
              from "st_track_det" join "ord_det"
                on "ord_det"."c_br_code"+'/'+"ord_det"."c_year"+'/'+"ord_det"."c_prefix"+'/'+"string"("ord_det"."n_srno") = "st_track_det"."c_doc_no"
                and "ord_det"."n_seq" = "st_track_det"."n_seq"
              where "c_doc_no" = @DocNo
              and "n_seq" = @OrgSeq
              and "st_track_det"."c_godown_code" = @GodownCode
        else --Update 
          update "ord_ledger" set "n_cancel_qty" = "n_cancel_qty"+(@Qty*@d_qtp)
            where "ord_ledger"."c_br_code" = @TranBrCode
            and "ord_ledger"."c_year" = @TranYear
            and "ord_ledger"."c_prefix" = @TranPrefix
            and "ord_ledger"."n_srno" = @TranSrno
            and "ord_ledger"."n_seq" = @OrgSeq
            and "ord_ledger"."c_item_code" = @ItemCode
        end if end if;
      --Saneesh 11 oct 2018
      if @ItemNotFound = 1 and @TranPrefix = 'O' then
        select "count"()
          into @li_gdn_count from "gdn_bounced_items"
          where "gdn_bounced_items"."c_br_code" = @TranBrCode
          and "gdn_bounced_items"."c_year" = @TranYear
          and "gdn_bounced_items"."c_prefix" = @TranPrefix
          and "gdn_bounced_items"."n_srno" = @TranSrno
          and "gdn_bounced_items"."n_seq" = @OrgSeq
          and "gdn_bounced_items"."c_item_code" = @ItemCode;
        if @li_gdn_count = 0 then --Insert
          insert into "gdn_bounced_items"
            ( "c_br_code","c_year","c_prefix","n_srno","c_item_code","n_qty","c_po_no","d_ldate","t_ltime","n_seq",
            "n_flag" ) on existing skip
            select @TranBrCode,@TranYear,@TranPrefix,@TranSrno,@ItemCode,@Qty,"st_track_det"."c_doc_no",@d_ldate,@t_ltime,"st_track_det"."n_seq",2
              from "st_track_det"
              where "c_doc_no" = @DocNo
              and "n_seq" = @OrgSeq
              and "st_track_det"."c_godown_code" = @GodownCode
        else --Update 
          update "gdn_bounced_items" set "n_qty" = "n_qty"+@Qty,
            "d_ldate" = @d_ldate,
            "t_ltime" = @t_ltime
            where "gdn_bounced_items"."c_br_code" = @TranBrCode
            and "gdn_bounced_items"."c_year" = @TranYear
            and "gdn_bounced_items"."c_prefix" = @TranPrefix
            and "gdn_bounced_items"."n_srno" = @TranSrno
            and "gdn_bounced_items"."n_seq" = @OrgSeq
            and "gdn_bounced_items"."c_item_code" = @ItemCode
        end if end if;
      select(if("n_bal_qty"-@Qty) < 0 then 0 else("n_bal_qty"-@Qty) endif)
        into @RemainingQty from "st_track_det"
        where "c_doc_no" = @DocNo
        and "n_inout" = @InOutFlag
        and "c_item_code" = @ItemCode
        and "n_seq" = @OrgSeq
        and "st_track_det"."c_godown_code" = @GodownCode;
      if @ItemNotFound = 0 then
        set @d_item_pick_count = @d_item_pick_count+1;
        insert into "st_track_pick"
          ( "c_doc_no","n_inout","n_seq","n_org_seq","c_item_code","c_batch_no","n_qty","n_hold_flag","c_reason_code","c_note","c_user","t_time","c_tray_code","c_device_id","c_rack","c_rack_grp_code","c_stage_code",
          "c_godown_code" ) on existing update defaults off values
          ( @DocNo,@InOutFlag,@Seq,@OrgSeq,@ItemCode,@BatchNo,@Qty,@HoldFlag,@cReason,@cNote,@UserId,@t_pick_time,@CurrentTray,@devID,@RackCode,@CurrentGrp,@StageCode,@GodownCode ) ;
        update "st_track_det"
          set "n_complete" = (if "n_complete" = 2 then 2 else(if @RemainingQty = 0 then 1 else 0 endif) endif), /* complete = 1 @ForwardFlag*/
          "n_bal_qty" = @RemainingQty,
          "c_user" = @UserId
          where "c_doc_no" = @DocNo
          and "n_inout" = @InOutFlag
          and "c_item_code" = @ItemCode
          and "n_seq" = @OrgSeq
          and "st_track_det"."c_godown_code" = @GodownCode
      else
        set @d_item_pick_count = @d_item_pick_count+1;
        update "st_track_det"
          set "n_complete" = 2, --item not found
          "c_reason_code" = @cReason,
          "c_user" = @UserId
          where "c_doc_no" = @DocNo
          and "n_inout" = @InOutFlag
          and "c_item_code" = @ItemCode
          and "n_seq" = @OrgSeq
          and "st_track_det"."c_godown_code" = @GodownCode
      end if
    end loop;
    if @enable_log = 1 then
      update
        "st_doc_done_log"
        set "n_item_count" = @nIter,
        "n_bounce_cnt" = @bounce_cnt,
        "t_e_time" = "getdate"()
        where "n_seq" = @log_seq
    end if;
    if(select "count"("c_tray_code") from "st_track_tray_move" where "c_tray_code" = @CurrentTray and "c_godown_code" = @GodownCode) > 1 then
      --at the end of the stage(last RG) preserve 1 record for scanning process
      select top 1 "st_track_tray_move"."c_rack_grp_code"
        into @maxRackGrp from "st_track_tray_move"
          join "temp_rack_grp_list" on "st_track_tray_move"."c_stage_code" = "temp_rack_grp_list"."c_stage_code"
          and "st_track_tray_move"."c_rack_grp_code" = "temp_rack_grp_list"."c_rack_grp_code"
        where "st_track_tray_move"."c_godown_code" = @GodownCode
        --and st_track_tray_move.c_stage_code = @StageCode
        order by "n_seq" desc;
      delete from "st_track_tray_move"
        where "c_tray_code" = @CurrentTray
        and "c_rack_grp_code" <> @maxRackGrp
        --and c_stage_code = @StageCode
        and "st_track_tray_move"."c_godown_code" = @GodownCode;
      if @enable_log = 1 then
        update "st_doc_done_log"
          set "n_delete" = 1
          where "n_seq" = @log_seq
      end if end if;
    if @nextRackGrp is not null then //--a or b
    else if @ItemsInDetail = 0 and @NextTray <> '1' then
        //check for pending items
        if(select "count"("c_item_code") from "st_track_det" join "temp_rack_grp_list"
              on "st_track_det"."c_stage_code" = "temp_rack_grp_list"."c_stage_code"
              and "st_track_det"."c_rack_grp_code" = "temp_rack_grp_list"."c_rack_grp_code"
            where "st_track_det"."n_complete" = 0
            and "st_track_det"."c_tray_code" = @CurrentTray
            and "st_track_det"."n_inout" = @InOutFlag
            and "st_track_det"."c_godown_code" = @GodownCode
            and "st_track_det"."c_doc_no" = @DocNo) > 0 then
          if @enable_log = 1 then
            insert into "st_log_ret"
              ( "c_doc_no","c_tray","c_stage","c_rg","n_flag","t_time" ) values
              ( @DocNo,@CurrentTray,@StageCode,'Blank Tray Move To '+"ISNULL"(@nextRackGrp,'N1'),5,"getdate"() ) 
          end if;
          select 'Success' as "c_message",@maxSeq as "n_max_seq" for xml raw,elements;
          return
        end if end if;
      //################## Added On 04/12/16
      --preserve old time 
      select top 1 "t_time"
        into @t_preserve_ltime from "st_track_tray_move"
        where "c_tray_code" = @CurrentTray
        -- and c_stage_code = @StageCode
        and "st_track_tray_move"."c_godown_code" = @GodownCode;
      set @t_ltime = "left"("now"(),19);
      --print @t_ltime ;
      select top 1 "c_rack_grp_code"
        into @rackGrp from "st_track_tray_move"
        where "c_doc_no" = @DocNo
        and "n_inout" = @InOutFlag
        --and c_stage_code = @StageCode
        and "c_tray_code" = @CurrentTray
        --and c_user =@UserId ;
        order by if "c_user" = @UserId then 0 else 1 endif asc; //removed user id where condition and added order by as some times null was comming
      --//call uf_update_tray_time(@DocNo,@InOutFlag,@CurrentTray,'PICKING',@UserId,@rackGrp,@StageCode,2,@t_tray_move_time,@d_item_pick_count,@d_item_bounce_count);
      update "st_track_tray_move"
        set "n_inout" = 9,
        "c_rack_grp_code" = '-',
        "t_time" = @t_ltime,
        "n_tray_flag" = 0
        where "c_doc_no" = @DocNo
        and "n_inout" = @InOutFlag
        and "c_tray_code" = @CurrentTray
        -- and c_stage_code = @StageCode
        and "c_godown_code" = @GodownCode;
      select "count"("st_track_det"."c_item_code")
        into @itemcount from "st_track_det" where "st_track_det"."c_doc_no" = @DocNo
        and "st_track_det"."n_inout" = @InOutFlag
        and "st_track_det"."n_complete" not in( 9,8 ) 
        and "n_bal_qty" <> "n_qty";
      if @itemcount = 0 then
        update "st_track_mst" set "st_track_mst"."n_complete" = 9,"st_track_mst"."t_time_in" = "now"()
          where "st_track_mst"."c_doc_no" = @DocNo
          and "st_track_mst"."n_inout" = @InOutFlag
      end if end if; --last rack grp 
    if @nextRackGrp is null then
      select "count"()
        into @n_pick_count from "st_track_pick"
        where "st_track_pick"."c_tray_code" = @CurrentTray
        and "st_track_pick"."c_doc_no" = @DocNo
        --and c_stage_code = @StageCode
        and "st_track_pick"."c_godown_code" = @GodownCode;
      if @n_pick_count is null then
        set @n_pick_count = 0
      end if;
      --print @n_pick_count ;
      if @n_pick_count = 0 then
        delete from "st_track_tray_move"
          where "c_tray_code" = @CurrentTray
          and "c_doc_no" = @DocNo
          --and c_stage_code = @StageCode
          and "c_godown_code" = @GodownCode;
        commit work
      end if end if;
    if sqlstate = '00000' then
      commit work;
      set @DetSuccessFlag = 1
    else
      rollback work;
      set @DetSuccessFlag = 0
    end if;
    -- for tray release<<
    if(select "count"("c_doc_no") from "st_track_det" where("n_complete" = 0) and "c_doc_no" = @DocNo and "c_godown_code" = @GodownCode) = 0 then
      --n_complete = 0
      update "st_track_mst"
        set "c_phase_code" = 'PH0002'
        where "c_doc_no" = @DocNo;
      commit work
    end if;
    --2018-01-11 update mst_godown gargee
    select "count"("st_track_det"."c_item_code")
      into @itemcount from "st_track_det" where "st_track_det"."c_doc_no" = @DocNo
      and "st_track_det"."n_inout" = @InOutFlag
      and "st_track_det"."n_complete" not in( 9,8 ) 
      and "n_bal_qty" <> "n_qty";
    if @itemcount = 0 then
      update "st_track_mst" set "st_track_mst"."n_complete" = 9,"st_track_mst"."t_time_in" = "now"()
        where "st_track_mst"."c_doc_no" = @DocNo
    end if;
    if @ItemsInDetail <> 1 then
      set @DetSuccessFlag = 1 --no det data to batch success flag
    end if;
    --print('next tray doc done' + @NextTray);
    if @NextTray is null or "trim"(@NextTray) = '' then -- Normal doc Done 
      if @DetSuccessFlag = 1 then
        select "max"("st_track_pick"."n_seq") as "n_max_seq"
          into @maxSeq from "st_track_pick"
            join "temp_rack_grp_list"
            on "st_track_pick"."c_rack_grp_code" = "temp_rack_grp_list"."c_rack_grp_code"
          where "st_track_pick"."c_doc_no" = @DocNo
          and "st_track_pick"."c_godown_code" = @GodownCode;
        select 'Success' as "c_message",@maxSeq as "n_max_seq" for xml raw,elements
      else
        select 'Failure' as "c_message" for xml raw,elements
      --set @DetData='1'+@ColSep+'2' +@ColSep + string(@nTrayFull) + @ColSep+@RowSep;
      end if
    else set @DetData = '1'+@ColSep+'2'+@ColSep+@RowSep
    end if when 'check_login' then
    select "uf_st_check_login"(@BrCode,@RackGrpCode,@UserId,@devID,1) as "c_message" for xml raw,elements;
    return
  when 'reason_mst' then -----------------------------------------------------------------------
    select "reason_mst"."c_name" as "c_name",
      "reason_mst"."c_code" as "c_code"
      from "reason_mst"
      where "reason_mst"."n_type" in( 0,11 ) for xml raw,elements
  when 'get_pend_doc_list' then -----------------------------------------------------------------------
    select "c_doc_no",
      "list"(distinct ' User : '+"c_user"+' - Stage : '+"c_stage_code") as "c_user_lst",
      "sum"(if "n_complete" <> 0 then 1 else 0 endif) as "pending_cnt",
      "count"() as "rowcnt"
      from "st_track_det"
      group by "c_doc_no"
      having "pending_cnt" <> "rowcnt" and "pending_cnt" <> 0 for xml raw,elements;
    return
  end case
end;