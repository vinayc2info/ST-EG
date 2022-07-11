CREATE PROCEDURE "DBA"."usp_st_stock_removal"( 
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
Author 		: Anup 
Procedure	: usp_st_stock_removal
SERVICE		: ws_st_stock_removal
Date 		: 25-09-2014
Modified By : Saneesh C G 
Ldate 		: 21-09-2015 
Purpose		: Store Track TRANSACTION to TAB/DESKTOP
Input		: gsBr~devID~sKey~UserId~PhaseCode~RackGrpCode~StageCode~cIndex~HdrData~DetData
RackGrpCode= rg1**rg2**__
IndexDetails: get_store_stage, get_doc_list, set_selected_tray, get_rack_group, document_done, item_done, free_trays	
Tags		: if <c_message> contains "Error" then force logout (android)
Note		:
Service Call (Format): http://192.168.7.12:13000/ws_st_stock_removal?gsBr=003&devID=devID&sKey=KEY&UserId=MYBOSS&PhaseCode=&RackGrpCode=&StageCode=&cIndex=&HdrData=&DetData=	
Changes    : Added left join stock_mst to st_track_det in second union of index get_batch_list on 21-09-2015
: set_selected_tray and document_done merg ver 123 
:tray_full_validate index added ver 125 
Log Table Structure
CREATE TABLE DBA.st_log_ret (
n_seq NUMERIC(30,0) NOT NULL DEFAULT AUTOINCREMENT,
c_doc_no CHAR(30) NULL,
c_tray CHAR(6) NULL,
c_stage CHAR(6) NULL,
c_rg CHAR(100) NULL,
n_flag NUMERIC(1,0) NULL,
t_time datetime NULL,
PRIMARY KEY ( n_seq ASC )
) IN system;
CREATE TABLE DBA.st_doc_done_log (
n_seq NUMERIC(30,0) NOT NULL DEFAULT AUTOINCREMENT,
c_doc CHAR(50) NULL,
c_tray CHAR(6) NULL,
c_stage CHAR(6) NULL,
c_hdr CHAR(8000) NULL,
c_det CHAR(32767) NULL,
c_rg CHAR(1000) NULL,
n_item_det_flag NUMERIC(1,0) NULL,
n_item_count NUMERIC(4,0) NULL,
n_bounce_cnt NUMERIC(4,0) NULL,
n_tray_full NUMERIC(1,0) NULL,
t_s_time datetime NULL,
t_e_time datetime NULL,
t_e_trf_time datetime NULL,
n_delete NUMERIC(1,0) NULL,
n_tray_time NUMERIC(1,0) NULL,
n_tf_called NUMERIC(1,0) NULL,
PRIMARY KEY ( n_seq ASC )
) IN system;
--Added c_note  tag in get doc list added ver 127 on  27-12-2016
*/
  --common >>
  declare @TrolleyCode char(6);
  declare @n_barcode_print integer;
  declare @non_pick_flag integer;
  declare @n_dynamic_godown_qty integer;
  declare @c_patient char(50);
  declare @n_qty_per_box integer;
  declare @s_br_code char(6);
  declare @s_year char(6);
  declare @s_prefix char(6);
  declare @s_srno numeric(9);
  declare @c_br_rack char(6);
  declare @p_note char(100);
  declare @p_reason char(6);
  declare @n_park_flag integer;
  declare @out_barcode_print_flag integer;
  declare @barcode_print_on_move integer;
  declare @tmp_rg char(20);
  declare @sh_name char(10);
  declare @removed_doc_flag numeric(1);
  declare @display_base integer;
  declare @doc_seq integer;
  declare @ExpBatch varchar(5000);
  declare @Exp_Batch varchar(5000);
  declare @batchreasoncode char(6);
  declare @selected_batch char(25);
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
  declare @Pos integer;
  declare @ColPos integer;
  declare @RowPos integer;
  declare @ColMaxLen numeric(4);
  declare @RowMaxLen numeric(4);
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
  declare @comp_sh_name char(10);
  ----------added by Vinay
  declare local temporary table "temp_items_not_in_stock_ledger_inward"(
    "c_item_code" char(6) not null,
    "c_batch_no" char(15) not null,
    primary key("c_item_code" asc,"c_batch_no" asc),) on commit preserve rows;
  declare @n_rate_on integer;
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
    ) on commit delete rows;
  declare local temporary table "batch_list"(
    "c_item_code" char(6) null,
    "c_batch_no" char(25) null,
    "n_mrp" numeric(11,3) null,
    "n_mrp_box" numeric(11,3) null,
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
  declare @d_exp_dt char(10);
  --DECLARE @st_track_tray_move_t_time char(25);
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
  --gargee
  --set @enable_log = 1; //IF 1 its start recording in Log tables -->> st_doc_done_log & st+log_ret
  select "N_ACTIVE" into @out_barcode_print_flag from "ST_TRACK_MODULE_MST" where "C_CODE" = 'M00063' and "st_track_module_mst"."c_br_code" = @gsBr;
  select "N_ACTIVE" into @barcode_print_on_move from "ST_TRACK_MODULE_MST" where "C_CODE" = 'M00065' and "st_track_module_mst"."c_br_code" = @gsBr;
  select "n_active" into @enable_log from "st_track_module_mst" where "st_track_module_mst"."c_code" = 'M00039' and "st_track_module_mst"."c_br_code" = @gsBr;
  if @enable_log is null then
    set @enable_log = 0
  end if;
  -- print 'me..';
  -- print @enable_log;
  select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
  select "c_delim" into @RowSep from "ps_tab_delimiter" where "n_seq" = 1;
  set @ColMaxLen = "Length"(@ColSep);
  set @RowMaxLen = "Length"(@RowSep);
  set @BrCode = "uf_get_br_code"(@gsBr);
  set @t_ltime = "left"("now"(),19);
  set @t_tray_move_time = "left"("now"(),19);
  set @d_ldate = "uf_default_date"();
  select top 1 "c_user" into @cUser from "logon_det" order by "n_srno" desc;
  select "n_flag" into @nSingleUser from "st_store_stage_mst" where "c_code" = @StageCode;
  set @d_item_pick_count = 0;
  set @d_qtp = 1;
  set @d_item_bounce_count = 0;
  case @cIndex
  when 'get_notif' then
    --HdrData: storeInNotifNeeded
    set @storeInNotifNeeded = @HdrData;
    set @storeInCount = 0;
    if @storeInNotifNeeded = 1 then
      set @RackGrpList = @RackGrpCode;
      --load storeInCount here
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
      select top 1 "c_rack_grp_code"
        into @FirstRackGroup from "st_store_stage_det"
        where "c_stage_code" = @StageCode
        order by "n_pos_seq" asc;
      --if user is FirstInStage then DOC_LIST else TRAY_LIST 
      ----------Chnaged By Saneesh 
      insert into "doc_list"
        select "st_track_det"."c_doc_no" as "c_doc_no",
          1 as "n_first_in_stage",
          "st_track_det"."c_doc_no" as "c_doc_name",
          "st_track_det"."c_tray_code" as "c_tray_code",
          "st_track_det"."n_inout" as "n_inout",
          '' as "c_message",
          "st_track_mst"."t_time_in" as "t_time_in",
          (select "count"("c_doc_no") from "st_track_tray_move" where "c_stage_code" = @StageCode and "c_doc_no" = "st_track_det"."c_doc_no") as "tray_count",
          "sum"(if "isnull"("st_track_det"."c_rack_grp_code",'') <> '' and "st_track_det"."n_complete" = 0 and "temp_rack_grp_list"."c_rack_grp_code" is not null then 1 else 0 endif) as "n_item_count",
          "sum"(if "st_track_det"."n_complete" = 0 then 1 else 0 endif) as "n_items_in_stage",
          (if @nSingleUser = 0 then "st_track_det"."c_user" else '-' endif) as "c_user"
          from "st_track_det"
            join "st_track_mst" on "st_track_det"."c_doc_no" = "st_track_mst"."c_doc_no"
            and "st_track_det"."n_inout" = "st_track_mst"."n_inout"
            left outer join "temp_rack_grp_list" on "st_track_det"."c_rack_grp_code" = "temp_rack_grp_list"."c_rack_grp_code"
          where "st_track_det"."c_stage_code" = @StageCode
          and "st_track_det"."c_tray_code" is not null
          and "isnull"("st_track_det"."c_godown_code",'-') = @GodownCode
          group by "st_track_det"."c_doc_no","n_first_in_stage","c_doc_name","c_tray_code",
          "st_track_det"."n_inout","c_message","st_track_mst"."t_time_in","c_user"
          order by "st_track_mst"."t_time_in" asc;
      -----------------------------------
      if(select "count"("c_rack_grp_code") from "temp_rack_grp_list" where "c_rack_grp_code" = @FirstRackGroup) > 0 then
        select "count"()
          into @storeInCount
          from(select "c_tray_code",
              "n_first_in_stage",
              "c_doc_no",
              "n_inout",
              "c_message",
              "n_item_count",
              0 as "n_max_seq"
              from "doc_list"
              where(select "count"("sd"."c_doc_no")
                from "st_track_det" as "sd"
                where "sd"."c_doc_no" = "doc_list"."c_doc_no"
                and("sd"."c_rack" is null or "sd"."c_stage_code" is null or "sd"."c_rack_grp_code" is null))
               = 0
              and "isnull"("doc_list"."c_user",'-') = (if @nSingleUser = 0 then(if "doc_list"."c_user" is null then "isnull"("doc_list"."c_user",'-') else @UserId endif) else "isnull"("doc_list"."c_user",'-') endif)
              and "doc_list"."n_inout" = 1
              and("n_item_count" > 0 or(("n_items_in_stage"-"n_item_count") > 0 and "tray_count" = 0))
              and "n_items_in_stage" > 0) as "t1"
      else
        ----------------------
        ---Chnaged By Saneesh 
        insert into "tray_list"
          select distinct "st_track_tray_move"."c_tray_code" as "c_tray_code",
            0 as "n_first_in_stage",
            "st_track_tray_move"."c_doc_no" as "c_doc_no",
            "st_track_tray_move"."n_inout" as "n_inout",
            "st_track_tray_move"."t_time" as "t_time",
            '' as "c_message",
            (select "count"("b"."c_item_code") from "st_track_det" as "b" join "temp_rack_grp_list" on "b"."c_rack_grp_code" = "temp_rack_grp_list"."c_rack_grp_code" where "b"."c_doc_no" = "st_track_det"."c_doc_no" and "b"."n_complete" = 0) as "n_item_count",
            0 as "n_max_seq",
            "st_track_mst"."n_confirm" as "n_confirm",
            --st_track_mst.n_urgent as n_urgent,
            if "isnull"("st_track_urgent_doc"."n_urgent",0) <> 4 then "st_track_mst"."n_urgent" else "st_track_urgent_doc"."n_urgent" endif as "n_urgent",
            "st_track_mst"."c_sort" as "c_sort",
            "st_track_det"."c_user" as "c_user"
            from "st_track_tray_move"
              left outer join "st_track_det" on "st_track_tray_move"."c_doc_no" = "st_track_det"."c_doc_no"
              and "st_track_tray_move"."n_inout" = "st_track_det"."n_inout"
              and "st_track_tray_move"."c_tray_code" = "st_track_det"."c_tray_code"
              and "st_track_tray_move"."c_rack_grp_code" = "st_track_det"."c_rack_grp_code"
              join "temp_rack_grp_list" on "st_track_tray_move"."c_rack_grp_code" = "temp_rack_grp_list"."c_rack_grp_code"
              left outer join "st_track_urgent_doc" on "st_track_urgent_doc"."c_doc_no" = "st_track_det"."c_doc_no"
              and "st_track_urgent_doc"."n_inout" = "st_track_det"."n_inout"
              join "st_track_mst" on "st_track_mst"."c_doc_no" = "st_track_tray_move"."c_doc_no"
              and "st_track_mst"."n_inout" = "st_track_tray_move"."n_inout"
            where "st_track_tray_move"."n_inout" not in( 9,8,0 ) 
            and "isnull"("st_track_tray_move"."c_godown_code",'-') = @GodownCode;
        ---------------------
        ---Chnaged By Saneesh 
        select "count"()
          into @storeInCount
          from(select "c_tray_code" as "c_tray_code",
              "n_first_in_stage",
              "c_doc_no",
              "n_inout",
              "c_message",
              "max"("n_item_count") as "n_item_count",
              "n_max_seq",
              "t_time"
              from "tray_list"
              group by "c_tray_code","n_first_in_stage","c_doc_no","n_inout","c_message","n_max_seq","t_time"
              order by "t_time" asc) as "t2"
      end if end if;
    select "COUNT"("n_srno")
      into @msgCount from "message_mst"
      where "c_stage_code" = @StageCode
      and "c_from_user" is not null
      and "c_to_user" = @UserId
      and "n_status" = 0;
    select @storeInCount as "n_storein_count",@msgCount as "n_msg_count" for xml raw,elements
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
    if(select "count"("c_code") from "st_store_stage_mst" where "c_code" = @StageCode) > 0 then
      if(select "count"("c_code") from "st_store_stage_mst" where "c_code" = @StageCode and "n_cancel_flag" = 1) > 0 then
        select '' as "c_rack_grp_code",
          '' as "c_rack_grp_name",
          'Warning!! : Stage '+"string"("c_name")+'['+"string"("c_code")+'] is locked' as "c_message"
          from "st_store_stage_mst"
          where "c_code" = @StageCode for xml raw,elements;
        return
      end if;
      select "count"("rack_group_mst"."c_code")
        into @rgCount from "rack_group_mst"
          join "st_store_stage_det" on "rack_group_mst"."c_code" = "st_store_stage_det"."c_rack_grp_code"
          and "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
        where "st_store_stage_det"."c_stage_code" = @StageCode
        and "rack_group_mst"."n_lock" = 0;
      if @rgCount = 0 then
        select '' as "c_rack_grp_code",
          '' as "c_rack_grp_name",
          'Warning!! : No Rack Groups Found for Stage : '+"string"(@StageCode) as "c_message" for xml raw,elements;
        return
      end if;
      --STORE STAGE WISE RACK GROUP SELECTION
      select "rack_group_mst"."c_code" as "c_rack_grp_code",
        "rack_group_mst"."c_name" as "c_rack_grp_name",
        '' as "c_message"
        from "rack_group_mst"
          join "st_store_stage_det" on "rack_group_mst"."c_code" = "st_store_stage_det"."c_rack_grp_code"
          and "st_store_stage_det"."c_br_code" = "rack_group_mst"."c_br_code"
        where "st_store_stage_det"."c_stage_code" = @StageCode
        and "rack_group_mst"."n_lock" = 0
        order by "st_store_stage_det"."n_pos_seq" asc for xml raw,elements
    else
      select '' as "c_rack_grp_code",
        '' as "c_rack_grp_name",
        'Warning!! : Stage - '+"string"(@StageCode)+' not found' as "c_message" for xml raw,elements
    end if when 'godown_mst' then -----------------------------------------------------------------------
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
    end if when 'login_status' then -----------------------------------------------------------------------
    set @LoginFlag = 1;
    --message @RackGrpCode	type warning to client;
    --to display only items from the given rack groups 
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
          where "tm"."c_stage_code" = @StageCode and "tm"."n_inout" = 0;
        select top 1 "count"("tm"."c_rack_grp_code")
          into @stageRGcount from "st_track_tray_move" as "tm"
          where "tm"."c_stage_code" = @StageCode and "tm"."n_inout" = 0
      end if end if;
    if @seltmRGcount <> @stageRGcount or @tmRGcount is not null then
      select 'Error! : Cannot login to the selected rack groups '+@ColSep+' Please process the pending documents' as "c_message" for xml raw,elements;
      return
    end if;
    while @RackGrpList <> '' loop
      --1 RackGrpList
      select "Locate"(@RackGrpList,@ColSep) into @ColPos;
      set @tmp = "Trim"("Left"(@RackGrpList,@ColPos-1));
      set @RackGrpList = "SubString"(@RackGrpList,@ColPos+@ColMaxLen);
      select "uf_st_login_status"(@BrCode,@tmp,@LoginFlag,@UserId,@devID,0)
        into @LoginStatus;
      if "length"(@LoginStatus) > 1 then
        select @LoginStatus as "c_message" for xml raw,elements;
        --select 'Error!!: Rack Group : '+@tmp+' already assigned to User : '+@ValidRGUser;
        return
      end if
    end loop;
    select '' as "c_message" for xml raw,elements
  when 'get_doc_list' then -----------------------------------------------------------------------
    --DetData = LoginFlag**__ 	
    --1 LoginFlag //1 for the first call and 0 for consequent
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @LoginFlag = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --message 'LoginFlag '+@LoginFlag type warning to client;
    if @LoginFlag = '' then
      set @LoginFlag = 0
    end if;
    --message @RackGrpCode	type warning to client;
    set @RackGrpList = @RackGrpCode;
    --print '@RackGrpList'+@RackGrpList;
    while @RackGrpList <> '' loop
      --1 RackGrpList
      select "Locate"(@RackGrpList,@ColSep) into @ColPos;
      set @tmp = "Trim"("Left"(@RackGrpList,@ColPos-1));
      set @RackGrpList = "SubString"(@RackGrpList,@ColPos+@ColMaxLen);
      --message 'RackGrpList '+@tmp type warning to client;
      --to check if force logged out on each get doclist call....
      select "uf_st_login_status"(@BrCode,@tmp,@LoginFlag,@UserId,@devID,0) into @LoginStatus;
      if "length"(@LoginStatus) > 1 then
        select '' as "c_doc_no",
          '' as "n_first_in_stage",
          '' as "c_doc_name",
          '' as "c_ref_no",
          '' as "n_inout",
          @LoginStatus as "c_message" for xml raw,elements;
        return
      end if;
      if(select "COUNT"("C_CODE") from "RACK_GROUP_MST" where "n_lock" = 0 and "C_CODE" = @tmp) > 0 then --valid rack group selection 
        select "n_pos_seq" into @Seq from "st_store_stage_det" where "c_rack_grp_code" = @tmp;
        insert into "temp_rack_grp_list"( "c_rack_grp_code","c_stage_code","n_seq" ) values( @tmp,@StageCode,@Seq ) ;
        update "st_track_det" set "c_user" = @UserId where "c_rack_grp_code" = @tmp and "c_doc_no" = @DocNo;
        commit work
      /*
@LoginFlag = 	1 if its a call just after rack group selection
0 subsequent call for document list 
*/
      end if
    end loop;
    select top 1 "c_rack_grp_code"
      into @FirstRackGroup from "st_store_stage_det"
      where "c_stage_code" = @StageCode
      order by "n_pos_seq" asc;
    select "max"("st_track_pick"."n_seq") as "n_max_seq"
      into @maxSeq from "st_track_pick"
        join "temp_rack_grp_list" on "st_track_pick"."c_rack_grp_code" = "temp_rack_grp_list"."c_rack_grp_code"
      where "st_track_pick"."c_doc_no" = @DocNo
      and "st_track_pick"."c_stage_code" = @StageCode
      and "st_track_pick"."c_godown_code" = @GodownCode;
    --if user is FirstInStage then DOC_LIST else TRAY_LIST 
    if(select "count"("c_rack_grp_code") from "temp_rack_grp_list" where "c_rack_grp_code" = @FirstRackGroup) > 0 then
      -------Changed By Saneesh 
      insert into "document_list"
        select "st_track_det"."c_doc_no" as "c_doc_no",
          1 as "n_first_in_stage",
          "st_track_det"."c_doc_no" as "c_doc_name",
          "st_track_det"."c_doc_no" as "c_ref_no",
          "st_track_det"."n_inout" as "n_inout",
          '' as "c_message",
          "st_track_mst"."t_time_in" as "t_time_in",
          (select "count"("c_doc_no") from "st_track_tray_move" join "temp_rack_grp_list" on "st_track_tray_move"."c_rack_grp_code" = "temp_rack_grp_list"."c_rack_grp_code" where "st_track_tray_move"."n_inout" = 0 and "st_track_tray_move"."c_stage_code" = @StageCode and "c_doc_no" = "st_track_det"."c_doc_no" and "c_godown_code" = @GodownCode) as "tray_count_rg",
          (select "count"("c_doc_no") from "st_track_tray_move" where "c_stage_code" = @StageCode and "c_doc_no" = "st_track_det"."c_doc_no") as "tray_count_stage",
          "sum"(if "isnull"("st_track_det"."c_rack_grp_code",'') <> '' and "st_track_det"."n_complete" = 0 and "temp_rack_grp_list"."c_rack_grp_code" is not null then 1 else 0 endif) as "n_item_count",
          "sum"(if "st_track_det"."n_complete" = 0 then 1 else 0 endif) as "n_items_in_stage",
          "st_track_mst"."n_confirm" as "n_confirm",
          --st_track_mst.n_urgent as n_urgent,
          if "isnull"("st_track_urgent_doc"."n_urgent",0) <> 4 then "st_track_mst"."n_urgent" else "st_track_urgent_doc"."n_urgent" endif as "n_urgent",
          "st_track_mst"."c_sort" as "c_sort",
          (if @nSingleUser = 0 then "st_track_det"."c_user" else '-' endif) as "c_user",
          "st_track_mst"."d_date" as "d_date",
          "st_track_det"."c_godown_code",
          "isnull"("godown_tran_mst"."n_eb_flag",0) as "n_exp_doc",
          "trim"("substring"("godown_tran_mst"."c_note","charindex"(':',"godown_tran_mst"."c_note")+1)) as "c_note",
          if "len"("trim"("isnull"("st_track_mst"."c_order_id",''))) <> 0 then
            0
          else
            1
          endif as "n_allow_not_found"
          from "st_track_det"
            join "st_track_mst" on "st_track_det"."c_doc_no" = "st_track_mst"."c_doc_no"
            and "st_track_det"."n_inout" = "st_track_mst"."n_inout"
            left outer join "godown_tran_mst"
            on "godown_tran_mst"."c_br_code" = "left"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")-1)
            and "godown_tran_mst"."c_year" = "left"("substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1),"charindex"('/',"substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1))-1)
            and "godown_tran_mst"."c_prefix" = "left"("substring"("substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1),"charindex"('/',"substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1),"charindex"('/',"substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1))+1))-1)
            and "godown_tran_mst"."n_srno" = "reverse"("left"("reverse"("st_track_det"."c_doc_no"),"charindex"('/',"reverse"("st_track_det"."c_doc_no"))-1))
            left outer join "temp_rack_grp_list" on "st_track_det"."c_rack_grp_code" = "temp_rack_grp_list"."c_rack_grp_code"
            and "st_track_det"."c_stage_code" = "temp_rack_grp_list"."c_stage_code"
            left outer join "st_track_urgent_doc" on "st_track_urgent_doc"."c_doc_no" = "st_track_det"."c_doc_no"
            and "st_track_urgent_doc"."n_inout" = "st_track_det"."n_inout"
            left outer join "st_track_park" on "st_track_park"."c_doc_no" = "st_track_det"."c_doc_no" and "st_track_det"."n_inout" = "st_track_park"."n_inout"
            and "st_track_park"."n_org_seq" = "st_track_det"."n_seq" and "st_track_det"."c_tray_code" = "st_track_park"."c_tray_code"
            and "st_track_park"."c_stage_code" = "st_track_det"."c_stage_code"
          where "st_track_det"."c_stage_code" = @StageCode
          //          and "temp_rack_grp_list"."c_rack_grp_code" = "st_track_park"."c_rack_grp_code" and "temp_rack_grp_list"."c_stage_code" = "st_track_park"."c_stage_code"
          and "st_track_mst"."n_confirm" = 1 and "st_track_det"."n_inout" = 0 and "st_track_park"."c_doc_no" is null
          and "st_track_det"."c_godown_code" = @GodownCode
          group by "st_track_det"."c_doc_no","st_track_det"."c_doc_no","st_track_det"."c_doc_no","st_track_det"."n_inout",
          "st_track_mst"."t_time_in","st_track_mst"."n_confirm","st_track_mst"."c_sort",
          "c_user","st_track_mst"."d_date","st_track_det"."c_godown_code","n_urgent","n_exp_doc","c_note","n_allow_not_found";
      ----------------
      select
        "isnull"(
        (select "max"("c_tray_code")
          from "st_track_det"
          where "st_track_det"."c_doc_no" = "document_list"."c_doc_no"
          and "st_track_det"."c_stage_code" = @StageCode
          and "st_track_det"."n_complete" = 0
          and "st_track_det"."c_godown_code" = @GodownCode),
        '') as "c_tray_code",
        "n_first_in_stage",
        "c_doc_no",
        "n_inout",
        "c_message",
        "n_item_count",
        0 as "n_max_seq",
        "t_time_in" as "t_time", --X (not req for import at tab )
        "tray_count_rg","tray_count_stage",
        "n_items_in_stage",
        "n_exp_doc",
        "c_note",
        "n_allow_not_found"
        from "document_list"
        where(select "count"("sd"."c_doc_no")
          from "st_track_det" as "sd"
          where "sd"."c_doc_no" = "document_list"."c_doc_no"
          and("sd"."c_rack" is null or "sd"."c_stage_code" is null or "sd"."c_rack_grp_code" is null)
          and "sd"."c_godown_code" = @GodownCode)
         = 0
        and "isnull"("document_list"."c_user",'-') = (if @nSingleUser = 0 then(if "document_list"."c_user" is null then "isnull"("document_list"."c_user",'-') else @UserId endif) else "isnull"("document_list"."c_user",'-') endif)
        and "document_list"."n_inout" = 0
        and("tray_count_rg" > 0 or "tray_count_stage" = 0 or "n_item_count" > 0)
        and "n_items_in_stage" > 0
        order by(if "c_tray_code" = '' then 'zzzzzz' else "c_tray_code" endif) asc,"document_list"."n_urgent" desc,"document_list"."d_date" asc,"c_sort" asc,"document_list"."t_time_in" asc,"document_list"."c_doc_no" asc for xml raw,elements
    else
      select "c_tray_code" as "c_tray_code",
        "n_first_in_stage",
        "c_doc_no",
        "n_inout",
        "c_message",
        "max"("n_item_count") as "n_item_count",
        "n_max_seq",
        "t_time",
        "n_exp_doc",
        "c_note",
        "n_allow_not_found",
        "n_urgent"
        --st_track_mst.n_urgent as n_urgent,
        from(select distinct "st_track_tray_move"."c_tray_code" as "c_tray_code",
            0 as "n_first_in_stage",
            "st_track_tray_move"."c_doc_no" as "c_doc_no",
            "st_track_tray_move"."n_inout" as "n_inout",
            "st_track_tray_move"."t_time" as "t_time",
            '' as "c_message",
            (select "count"("b"."c_item_code") from "st_track_det" as "b" join "temp_rack_grp_list" on "b"."c_rack_grp_code" = "temp_rack_grp_list"."c_rack_grp_code" where "b"."c_doc_no" = "st_track_det"."c_doc_no" and "b"."c_tray_code" = "st_track_det"."c_tray_code" and "b"."n_complete" = 0) as "n_item_count",
            "isnull"(@maxSeq,0) as "n_max_seq",
            "st_track_mst"."n_confirm" as "n_confirm",
            if "isnull"("st_track_urgent_doc"."n_urgent",0) <> 4 then "st_track_mst"."n_urgent" else "st_track_urgent_doc"."n_urgent" endif as "n_urgent",
            "st_track_mst"."c_sort" as "c_sort",
            "st_track_det"."c_user" as "c_user",
            "isnull"("godown_tran_mst"."n_eb_flag",0) as "n_exp_doc",
            "trim"("substring"("godown_tran_mst"."c_note","charindex"(':',"godown_tran_mst"."c_note")+1)) as "c_note",
            if "len"("trim"("isnull"("st_track_mst"."c_order_id",''))) <> 0 then
              0
            else
              1
            endif as "n_allow_not_found"
            from "st_track_tray_move"
              left outer join "st_track_det" on "st_track_tray_move"."c_doc_no" = "st_track_det"."c_doc_no"
              and "st_track_tray_move"."n_inout" = "st_track_det"."n_inout"
              and "st_track_tray_move"."c_tray_code" = "st_track_det"."c_tray_code"
              and "st_track_tray_move"."c_godown_code" = "st_track_det"."c_godown_code"
              and "st_track_tray_move"."c_stage_code" = "st_track_det"."c_stage_code"
              and "st_track_tray_move"."c_rack_grp_code" = "st_track_det"."c_rack_grp_code"
              left outer join "godown_tran_mst"
              on "godown_tran_mst"."c_br_code" = "left"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")-1)
              and "godown_tran_mst"."c_year" = "left"("substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1),"charindex"('/',"substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1))-1)
              and "godown_tran_mst"."c_prefix" = "left"("substring"("substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1),"charindex"('/',"substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1))+1),"charindex"('/',"substring"("substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1),"charindex"('/',"substring"("st_track_det"."c_doc_no","charindex"('/',"st_track_det"."c_doc_no")+1))+1))-1)
              and "godown_tran_mst"."n_srno" = "reverse"("left"("reverse"("st_track_det"."c_doc_no"),"charindex"('/',"reverse"("st_track_det"."c_doc_no"))-1))
              join "temp_rack_grp_list" on "st_track_tray_move"."c_rack_grp_code" = "temp_rack_grp_list"."c_rack_grp_code"
              join "st_track_mst" on "st_track_mst"."c_doc_no" = "st_track_tray_move"."c_doc_no"
              and "st_track_mst"."n_inout" = "st_track_tray_move"."n_inout"
              left outer join "st_track_urgent_doc" on "st_track_urgent_doc"."c_doc_no" = "st_track_det"."c_doc_no"
              and "st_track_urgent_doc"."n_inout" = "st_track_det"."n_inout"
            where "st_track_tray_move"."n_inout" not in( 8,9,1 ) and "st_track_tray_move"."n_park_flag" = 0
            and "st_track_tray_move"."c_godown_code" = @GodownCode) as "tray_list"
        group by "c_tray_code","n_first_in_stage","c_doc_no","n_inout","c_message","n_max_seq","t_time","n_exp_doc","c_note","n_allow_not_found","n_urgent"
        order by "t_time" asc,"n_urgent" desc for xml raw,elements
    end if when 'set_selected_tray' then -----------------------------------------------------------------------
    --@HdrData  : 1 Tranbrcode~2 TranYear~3 TranPrefix~4 TranSrno~5 CurrentTray~6 FirstInStage~7 OldTray~8 nVerifyDocUser~9 nFilterNoBatchItems
    --@DetData : ValidateTray**__
    --(validateTray : 1 - new tray assigned ,
    --	- to retrieve the items in the existing tray)
    call "usp_set_selected_tray"(@UserId,@HdrData,@DetData,@RackGrpCode,@StageCode,@GodownCode,@gsBr,@t_preserve_ltime);
    return
  when 'get_batch_list' then -----------------------------------------------------------------------
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
      select "c_cust_code" into @CustCode from "st_track_mst" where "c_doc_no" = @DocNo;
      select "n_type","n_rate_on" into @n_type,@n_rate_on from "act_mst" where "act_mst"."c_code" = @CustCode;
      set @tranExpDays
         = "isnull"(
        (select "n_sale_exp_days" as "n_gdn_exp_days"
          from "item_group_mst"
            join "item_mst" on "item_group_mst"."c_code" = "item_mst"."c_group_code"
          where "item_mst"."c_code" = @ItemCode
          and @TranPrefix = '6'),
        50);
      if @n_rate_on = 5 and @n_type = 2 then
        insert into "temp_items_not_in_stock_ledger_inward"(
          select distinct "stock_ledger_inward"."c_item_code","stock_ledger_inward"."c_batch_no"
            from "stock_ledger_inward" where "c_item_code" = @ItemCode)
      end if when 'O' then
      select "c_cust_code" into @CustCode from "st_track_mst" where "c_doc_no" = @DocNo;
      select "n_type","n_rate_on" into @n_type,@n_rate_on from "act_mst" where "act_mst"."c_code" = @CustCode;
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
            50);
          //added by vinay
          if @n_rate_on = 5 then
            insert into "temp_items_not_in_stock_ledger_inward"(
              select distinct "stock_ledger_inward"."c_item_code","stock_ledger_inward"."c_batch_no"
                from "stock_ledger_inward" where "c_item_code" = @ItemCode)
          //added by vinay
          end if
        else set @tranExpnDays = 50
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
          "stock_mst"."n_mrp_box" as "n_mrp_box",
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
          "stock_mst"."n_mrp_box" as "n_mrp_box",
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
          "stock_mst"."n_mrp_box" as "n_mrp_box",
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
    ----------------------
    if "uf_get_br_code"(@gsBr) = '503' then
      select 'WF-'+"c_sh_name" into @sh_name from "act_mst" where "c_code" = @Tranbrcode
    else
      select "c_sh_name" into @sh_name from "act_mst" where "c_code" = @Tranbrcode
    end if;
    select "c_sh_name" into @comp_sh_name from "act_mst" where "n_type" = 3 and "c_code" = @gsBr;
    if(@n_type = 2 and @n_rate_on = 5) then
      select "batch_list"."c_batch_no",
        "max"("batch_list"."n_mrp") as "n_mrp",
        "max"("batch_list"."n_mrp_box") as "n_mrp_box",
        "max"("batch_list"."n_sale_rate") as "n_sale_rate",
        "date"("max"("batch_list"."d_exp_dt")) as "d_exp_dt",
        "TRIM"("STR"("TRUNCNUM"("sum"("batch_list"."n_stock_qty")+"sum"("batch_list"."n_issue_qty"),3),10,0)) as "n_bal_qty",
        "item_mst"."n_qty_per_box" as "n_qty_per_box",
        "TRIM"("STR"("TRUNCNUM"("sum"("batch_list"."n_stock_qty"),3),10,0)) as "n_eg_stock",
        if "item_mst"."n_self_barcode_req" = 2 then
          null
        else
          "trim"("barcode_det"."c_key")
        endif as "c_key",
        @sh_name as "sh_name",
        @comp_sh_name as "comp_sh_name"
        from "batch_list"
          left outer join "temp_items_not_in_stock_ledger_inward" as "st_ldgr_in" on "st_ldgr_in"."c_item_code" = "batch_list"."c_item_code" and "st_ldgr_in"."c_batch_no" = "batch_list"."c_batch_no"
          join "item_mst" on "item_mst"."c_code" = "batch_list"."c_item_code"
          left outer join "barcode_det" on "barcode_det"."c_item_code" = @ItemCode and "barcode_det"."c_batch_no" = "batch_list"."c_batch_no" and "barcode_det"."c_br_code" = @BrCode
        where "item_mst"."c_code" = @ItemCode
        group by "batch_list"."c_batch_no","n_qty_per_box","batch_list"."c_item_code","n_self_barcode_req","c_key"
        having "n_bal_qty" > 0
        order by "d_exp_dt" asc for xml raw,elements
    else
      select "batch_list"."c_batch_no",
        "max"("batch_list"."n_mrp") as "n_mrp",
        "max"("batch_list"."n_mrp_box") as "n_mrp_box",
        "max"("batch_list"."n_sale_rate") as "n_sale_rate",
        "date"("max"("batch_list"."d_exp_dt")) as "d_exp_dt",
        "TRIM"("STR"("TRUNCNUM"("sum"("batch_list"."n_stock_qty")+"sum"("batch_list"."n_issue_qty"),3),10,0)) as "n_bal_qty",
        "item_mst"."n_qty_per_box" as "n_qty_per_box",
        "TRIM"("STR"("TRUNCNUM"("sum"("batch_list"."n_stock_qty"),3),10,0)) as "n_eg_stock",
        if "item_mst"."n_self_barcode_req" = 2 then
          null
        else
          "trim"("barcode_det"."c_key")
        endif as "c_key",
        @sh_name as "sh_name",
        @comp_sh_name as "comp_sh_name"
        from "batch_list"
          join "item_mst" on "item_mst"."c_code" = "batch_list"."c_item_code"
          left outer join "barcode_det" on "barcode_det"."c_item_code" = @ItemCode and "barcode_det"."c_batch_no" = "batch_list"."c_batch_no" and "barcode_det"."c_br_code" = @BrCode
        where "item_mst"."c_code" = @ItemCode
        group by "batch_list"."c_batch_no","n_qty_per_box","batch_list"."c_item_code","n_self_barcode_req","c_key"
        having "n_bal_qty" > 0
        order by "d_exp_dt" asc for xml raw,elements
    end if when 'document_done' then -----------------------------------------------------------------------
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
    --print +'njan'+@DetData;
    set @DocNo = @Tranbrcode+'/'+@TranYear+'/'+@TranPrefix+'/'+"string"(@TranSrno);
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
        and "det"."c_stage_code" = @StageCode
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
    //Shifted from down by Dileep
    select "c_rack_grp_code"
      into @nextRackGrp from "st_store_stage_det"
      where "c_stage_code" = @StageCode and "n_pos_seq" = any(select top 1 "n_seq"+1 as "n_seq" from "temp_rack_grp_list"
        order by "n_seq" desc);
    --for batch error 
    --gargee new 
    set @ExpBatch = "http_variable"('ExpBatch');
    set @doc_seq = 0;
    while @ExpBatch <> '' loop
      select "Locate"(@ExpBatch,@ColSep) into @ColPos;
      set @InOutFlag = "Trim"("Left"(@ExpBatch,@ColPos-1));
      set @ExpBatch = "SubString"(@ExpBatch,@ColPos+@ColMaxLen);
      --2 Seq
      select "Locate"(@ExpBatch,@ColSep) into @ColPos;
      set @OrgSeq = "Trim"("Left"(@ExpBatch,@ColPos-1));
      set @ExpBatch = "SubString"(@ExpBatch,@ColPos+@ColMaxLen);
      --3 ItemCode
      select "Locate"(@ExpBatch,@ColSep) into @ColPos;
      set @ItemCode = "Trim"("Left"(@ExpBatch,@ColPos-1));
      set @ExpBatch = "SubString"(@ExpBatch,@ColPos+@ColMaxLen);
      --4 batchreason
      select "Locate"(@ExpBatch,@ColSep) into @ColPos;
      set @batchreasoncode = "Trim"("Left"(@ExpBatch,@ColPos-1));
      set @ExpBatch = "SubString"(@ExpBatch,@ColPos+@ColMaxLen);
      --5 First batch
      select "Locate"(@ExpBatch,@ColSep) into @ColPos;
      set @BatchNo = "Trim"("Left"(@ExpBatch,@ColPos-1));
      set @ExpBatch = "SubString"(@ExpBatch,@ColPos+@ColMaxLen);
      -- 6 Selected batch
      select "Locate"(@ExpBatch,@ColSep) into @ColPos;
      set @selected_batch = "Trim"("Left"(@ExpBatch,@ColPos-1));
      set @ExpBatch = "SubString"(@ExpBatch,@ColPos+@ColMaxLen);
      --7 Qty
      select "Locate"(@ExpBatch,@ColSep) into @ColPos;
      set @Qty = "Trim"("Left"(@ExpBatch,@ColPos-1));
      set @ExpBatch = "SubString"(@ExpBatch,@ColPos+@ColMaxLen);
      -- Row Seperator--
      select "Locate"(@ExpBatch,@RowSep) into @RowPos;
      set @ExpBatch = "SubString"(@ExpBatch,@RowPos+@RowMaxLen);
      set @doc_seq = @doc_seq+1;
      if @ItemCode <> '' then
        insert into "st_batch_error"( "c_doc_no","d_date","c_item_code","c_batch_no","n_doc_seq","n_seq","c_reason_code","c_note","c_user","c_tray_code","c_checked_user","n_status","n_error_type","n_qty","c_rack_grp_code","c_stage_code" ) on existing update defaults off
          select @DocNo,@t_ltime,@ItemCode,@BatchNo,@doc_seq,@OrgSeq,@batchreasoncode,@selected_batch,@UserId,@CurrentTray,'',0,0,@Qty,@tmp,@StageCode
      end if
    end loop;
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
        //Added on 02/11/16 by Dileep to avoid double document_done 
        //###-----------------------------------------------------###
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
              and "c_stage_code" = @StageCode
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
            and "st_track_pick"."c_stage_code" = @StageCode
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
      set @t_pick_time = "Trim"("Left"(@DetData,@ColPos-1)); --@t_pick_time value original code
      --  set @t_pick_time = convert(timestamp,"Trim"("Left"(@DetData,@ColPos-1)));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --print @t_pick_time;
      if "trim"(@t_pick_time) = '' or @t_pick_time is null then
        set @t_pick_time = convert(time,"left"("now"(),19))
      end if;
      -- Non pick flag used in PA for some purpose we are not using in EG
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @non_pick_flag = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      -- n_dynamic_godown_qty added in EG for set selected tray and get batch list calling , but not used anywhere
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @n_dynamic_godown_qty = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      -- n_barcode_print based on Module M00099 when enabled , user can mark the items as not barcoded in picking.
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @n_barcode_print = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      select "Locate"(@DetData,@RowSep) into @RowPos;
      set @DetData = "SubString"(@DetData,@RowPos+@RowMaxLen);
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
        end if;
        //vinay added on 14-10-2020
        insert into "gdn_bounced_items_det"
          ( "c_br_code","c_year","c_prefix","n_srno","c_item_code",
          "n_qty","c_po_no","d_ldate","t_ltime","n_seq",
          "n_flag","n_pk","c_reason_code","c_process_id",
          "c_user","c_sys_ip","c_remark" ) on existing skip
          select @TranBrCode,@TranYear,@TranPrefix,@TranSrno,@ItemCode,
            @Qty,"st_track_det"."c_doc_no",@d_ldate,@t_ltime,"st_track_det"."n_seq",
            2,0,@cReason,'000003',@userid,'','PICKING'
            from "st_track_det"
            where "c_doc_no" = @DocNo
            and "n_seq" = @OrgSeq
            and "st_track_det"."c_godown_code" = @GodownCode
      elseif @ItemNotFound = 1 and @TranPrefix = '6' then
        //Done By Dileep on 04/01/20
        update "ord_ledger" set "n_cancel_qty" = "isnull"("n_cancel_qty",0)+"isnull"(@Qty,0)
          where "ord_ledger"."c_br_code" = @TranBrCode
          and "ord_ledger"."c_year" = @TranYear
          and "ord_ledger"."c_prefix" = @TranPrefix
          and "ord_ledger"."n_srno" = @TranSrno
          and "ord_ledger"."n_seq" = @OrgSeq
          and "ord_ledger"."c_item_code" = @ItemCode
      end if;
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
          "c_godown_code","n_barcode_print" ) on existing update defaults off values
          ( @DocNo,@InOutFlag,@Seq,@OrgSeq,@ItemCode,@BatchNo,@Qty,@HoldFlag,@cReason,@cNote,@UserId,@t_pick_time,@CurrentTray,@devID,@RackCode,@CurrentGrp,@StageCode,@GodownCode,@n_barcode_print ) ;
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
    if(select "count"("c_tray_code") from "st_track_tray_move" where "c_tray_code" = @CurrentTray and "c_stage_code" = @StageCode and "c_godown_code" = @GodownCode) > 1 then
      --at the end of the stage(last RG) preserve 1 record for scanning process
      select top 1 "st_track_tray_move"."c_rack_grp_code"
        into @maxRackGrp from "st_track_tray_move"
          join "temp_rack_grp_list" on "st_track_tray_move"."c_stage_code" = "temp_rack_grp_list"."c_stage_code"
          and "st_track_tray_move"."c_rack_grp_code" = "temp_rack_grp_list"."c_rack_grp_code"
        where "st_track_tray_move"."c_godown_code" = @GodownCode and "st_track_tray_move"."c_stage_code" = @StageCode
        order by "n_seq" desc;
      delete from "st_track_tray_move"
        where "c_tray_code" = @CurrentTray
        and "c_rack_grp_code" <> @maxRackGrp
        and "c_stage_code" = @StageCode
        and "st_track_tray_move"."c_godown_code" = @GodownCode;
      if @enable_log = 1 then
        update "st_doc_done_log"
          set "n_delete" = 1
          where "n_seq" = @log_seq
      end if end if;
    if @nextRackGrp is not null then //--a or b
      //################## Added On 04/12/16 for Vaoiding Blank Tray Move Which is not able to handle by Android Tab
      if @ItemsInDetail = 0 and @NextTray <> '1' then
        //check for pending items
        if(select "count"("c_item_code") from "st_track_det" join "temp_rack_grp_list"
              on "st_track_det"."c_stage_code" = "temp_rack_grp_list"."c_stage_code"
              and "st_track_det"."c_rack_grp_code" = "temp_rack_grp_list"."c_rack_grp_code"
            where "st_track_det"."n_complete" = 0
            and "st_track_det"."c_tray_code" = @CurrentTray
            and "st_track_det"."n_inout" = @InOutFlag
            and "st_track_det"."c_godown_code" = @GodownCode
            and "st_track_det"."c_doc_no" = @DocNo) > 0 then
          //DebugLog
          if @enable_log = 1 then
            insert into "st_log_ret"
              ( "c_doc_no","c_tray","c_stage","c_rg","n_flag","t_time" ) values
              ( @DocNo,@CurrentTray,@StageCode,'Blank Tray Move To '+"ISNULL"(@nextRackGrp,'N'),4,"getdate"() ) 
          end if;
          select 'Success' as "c_message",@maxSeq as "n_max_seq" for xml raw,elements;
          return
        end if end if;
      //############################################
      select top 1 "isnull"("t_time","now"())
        into @t_preserve_ltime from "st_track_tray_move"
        where "c_tray_code" = @CurrentTray
        and "st_track_tray_move"."c_godown_code" = @GodownCode;
      set @t_ltime = "left"("now"(),19);
      set @t_preserve_ltime = "left"(@t_preserve_ltime,19);
      --new tray insert
      select top 1 "c_rack_grp_code"
        into @rackGrp from "st_track_tray_move"
        where "c_doc_no" = @DocNo
        and "n_inout" = @InOutFlag
        and "c_tray_code" = @CurrentTray
        and "c_stage_code" = @StageCode
        --and c_user =@UserId ;
        order by if "c_user" = @UserId then 0 else 1 endif asc; //removed user id where condition and added order by as some times null was commit
      //Delete insert chnaged by Dileep to update on 02-11-2016
      if(select "n_active" from "st_track_module_mst" where "c_code" = 'M00084') = 0 then
        update "st_track_tray_move"
          set "c_rack_grp_code" = @nextRackGrp,
          "t_time" = @t_ltime,
          "c_user" = @UserId,
          "n_tray_flag" = 0
          where "st_track_tray_move"."c_tray_code" = @CurrentTray
          and "st_track_tray_move"."c_godown_code" = @GodownCode
          and "st_track_tray_move"."c_doc_no" = @DocNo
      else
        update "st_track_tray_move"
          set "c_rack_grp_code" = @nextRackGrp,"n_park_flag" = 0,
          "t_time" = @t_ltime,
          "c_user" = @UserId,
          "n_tray_flag" = 0
          where "st_track_tray_move"."c_tray_code" = @CurrentTray
          and "st_track_tray_move"."c_godown_code" = @GodownCode
          and "st_track_tray_move"."c_doc_no" = @DocNo;
        delete from "st_track_park" where "st_track_park"."c_doc_no" = @DocNo and "st_track_park"."c_tray_code" = @CurrentTray
          and "st_track_park"."c_godown_code" = @GodownCode and "c_stage_code" = @StageCode
      end if;
      if @enable_log = 1 then
        update "st_doc_done_log"
          set "n_tray_time" = 1
          where "n_seq" = @log_seq
      end if;
      call "uf_update_tray_time"(@DocNo,@InOutFlag,@CurrentTray,'PICKING',@UserId,@rackGrp,@StageCode,2,@t_tray_move_time,@d_item_pick_count,@d_item_bounce_count);
      if @enable_log = 1 then
        update
          "st_doc_done_log"
          set "n_tray_time" = 2
          where "n_seq" = @log_seq
      end if;
      --sani
      select "max"("c_user_id")
        into @next_rack_user from "st_store_login_det"
        where "c_rack_grp_code" = @nextRackGrp
        and "c_stage_code" = @StageCode
        and "t_login_time" is not null;
      if @next_rack_user is null or "trim"(@next_rack_user) = '' then
      else
        if @enable_log = 1 then
          update
            "st_doc_done_log"
            set "n_tray_time" = 3
            where "n_seq" = @log_seq
        end if;
        call "uf_update_tray_time"(@DocNo,@InOutFlag,@CurrentTray,'PICKING',@UserId,@nextRackGrp,@StageCode,0,@t_tray_move_time,@d_item_pick_count,@d_item_bounce_count);
        if @enable_log = 1 then
          update
            "st_doc_done_log"
            set "n_tray_time" = 4
            where "n_seq" = @log_seq
        --Last rack grp 
        //################## Added On 04/12/16 for Vaoiding Blank Tray Move Which is not able to handle by Android Tab
        end if
      end if
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
        and "c_stage_code" = @StageCode
        and "st_track_tray_move"."c_godown_code" = @GodownCode;
      set @t_ltime = "left"("now"(),19);
      --print @t_ltime ;
      select top 1 "c_rack_grp_code"
        into @rackGrp from "st_track_tray_move"
        where "c_doc_no" = @DocNo
        and "n_inout" = @InOutFlag
        and "c_stage_code" = @StageCode
        and "c_tray_code" = @CurrentTray
        --and c_user =@UserId ;
        order by if "c_user" = @UserId then 0 else 1 endif asc; //removed user id where condition and added order by as some times null was comming
      if @enable_log = 1 then
        update
          "st_doc_done_log"
          set "n_tray_time" = 5
          where "n_seq" = @log_seq
      end if;
      --added by gargee for st_track_tray_time null issue on 21-01-2019
      select top 1 "c_rack_grp_code" into @tmp_rg from "temp_rack_grp_list";
      call "uf_update_tray_time"(@DocNo,@InOutFlag,@CurrentTray,'PICKING',@UserId,@tmp_rg,@StageCode,2,@t_tray_move_time,@d_item_pick_count,@d_item_bounce_count);
      if @enable_log = 1 then
        update "st_doc_done_log"
          set "n_tray_time" = 6
          where "n_seq" = @log_seq
      end if;
      if @barcode_print_on_move = 0 then
        if(select "n_active" from "st_track_module_mst" where "c_code" = 'M00084') = 0 then
          update "st_track_tray_move"
            set "n_inout" = 9,
            "c_rack_grp_code" = '-',
            "t_time" = @t_ltime,
            "n_tray_flag" = 0
            where "c_doc_no" = @DocNo
            and "n_inout" = @InOutFlag
            and "c_tray_code" = @CurrentTray
            and "c_stage_code" = @StageCode
            and "c_godown_code" = @GodownCode
        else
          update "st_track_tray_move"
            set "n_inout" = 9,"n_park_flag" = 0,
            "c_rack_grp_code" = '-',
            "t_time" = @t_ltime,
            "n_tray_flag" = 0
            where "c_doc_no" = @DocNo
            and "n_inout" = @InOutFlag
            and "c_tray_code" = @CurrentTray
            and "c_stage_code" = @StageCode
            and "c_godown_code" = @GodownCode;
          delete from "st_track_park" where "st_track_park"."c_doc_no" = @DocNo and "st_track_park"."c_tray_code" = @CurrentTray
            and "st_track_park"."c_godown_code" = @GodownCode and "c_stage_code" = @StageCode
        end if
      else if @out_barcode_print_flag = 1 then
          if(select "n_active" from "st_track_module_mst" where "c_code" = 'M00084') = 1 then
            update "st_track_tray_move"
              set "n_inout" = 9,"n_park_flag" = 0,
              "c_rack_grp_code" = '-',
              "t_time" = @t_ltime,
              "n_tray_flag" = 0,"st_track_tray_move"."n_flag" = 1
              where "c_doc_no" = @DocNo
              and "n_inout" = @InOutFlag
              and "c_tray_code" = @CurrentTray
              and "c_stage_code" = @StageCode
              and "c_godown_code" = @GodownCode;
            delete from "st_track_park" where "st_track_park"."c_doc_no" = @DocNo and "st_track_park"."c_tray_code" = @CurrentTray
              and "st_track_park"."c_godown_code" = @GodownCode and "c_stage_code" = @StageCode
          else
            update "st_track_tray_move"
              set "n_inout" = 9,
              "c_rack_grp_code" = '-',
              "t_time" = @t_ltime,
              "n_tray_flag" = 0,"st_track_tray_move"."n_flag" = 1
              where "c_doc_no" = @DocNo
              and "n_inout" = @InOutFlag
              and "c_tray_code" = @CurrentTray
              and "c_stage_code" = @StageCode
              and "c_godown_code" = @GodownCode
          end if;
          update "st_track_tray_move"
            set "n_inout" = 9,
            "c_rack_grp_code" = '-',
            "t_time" = @t_ltime,
            "n_tray_flag" = 0,"st_track_tray_move"."n_flag" = 1
            where "c_doc_no" = @DocNo
            and "n_inout" = @InOutFlag
            and "c_tray_code" = @CurrentTray
            and "c_stage_code" = @StageCode
            and "c_godown_code" = @GodownCode
        end if end if;
      select "count"("st_track_det"."c_item_code")
        into @itemcount from "st_track_det" where "st_track_det"."c_doc_no" = @DocNo
        and "st_track_det"."n_inout" = @InOutFlag
        and("st_track_det"."n_complete" not in( 2,9,8 ) or "st_track_det"."n_qty" > "st_track_det"."n_bal_qty"); //vinay added (or st_track_det.n_qty>st_track_det.n_bal_qty) on 14-10-20
      if @itemcount = 0 then
        update "st_track_mst" set "st_track_mst"."n_complete" = 9,"st_track_mst"."t_time_in" = "now"()
          where "st_track_mst"."c_doc_no" = @DocNo
          and "st_track_mst"."n_inout" = @InOutFlag
      end if;
      --Sani 17_06_2016
      --call uf_st_insert_godown_transfer_from_exp(@DocNo ,@InOutFlag, @CurrentTray ,@GodownCode ,@UserId  ) ;
      --call uf_st_insert_expiry_inward_doc(@DocNo ,@InOutFlag, @CurrentTray ,@GodownCode ,@UserId  ) ;
      if @TranPrefix = '162' then --Godown transfer req 
        if @nextRackGrp is null then --@ItemsInDetail = 1 then--//@ItemsInDetail = 1 then  validation removed 
          -- to handle exp stock removal  on 14-07-2016	
          ---------------------- GET details from request table.
          select "c_godown_from_code","c_godown_to_code","c_reason_code","c_note","n_eb_flag"
            into @godownFrom,@godownTo,@ReasonCode,@cNote,@n_eb_flag
            from "godown_tran_mst"
            where "c_br_code"+'/'+"c_year"+'/'+"c_prefix"+'/'+"string"("n_srno") = @DocNo;
          if "trim"(@godownTo) = '' or @godownTo is null then
            set @godownTo = '-'
          end if;
          if @NewSrno is null then
            set @NewSrno = 1
          end if;
          select "count"("c_trans")
            into @nPrefixCount from "prefix_serial_no"
            where "c_trans" = 'GDNST'
            and "c_year" = @TranYear
            and "c_br_code" = @TranBrCode
            and "c_prefix" = '160';
          if(@nPrefixCount) <= 0 then
            insert into "prefix_serial_no"
              ( "c_trans","c_br_code","c_year","c_prefix","n_sr_number","c_note",
              "n_stationery_type" ) on existing skip
              select 'GDNST',@gsBr,@TranYear,'160',@NewSrno,null,0
          else
            select "n_sr_number"
              into @NewSrno from "prefix_serial_no"
              where "c_trans" = 'GDNST'
              and "c_year" = @TranYear
              and "c_br_code" = @TranBrCode
              and "c_prefix" = '160'
          end if;
          update "prefix_serial_no" set "n_sr_number" = "n_sr_number"+1
            where "c_trans" = 'GDNST'
            and "c_year" = @TranYear
            and "c_br_code" = @TranBrCode
            and "c_prefix" = '160';
          set @cNote = 'Tray : '+"string"(@CurrentTray);
          insert into "godown_tran_mst"
            ( "c_br_code","c_year","c_prefix","n_srno","d_date",
            "t_time","c_godown_from_code","c_godown_to_code","c_reason_code","c_note",
            "c_lr_no","d_lr_date","d_stock_sent_date","n_cases","n_approved",
            "n_shift","n_cnt_no","n_cancel_flag","d_ldate","t_ltime",
            "c_user","c_modiuser","n_store_track","c_computer_name","c_sys_user",
            "c_sys_ip",
            "n_eb_flag" ) 
            select @TranBrCode as "c_br_code",@TranYear as "c_year",'160' as "c_prefix",
              @NewSrno as "n_srno","uf_default_date"() as "d_date","now"() as "t_time",@godownTo as "c_godown_from_code",
              @godownFrom as "c_godown_to_code",@ReasonCode as "c_reason_code",@cNote as "c_note",@DocNo as "c_lr_no",null,
              "uf_default_date"() as "d_stock_sent_date",
              0,1,0,0,0,"uf_default_date"(),"now"(),@UserId,@UserId,2,null,null,null,@n_eb_flag;
          insert into "godown_tran_det"
            ( "c_br_code","c_year","c_prefix","n_srno","n_seq",
            "d_date","c_godown_from_code","c_godown_to_code","c_item_code","c_batch_no",
            "n_request_qty","n_qty","n_approved","n_shift","n_cancel_flag",
            "d_ldate","t_ltime","n_store_track","c_tray_code",
            "n_eb_flag" ) 
            select @TranBrCode,@TranYear,'160',@NewSrno,"number"(),"uf_default_date"(),@godownTo,@godownFrom,"c_item_code","c_batch_no",0,"n_qty",
              1,0,0,"uf_default_date"(),"now"(),
              2,"c_tray_code",@n_eb_flag
              from "st_track_pick"
              where "c_doc_no" = @DocNo
              and "c_tray_code" = @CurrentTray
              and "n_confirm_qty" = 0;
          update "st_track_pick" set "n_confirm_qty" = "n_qty"
            where "c_doc_no" = @DocNo
            and "c_tray_code" = @CurrentTray;
          update "st_track_det","st_track_pick"
            set "st_track_det"."n_complete" = 9
            where "st_track_det"."c_doc_no" = "st_track_pick"."c_doc_no"
            and "st_track_det"."n_seq" = "st_track_pick"."n_org_seq"
            and "st_track_pick"."c_doc_no" = @DocNo
            and "st_track_pick"."c_tray_code" = @CurrentTray
        end if; -- ItemsInDetail
        delete from "st_track_tray_move"
          where "c_doc_no" = @DocNo
          and "c_tray_code" = @CurrentTray
          and "c_stage_code" = @StageCode
          and "c_godown_code" = @GodownCode
      --godown request
      end if end if; --last rack grp 
    if @nextRackGrp is null then
      select "count"()
        into @n_pick_count from "st_track_pick"
        where "st_track_pick"."c_tray_code" = @CurrentTray
        and "st_track_pick"."c_doc_no" = @DocNo
        and "c_stage_code" = @StageCode
        and "st_track_pick"."c_godown_code" = @GodownCode;
      if @n_pick_count is null then
        set @n_pick_count = 0
      end if;
      --print @n_pick_count ;
      if @n_pick_count = 0 then
        delete from "st_track_tray_move"
          where "c_tray_code" = @CurrentTray
          and "c_doc_no" = @DocNo
          and "c_stage_code" = @StageCode
          and "c_godown_code" = @GodownCode;
        commit work;
        if @enable_log = 1 then
          insert into "st_log_ret"
            ( "c_doc_no","c_tray","c_stage","c_rg","n_flag","t_time" ) values
            ( @DocNo,@CurrentTray,@StageCode,'TRAY DELETE: gdwn ='+"ISNULL"(@GodownCode,'G'),8,"getdate"() ) 
        end if end if end if;
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
      into @itemcount
      from "st_track_det" where "st_track_det"."c_doc_no" = @DocNo and "st_track_det"."n_inout" = @InOutFlag
      and("st_track_det"."n_complete" not in( 2,9,8 ) or "st_track_det"."n_qty" > "st_track_det"."n_bal_qty");
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
          and "st_track_pick"."c_stage_code" = @StageCode
          and "st_track_pick"."c_godown_code" = @GodownCode;
        select 'Success' as "c_message",@maxSeq as "n_max_seq" for xml raw,elements
      else
        select 'Failure' as "c_message" for xml raw,elements
      --set @DetData='1'+@ColSep+'2' +@ColSep + string(@nTrayFull) + @ColSep+@RowSep;
      end if
    else set @DetData = '1'+@ColSep+'2'+@ColSep+@RowSep;
      --Print('Det data frm  doc done ' + @DetData);
      --Saneesh For capture Tray Process time 
      call "usp_set_selected_tray"(@UserId,@HdrData_Set_Selected_Tray,@DetData,@RackGrpCode,@StageCode,@GodownCode,@gsBr,@t_preserve_ltime);
      return
    end if when 'item_done' then -----------------------------------------------------------------------
    --called when an item is picked or put back
    --@HdrData
    --1 Tranbrcode~2 TranYear~3 TranPrefix~4 TranSrno~5 ForwardFlag
    --@DetData
    --1 InOutFlag~2 ItemCode~3 BatchNo~4 Seq~5 Qty~6 ReasonCode
    -------HdrData
    --1 Tranbrcode
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
    --5 ForwardFlag
    /*		
0 - shift back, 
1 - item done, 
2 - item not found
3 - shift back when item not found 
*/
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @ForwardFlag = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --message 'ForwardFlag '+string(@ForwardFlag ) type warning to client;			
    set @DocNo = @Tranbrcode+'/'+@TranYear+'/'+@TranPrefix+'/'+"string"(@TranSrno);
    --DetData--------------
    --1 InOutFlag~2 ItemCode~3 BatchNo~4 Seq~5 PickedQty~6 ReasonCode
    --1 InOutFlag
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @InOutFlag = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --message 'InOutFlag '+@InOutFlag type warning to client;
    --2 ItemCode
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @ItemCode = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --message 'ItemCode '+@ItemCode type warning to client;
    --3 BatchNo
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @BatchNo = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --message 'BatchNo '+@BatchNo type warning to client;	
    --4 Seq
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @Seq = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --message 'Seq '+@Seq type warning to client;	
    --5 PickedQty
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @PickedQty = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --message 'Seq '+@Seq type warning to client;	
    --6 ReasonCode		
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @ReasonCode = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --message 'ReasonCode '+@ReasonCode type warning to client;	
    if @ForwardFlag = 1 then -- item done
      select(if("n_bal_qty"-@PickedQty) < 0 then 0 else("n_bal_qty"-@PickedQty) endif)
        into @RemainingQty from "st_track_det"
        where "c_doc_no" = @DocNo
        and "n_inout" = @InOutFlag
        and "c_item_code" = @ItemCode
        and "n_seq" = @Seq
        and "st_track_det"."c_godown_code" = @GodownCode;
      update "st_track_det"
        set "n_complete" = (if @RemainingQty = 0 then @ForwardFlag else 0 endif),
        "n_bal_qty" = @RemainingQty
        where "c_doc_no" = @DocNo
        and "n_inout" = @InOutFlag
        and "c_item_code" = @ItemCode
        and "n_seq" = @Seq
        and "st_track_det"."c_godown_code" = @GodownCode
    --and c_batch_no = @BatchNo;			
    elseif @ForwardFlag = 0 then -- shift back, 
      update "st_track_det"
        set "n_complete" = @ForwardFlag,
        "n_bal_qty" = ("n_bal_qty"+@PickedQty)
        where "c_doc_no" = @DocNo
        and "n_inout" = @InOutFlag
        and "c_item_code" = @ItemCode
        and "n_seq" = @Seq
        and "st_track_det"."c_godown_code" = @GodownCode
    elseif @ForwardFlag = 2 then -- item not found
      update "st_track_det"
        set "n_complete" = @ForwardFlag,
        "c_reason_code" = @ReasonCode
        where "c_doc_no" = @DocNo
        and "n_inout" = @InOutFlag
        and "c_item_code" = @ItemCode
        and "n_seq" = @Seq
        and "st_track_det"."c_godown_code" = @GodownCode
    elseif @ForwardFlag = 3 then -- shift back when item not found 
      update "st_track_det"
        set "n_complete" = 0
        where "c_doc_no" = @DocNo
        and "n_inout" = @InOutFlag
        and "c_item_code" = @ItemCode
        and "n_seq" = @Seq
        and "st_track_det"."c_godown_code" = @GodownCode
    end if;
    if sqlstate = '00000' then
      commit work;
      select 'Success' as "c_message" for xml raw,elements
    else
      rollback work;
      select 'Failure' as "c_message" for xml raw,elements
    end if when 'free_trays' then -----------------------------------------------------------------------
    --http://192.168.7.12:13000/ws_st_stock_removal?gsbr=000&devID=GajananPC[192.168.7.12]&sKEY=KEY&UserId=MYBOSS&PhaseCode=PH0001&RackGrpcode=-**&StageCode=SS0001&cindex=free_trays&Hdrdata=&DetData=
    select distinct top 50 "a"."c_code" as "c_tray",
      "a"."c_name" as "c_tray_name"
      from "st_tray_mst" as "a"
        join "st_tray_type_mst" as "c" on "a"."c_tray_type_code" = "c"."c_code"
        left outer join "st_track_in" as "b" on "a"."c_code" = "b"."c_tray_code"
        left outer join "st_track_tray_move" as "d" on "a"."c_code" = "d"."c_tray_code"
      where "b"."c_tray_code" is null and "d"."c_tray_code" is null
      and "a"."n_in_out_flag" in( 1,2,3 ) 
      and "a"."n_cancel_flag" = 0
      and "c"."n_cancel_flag" = 0
      and "a"."c_code" like @HdrData+'%' for xml raw,elements
  when 'cache_items' then -----------------------------------------------------------------------
    set @RackGrpList = @RackGrpCode;
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
    select top 100 "cache_list"."c_doc_no" as "c_doc_no",
      "cache_list"."n_inout" as "n_inout",
      "cache_list"."c_item_code" as "c_item_code",
      "cache_list"."c_batch_no" as "c_batch_no",
      "cache_list"."n_seq" as "n_seq",
      "cache_list"."n_qty" as "n_qty",
      "cache_list"."n_bal_qty" as "n_bal_qty",
      "cache_list"."c_note" as "c_note",
      "cache_list"."c_rack" as "c_rack",
      "cache_list"."c_rack_grp_code" as "c_rack_grp_code",
      "cache_list"."c_stage_code" as "c_stage_code",
      "cache_list"."n_complete" as "n_complete",
      "cache_list"."c_reason" as "c_reason",
      "cache_list"."n_hold_flag" as "n_hold_flag",
      "cache_list"."c_tray_code" as "c_tray_code",
      "cache_list"."c_item_name" as "c_item_name",
      "cache_list"."c_pack_name" as "c_pack_name",
      "cache_list"."c_rack_name" as "c_rack_name",
      "cache_list"."d_exp_dt" as "d_exp_dt",
      "cache_list"."n_mrp" as "n_mrp",
      "cache_list"."c_tray_name" as "c_tray_name",
      "cache_list"."n_qty_per_box" as "n_qty_per_box",
      "cache_list"."c_message" as "c_message",
      "cache_list"."n_inner_pack_lot" as "n_inner_pack_lot"
      from(select "st_track_det"."c_doc_no" as "c_doc_no",
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
          (select "c_name" from "rack_mst" where "c_code" = "st_track_det"."c_rack") as "c_rack_name",
          "isnull"("stock_mst"."d_exp_dt",'') as "d_exp_dt",
          "TRIM"("STR"("TRUNCNUM"("stock_mst"."n_mrp",3),10,3)) as "n_mrp",
          (select "c_name" from "st_tray_mst" where "c_code" = "st_track_det"."c_tray_code") as "c_tray_name",
          "item_mst"."n_qty_per_box" as "n_qty_per_box",
          '' as "c_message",
          "isnull"("n_inner_pack_lot",0) as "n_inner_pack_lot"
          from "st_track_det"
            join "item_mst" on "st_track_det"."c_item_code" = "item_mst"."c_code"
            join "stock" on "stock"."c_item_code" = "st_track_det"."c_item_code"
            and "stock"."c_batch_no" = "st_track_det"."c_batch_no"
            and "stock"."c_br_code" = @BrCode
            join "temp_rack_grp_list" as "user_grp" on "st_track_det"."c_rack_grp_code" = "user_grp"."c_rack_grp_code"
            join "st_track_mst" on "st_track_det"."c_doc_no" = "st_track_mst"."c_doc_no"
            and "st_track_det"."n_inout" = "st_track_mst"."n_inout"
            left outer join "st_track_pick" on "st_track_det"."c_doc_no" = "st_track_pick"."c_doc_no"
            and "st_track_det"."n_inout" = "st_track_pick"."n_inout"
            and "st_track_det"."n_seq" = "st_track_pick"."n_org_seq"
            and "st_track_det"."c_rack_grp_code" = "st_track_pick"."c_rack_grp_code"
            and "st_track_det"."c_stage_code" = "st_track_pick"."c_stage_code"
            and "st_track_det"."c_godown_code" = "st_track_pick"."c_godown_code"
            ,"stock"
            join "stock_mst" on "stock"."c_item_code" = "stock_mst"."c_item_code"
            and "stock"."c_batch_no" = "stock_mst"."c_batch_no"
            ,"item_mst"
            join "pack_mst" on "pack_mst"."c_code" = "item_mst"."c_pack_code"
          where "st_track_det"."n_complete" = 0
          and "st_track_det"."c_godown_code" = @GodownCode
          and "st_track_mst"."n_complete" = 0
          and "st_track_mst"."n_confirm" = 1
          and "st_track_pick"."c_doc_no" is null union
        select "st_track_det"."c_doc_no" as "c_doc_no",
          "st_track_det"."n_inout" as "n_inout",
          "item_mst"."c_code" as "c_item_code",
          '' as "c_batch_no",
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
          (select "c_name" from "rack_mst" where "c_code" = "st_track_det"."c_rack") as "c_rack_name",
          "today"() as "d_exp_dt",
          0 as "n_mrp",
          (select "c_name" from "st_tray_mst" where "c_code" = "st_track_det"."c_tray_code") as "c_tray_name",
          "item_mst"."n_qty_per_box" as "n_qty_per_box",
          '' as "c_message",
          "isnull"("n_inner_pack_lot",0) as "n_inner_pack_lot"
          from "st_track_det"
            join "item_mst" on "st_track_det"."c_item_code" = "item_mst"."c_code"
            join "temp_rack_grp_list" as "user_grp" on "st_track_det"."c_rack_grp_code" = "user_grp"."c_rack_grp_code"
            join "st_track_mst" on "st_track_det"."c_doc_no" = "st_track_mst"."c_doc_no"
            and "st_track_det"."n_inout" = "st_track_mst"."n_inout"
            left outer join "st_track_pick" on "st_track_det"."c_doc_no" = "st_track_pick"."c_doc_no"
            and "st_track_det"."n_inout" = "st_track_pick"."n_inout"
            and "st_track_det"."n_seq" = "st_track_pick"."n_org_seq"
            and "st_track_det"."c_rack_grp_code" = "st_track_pick"."c_rack_grp_code"
            and "st_track_det"."c_stage_code" = "st_track_pick"."c_stage_code"
            and "st_track_det"."c_godown_code" = "st_track_pick"."c_godown_code"
            ,"item_mst"
            join "pack_mst" on "pack_mst"."c_code" = "item_mst"."c_pack_code"
          where "st_track_det"."n_complete" = 0
          and "st_track_det"."c_godown_code" = @GodownCode
          and "st_track_det"."c_batch_no" is null
          and "st_track_mst"."n_complete" = 0
          and "st_track_mst"."n_confirm" = 1
          and "st_track_pick"."c_doc_no" is null) as "cache_list"
      order by "cache_list"."c_doc_no" asc,"cache_list"."c_tray_code" desc,"cache_list"."c_item_name" asc for xml raw,elements
  when 'change_tray' then -----------------------------------------------------------------------
    --@HdrData  : 1 OldTray~2 NewTray
    --1 OldTray
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @OldTray = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --2 NewTray
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @NewTray = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --set @DocNo = @Tranbrcode+'/'+@TranYear+'/'+@TranPrefix+'/'+string(@TranSrno);
    select top 1 "c_doc_no","c_stage_code","count"("a"."c_tray_code")
      into @AssignedDocNo,@AssignedStageCode,@TrayExistsInTrackMove
      from "st_track_det" as "a"
      where "a"."c_tray_code" = @NewTray
      and "a"."n_complete" not in( 2,9,8 ) 
      group by "c_doc_no","c_stage_code";
    if(select "count"("c_code") from "st_tray_mst" where "c_code" = @NewTray) = 0 then
      select 'Warning! : Tray '+@NewTray+' Not Found' as "c_message" for xml raw,elements;
      return
    end if;
    if @TrayExistsInTrackMove > 0 then
      select 'Warning ! : Tray already exists for Document '+@AssignedDocNo+', at stage : '+@AssignedStageCode as "c_message" for xml raw,elements;
      return
    end if;
    select top 1 "c_doc_no"
      into @DocNo from "st_track_tray_move"
      where "c_tray_code" = @OldTray
      and "n_flag" <= 3;
    if @DocNo is null or "trim"(@DocNo) = '' then
      select 'Tray cannot be Changed after barcoding stage !!' as "c_message" for xml raw,elements;
      return
    end if;
    select top 1 "c_doc_no"
      into @tray_move_doc from "st_track_tray_move"
      where "c_tray_code" = @NewTray;
    if @tray_move_doc is not null then
      select 'Tray can not be assigned as it is already in use  for Document '+@DocNo+'!!' as "c_message" for xml raw,elements;
      return
    end if;
    --Need to validate the tray is present in st_track_in with partial assignmnet 
    set @tray_move_doc = '';
    select top 1 "c_doc_no"
      into @tray_move_doc from "St_track_in"
      where "c_tray_code" = @NewTray and "n_confirm" = 1;
    if @tray_move_doc is null or "trim"(@tray_move_doc) = '' then
    else
      select 'Tray can not be assigned as it is already in use for document '+@tray_move_doc as "c_message" for xml raw,elements;
      return
    end if;
    if @enable_log = 1 then
      insert into
        "st_change_tray_log"
        ( "c_doc_no","c_old_tray","c_new_tray","c_stage","c_rg","c_user","t_time" ) values
        ( @DocNo,@OldTray,@NewTray,@StageCode,'',@UserId,"GETDATE"() ) 
    end if;
    update "st_track_det"
      set "c_tray_code" = @NewTray
      where "c_doc_no" = @DocNo
      and "c_tray_code" = @OldTray
      and "c_godown_code" = @GodownCode;
    update "st_track_pick"
      set "c_tray_code" = @NewTray
      where "c_doc_no" = @DocNo
      and "c_tray_code" = @OldTray
      and "c_godown_code" = @GodownCode;
    update "st_track_park"
      set "c_tray_code" = @NewTray
      where "c_doc_no" = @DocNo
      and "c_tray_code" = @OldTray
      and "c_godown_code" = @GodownCode;
    update "st_track_tray_move"
      set "c_tray_code" = @NewTray
      where "c_doc_no" = @DocNo
      and "c_tray_code" = @OldTray
      and "c_godown_code" = @GodownCode;
    if sqlstate = '00000' then
      commit work;
      select 'Success' as "c_message" for xml raw,elements
    else
      rollback work;
      select 'Failure' as "c_message" for xml raw,elements
    end if when 'tray_full_validate' then -----------------------------------------------------------------------
    --@HdrData  : 1 Traycode~2 docno 3@StageCode
    --1 OldTray
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @OldTray = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --2 NewTray
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @DocNo = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --3 NewTray
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @StageCode = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    select "isnull"("count"(),0) as "pick_item_count" from "st_track_pick"
      where "c_doc_no" = @DocNo
      and "c_tray_code" = @OldTray
      and "c_stage_code" = @StageCode for xml raw,elements
  when 'check_login' then
    select "uf_st_check_login"(@BrCode,@RackGrpCode,@UserId,@devID,1) as "c_message" for xml raw,elements;
    return
  when 'reason_mst' then -----------------------------------------------------------------------
    --http://192.168.7.12:14013/ws_st_stock_removal?devID=DEVID&sKEY=KEY&UserId=MYBOSS&PhaseCode=PH0001&RackGrpcode=RG0001**__&StageCode=SS0001&cindex=reason_mst&Hdrdata=
    select "reason_mst"."c_name" as "c_name",
      "reason_mst"."c_code" as "c_code"
      from "reason_mst"
      where "reason_mst"."n_type" in( 0,11 ) for xml raw,elements
  when 'Get_setup' then -----------------------------------------------------------------------
    call "uf_get_module_mst_value_multi"(@HdrData,@ColPos,@ColMaxLen,@ColSep);
    return
  when 'get_batch_list_batch_key' then -----------------------------For Barcode(key) Sacnning------------------------------------------
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
    set @batch_key = "http_variable"('batch_key');
    select top 1
      "stock"."c_item_code",
      "stock"."c_batch_no"
      into @barcode_item_code,@barcode_batch_no
      from "barcode_det" join "stock"
        on("barcode_det"."c_item_code" = "stock"."c_item_code")
        and("barcode_det"."c_batch_no" = "stock"."c_batch_no")
      where("barcode_det"."c_key" = @batch_key)
      and("stock"."n_bal_qty" > 0);
    set @tranExpDays = 0;
    case(@TranPrefix)
    when 'S' then
      set @tranExpDays
         = "isnull"(
        (select "n_sale_exp_days" as "n_sale_exp_days"
          from "item_group_mst"
            join "item_mst" on "item_group_mst"."c_code" = "item_mst"."c_group_code"
          where "item_mst"."c_code" = @barcode_item_code
          and @TranPrefix = 'S'),
        50)
    when 'T' then
      set @tranExpDays
         = "isnull"(
        (select "n_sale_exp_days" as "n_sale_exp_days"
          from "item_group_mst"
            join "item_mst" on "item_group_mst"."c_code" = "item_mst"."c_group_code"
          where "item_mst"."c_code" = @barcode_item_code
          and @TranPrefix = 'T'),
        50)
    when 'N' then
      set @tranExpDays
         = "isnull"(
        (select "n_gdn_exp_days" as "n_gdn_exp_days"
          from "item_group_mst"
            join "item_mst" on "item_group_mst"."c_code" = "item_mst"."c_group_code"
          where "item_mst"."c_code" = @barcode_item_code
          and @TranPrefix = 'N'),
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
            where "item_mst"."c_code" = @barcode_item_code
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
              where "item_mst"."c_code" = @barcode_item_code and @TranPrefix = 'O'),
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
            ("stock"."n_bal_qty"-"stock"."n_hold_qty"-"Isnull"("stock"."n_dc_inv_qty",0))
          else
            if "n_act_stock_qty" < 0 then "n_godown_qty"-"abs"("n_act_stock_qty") else "n_godown_qty" endif
          endif) as "n_stock_qty",
          0 as "n_issue_qty",
          0 as "n_tran_exp_days",
          "isnull"((select "sum"("n_qty"-"n_hold_qty") from "stock_godown" where "c_br_code" = @BrCode and "c_item_code" = "stock"."c_item_code" and "c_batch_no" = "stock"."c_batch_no" and "c_godown_code" = (if @GodownCode = '-' then "c_godown_code" else @GodownCode endif)),0) as "n_godown_qty"
          from "stock"
            join "stock_mst" on "stock"."c_item_code" = "stock_mst"."c_item_code"
            and "stock"."c_batch_no" = "stock_mst"."c_batch_no"
          where "stock"."c_br_code" = @BrCode
          and "stock"."c_item_code" = @barcode_item_code
          and "stock"."c_batch_no" = @barcode_batch_no
          and "stock"."n_bal_qty" > 0
    else --They will remove future expiry items also 
      --and stock_mst.d_exp_dt < uf_default_date()
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
          @tranExpDays as "n_tran_exp_days",
          "isnull"((select "sum"("n_qty"-"n_hold_qty") from "stock_godown" where "c_br_code" = @BrCode and "c_item_code" = "stock"."c_item_code" and "c_batch_no" = "stock"."c_batch_no" and "c_godown_code" = (if @GodownCode = '-' then "c_godown_code" else @GodownCode endif)),0) as "n_godown_qty"
          from "stock"
            join "stock_mst" on "stock"."c_item_code" = "stock_mst"."c_item_code"
            and "stock"."c_batch_no" = "stock_mst"."c_batch_no"
          where "stock"."c_br_code" = @BrCode
          and "stock"."c_item_code" = @barcode_item_code
          and "stock"."c_batch_no" = @barcode_batch_no
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
            left outer join "stock_mst" on "stock_mst"."c_item_code" = "st_track_det"."c_item_code" and "stock_mst"."c_batch_no" = "st_track_det"."c_batch_no"
            and "stock_mst"."c_batch_no" = @barcode_batch_no
            and "ymd"("year"("stock_mst"."d_exp_dt"),"right"('00'+"string"("month"("stock_mst"."d_exp_dt")),2),1) >= "uf_default_date"()
          where "st_track_det"."c_item_code" = @barcode_item_code
          and "st_track_det"."c_batch_no" is not null
          and "st_track_det"."n_hold_flag" = 0
          and "n_issue_qty" > 0
          and "st_track_det"."n_inout" = 0
          and "st_track_det"."n_complete" not in( 1,9 ) 
          and "st_track_det"."c_godown_code" = @GodownCode
    end if;
    ----------------------
    select "batch_list"."c_item_code" as "c_item_code",
      "batch_list"."c_batch_no",
      "max"("batch_list"."n_mrp") as "n_mrp",
      "max"("batch_list"."n_sale_rate") as "n_sale_rate",
      "date"("max"("batch_list"."d_exp_dt")) as "d_exp_dt",
      "TRIM"("STR"("TRUNCNUM"("sum"("batch_list"."n_stock_qty")+"sum"("batch_list"."n_issue_qty"),3),10,0)) as "n_bal_qty",
      "item_mst"."n_qty_per_box" as "n_qty_per_box",
      "TRIM"("STR"("TRUNCNUM"("sum"("batch_list"."n_stock_qty"),3),10,0)) as "n_eg_stock"
      from "batch_list"
        join "item_mst" on "item_mst"."c_code" = "batch_list"."c_item_code"
      group by "batch_list"."c_batch_no","n_qty_per_box","batch_list"."c_item_code"
      having "n_bal_qty" > 0
      order by 4 asc for xml raw,elements
  when 'get_rack_list' then
    select "rack_mst"."c_code" as "rack",
      "st_store_stage_mst"."c_code" as "stage_code",
      "st_store_stage_det"."c_rack_grp_code" as "rack_group_code",
      "st_store_stage_grp_mst"."c_name" as "stage_name"
      from "st_store_stage_mst" join "st_store_stage_det"
        on "st_store_stage_mst"."c_br_code" = "st_store_stage_det"."c_br_code"
        and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
        join "st_store_stage_grp_mst" on "st_store_stage_mst"."c_stage_grp_code" = "st_store_stage_grp_mst"."c_code"
        join "rack_mst" on "st_store_stage_det"."c_br_code" = "rack_mst"."c_br_code"
        and "st_store_stage_det"."c_rack_grp_code" = "rack_mst"."c_rack_grp_code"
      order by 1 asc for xml raw,elements
  when 'batch_reason' then -----------------------------------------------------------------------
    --http://192.168.7.12:14013/ws_st_stock_removal?devID=DEVID&sKEY=KEY&UserId=MYBOSS&PhaseCode=PH0001&RackGrpcode=RG0001**__&StageCode=SS0001&cindex=reason_mst&Hdrdata=
    select "reason_mst"."c_name" as "c_name",
      "reason_mst"."c_code" as "c_code"
      from "reason_mst"
      where "reason_mst"."n_type" in( 13 ) for xml raw,elements
  when 'itemwise_doc_done' then -----------------------------------------------------------------------
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
    --print +'ranjan'+@DetData;
    set @DocNo = @Tranbrcode+'/'+@TranYear+'/'+@TranPrefix+'/'+"string"(@TranSrno);
    if @DetData = '' and @nTrayFull = 1 and @CurrentTray <> '-nulltray-' then
      --second RACK GRP USER in the sequence if clicks on tray full validate if no items in tray 
      --if item_count in tray = 0 then error 
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
    --EXTRACT USER SELECTED RACK GROUPS			
    --set @RackGrpList = @RackGrpCode; --shifted above
    while @RackGrpList <> '' loop
      select "Locate"(@RackGrpList,@ColSep) into @ColPos;
      set @tmp = "Trim"("Left"(@RackGrpList,@ColPos-1));
      set @RackGrpList = "SubString"(@RackGrpList,@ColPos+@ColMaxLen);
      if(select "COUNT"("C_CODE") from "RACK_GROUP_MST" where "C_CODE" = @tmp) > 0 then --valid rack group selection 
        select "n_pos_seq" into @Seq from "st_store_stage_det" where "c_rack_grp_code" = @tmp;
        insert into "temp_rack_grp_list"( "c_rack_grp_code","c_stage_code","n_seq" ) values( @tmp,@StageCode,@Seq ) 
      end if
    end loop;
    while @DetData <> '' and @ItemsInDetail = 1 loop
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
      set @DetData = "SubString"(@DetData,@RowPos+@RowMaxLen)
    end loop;
    if @ItemNotFound = 0 then
      insert into "st_track_itemwise_pick"
        ( "c_doc_no","n_inout","n_seq","n_org_seq","c_item_code","c_batch_no","n_qty","n_hold_flag","c_reason_code","c_note","c_user","t_time","c_tray_code","c_device_id",
        "c_rack","c_rack_grp_code","c_stage_code",
        "c_godown_code" ) on existing update defaults off values
        ( @DocNo,@InOutFlag,@Seq,@OrgSeq,@ItemCode,@BatchNo,@Qty,@HoldFlag,@cReason,@cNote,@UserId,@t_pick_time,
        @CurrentTray,@devID,@RackCode,@CurrentGrp,@StageCode,@GodownCode ) 
    end if;
    select 'Success' as "c_message",@maxSeq as "n_max_seq" for xml raw,elements
  --   PRINT  11;
  --  print 'park_tray_Index_Started';  
  -- @t_pick_time_new                  new variable
  when 'park_tray' then
    while @RackGrpList <> '' loop
      select "Locate"(@RackGrpList,@ColSep) into @ColPos;
      set @tmp = "Trim"("Left"(@RackGrpList,@ColPos-1));
      set @RackGrpList = "SubString"(@RackGrpList,@ColPos+@ColMaxLen);
      if(select "COUNT"("C_CODE") from "RACK_GROUP_MST" where "C_CODE" = @tmp) > 0 then --valid rack group selection 
        select "n_pos_seq" into @Seq from "st_store_stage_det" where "c_rack_grp_code" = @tmp;
        insert into "temp_rack_grp_list"( "c_rack_grp_code","c_stage_code","n_seq" ) values( @tmp,@StageCode,@Seq ) 
      --MDY';
      end if
    end loop;
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
    --10 p_reason
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @p_reason = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --10 p_note
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @p_note = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    set @DocNo = @Tranbrcode+'/'+@TranYear+'/'+@TranPrefix+'/'+"string"(@TranSrno);
    if(select "count"("c_doc_no") from "st_track_park" where "c_doc_no" = @DocNo and "c_tray_code" = @CurrentTray) > 0 then
      delete from "st_track_park" where "c_doc_no" = @DocNo and "c_tray_code" = @CurrentTray
    end if;
    while @DetData <> '' and @ItemsInDetail = 1 loop
      -- DocNo		
      --1 InOutFlag
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @InOutFlag = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      print @InOutFlag;
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
      --   select 'Success Batch No' as "c_message",@DetData as "n_max_seq" for xml raw,elements;
      --    return ;
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @BatchNo = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --6 d_exp_dt 
      //#300 error track
      --select 'Success' as "c_message",@DetData as "n_max_seq" for xml raw,elements;
      --return ;
      -- added new code for handling null value of d_exp_dt
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @d_exp_dt = "Trim"("Left"(@DetData,@ColPos-1));
      --select 'exp_dt Success' as "c_message",@d_exp_dt  as "exp_dt without null with value" for xml raw,elements;
      --    return ;
      -- added new code for exp_dt null value
      if @d_exp_dt is null or @d_exp_dt = '' or @d_exp_dt = 'null' then
        set @d_exp_dt = '9999-12-31'
      end if;
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --7 Qty
      --    select 'Success' as "c_message",@DetData as "n_max_seq" for xml raw,elements;
      --     return ;
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @Qty = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --8 HoldFlag
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @HoldFlag = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --9 cReason
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @cReason = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --10 cNote
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @cNote = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --11 CurrentTray
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @CurrentTray = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --12 br_RackCode
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @c_br_rack = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --13 RackCode
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @RackCode = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --14 CurrentGrp
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @CurrentGrp = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --15 ItemNotFound
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @ItemNotFound = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --16 t_pick_time
      -- select 'Success pick time start' as "c_message",@DetData as "n_max_seq" for xml raw,elements;
      --   return ;
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @t_pick_time = "Trim"("Left"(@DetData,@ColPos-1)); -- original code
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      if "trim"(@t_pick_time) = '' or @t_pick_time is null then -- original code
        set @t_pick_time = "left"("now"(),19) -- original code
      end if;
      //if "trim"(@t_pick_time_new) = '' or @t_pick_time_new is null then
      // set @t_pick_time_new = "left"("now"(),19)
      //end if;
      //set @t_pick_time_new =now();
      select "n_qty_per_box" into @n_qty_per_box from "item_mst" where "c_code" = @ItemCode;
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @n_park_flag = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --select 'Success pick time end' as "c_message",@DetData as "n_max_seq" for xml raw,elements;
      --   return ;
      //IF @n_park_flag = 0 THEN
      //     set @Qty = @n_qty_per_box*@Qty;
      // ENDIF ;
      select "Locate"(@DetData,@RowSep) into @RowPos;
      set @DetData = "SubString"(@DetData,@RowPos+@RowMaxLen);
      select "c_patient" into @c_patient from "ord_mst" where "c_br_code" = @Tranbrcode
        and "c_prefix" = @TranPrefix
        and "c_year" = @TranYear
        and "n_srno" = @TranSrno;
      --  select 'Success pick time end' as "c_message",@DetData as "n_max_seq" for xml raw,elements;
      -- return ;
      insert into "st_track_park"
        ( "c_doc_no","n_inout","n_seq","n_org_seq","c_item_code","c_batch_no","n_qty","n_hold_flag","c_reason_code","c_note","c_user",
        "c_tray_code","c_device_id","c_rack","c_rack_grp_code","c_stage_code","c_godown_code","n_park_flag","d_ldate","t_ltime",
        "c_br_rack","d_exp_dt","c_patient" ) on existing update defaults off values
        ( @DocNo,@InOutFlag,@Seq,@OrgSeq,@ItemCode,@BatchNo,@Qty,@HoldFlag,@cReason,@cNote,@UserId,
        @CurrentTray,@devID,@RackCode,@CurrentGrp,@StageCode,@GodownCode,@n_park_flag,"today"(),"now"(),@c_br_rack,@d_exp_dt,@c_patient ) 
    end loop;
    -- error line
    --select 'Success pick time error' as "c_message",@DetData as "n_max_seq" for xml raw,elements;
    --   return ;
    select "c_br_code","c_year","c_prefix","n_sr_number"
      into @s_br_code,@s_year,@s_prefix,@s_srno
      from "prefix_serial_no" where "c_trans" = 'MESG' and "c_year" = "right"("db_name"(''),2) and "c_br_code" = "uf_get_br_code"('000');
    set @s_srno = @s_srno+1;
    insert into "DBA"."message_mst"( "c_br_code","c_year","c_prefix","n_srno","d_date",
      "c_from_user","c_to_user","c_doc_no","c_tray_code","c_item_code",
      "c_rack","c_rack_grp_code","c_stage_code","c_godown_code","c_message",
      "n_status","c_update_user","t_time","n_cancel_flag","d_ldate",
      "t_ltime","n_urgent","c_device_id","c_sys_ip" ) on existing update defaults off values
      ( @s_br_code,@s_year,@s_prefix,@s_srno,"today"(),
      @UserId,null,@DocNo,@CurrentTray,'-',
      @RackCode,@CurrentGrp,@StageCode,@GodownCode,'Tray Parked: Tray Code: '+@CurrentTray+' parked in rack group: '+@CurrentGrp+' by user: '+@UserId+'.',
      0,@UserId,
      "substr"("now"(),"charindex"(' ',"now"())+1),
      0,"today"(),"now"(),
      0,@devID,'-' ) ;
    if sqlstate = '00000' then
      commit work;
      update "st_track_tray_move" set "st_track_tray_move"."c_reason_code" = @p_reason,"st_track_tray_move"."c_note" = @p_note,
        "st_track_tray_move"."n_park_flag" = 1,"c_user_2" = @UserId
        where "st_track_tray_move"."c_doc_no" = @DocNo
        and "st_track_tray_move"."n_inout" = @InOutFlag
        and "st_track_tray_move"."c_tray_code" = @CurrentTray
        and "st_track_tray_move"."c_rack_grp_code" = @CurrentGrp
        and "st_track_tray_move"."c_stage_code" = @StageCode
        and "st_track_tray_move"."c_godown_code" = @GodownCode;
      select 1 as "n_status",'Success' as "c_message" for xml raw,elements
    else
      rollback work;
      select 0 as "n_status",'Failure' as "c_message" for xml raw,elements
    end if when 'get_park_doc_list' then
    set @RackGrpList = @RackGrpCode;
    while @RackGrpList <> '' loop
      select "Locate"(@RackGrpList,@ColSep) into @ColPos;
      set @tmp = "Trim"("Left"(@RackGrpList,@ColPos-1));
      set @RackGrpList = "SubString"(@RackGrpList,@ColPos+@ColMaxLen);
      if(select "COUNT"("C_CODE") from "RACK_GROUP_MST" where "C_CODE" = @tmp) > 0 then --valid rack group selection 
        select "n_pos_seq" into @Seq from "st_store_stage_det" where "c_rack_grp_code" = @tmp;
        insert into "temp_rack_grp_list"( "c_rack_grp_code","c_stage_code","n_seq" ) values( @tmp,@StageCode,@Seq ) 
      --select CONVERT (TIMESTAMP ,"t_time") into @st_track_tray_move_t_time from st_track_tray_move;
      end if
    end loop;
    select "st_track_park"."c_doc_no",
      "st_track_park"."c_tray_code",
      "st_track_tray_move"."t_time",
      --    @st_track_tray_move_t_time,
      "count"("c_item_code") as "n_item_count",
      if "len"("trim"("isnull"("st_track_mst"."c_order_id",''))) <> 0 then
        0
      else
        1
      endif as "n_allow_not_found"
      from "st_track_park"
        join "st_track_mst" on "st_track_mst"."c_doc_no" = "st_track_park"."c_doc_no" and "st_track_park"."n_inout" = "st_track_mst"."n_inout"
        join "st_track_tray_move" on "st_track_tray_move"."c_doc_no" = "st_track_park"."c_doc_no"
        and "st_track_tray_move"."n_inout" = "st_track_park"."n_inout"
        and "st_track_tray_move"."c_tray_code" = "st_track_park"."c_tray_code"
        and "st_track_tray_move"."c_rack_grp_code" = "st_track_park"."c_rack_grp_code"
        and "st_track_tray_move"."c_stage_code" = "st_track_park"."c_stage_code"
        and "st_track_tray_move"."c_godown_code" = "st_track_park"."c_godown_code"
        join "temp_rack_grp_list" on "st_track_park"."c_rack_grp_code" = "temp_rack_grp_list"."c_rack_grp_code"
      where "st_track_tray_move"."n_park_flag" = 1 and "st_track_tray_move"."c_stage_code" = @stagecode
      group by "st_track_park"."c_doc_no","st_track_park"."c_tray_code","st_track_tray_move"."t_time","st_track_mst"."c_order_id"
      order by "st_track_tray_move"."t_time" desc for xml raw,elements
  when 'get_park_doc_item_list' then
    set @RackGrpList = @RackGrpCode;
    while @RackGrpList <> '' loop
      select "Locate"(@RackGrpList,@ColSep) into @ColPos;
      set @tmp = "Trim"("Left"(@RackGrpList,@ColPos-1));
      set @RackGrpList = "SubString"(@RackGrpList,@ColPos+@ColMaxLen);
      if(select "COUNT"("C_CODE") from "RACK_GROUP_MST" where "C_CODE" = @tmp) > 0 then --valid rack group selection 
        select "n_pos_seq" into @Seq from "st_store_stage_det" where "c_rack_grp_code" = @tmp;
        insert into "temp_rack_grp_list"( "c_rack_grp_code","c_stage_code","n_seq" ) values( @tmp,@StageCode,@Seq ) 
      --1 InOutFlag
      end if
    end loop;
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @InOutFlag = "Trim"("Left"(@HdrData,@ColPos-1));
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
    set @DocNo = @Tranbrcode+'/'+@TranYear+'/'+@TranPrefix+'/'+"string"(@TranSrno);
    select "st_track_park"."c_doc_no",
      "st_track_park"."n_inout",
      "st_track_park"."n_seq",
      "st_track_park"."n_org_seq",
      "st_track_park"."c_item_code",
      "item_mst"."c_name" as "c_item_name",
      "st_track_park"."c_batch_no",
      "st_track_park"."d_exp_dt",
      "TRIM"("STR"("TRUNCNUM"("st_track_park"."n_qty",3),10,0)) as "n_qty",
      "TRIM"("STR"("TRUNCNUM"("st_track_park"."n_qty",3),10,0)) as "n_bal_qty",
      "st_track_park"."n_hold_flag",
      "st_track_park"."c_reason_code" as "c_reason",
      "st_track_park"."c_note",
      "st_track_park"."c_user",
      "st_track_park"."t_time",
      "st_track_park"."c_tray_code",
      "st_track_park"."c_device_id",
      "st_track_park"."c_rack",
      "rack_mst"."c_name" as "c_rack_name",
      "st_track_park"."c_rack_grp_code",
      "st_track_park"."c_stage_code",
      "st_track_park"."c_godown_code",
      "st_track_park"."n_park_flag",
      "st_track_park"."d_ldate",
      "st_track_park"."t_ltime",
      "item_mst"."c_mfac_code" as "c_mfac_code",
      "mfac_mst"."c_name" as "mfac_name",
      "item_mst"."n_inner_pack_lot" as "n_inner_pack_lot",
      "item_mst"."n_qty_per_box" as "n_qty_per_box",
      "stock_mst"."n_mrp" as "n_mrp",
      "pack_mst"."c_name" as "c_pack_name",
      "st_track_park"."c_br_rack" as "c_br_rack",
      0 as "n_error_mark",
      '' as "c_alert_msg",
      '' as "c_message",
      if "len"("trim"("isnull"("st_track_mst"."c_order_id",''))) <> 0 then
        0
      else
        1
      endif as "n_allow_not_found"
      from "st_track_park"
        join "st_track_mst" on "st_track_mst"."c_doc_no" = "st_track_park"."c_doc_no" and "st_track_park"."n_inout" = "st_track_mst"."n_inout"
        join "item_mst" on "item_mst"."c_code" = "st_track_park"."c_item_code"
        join "mfac_mst" on "mfac_mst"."c_code" = "item_mst"."c_mfac_code"
        join "rack_mst" on "rack_mst"."c_code" = "st_track_park"."c_rack" and "rack_mst"."c_br_code" = @BrCode
        join "pack_mst" on "pack_mst"."c_code" = "item_mst"."c_pack_code"
        left outer join "stock_mst" on "stock_mst"."c_item_code" = "st_track_park"."c_item_code" and "stock_mst"."c_batch_no" = "st_track_park"."c_batch_no"
        left outer join "temp_rack_grp_list" on "st_track_park"."c_rack_grp_code" = "temp_rack_grp_list"."c_rack_grp_code"
      where "st_track_park"."c_doc_no" = @DocNo
      and "st_track_park"."c_tray_code" = @CurrentTray
      and "st_track_park"."c_stage_code" = @StageCode
      order by "st_track_park"."t_ltime" desc for xml raw,elements
  when 'get_park_reason' then
    select "c_code","c_name"
      from "reason_mst" where "n_type" = 15 order by "c_name" asc for xml raw,elements
  end case
end;