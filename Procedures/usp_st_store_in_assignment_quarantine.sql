CREATE PROCEDURE "DBA"."usp_st_store_in_assignment_quarantine"( 
  ------------------------------------------------------------------------------------------------------------------------------------
  in @gsBr char(6),
  in @devID char(200),
  in @sKey char(20),
  in @UserId char(20),
  in @PhaseCode char(6),
  in @StageCode char(6),
  in @RackGrpCode char(300),
  in @cIndex char(30),
  in @HdrData char(32767),
  in @DetData char(32767),
  in @DocNo char(25),
  in @GodownCode char(6) ) 
result( "is_xml_string" xml ) 
begin
  /*
Author 		:  Saneesh C G
Procedure	: usp_st_store_in_assignment_quarantine
SERVICE		: ws_st_store_in_assignment_quarantine
Date 		: 08-03-2017
--------------------------------------------------------------------------------------------------------------------------------
Modified By                 Ldate               Index                       Changes
--------------------------------------------------------------------------------------------------------------------------------
Pratheesh P                11-01-2021           get_doc_list               C23613  DAYS COLUMN IN EXPIRY AND INWARD ASSIGNMENT EXPIRY
Pratheesh P                20-01-2021           get_doc_list               C23613  DAYS COLUMN IN EXPIRY AND INWARD ASSIGNMENT EXPIRY - changed to days count
--------------------------------------------------------------------------------------------------------------------------------
*/
  --common >>
  declare @BrCode char(6);
  declare @t_ltime char(25);
  declare @d_ldate char(20);
  declare @nUserValid integer;
  declare @RackGrpList char(7000);
  declare @ColSep char(6);
  declare @RowSep char(6);
  declare @Pos integer;
  declare @ColPos integer;
  declare @RowPos integer;
  declare @ColMaxLen numeric(4);
  declare @RowMaxLen numeric(4);
  declare @RetStr char(100);
  --get_items >>
  declare @UnprocessedTray char(6);
  declare @UnprocessedDoc char(15);
  declare @cDocAlreadyAssignedToUser char(20);
  declare @cTrayAssigned char(6);
  declare @CurrentTray char(6);
  declare @Reason_code char(6);
  --get_items <<
  --item_done>>
  declare @ForwardFlag integer;
  declare @InOutFlag integer;
  declare @ItemCode char(6);
  declare @PickedQty numeric(12);
  declare @ReasonCode char(6);
  declare @RemainingQty numeric(12);
  declare @li_pos numeric(12);
  declare @Qtp numeric(12);
  declare @storein_tray_code char(6);
  declare @BatchNo char(15);
  --item_done<<
  --get_tray_list>>
  declare @SuppCode char(6);
  declare @n_exp_ret_flag numeric(1);
  declare @c_exp_ret_SuppCode char(6);
  declare @c_MfacCode char(6);
  declare @c_item_code char(6);
  --get_tray_list<<
  declare @validate_mode numeric(1);
  declare @new_tary_flag numeric(1);
  declare @cnt numeric(10);
  declare @new_tray_code char(15);
  declare @tray_assigned_doc_no char(25);
  declare @allocated_to char(15);
  declare @suppname char(100);
  --get_tray_list>>
  --documnet_done>>
  declare @nextRackGrp char(20);
  declare @maxRackGrp char(20);
  declare @nDocItemCount integer;
  declare @nDocItemNotFoundCount integer;
  declare @ItemsInDetail integer;
  declare @DetSuccessFlag integer;
  declare @OrgSeq integer;
  declare @Seq integer;
  declare @Qty numeric(12);
  declare @HoldFlag integer;
  declare @cReason char(6);
  declare @cNote char(40);
  declare @RackCode char(6);
  declare @CurrentGrp char(6);
  declare @ItemSuppCode char(6);
  declare @Godown_Tray_Code char(6);
  declare @ItemNotFound integer;
  declare @maxSeq integer;
  declare @nItemsInStage integer;
  declare @cStinRefNo char(25);
  declare @RefSep char(5);
  declare @ColMaxLenRef numeric(4);
  declare @TranSeq numeric(6);
  declare @Trandocno char(25);
  declare @TranBrCode char(6);
  declare @TranPrefix char(4);
  declare @TranYear char(2);
  declare @TranSrno numeric(6);
  declare @s_pick_user char(10);
  --documnet_done<<
  --USER  
  declare @c_confirm_user char(25);
  --shift_tarys>>
  declare @flag_val numeric(1);
  declare @OldTrayCode char(6);
  declare @TrayCode char(6);
  declare @NewTrayCode char(6);
  declare @genDocNo char(50);
  declare @old_genDocNo char(50);
  declare @godown_code char(50);
  declare @li_ext_tray_cnt numeric(9);
  declare @li_temp_tray_cnt numeric(9);
  declare @ls_doc_no char(50);
  declare @show_exp_date numeric(1);
  --shift_tarys<<
  declare @DocList char(32767);
  declare local temporary table "doc_list"(
    "c_doc_no" char(50) null,
    "c_user" char(20) null,) on commit delete rows;
  declare local temporary table "temp_st_track_det"(
    "c_doc_no" char(50) not null,
    "n_inout" numeric(1) not null,
    "c_item_code" char(6) not null,
    "c_batch_no" char(15) null,
    "n_seq" numeric(4) not null default 0,
    "n_qty" numeric(11,3) not null,
    "n_bal_qty" numeric(11,3) not null,
    "c_note" char(40) null,
    "c_rack" char(6) null,
    "c_rack_grp_code" char(6) null,
    "c_stage_code" char(6) null,
    "n_complete" numeric(1) not null default 0,
    "c_reason_code" char(6) not null default 0,
    "n_hold_flag" numeric(1) not null,
    "c_tray_code" char(6) null,
    "c_user" char(20) null,
    "c_godown_code" char(6) null default '-',
    "c_stin_ref_no" char(25) null,
    "c_user_2" char(10) null,
    "t_time" timestamp null,) on commit delete rows;
  declare local temporary table "temp_st_track_mst"(
    "c_br_code" char(6) null,
    "c_doc_no" char(50) not null,
    "n_inout" numeric(1) not null,
    "c_phase_code" char(6) not null,
    "c_cust_code" char(6) null,
    "d_date" date null,
    "c_user" char(20) null,
    "c_system_name" char(100) null,
    "c_system_ip" char(30) null,
    "t_time_in" timestamp null,
    "t_time_out" timestamp null,
    "n_complete" numeric(1) null,
    "n_confirm" numeric(1) null default 0,
    "n_urgent" numeric(4) null default 0,
    "c_sort" char(20) null default 0,
    "c_user_2" char(10) null,) on commit delete rows;
  declare @nAllDoc numeric(1);
  declare @tmp char(50);
  declare @inward_loop integer;
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
    set @DocNo = "http_variable"('DocNo'); --11
    set @GodownCode = "http_variable"('GodownCode'); --12		
    set @TrayCode = "HTTP_VARIABLE"('TrayCode')
  end if;
  select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
  select "c_delim" into @RowSep from "ps_tab_delimiter" where "n_seq" = 1;
  if @ColSep is null or @ColSep = '' then
    select '--------------------\x0D\x0ASQL error: usp_st_storein_quarantine  No Delimiter Defined';
    return
  end if;
  set @ColMaxLen = "Length"(@ColSep);
  set @RowMaxLen = "Length"(@RowSep);
  set @BrCode = "uf_get_br_code"(@gsBr);
  set @t_ltime = "left"("now"(),19);
  set @d_ldate = "uf_default_date"();
  case @cIndex
  when 'get_godown_code' then -----------------------------------------------------------------------
    --http://172.16.18.38:16503/ws_st_store_in_assignment_quarantine?&cIndex=get_godown_code&GodownCode=&gsbr=503&devID=3ee1041c3d57c46c23022017115840450&sKEY=sKey&UserId=MYBOSS
    select "max"("c_godown_code") as "c_godown_code" from "storein_setup" where "c_br_code" = @BrCode for xml raw,elements
  when 'get_doc_list' then -----------------------------------------------------------------------
    --http://172.16.18.38:16503/ws_st_store_in_assignment_quarantine?&cIndex=get_doc_list&GodownCode=5033&gsbr=503&devID=3ee1041c3d57c46c23022017115840450&sKEY=sKey&UserId=MYBOSS
    select "n_active" into @show_exp_date from "st_track_module_mst" where "c_code" = 'M00125';
    set @show_exp_date = "isnull"(@show_exp_date,0);
    select "c_doc_no",
      "count"("st_track_in"."c_item_code") as "n_item_count",
      "list"(distinct "st_track_in"."c_user") as "c_user_list",
      "sum"(if "st_track_in"."c_tray_code" is null then 0 else 1 endif) as "n_assigned_count",
      "isnull"("pur_mst"."c_bill_no","isnull"("string"("grn_mst"."n_ref_srno"),"crnt_mst"."c_ref_no")) as "c_bill_no",
      "isnull"("prefix_srno"."c_trans","prefix_serial_no"."c_trans") as "c_trans",if @show_exp_date = 0 then null else "datediff"("dd",cast("st_track_in"."t_time" as date),"now"()) endif as "expirydate"
      from "st_track_in"
        left outer join "pur_mst" on "pur_mst"."c_br_code" = "left"(("st_track_in"."c_doc_no"),"charindex"('/',("st_track_in"."c_doc_no"))-1)
        and "pur_mst"."c_year" = "left"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))-1)
        and "pur_mst"."c_prefix" = "left"("substr"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))+1),"charindex"('/',"substr"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))+1))-1)
        and "pur_mst"."n_srno" = "reverse"("left"("reverse"("st_track_in"."c_doc_no"),"charindex"('/',("reverse"("st_track_in"."c_doc_no")))-1))
        and "pur_mst"."n_post" = 1
        left outer join "grn_mst" on "grn_mst"."c_br_code" = "left"(("st_track_in"."c_doc_no"),"charindex"('/',("st_track_in"."c_doc_no"))-1)
        and "grn_mst"."c_year" = "left"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))-1)
        and "grn_mst"."c_prefix" = "left"("substr"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))+1),"charindex"('/',"substr"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))+1))-1)
        and "grn_mst"."n_srno" = "reverse"("left"("reverse"("st_track_in"."c_doc_no"),"charindex"('/',("reverse"("st_track_in"."c_doc_no")))-1))
        and "grn_mst"."n_post" = 1
        left outer join "crnt_mst" on "crnt_mst"."c_br_code" = "left"(("st_track_in"."c_doc_no"),"charindex"('/',("st_track_in"."c_doc_no"))-1)
        and "crnt_mst"."c_year" = "left"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))-1)
        and "crnt_mst"."c_prefix" = "left"("substr"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))+1),"charindex"('/',"substr"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))+1))-1)
        and "crnt_mst"."n_srno" = "reverse"("left"("reverse"("st_track_in"."c_doc_no"),"charindex"('/',("reverse"("st_track_in"."c_doc_no")))-1))
        left outer join "godown_tran_mst" on "godown_tran_mst"."c_br_code" = "left"(("st_track_in"."c_doc_no"),"charindex"('/',("st_track_in"."c_doc_no"))-1)
        and "godown_tran_mst"."c_year" = "left"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))-1)
        and "godown_tran_mst"."c_prefix" = "left"("substr"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))+1),"charindex"('/',"substr"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))+1))-1)
        and "godown_tran_mst"."n_srno" = "reverse"("left"("reverse"("st_track_in"."c_doc_no"),"charindex"('/',("reverse"("st_track_in"."c_doc_no")))-1))
        and "godown_tran_mst"."n_approved" = 1
        left outer join "dbnt_mst" on "dbnt_mst"."c_br_code" = "left"(("st_track_in"."c_doc_no"),"charindex"('/',("st_track_in"."c_doc_no"))-1)
        and "dbnt_mst"."c_year" = "left"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))-1)
        and "dbnt_mst"."c_prefix" = "left"("substr"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))+1),"charindex"('/',"substr"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))+1))-1)
        and "dbnt_mst"."n_srno" = "reverse"("left"("reverse"("st_track_in"."c_doc_no"),"charindex"('/',("reverse"("st_track_in"."c_doc_no")))-1))
        and "dbnt_mst"."n_approved" = 1
        left outer join "prefix_srno" on "prefix_srno"."c_br_code" = "left"(("st_track_in"."c_doc_no"),"charindex"('/',("st_track_in"."c_doc_no"))-1)
        and "prefix_srno"."c_year" = "left"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))-1)
        and "prefix_srno"."c_prefix" = "left"("substr"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))+1),"charindex"('/',"substr"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))+1))-1)
        left outer join "prefix_serial_no" on "prefix_serial_no"."c_br_code" = "left"(("st_track_in"."c_doc_no"),"charindex"('/',("st_track_in"."c_doc_no"))-1)
        and "prefix_serial_no"."c_year" = "left"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))-1)
        and "prefix_serial_no"."c_prefix" = "left"("substr"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))+1),"charindex"('/',"substr"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))+1))-1)
        left outer join "stock_mst" on "stock_mst"."c_item_code" = "st_track_in"."c_item_code" and "stock_mst"."c_batch_no" = "st_track_in"."c_batch_no"
      where "n_complete" <> 9 and "n_qty"-"n_send_qty" > 0 and "st_track_in"."c_godown_code" = @GodownCode
      group by "c_doc_no","c_bill_no","c_trans","expirydate"
      order by "n_assigned_count" asc,"n_item_count"/(if "n_assigned_count" = 0 then 1 else "n_assigned_count" endif) desc for xml raw,elements
  when 'get_items' then -----------------------------------------------------------------------
    --http://172.16.18.38:16503/ws_st_store_in_assignment_quarantine?&cIndex=get_items&DocList=503/16/160/59775^^503/16/G/16273^^&GodownCode=5033&gsbr=503&devID=3ee1041c3d57c46c23022017115840450&sKEY=sKey&UserId=MYBOSS
    set @DocList = "HTTP_VARIABLE"('DocList');
    if "length"("isnull"(@DocList,'')) < 10 then
      set @nAllDoc = 1
    else
      set @nAllDoc = 0;
      --execute immediate with result set on 'insert into doc_list select distinct c_doc_no,c_user From st_track_in where c_doc_no in ('+@DocList+')' 
      while @DocList <> '' loop
        --1 RackGrpList
        select "Locate"(@DocList,@ColSep) into @ColPos;
        set @tmp = "Trim"("Left"(@DocList,@ColPos-1));
        set @DocList = "SubString"(@DocList,@ColPos+@ColMaxLen);
        insert into "doc_list"( "c_doc_no","c_user" ) values( @tmp,@UserId ) ;
        update "st_track_in" set "c_user" = @UserId where "c_doc_no" = @tmp
      end loop
    end if;
    --Select  c_doc_no as a  from doc_list for xml raw,elements ;
    --return;
    select "c_doc_no" as "c_doc_no",
      "n_seq" as "n_seq",
      "st_track_in"."c_item_code" as "c_item_code",
      "st_track_in"."c_batch_no" as "c_batch_no",
      "trim"("str"("truncnum"("n_qty",3),10,0)) as "n_qty",
      "c_tray_code" as "c_tray_code",
      "n_complete" as "n_complete",
      "st_track_in"."c_godown_code",
      (if "isnull"("st_track_in"."c_godown_code",'-') = '-' then "item_mst_br_info"."c_rack" else "item_mst_br_info_godown"."c_rack" endif) as "c_rack_code",
      "rack_group_mst"."c_code" as "c_rack_grp_code",
      "c_user",
      (select "max"("c_stage_code") from "st_store_stage_det" where "c_rack_grp_code" = "st_track_in"."c_rack_grp_code") as "c_stage_code",
      "item_mst"."c_name"+"uf_st_get_pack_name"("pack_mst"."c_name") as "c_item_name",
      "item_mst"."n_qty_per_box" as "n_qty_per_box",
      "stock_mst"."d_exp_dt",
      "stock_mst"."n_mrp",
      (select "c_name" from "godown_mst" where "c_code" = "st_track_in"."c_godown_code") as "c_godown_name",
      '' as "c_message",
      "trans"."c_bill_no",
      (select "list"(distinct "item_bin_info"."c_bin_code")+'-'+"list"(distinct "item_bin_info"."c_tray_code")+'-'+"list"(distinct "item_bin_info"."n_carton_no")
        from "item_bin_info"
        where "item_bin_info"."n_gate_pass_no" = "trans"."n_gate_pass_no"
        and "item_bin_info"."c_item_code" = "st_track_in"."c_item_code"
        and "item_bin_info"."c_batch_no" = "st_track_in"."c_batch_no") as "c_bin_code",
      "n_confirm" as "n_picked_flag",
      (if "item_mst"."n_non_returnable_item" > 0 then 1 else 0 endif) as "non_returnable_item_flag"
      from "st_track_in"
        left outer join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = ("left"("st_track_in"."c_doc_no","locate"("st_track_in"."c_doc_no",'/')-1))
        and "item_mst_br_info"."c_code" = "st_track_in"."c_item_code"
        left outer join "item_mst_br_info_godown" on "item_mst_br_info_godown"."c_br_code" = ("left"("st_track_in"."c_doc_no","locate"("st_track_in"."c_doc_no",'/')-1))
        and "item_mst_br_info_godown"."c_code" = "st_track_in"."c_item_code"
        and "item_mst_br_info_godown"."c_godown_code" = "isnull"("st_track_in"."c_godown_code",'-')
        left outer join "rack_mst" on "rack_mst"."c_br_code" = "left"("st_track_in"."c_doc_no",3)
        and "rack_mst"."c_code" = "c_rack_code"
        left outer join "rack_group_mst" on "rack_mst"."c_br_code" = "rack_group_mst"."c_br_code"
        and "rack_mst"."c_rack_grp_code" = "rack_group_mst"."c_code"
        join "item_mst" on "st_track_in"."c_item_code" = "item_mst"."c_code"
        join "pack_mst" on "pack_mst"."c_code" = "item_mst"."c_pack_code"
        join "stock_mst" on "st_track_in"."c_item_code" = "stock_mst"."c_item_code" and "st_track_in"."c_batch_no" = "stock_mst"."c_batch_no"
        join(select "c_br_code","c_year","c_prefix","n_srno","c_bill_no","n_gate_pass_no" from "pur_mst" where "n_post" = 1 union
        select "c_br_code","c_year","c_prefix","n_srno","string"("n_ref_srno"),0 as "n_gate_pass_no" from "grn_mst" where "n_post" = 1 union
        select "c_br_code","c_year","c_prefix","n_srno","c_ref_no",0 as "n_gate_pass_no" from "crnt_mst" union
        select "c_br_code","c_year","c_prefix","n_srno",'',0 as "n_gate_pass_no" from "godown_tran_mst" where "godown_tran_mst"."n_approved" = 1 union
        select "c_br_code","c_year","c_prefix","n_srno",'' as "c_ref_no",0 as "n_gate_pass_no" from "dbnt_mst" where "dbnt_mst"."n_approved" = 1) as "trans"
        on "trans"."c_br_code" = "left"(("st_track_in"."c_doc_no"),"charindex"('/',("st_track_in"."c_doc_no"))-1)
        and "trans"."c_year" = "left"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))-1)
        and "trans"."c_prefix" = "left"("substr"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))+1),"charindex"('/',"substr"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),"charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),"charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))+1))-1)
        and "trans"."n_srno" = "reverse"("left"("reverse"("st_track_in"."c_doc_no"),"charindex"('/',("reverse"("st_track_in"."c_doc_no")))-1))
      where((@nAllDoc = 0 and "c_doc_no" = any(select "c_doc_no" from "doc_list")) or(@nAllDoc = 1 and "c_doc_no" = "c_doc_no"))
      and "n_complete" <> 9 and "n_qty"-"n_send_qty" > 0 and "st_track_in"."c_godown_code" = @GodownCode
      order by "c_tray_code" asc,"st_track_in"."c_godown_code" asc,"c_rack_code" asc for xml raw,elements
  when 'validate_tray' then ----------------------------------------------------------------------- 
    --http://172.16.18.38:16503/ws_st_store_in_assignment_quarantine?&cIndex=validate_tray&TrayCode=1028&GodownCode=5033&gsbr=503&devID=3ee1041c3d57c46c23022017115840450&sKEY=sKey&UserId=MYBOSS
    --Index added By Saneesh on 18-06-2015 
    select "COUNT"() into @li_ext_tray_cnt from "st_tray_mst" where "c_code" = @TrayCode;
    if @li_ext_tray_cnt = 0 then
      select 'Error(201) : Tray '+@TrayCode+' is not a Valid Tray !.' as "c_message" for xml raw,elements;
      return
    end if;
    set @li_ext_tray_cnt = 0;
    select "count"() into @li_temp_tray_cnt from "st_tray_mst" where "n_in_out_flag" = 3 and "c_code" = @TrayCode;
    select "COUNT"() into @li_ext_tray_cnt from "st_tray_mst" where "c_code" = @TrayCode and "n_in_out_flag" = 0;
    if @li_ext_tray_cnt > 0 then
      select 'Error(202) : Tray '+@TrayCode+' is an external Tray code.' as "c_message" for xml raw,elements;
      return
    end if;
    --//Temp Tray validation 
    if(select "count"() from "st_track_in"
          join "st_tray_mst" on "st_tray_mst"."c_code" = "st_track_in"."c_tray_code" and "st_tray_mst"."n_in_out_flag" = 3
        where "c_tray_code" = @TrayCode and "c_user" <> @UserId) > 0 then
      select 'Error(203) TrayCode '+@TrayCode+' is already Taken By Other User  ' as "c_message" for xml raw,elements;
      return
    end if;
    select top 1 "c_doc_no"
      into @ls_doc_no
      from(select distinct "a"."c_code" as "c_tray",
          "a"."c_name" as "c_tray_name",
          "isnull"("st_track_tray_move"."c_doc_no",'') as "c_doc_no"
          from "st_tray_mst" as "a"
            join "st_tray_type_mst" as "c" on "a"."c_tray_type_code" = "c"."c_code"
            join "st_track_tray_move" on "st_track_tray_move"."c_tray_code" = "a"."c_code" union
        select distinct "a"."c_code" as "c_tray",
          "a"."c_name" as "c_tray_name",
          "isnull"("st_track_tray_move"."c_doc_no",'') as "c_doc_no"
          from "st_tray_mst" as "a"
            join "st_tray_type_mst" as "c" on "a"."c_tray_type_code" = "c"."c_code"
            join "st_Track_in" as "st_track_tray_move" on "st_track_tray_move"."c_tray_code" = "a"."c_code"
          where "a"."c_code" <> @TrayCode) as "t"
      where "t"."c_tray" = @TrayCode;
    if @ls_doc_no is not null or "ltrim"("rtrim"(@ls_doc_no)) <> '' then --Store out
      select 'Error(204) : Tray '+@TrayCode+' in use for Document  .'+@ls_doc_no+'.' as "c_message" for xml raw,elements;
      return
    end if;
    --store in 
    set @ls_doc_no = null;
    select top 1 "st_track_mst"."c_doc_no"
      into @ls_doc_no from "st_track_det" join "st_track_mst"
        on "st_track_mst"."c_doc_no" = "st_track_det"."c_doc_no"
        and "st_track_mst"."n_inout" = "st_track_det"."n_inout"
      where "st_track_det"."c_tray_code" = @TrayCode and "st_track_mst"."n_complete" not in( 9,8 ) ;
    if @ls_doc_no is not null or "ltrim"("rtrim"(@ls_doc_no)) <> '' then
      select 'Error(204.1) : Tray '+@TrayCode+' in use for Document  .'+@ls_doc_no+'.' as "c_message" for xml raw,elements;
      return
    end if;
    select top 1 "c_doc_no" into @ls_doc_no from "st_track_det" where "c_tray_code" = @TrayCode and "n_complete" not in( 9,8,2 ) ;
    if @ls_doc_no is not null or "ltrim"("rtrim"(@ls_doc_no)) <> '' then --Store out
      select 'Error(205) : Tray '+@TrayCode+' in use for Document  .'+@ls_doc_no+'.' as "c_message" for xml raw,elements;
      return
    end if;
    if(select "count"() from "st_track_in" where "c_tray_code" = @TrayCode and "c_godown_code" <> @GodownCode) > 0 then
      select 'Error(206) : Tray '+@TrayCode+' in use for Document  .'+@ls_doc_no+'.' as "c_message" for xml raw,elements;
      return
    end if;
    select '' as "c_message" for xml raw,elements;
    return
  when 'get_tray_list' then -----------------------------------------------------------------------
    --@sani 
    --http://172.16.18.38:16503/ws_st_store_in_assignment_quarantine?&cIndex=get_tray_list&HdrData=503/16/G/16995^^Itemcode^^BatchNO ^^ &StageCode=P22&GodownCode=5033&gsbr=503&devID=d0a7bf9be71a7a4307102015043524302&sKEY=sKey&UserId=YUSUF%20A
    --@HdrData 
    --DocNo~ItemCode~BatchNo
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @DocNo = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    set @Trandocno = @DocNo;
    --//503/16/5/468
    set @li_pos = "charindex"('/',@Trandocno);
    if @li_pos > 0 then
      set @TranBrCode = "left"(@Trandocno,@li_pos-1);
      set @Trandocno = "substring"(@Trandocno,@li_pos+1)
    end if;
    set @li_pos = "charindex"('/',@Trandocno);
    if @li_pos > 0 then
      set @TranYear = "left"(@Trandocno,@li_pos-1);
      set @Trandocno = "substring"(@Trandocno,@li_pos+1)
    end if;
    set @li_pos = "charindex"('/',@Trandocno);
    if @li_pos > 0 then
      set @TranPrefix = "left"(@Trandocno,@li_pos-1);
      set @Trandocno = "substring"(@Trandocno,@li_pos+1);
      set @TranSrno = cast(@Trandocno as numeric(14))
    end if;
    case(@TranPrefix)
    when 'K' then
      select "c_supp_code"
        into @SuppCode from "pur_mst"
        where "c_br_code" = @TranBrCode
        and "c_year" = @TranYear
        and "C_prefix" = @TranPrefix
        and "n_srno" = @TranSrno
    when 'G' then
      select "c_ref_br_code"
        into @SuppCode from "Grn_mst"
        where "c_br_code" = @TranBrCode
        and "c_year" = @TranYear
        and "C_prefix" = @TranPrefix
        and "n_srno" = @TranSrno
    when 'L' then
      select "c_cust_code"
        into @SuppCode from "crnt_mst"
        where "c_br_code" = @TranBrCode
        and "c_year" = @TranYear
        and "C_prefix" = @TranPrefix
        and "n_srno" = @TranSrno
    when 'U' then
      select "c_cust_code"
        into @SuppCode from "dbnt_mst"
        where "c_br_code" = @TranBrCode
        and "c_year" = @TranYear
        and "C_prefix" = @TranPrefix
        and "n_srno" = @TranSrno
    end case;
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @c_item_code = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @BatchNo = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    if(select "count"(distinct "c_tray_code") from "st_track_branch_return" where "n_qty" > 0 and "c_supp_code" = @SuppCode and "n_complete" = 0) > 0 then
      select distinct "c_tray_code"
        from "st_track_branch_return"
        where "st_track_branch_return"."c_supp_code" = @SuppCode
        and "n_qty" > 0 and "n_complete" = 0 order by "c_tray_code" asc for xml raw,elements
    else
      select 'Warning(206)!! No Active Tray(s) For Supplier '+@suppCode as "c_message" for xml raw,elements
    end if;
    return
  when 'add_tray' then -----------------------------------------------------------------------
    --@HdrData -->new_tary_flag ~new_tray_code~suppcode^^
    --@new_tary_flag -- 1 New Tray ,0 -- old Tray 
    --http://172.16.18.38:16503/ws_st_store_in_assignment_quarantine?&cIndex=add_tray&HdrData=newtrayflag^^Newtarycode^^Suppcode ^^ &StageCode=P22&GodownCode=5033&gsbr=503&devID=d0a7bf9be71a7a4307102015043524302&sKEY=sKey&UserId=YUSUF%20A			
    --http://172.16.18.38:16503/ws_st_store_in_assignment_quarantine?&cIndex=add_tray&DocNo=503/16/G/16968&HdrData=1^^1083^^H00315^^&GodownCode=5033&gsbr=503&devID=3ee1041c3d57c46c23022017115840450&sKEY=sKey&UserId=MYBOSS
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @new_tary_flag = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @new_tray_code = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @SuppCode = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    if @new_tray_code is null or "trim"(@new_tray_code) = '' then
      select '0|Warning(207)!! ,Traycode is Null' as "c_message" for xml raw,elements;
      return
    end if;
    set @Trandocno = @DocNo;
    --//503/16/5/468
    set @li_pos = "charindex"('/',@Trandocno);
    if @li_pos > 0 then
      set @TranBrCode = "left"(@Trandocno,@li_pos-1);
      set @Trandocno = "substring"(@Trandocno,@li_pos+1)
    end if;
    set @li_pos = "charindex"('/',@Trandocno);
    if @li_pos > 0 then
      set @TranYear = "left"(@Trandocno,@li_pos-1);
      set @Trandocno = "substring"(@Trandocno,@li_pos+1)
    end if;
    set @li_pos = "charindex"('/',@Trandocno);
    if @li_pos > 0 then
      set @TranPrefix = "left"(@Trandocno,@li_pos-1);
      set @Trandocno = "substring"(@Trandocno,@li_pos+1);
      set @TranSrno = cast(@Trandocno as numeric(14))
    end if;
    case(@TranPrefix)
    when 'K' then
      select "c_supp_code"
        into @SuppCode from "pur_mst"
        where "c_br_code" = @TranBrCode
        and "c_year" = @TranYear
        and "C_prefix" = @TranPrefix
        and "n_srno" = @TranSrno
    when 'G' then
      select "c_ref_br_code"
        into @SuppCode from "Grn_mst"
        where "c_br_code" = @TranBrCode
        and "c_year" = @TranYear
        and "C_prefix" = @TranPrefix
        and "n_srno" = @TranSrno
    when 'L' then
      select "c_cust_code"
        into @SuppCode from "crnt_mst"
        where "c_br_code" = @TranBrCode
        and "c_year" = @TranYear
        and "C_prefix" = @TranPrefix
        and "n_srno" = @TranSrno
    when 'U' then
      select "c_cust_code"
        into @SuppCode from "dbnt_mst"
        where "c_br_code" = @TranBrCode
        and "c_year" = @TranYear
        and "C_prefix" = @TranPrefix
        and "n_srno" = @TranSrno
    end case;
    set @cnt = 0;
    select "count"()
      into @cnt from "st_tray_mst"
      where "n_cancel_flag" = 0
      and "c_code" = @new_tray_code;
    if @cnt is null or @cnt = 0 then
      select '0|Warning(208)!! ,Tray code '+@new_tray_code+' Not Found ' as "c_message" for xml raw,elements;
      return
    end if;
    set @suppname = null;
    select top 1 "c_supp_code","act_mst"."c_name" into @allocated_to,@suppname
      from "st_track_branch_return" join "act_mst" on "act_mst"."c_code" = "st_track_branch_return"."c_supp_code"
      where "c_tray_code" = @new_tray_code
      and "n_qty" > 0 and "n_complete" = 0
      and "c_supp_code" <> @SuppCode;
    if "trim"(@allocated_to) <> '' or @allocated_to is not null then
      select '0|Warning(209)!! ,Tray code '+@new_tray_code+' is allocated for  Supplier :'+@suppname+'['+@allocated_to+']' as "c_message" for xml raw,elements;
      return
    end if;
    --select 'Success' as c_message for xml raw,elements;
    if @new_tary_flag = 1 then
      insert into "st_track_tray_move"
        ( "c_doc_no","n_inout","c_tray_code","c_rack_grp_code","c_stage_code","t_time","c_user","n_flag","c_godown_code","c_user_2" ) on existing update defaults off
        select @DocNo,1,@new_tray_code,'-','-',"now"(),@UserId,0,@GodownCode,null;
      select '1|Tray code Assigned ' as "c_message" for xml raw,elements
    else
      select '1|Tray code Assigned ' as "c_message" for xml raw,elements
    end if when 'revert_tray' then -----------------------------------------------------------------------
  when 'get_assigned_tray' then -----------------------------------------------------------------------
    --@HdrData-- Rack grp code for tht item 
    select distinct "c_tray_code" as "c_tray"
      from "st_track_in" left outer join "st_tray_mst" on "st_track_in"."c_tray_code" = "st_tray_mst"."c_code"
      where "c_rack_grp_code" = @HdrData
      and "n_complete" <> 9
      and "c_godown_code" = @GodownCode
      and "c_tray_code" is not null
      and "st_tray_mst"."n_in_out_flag" <> 3 for xml raw,elements
  when 'get_temp_tray' then
    --Index added By Saneesh 
    --http://172.16.18.38:16503/ws_st_store_in_assignment_quarantine?&cIndex=get_temp_tray&GodownCode=&gsbr=503&devID=3ee1041c3d57c46c23022017115840450&sKEY=sKey&UserId=MYBOSS
    select top 50 "a"."c_code" as "c_tray"
      from "st_tray_mst" as "a"
        join "st_tray_type_mst" as "c" on "a"."c_tray_type_code" = "c"."c_code"
        left outer join "st_track_in" as "b" on "a"."c_code" = "b"."c_tray_code"
        left outer join "st_track_tray_move" as "d" on "a"."c_code" = "d"."c_tray_code"
        left outer join(select "m"."c_doc_no","m"."d_date","d"."c_tray_code"
          from "st_track_det" as "d" join "st_track_mst" as "m" on "m"."c_doc_no" = "d"."c_doc_no" and "m"."n_inout" = "d"."n_inout" and "date"("m"."t_time_in") = "today"()) as "st"
        on "st"."c_tray_code" = "b"."c_tray_code"
      where "b"."c_tray_code" is null and "d"."c_tray_code" is null and "st"."c_tray_code" is null
      and "a"."n_in_out_flag" = 3 order by 1 asc for xml raw,elements
  when 'item_done' then -----------------------------------------------------------------------
    --called when an item is picked or put back
    --@HdrData
    --1-@ForwardFlag
    --	ForwardFlag --Values 
    --	0 - shift back, 
    --	1 - item done, 
    --	2 - item not found
    --	3 - shift back when item not found 
    --2-@storein_tray_code
    --@DetData
    --1 docno ~2 InOutFlag~3 ItemCode~4 BatchNo~5 Seq~6 Qty~7 ReasonCode ~8Godown_Tray_Code  ~9ItemSuppCode
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @ForwardFlag = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @storein_tray_code = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    -----------------------------------------------------
    --1doc no
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @DocNo = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --2inout 
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @InOutFlag = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --3ItemCode 
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @ItemCode = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --message 'ItemCode '+@ItemCode type warning to client;
    --print 'ItemCode '+@ItemCode;
    --4 BatchNo
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @BatchNo = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --message 'BatchNo '+@BatchNo type warning to client;	
    --print 'BatchNo '+@BatchNo;
    --5 Seq(OrgSeq)
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @Seq = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --message 'Seq '+string(@Seq) type warning to client;	
    --print 'Seq '+@Seq; 
    --6 PickedQty
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @PickedQty = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --message 'PickedQty '+@PickedQty type warning to client;	
    --print 'PickedQty '+@PickedQty; 
    --7 ReasonCode		
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @ReasonCode = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --8 Godown_Tray_Code  (for gdn)
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @Godown_Tray_Code = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --9 ItemSuppCode (branch /supplier code )
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @ItemSuppCode = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    -----------------------------------------------------
    select "n_qty_per_box" into @Qtp from "item_mst" where "c_code" = @ItemCode;
    if @Qtp is null then
      set @Qtp = 1
    end if;
    --set @PickedQty = @PickedQty * @Qtp ;
    if @ForwardFlag = 1 then -- item done
      update "st_track_in"
        set "c_tray_code" = @storein_tray_code,"c_user" = @UserId,"t_time" = "now"(),"n_confirm" = 1,
        "n_send_qty" = "n_send_qty"+@PickedQty
        where "c_doc_no" = @DocNo and "n_seq" = @Seq
        and "c_item_code" = @ItemCode
        and "c_batch_no" = @BatchNo;
      set @RetStr
         = "uf_add_st_track_branch_return"(
        @BrCode,@ItemCode,@BatchNo,@Godown_Tray_Code,@ItemSuppCode,@PickedQty,@DocNo,@UserId,@Seq)
    elseif @ForwardFlag = 0 then -- shift back, 
      update "st_track_in"
        set "c_tray_code" = null,"c_user" = null,"t_time" = "now"(),"n_confirm" = 0,
        "n_send_qty" = "n_send_qty"-@PickedQty
        where "c_doc_no" = @DocNo and "n_seq" = @Seq
        and "c_item_code" = @ItemCode
        and "c_batch_no" = @BatchNo;
      set @RetStr
         = "uf_add_st_track_branch_return"(
        @BrCode,@ItemCode,@BatchNo,@Godown_Tray_Code,@ItemSuppCode,-1*@PickedQty,@DocNo,@UserId,@Seq)
    elseif @ForwardFlag = 2 then -- item not found
    elseif @ForwardFlag = 3 then -- shift back when item not found 
    end if;
    if "trim"(@RetStr) = '' then
    else
      select @RetStr as "c_message" for xml raw,elements;
      return
    end if;
    if sqlstate = '00000' then
      commit work;
      select 'Success' as "c_message" for xml raw,elements
    else
      rollback work;
      select 'Failure' as "c_message" for xml raw,elements
    end if when 'send_inward_tray' then -----------------------------------------------------------------------
    --@DetData
    --1 docno ~2 ItemCode~3 BatchNo~4 Seq~5 Qty~7 Storein_Tray_Code  ~8 Godown_Code||
    --1doc no
    set @old_genDocNo = '';
    set @inward_loop = 0;
    --gargee
    while @DetData <> '' loop
      set @inward_loop = @inward_loop+1;
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @DocNo = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --2 ItemCode
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @ItemCode = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --message 'ItemCode '+@ItemCode type warning to client;
      --print 'ItemCode '+@ItemCode;
      --3 BatchNo
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @BatchNo = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --message 'BatchNo '+@BatchNo type warning to client;	
      --print 'BatchNo '+@BatchNo;
      --4 Seq(OrgSeq)
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @Seq = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --message 'Seq '+string(@Seq) type warning to client;	
      --print 'Seq '+@Seq; 
      --5 PickedQty
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @PickedQty = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --message 'PickedQty '+@PickedQty type warning to client;	
      --print 'PickedQty '+@PickedQty; 
      --7 Storein_Tray_Code  (storein)
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @Storein_Tray_Code = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --8  Godowncode Line item wise 
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @GodownCode = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      select "Locate"(@DetData,@RowSep) into @RowPos;
      set @DetData = "SubString"(@DetData,@RowPos+@RowMaxLen);
      set @old_genDocNo = @genDocNo;
      select "string"(@Storein_Tray_Code,"day"(@d_ldate),"month"(@d_ldate),"hour"(@t_ltime),"minute"(@t_ltime)) into @genDocNo;
      --select max(c_godown_code) into @godown_code from st_track_in where c_tray_code = @TrayCode;
      if @godown_code <> '-' then
        select "max"("c_reason_code")
          into @Reason_code from "storein_setup"
          where "c_br_code" = @BrCode and "c_godown_code" = @GodownCode
          and "n_cancel_flag" = 0
      end if;
      if @Reason_code is null or "trim"(@Reason_code) = '' then
        set @Reason_code = '-'
      end if;
      if @inward_loop = 1 then
        if(select "count"("c_doc_no") from "st_send_inward_tray" where "st_send_inward_tray"."c_doc_no" = @DocNo and "st_send_inward_tray"."c_tray_code" = @Storein_Tray_Code) = 0 then
          insert into "st_send_inward_tray"( "c_doc_no","c_item_code","c_tray_code","n_seq" ) values( @DocNo,@ItemCode,@Storein_Tray_Code,@Seq ) 
        else
          select 'Error!! in send inward tray' as "c_message" for xml raw,elements;
          return
        end if end if;
      insert into "temp_st_track_det"
        ( "c_doc_no","n_inout","c_item_code","c_batch_no","n_seq",
        "n_qty","n_bal_qty","c_note","c_rack","c_rack_grp_code",
        "c_stage_code","n_complete","c_reason_code","n_hold_flag","c_tray_code",
        "c_user","c_godown_code","c_stin_ref_no",
        "c_user_2",
        "t_time" ) 
        select @genDocNo as "gen_doc",
          1 as "n_inout",@ItemCode,@BatchNo,1 as "n_seq",
          @PickedQty,@PickedQty as "n_bal_qty",null as "c_note",
          if @GodownCode = '-' then
            (select "c_rack" into "c_rak" from "item_mst_br_info" where "item_mst_br_info"."c_code" = @ItemCode and "item_mst_br_info"."c_br_code" = @BrCode)
          else
            (select "c_rack" into "c_rak" from "item_mst_br_info_godown" where "item_mst_br_info_godown"."c_code" = @ItemCode
              and "item_mst_br_info_godown"."c_godown_code" = @GodownCode
              and "item_mst_br_info_godown"."c_br_code" = @BrCode)
          endif as "c_rk_code",
          (select "c_rack_grp_code" into "rack_grp_code" from "rack_mst" where "rack_mst"."c_code" = "c_rk_code"
            and "rack_mst"."c_br_code" = @BrCode) as "c_rk_grp_code",
          (select top 1 "c_stage_code" from "st_store_stage_det" where "st_store_stage_det"."c_rack_grp_code" = "c_rk_grp_code") as "c_stage_code",
          0 as "n_complete",@Reason_code as "c_reason_code",1 as "n_hold_flag",@Storein_Tray_Code,
          null as "c_user",@GodownCode,@DocNo+'/'+"string"(@Seq) as "c_stin_ref_no",null as "c_user_2","now"();
      insert into "temp_st_track_mst"
        ( "c_br_code","c_doc_no","n_inout","c_phase_code","c_cust_code",
        "d_date","c_user","c_system_name","c_system_ip","t_time_in",
        "t_time_out","n_complete","n_confirm","n_urgent","c_sort",
        "c_user_2" ) 
        select @BrCode as "c_br_code",
          @genDocNo as "c_doc_no",1 as "n_inout",'PH0001' as "c_phase_code",null as "c_cust_code",
          "uf_default_date"() as "d_date",@UserId as "c_user",'TAB' as "c_system_name",null as "c_system_ip",@t_ltime as "t_time_in",
          null as "t_time_out",0 as "n_complete",1 as "n_confirm",0 as "n_urgent",null as "c_sort",null as "c_user_2"
    end loop;
    select "string"(@Storein_Tray_Code,"day"(@d_ldate),"month"(@d_ldate),"hour"(@t_ltime),"minute"(@t_ltime)) into @genDocNo;
    insert into "st_track_mst"
      ( "c_br_code","c_doc_no","n_inout","c_phase_code","c_cust_code",
      "d_date","c_user","c_system_name","c_system_ip","t_time_in",
      "t_time_out","n_complete","n_confirm","n_urgent","c_sort",
      "c_user_2" ) 
      select top 1 "c_br_code",@genDocNo as "docno","n_inout","c_phase_code","c_cust_code",
        "d_date","c_user","c_system_name","c_system_ip","t_time_in",
        "t_time_out","n_complete","n_confirm","n_urgent","c_sort",
        "c_user_2"
        from "temp_st_track_mst";
    insert into "st_track_det"
      ( "c_doc_no","n_inout","c_item_code","c_batch_no","n_seq",
      "n_qty","n_bal_qty","c_note","c_rack","c_rack_grp_code",
      "c_stage_code","n_complete","c_reason_code","n_hold_flag","c_tray_code",
      "c_user","c_godown_code","c_stin_ref_no",
      "c_user_2",
      "t_time" ) 
      select @genDocNo as "docno","n_inout","c_item_code","c_batch_no","number"() as "n_seq",
        "n_qty","n_bal_qty","c_note","c_rack","c_rack_grp_code",
        "c_stage_code","n_complete","c_reason_code","n_hold_flag","c_tray_code",
        "c_user","c_godown_code","c_stin_ref_no",
        "c_user_2","now"() as "t_ltime"
        from "temp_st_track_det";
    update "st_track_in"
      set "n_complete" = 9,
      "c_user" = @UserId,
      "n_confirm" = 1,
      "c_tray_code" = @Storein_Tray_Code,
      "t_time" = "now"(),
      "n_send_qty" = "temp_st_track_det"."n_qty" from
      "temp_st_track_det"
      where "temp_st_track_det"."c_stin_ref_no" = "st_track_in"."c_doc_no"+'/'+"string"("st_track_in"."n_seq");
    select 'Success' as "c_message" for xml raw,elements
  when 'send_godown_tray' then -----------------------------------------------------------------------
    --@DetData
    --1 docno ~3 ItemCode~4 BatchNo~5 Seq~6 Qty~8 Godown_Tray_Code  ~9 Godown_Code||
    --1doc no
    while @DetData <> '' loop
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @DocNo = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --3 Itm code 
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @ItemCode = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --4 BatchNo
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @BatchNo = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --5 Seq(OrgSeq)
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @Seq = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --6 PickedQty
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @PickedQty = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --8 Godown_Tray_Code  (for gdn)
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @Godown_Tray_Code = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --9  Godowncode Line item wise 
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @GodownCode = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      select "Locate"(@DetData,@RowSep) into @RowPos;
      set @DetData = "SubString"(@DetData,@RowPos+@RowMaxLen);
      set @Trandocno = @DocNo;
      --//503/16/5/468
      set @li_pos = "charindex"('/',@Trandocno);
      if @li_pos > 0 then
        set @TranBrCode = "left"(@Trandocno,@li_pos-1);
        set @Trandocno = "substring"(@Trandocno,@li_pos+1)
      end if;
      set @li_pos = "charindex"('/',@Trandocno);
      if @li_pos > 0 then
        set @TranYear = "left"(@Trandocno,@li_pos-1);
        set @Trandocno = "substring"(@Trandocno,@li_pos+1)
      end if;
      set @li_pos = "charindex"('/',@Trandocno);
      if @li_pos > 0 then
        set @TranPrefix = "left"(@Trandocno,@li_pos-1);
        set @Trandocno = "substring"(@Trandocno,@li_pos+1);
        set @TranSrno = cast(@Trandocno as numeric(14))
      end if;
      case(@TranPrefix)
      when 'K' then
        select "c_supp_code"
          into @SuppCode from "pur_mst"
          where "c_br_code" = @TranBrCode
          and "c_year" = @TranYear
          and "C_prefix" = @TranPrefix
          and "n_srno" = @TranSrno
      when 'G' then
        select "c_ref_br_code"
          into @SuppCode from "Grn_mst"
          where "c_br_code" = @TranBrCode
          and "c_year" = @TranYear
          and "C_prefix" = @TranPrefix
          and "n_srno" = @TranSrno
      when 'L' then
        select "c_cust_code"
          into @SuppCode from "crnt_mst"
          where "c_br_code" = @TranBrCode
          and "c_year" = @TranYear
          and "C_prefix" = @TranPrefix
          and "n_srno" = @TranSrno
      when 'U' then
        select "c_cust_code"
          into @SuppCode from "dbnt_mst"
          where "c_br_code" = @TranBrCode
          and "c_year" = @TranYear
          and "C_prefix" = @TranPrefix
          and "n_srno" = @TranSrno
      end case;
      set @RetStr
         = "uf_add_st_track_branch_return"(
        @BrCode,@ItemCode,@BatchNo,@Godown_Tray_Code,@SuppCode,@PickedQty,@DocNo,@UserId,@Seq);
      if "trim"(@RetStr) = '' then
      else
        select @RetStr as "c_message" for xml raw,elements;
        return
      end if;
      update "st_track_in" set "c_tray_code" = '-',"n_qty" = @PickedQty,"c_user" = @UserId,"t_time" = "now"()
        where "c_doc_no" = @DocNo
        and "n_seq" = @Seq
        and "c_item_code" = @ItemCode
        and "c_batch_no" = @BatchNo;
      delete from "st_track_in"
        where "c_doc_no" = @DocNo
        and "n_seq" = @Seq
        and "c_item_code" = @ItemCode
        and "c_batch_no" = @BatchNo
    end loop;
    select 'Success' as "c_message" for xml raw,elements
  --ADDED BY GARGEE FOR CHECK ID VALIDATION 
  when 'Validate_Check_ID' then
    --http://192.168.7.12:16503/ws_st_stock_audit?&cIndex=Validate_Check_ID&GodownCode=-&UserId=myboss&HdrData=32014
    --sani
    select "max"("user_mst"."c_user_id")
      into @c_confirm_user from "user_mst","act_mst"
      where "user_mst"."c_code" = "act_mst"."c_code"
      and "act_mst"."n_lock" = 0
      and "string"("user_mst"."n_id") = @HdrData;
    if @c_confirm_user = 'SUPERVISOR' or @HdrData = '0' or @c_confirm_user is null or "trim"(@c_confirm_user) = '' then
      select 'Error!! ,Wrong ID ' as "c_message" for xml raw,elements
    else
      select 'Success'+@ColSep+@c_confirm_user as "c_message" for xml raw,elements
    end if when 'revert_tray' then
    --Update st_track_in set c_tray_code =null ,@TrayCode		
  when 'get_setup' then
  else
    select 'Invalid Index !!' as "c_message" for xml raw,elements
  end case
end;