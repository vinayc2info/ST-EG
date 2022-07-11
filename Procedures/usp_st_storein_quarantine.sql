CREATE PROCEDURE "DBA"."usp_st_storein_quarantine"( 
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
Procedure	: usp_st_storein_quarantine
SERVICE		: usp_st_storein_quarantine
Date 		: 27-12-2015
Purpose		: Quarantine Stock Storein 
--------------------------------------------------------------------------------------------------------------------------------
Modified By                 Ldate               Index                       Changes
--------------------------------------------------------------------------------------------------------------------------------
Pratheesh P                21-01-2021           get_doc_list               C23613  DAYS COLUMN IN EXPIRY AND INWARD ASSIGNMENT EXPIRY
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
  declare @DetData_for_stk_adj char(32767);
  declare @doc_user char(10);
  declare @st_track_stock_eb_supp char(150);
  declare @show_exp_date numeric(1);
  --get_items >>
  declare @UnprocessedTray char(6);
  declare @UnprocessedDoc char(15);
  declare @cDocAlreadyAssignedToUser char(20);
  declare @cTrayAssigned char(6);
  declare @ENABLE_INWARD_ITEM_TRACK numeric(1);
  declare @CurrentTray char(6);
  --get_items <<
  --item_done>>
  declare @ForwardFlag integer;
  declare @InOutFlag integer;
  declare @ItemCode char(6);
  declare @PickedQty numeric(12);
  declare @ReasonCode char(6);
  declare @RemainingQty numeric(12);
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
  declare @c_exp_stage_code char(6);
  declare @c_exp_rack_grp_code char(6);
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
  declare @n_inward_qty integer;
  declare @cStinRefNo char(25);
  declare @RefSep char(5);
  declare @ColMaxLenRef numeric(4);
  declare @TranSeq numeric(6);
  declare @TranBrCode char(6);
  declare @TranPrefix char(4);
  declare @TranYear char(2);
  declare @TranSrno numeric(6);
  declare @s_pick_user char(10);
  --documnet_done<<
  --shift_tarys>>
  declare @flag_val numeric(1);
  declare @OldTrayCode char(6);
  declare @NewTrayCode char(6);
  --shift_tarys<<
  declare @an_item_bounce_count numeric(14);
  declare @an_item_pick_count numeric(14);
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
    set @GodownCode = "http_variable"('GodownCode') --12		
  end if;
  set @an_item_bounce_count = 0;
  set @an_item_pick_count = 0;
  select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
  select "c_delim" into @RowSep from "ps_tab_delimiter" where "n_seq" = 1;
  select "n_active" into @ENABLE_INWARD_ITEM_TRACK from "st_track_module_mst"
    where "c_code" = 'M00032';
  if @ENABLE_INWARD_ITEM_TRACK is null then
    set @ENABLE_INWARD_ITEM_TRACK = 0
  end if;
  if @ColSep is null or @ColSep = '' then
    select '--------------------\x0D\x0ASQL error: usp_st_storein_quarantine  No Delimiter Defined';
    return
  end if;
  set @ColMaxLen = "Length"(@ColSep);
  set @RowMaxLen = "Length"(@RowSep);
  --saneesh 
  set @BrCode = "uf_get_br_code"(@gsBr);
  set @t_ltime = "left"("now"(),19);
  set @d_ldate = "uf_default_date"();
  case @cIndex
  when 'get_godown_code' then -----------------------------------------------------------------------
    --http://192.168.7.12:15503/ws_st_storein_quarantine?&cIndex=get_godown_code
    select "max"("c_godown_code") as "c_godown_code" from "storein_setup" where "c_br_code" = @BrCode for xml raw,elements
  when 'get_doc_list' then -----------------------------------------------------------------------
    --http://192.168.7.12:15503/ws_st_storein_quarantine?&cIndex=get_doc_list&GodownCode=-&gsbr=503&UserId=SALE
    select "n_active" into @show_exp_date from "st_track_module_mst" where "c_code" = 'M00125';
    set @show_exp_date = "isnull"(@show_exp_date,0);
    select distinct "st_track_det"."c_tray_code" as "c_tray_code",
      1 as "n_first_in_stage",
      "st_track_det"."c_doc_no",
      "st_track_det"."n_inout",
      '' as "c_message",
      "count"("n_seq") as "n_item_count",
      --reverse(substring(reverse(c_stin_ref_no) ,charindex('/',reverse(c_stin_ref_no)  ) + 1  ) ) as tran_doc_no
      0 as "tran_doc_no",
      "isnull"("max"("st_track_det"."c_user"),'') as "c_user",
      if @show_exp_date = 0 then null else "datediff"("dd",cast("st_track_mst"."d_date" as date),"now"()) endif as "expirydate"
      from "st_track_det"
        join "st_track_mst" on "st_track_det"."c_doc_no" = "st_track_mst"."c_doc_no"
        and "st_track_det"."n_inout" = "st_track_mst"."n_inout"
      where "st_track_det"."c_tray_code" is not null
      and "st_track_mst"."n_complete" <> (9)
      and "isnull"("st_track_det"."c_godown_code",'-') = @GodownCode
      --and (isnull(st_track_det.c_user,@UserId)= @UserId or(trim(c_user)  =''))
      and "st_track_det"."n_inout" = 1
      --and  st_track_det.n_complete not in(8, 2) 
      group by "c_tray_code","n_first_in_stage","st_track_det"."c_doc_no","st_track_det"."n_inout","c_message","tran_doc_no","expirydate"
      order by "c_tray_code" asc,"st_track_det"."c_doc_no" asc for xml raw,elements
  when 'get_items' then -----------------------------------------------------------------------
    --http://192.168.7.12:15503/ws_st_storein_quarantine?&cIndex=get_items&HdrData=15542^^&DocNo=155420160023751&GodownCode=-&gsbr=503&UserId=SALE
    --@HdrData-->CurrentTray~~
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @CurrentTray = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    if "trim"(@CurrentTray) = '' or @CurrentTray is null then
      select ' Warning! : Invalid Tray Code  : ' as "c_message" for xml raw,elements;
      return
    end if;
    select top 1 "c_user","c_rack_grp_code","c_stage_code"
      into @doc_user,@c_exp_rack_grp_code,@c_exp_stage_code
      from "st_track_det"
      where "st_track_det"."c_doc_no" = @DocNo
      and "isnull"("st_track_det"."c_godown_code",'-') = @GodownCode
      and "st_track_det"."n_complete" <> 8 and "st_track_det"."n_inout" = 1
      and "st_track_det"."c_tray_code" = @CurrentTray;
    if "trim"(@doc_user) = '' or @doc_user is null then
    else
      if @doc_user <> @UserId then
        select 'Tray '+@CurrentTray+' is already Taken By Another User '+@doc_user as "c_message" for xml raw,elements;
        return
      end if end if;
    update "st_track_det" set "c_user" = @UserId
      where "st_track_det"."c_doc_no" = @DocNo
      and "isnull"("st_track_det"."c_godown_code",'-') = @GodownCode
      and "st_track_det"."c_tray_code" = @CurrentTray;
    ---saneesh for capture Tray processing time 
    call "uf_update_tray_time"(@DocNo,1,@CurrentTray,'STOREIN_EXP',@UserId,@c_exp_rack_grp_code,@c_exp_stage_code,1,null,@an_item_pick_count,@an_item_bounce_count);
    ---saneesh for capture Tray processing time 
    --Get the Item List for the Selected Tray
    select "st_track_det"."c_doc_no" as "c_doc_no",
      "st_track_det"."n_inout" as "n_inout",
      "item_mst"."c_code" as "c_item_code",
      "isnull"("st_track_det"."c_batch_no",'') as "c_batch_no",
      "st_track_det"."n_seq" as "n_seq",
      "uf_get_last_purchase_supplier"("c_item_code","c_batch_no",@BrCode) as "c_supp_code",
      "act_mst"."c_name" as "c_supp_name",
      "TRIM"("STR"("TRUNCNUM"("st_track_det"."n_qty",3),10,0)) as "n_qty",
      "TRIM"("STR"("TRUNCNUM"("st_track_det"."n_bal_qty",3),10,0)) as "n_bal_qty",
      "st_track_det"."c_note" as "c_note",
      "st_track_det"."c_stage_code" as "c_stage_code",
      "st_track_det"."n_complete" as "n_complete",
      "st_track_det"."c_reason_code" as "c_reason",
      "st_track_det"."n_hold_flag" as "n_hold_flag",
      "st_track_det"."c_tray_code" as "c_tray_code",
      "item_mst"."c_name" as "c_item_name",
      "pack_mst"."c_name" as "c_pack_name",
      "date"("isnull"("stock_mst"."d_exp_dt",'')) as "d_exp_dt",
      "TRIM"("STR"("TRUNCNUM"("stock_mst"."n_mrp",3),10,3)) as "n_mrp",
      "item_mst"."n_qty_per_box" as "n_qty_per_box",
      '' as "c_message",
      "isnull"("item_mst"."c_barcode"+',','')+"isnull"((select "list"("c_barcode") from "item_multi_barcode_det" where "c_item_code" = "st_track_det"."c_item_code"),'') as "c_barcode_list",
      "isnull"("n_inner_pack_lot",0) as "n_inner_pack_lot",
      "st_track_det"."c_user" as "c_user",
      /*(select top 1 c_tray_code from  st_track_stock_eb 
where  st_track_det.c_item_code =st_track_stock_eb.c_item_code  
and st_track_det.c_batch_no =st_track_stock_eb.c_batch_no
and st_track_stock_eb.c_supp_code =c_supp_code
and st_track_stock_eb.c_doc_no = st_track_det.c_doc_no
and st_track_stock_eb.n_qty >0 
) as c_godown_tray_code,
*/
      "st_track_stock_eb"."c_tray_code" as "c_godown_tray_code",
      "st_track_stock_eb"."n_qty" as "n_godown_qty",
      "isnull"("act_br_limit"."n_exp_days",60) as "n_exp_ret_days",
      if "d_exp_dt" < "DATEADD"("day",-"n_exp_ret_days","uf_default_date"()) then
        1
      else
        0
      endif as "n_exp_ret_flag",
      "reverse"("substr"("reverse"("c_stin_ref_no"),"charindex"('/',"reverse"("c_stin_ref_no"))+1)) as "inward_ref_no",
      "mfac_mst"."c_sh_name" as "mfac_code"
      from "st_track_det"
        join "st_track_mst" on "st_track_mst"."c_doc_no" = "st_track_det"."c_doc_no"
        and "st_track_mst"."n_inout" = "st_track_det"."n_inout"
        join "st_tray_mst" on "st_tray_mst"."c_code" = "st_track_det"."c_tray_code"
        join "item_mst" on "st_track_det"."c_item_code" = "item_mst"."c_code"
        join "mfac_mst" on "item_mst"."c_mfac_code" = "mfac_mst"."c_code"
        join "pack_mst" on "pack_mst"."c_code" = "item_mst"."c_pack_code"
        join "stock" on "stock"."c_item_code" = "st_track_det"."c_item_code"
        and "stock"."c_batch_no" = "st_track_det"."c_batch_no"
        and "stock"."c_br_code" = @BrCode
        join "stock_mst" on "stock"."c_item_code" = "stock_mst"."c_item_code"
        and "stock"."c_batch_no" = "stock_mst"."c_batch_no"
        join "act_mst" on "act_mst"."c_code" = "c_supp_code"
        left outer join(select "c_br_code","c_item_code","c_batch_no","c_tray_code","c_supp_code","n_qty","n_complete","c_doc_no","n_inout","n_seq"
          from "DBA"."st_track_stock_eb" where "n_qty" > 0) as "st_track_stock_eb"
        on "st_track_det"."c_item_code" = "st_track_stock_eb"."c_item_code"
        and "st_track_det"."c_batch_no" = "st_track_stock_eb"."c_batch_no"
        and "st_track_stock_eb"."c_doc_no" = "st_track_det"."c_doc_no"
        and "st_track_stock_eb"."n_inout" = "st_track_det"."n_inout"
        and "st_track_stock_eb"."n_seq" = "st_track_det"."n_seq"
        left outer join "act_br_limit" on "act_br_limit"."c_code" = "c_supp_code" and "act_br_limit"."n_cancel_flag" = 0
        and "act_br_limit"."c_br_code" = @BrCode
      where "st_track_det"."c_doc_no" = @DocNo
      and "isnull"("st_track_det"."c_godown_code",'-') = @GodownCode
      and "st_track_det"."c_tray_code" = @CurrentTray
      and "st_track_mst"."n_complete" <> 9
      --and st_track_det.n_bal_qty > 0 
      order by "n_exp_ret_flag" asc,"c_supp_name" asc for xml raw,elements
  when 'get_tray_list' then -----------------------------------------------------------------------
    --On Item Click ,list all opened Tray for that supp
    --Option to add New Tray
    --added flg ^^n_exp_ret_flag^^ 04-07-2016
    --@HdrData -- Supp Code^^n_exp_ret_flag^^c_item_code ^^
    --n_exp_ret_flag --1-->can't giv to supplier 0-->can return to supp 
    --http://192.168.7.12:15503/ws_st_storein_quarantine?&cIndex=get_tray_list&HdrData=S01235^^&GodownCode=5033&gsbr=503&UserId=SALE
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @SuppCode = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @n_exp_ret_flag = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @c_item_code = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    select "c_mfac_code" into @c_MfacCode from "item_mst" where "c_code" = @c_item_code;
    if @SuppCode is null or "trim"(@SuppCode) = '' then
      select 'Warning!! ,Supplier Code is Null' as "c_message" for xml raw,elements;
      return
    end if;
    if @n_exp_ret_flag = 1 then --can't giv to supp ,Assign to dummy supp
      select top 1 "c_exp_ret_supp" into @c_exp_ret_SuppCode from "st_track_setup";
      if @c_exp_ret_SuppCode is null or "trim"(@c_exp_ret_SuppCode) = '' then
        select 'Warning!! ,Default Supplier Code is not updated !!' as "c_message" for xml raw,elements;
        return
      end if;
      set @SuppCode = @c_exp_ret_SuppCode
    end if;
    --print @SuppCode;
    --Get the Open Trays for tht supp
    if(select "count"(distinct "c_tray_code") from "st_track_stock_eb" where "n_qty" > 0 and "c_supp_code" = @SuppCode) > 0 then
      /*
select  distinct c_tray_code  as c_tray_code  
from st_track_stock_eb  
where n_qty > 0 and  c_supp_code = @SuppCode  for xml raw,elements;
*/
      select distinct "t"."c_tray_code" as "c_tray_code",
        "min"("t"."n_flag") as "n_flag",
        --        (select "count"() from "st_track_stock_eb" where "c_tray_code" = "t"."c_tray_code" and "n_qty" > 0) as "n_tray_item_count",
        "count"("t"."c_item_code") as "n_tray_item_count",
        if "n_tray_item_count" >= "n_max_tray_item_exp" then --Red
          2
        else
          "n_flag"
        endif as "n_sort"
        --green
        --vinay
        from(select "c_mfac_code","st_track_stock_eb"."c_tray_code",
            if "item_mst"."c_mfac_code" = @c_MfacCode then
              0
            else
              1
            endif as "n_flag",
            "st_track_setup"."n_max_tray_item_exp" as "n_max_tray_item_exp",
            "st_track_stock_eb"."c_item_code"
            from "st_track_stock_eb"
              join "item_mst" on "item_mst"."c_code" = "st_track_stock_eb"."c_item_code"
              join "st_track_setup" on "st_track_setup"."c_br_code" = "st_track_stock_eb"."c_br_code"
            where "n_qty" > 0 and "c_supp_code" = @SuppCode) as "t"
        group by "c_tray_code","n_max_tray_item_exp"
        order by "n_sort" asc for xml raw,elements
    else
      select 'Warning!! No Active Tray(s) For Supplier '+@suppCode as "c_message" for xml raw,elements
    end if;
    return
  when 'add_tray' then -----------------------------------------------------------------------
    --added flg ^^n_exp_ret_flag^^ 04-07-2016
    --@HdrData -->validate_mode~new_tary_flag ~new_tray_code~suppcode^^n_exp_ret_flag^^
    --validate_mode--0 -- Validate Tray with tray type ,st_track_stock_eb
    --validate_mode--1 -- No Validation With Tray Type ,Validate With Tray Move ,st_track_stock_eb
    --@new_tary_flag -- 1 New Tray ,0 -- old Tray 
    --http://192.168.1.15:15503/ws_st_storein_quarantine?&cIndex=add_tray&DocNo=1070819111510&HdrData=1^^1^^1705^^S01765^^&GodownCode=5033&gsbr=503&UserId=SALES		
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @validate_mode = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @new_tary_flag = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @new_tray_code = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @SuppCode = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @n_exp_ret_flag = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    if @n_exp_ret_flag = 1 then --can't giv to supp ,Assign to dummy supp
      select top 1 "c_exp_ret_supp" into @c_exp_ret_SuppCode from "st_track_setup";
      if @c_exp_ret_SuppCode is null or "trim"(@c_exp_ret_SuppCode) = '' then
        select 'Warning!! ,Default Supplier Code is not updated !!' as "c_message" for xml raw,elements;
        return
      end if;
      set @SuppCode = @c_exp_ret_SuppCode
    end if;
    if @new_tray_code is null or "trim"(@new_tray_code) = '' then
      select '0|Warning!! ,Traycode is Null' as "c_message" for xml raw,elements;
      return
    end if;
    set @cnt = 0;
    select "count"()
      into @cnt from "st_tray_mst"
      where "n_cancel_flag" = 0
      and "c_code" = @new_tray_code;
    if @cnt is null or @cnt = 0 then
      select '0|Warning!! ,Tray code '+@new_tray_code+' Not Found ' as "c_message" for xml raw,elements;
      return
    end if;
    if @validate_mode = 0 then
      set @cnt = 0;
      select "count"() into @cnt from "st_tray_mst"
        where "n_cancel_flag" = 0
        and "c_code" = @new_tray_code
        and "n_in_out_flag" = 4;
      if @cnt is null or @cnt = 0 then
        select '0|Warning!! ,Tray code '+@new_tray_code+' Not allocated for Expiry /Breakage   ' as "c_message" for xml raw,elements;
        return
      --@validate_mode = 1 then 
      end if
    else set @cnt = 0;
      select "count"(),"max"("c_doc_no") into @cnt,@tray_assigned_doc_no from "st_track_tray_move"
        where "st_track_tray_move"."c_tray_code" = @new_tray_code;
      if @cnt > 0 then
        if @new_tary_flag = 1 then
          if @tray_assigned_doc_no is null or "trim"(@tray_assigned_doc_no) = '' then
            select '0|Warning11!! ,Tray code '+@new_tray_code+' assigned to doc no : '+@tray_assigned_doc_no as "c_message" for xml raw,elements;
            return
          /*Else 
select c_supp_code  ,c_name  into @allocated_to,@suppname
from DBA.st_track_stock_eb join act_mst on  st_track_stock_eb.c_supp_code = act_mst.c_code 
where c_tray_code =@new_tray_code and c_doc_no = @tray_assigned_doc_no ;
select '0|Warning!! ,Tray code ' +@new_tray_code + ' is allocated for  Supplier :'+ @suppname +'['+@allocated_to +']' as c_message for xml raw,elements;
Return ;
*/
          end if end if end if end if;
    set @suppname = null;
    select top 1 "c_supp_code","act_mst"."c_name" into @allocated_to,@suppname
      from "st_track_stock_eb" join "act_mst" on "act_mst"."c_code" = "st_track_stock_eb"."c_supp_code"
      where "c_tray_code" = @new_tray_code
      and "n_qty" > 0
      and "c_supp_code" <> @SuppCode;
    --Group By c_supp_code ;
    if "trim"(@allocated_to) <> '' or @allocated_to is not null then
      select '0|Warning!! ,Tray code '+@new_tray_code+' is allocated for  Supplier :'+@suppname+'['+@allocated_to+']' as "c_message" for xml raw,elements;
      return
    end if;
    set @cnt = 0;
    select "count"() into @cnt from "st_track_in" where "c_tray_code" = @new_tray_code;
    if @cnt is null then
      set @cnt = 0
    end if;
    if @cnt > 0 then
      select '0|Warning!! ,Tray code '+@new_tray_code+' Already Used in Inward Assignment ' as "c_message" for xml raw,elements;
      return
    end if;
    set @cnt = 0;
    select "count"() into @cnt from "st_track_det" where "c_tray_code" = @new_tray_code and "n_complete" = 0;
    if @cnt is null then
      set @cnt = 0
    end if;
    if @cnt > 0 then
      select '0|Warning!! ,Tray code '+@new_tray_code+' Already In Use  ' as "c_message" for xml raw,elements;
      return
    end if;
    if @new_tary_flag = 1 then
      insert into "st_track_tray_move"
        ( "c_doc_no","n_inout","c_tray_code","c_rack_grp_code","c_stage_code","t_time","c_user","n_flag","c_godown_code","c_user_2" ) 
        select @DocNo,1,@new_tray_code,'-','-',"now"(),@UserId,0,@GodownCode,null;
      if sqlstate = '00000' then
        commit work;
        select '1|Tray code Assigned ' as "c_message" for xml raw,elements
      else
        rollback work;
        select '0|Warning!! ,Error On Tray code Assignment ' as "c_message" for xml raw,elements
      end if
    else select '1|Tray code Assigned ' as "c_message" for xml raw,elements
    end if when 'revert_tray' then -----------------------------------------------------------------------
    --called when tray is assigned and validation failed @ qty entry level,need to rels the tray 
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @new_tray_code = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    if(select "count"() from "st_track_tray_move" where "c_tray_code" = @new_tray_code) > 0 then
      if(select "isnull"("sum"("n_qty"),0) from "st_track_stock_eb" where "c_tray_code" = @new_tray_code) = 0 then //rels
        delete from "st_track_tray_move"
          where "c_tray_code" = @new_tray_code
          and "c_doc_no" = @DocNo
          and "isnull"("c_godown_code",'-') = @GodownCode;
        if sqlstate = '00000' then
          commit work;
          select 'Success' as "c_message" for xml raw,elements
        else
          rollback work;
          select 'Failure' as "c_message" for xml raw,elements
        end if
      else select 'Success' as "c_message" for xml raw,elements
      end if
    else select 'Success' as "c_message" for xml raw,elements
    end if when 'item_done' then -----------------------------------------------------------------------
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
    --1 InOutFlag~2 ItemCode~3 BatchNo~4 Seq~5 Qty~6 ReasonCode ~7Godown_Tray_Code  ~8ItemSuppCode~ 9 n_exp_ret_flag^^
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @ForwardFlag = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @storein_tray_code = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @InOutFlag = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --message 'InOutFlag '+@InOutFlag type warning to client;
    --print 'InOutFlag '+@InOutFlag ;
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
    --6 ReasonCode		
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @ReasonCode = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --7 Godown_Tray_Code 
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @Godown_Tray_Code = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --8 ItemSuppCode
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @ItemSuppCode = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --9 n_exp_ret_flag
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @n_exp_ret_flag = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    if @n_exp_ret_flag = 1 then --can't giv to supp ,Assign to dummy supp
      select top 1 "c_exp_ret_supp" into @c_exp_ret_SuppCode from "st_track_setup";
      if @c_exp_ret_SuppCode is null or "trim"(@c_exp_ret_SuppCode) = '' then
        select 'Warning!! ,Default Supplier Code is not updated !!' as "c_message" for xml raw,elements;
        return
      end if;
      set @ItemSuppCode = @c_exp_ret_SuppCode
    end if;
    --validate same item is been taken by other user 
    --sani
    select "count"(),"c_user" into @cnt,@s_pick_user from "st_track_det"
      where "c_item_code" = @ItemCode and "c_batch_no" = @BatchNo and "c_user" <> @UserId and "n_seq" = @Seq and "n_complete" = 8
      and "c_doc_no" = @DocNo
      group by "c_user";
    if @cnt is null or @cnt = 0 then
    else
      select 'Warning, item '+@ItemCode+' Batch '+@BatchNo+' is already taken by User '+@s_pick_user as "c_message" for xml raw,elements;
      return
    end if;
    select "n_qty_per_box" into @Qtp from "item_mst" where "c_code" = @ItemCode;
    if @Qtp is null then
      set @Qtp = 1
    end if;
    -----------------------------------------------------------
    --Validating same tray is been taken for another Supplier 
    --Saneesh 
    select top 1 "act_mst"."c_name"+'['+"c_supp_code"+']'
      into @st_track_stock_eb_supp from "st_track_stock_eb"
        join "act_mst" on "act_mst"."c_code" = "st_track_stock_eb"."c_supp_code"
      where "st_track_stock_eb"."c_tray_code" = @Godown_Tray_Code
      and "st_track_stock_eb"."c_supp_code" <> @ItemSuppCode
      and "n_qty" > 0;
    if @st_track_stock_eb_supp = '' or @st_track_stock_eb_supp is null then
    else
      select 'Warning!! ,Tray code '+@Godown_Tray_Code+' Already Taken for Supplier '+@st_track_stock_eb_supp as "c_message" for xml raw,elements;
      return
    end if;
    select "c_stin_ref_no"
      into @cStinRefNo from "st_track_det"
      where "c_item_code" = @ItemCode
      and "c_batch_no" = @BatchNo
      and "c_doc_no" = @DocNo
      and "n_seq" = @Seq;
    -----------------------------------------------------------
    --set @PickedQty = @PickedQty * @Qtp ;
    if @ForwardFlag = 1 then -- item done
      select("n_bal_qty"-@PickedQty)
        into @RemainingQty from "st_track_det"
        where "c_doc_no" = @DocNo
        and "n_inout" = @InOutFlag
        and "c_item_code" = @ItemCode
        and "n_seq" = @Seq
        and "isnull"("st_track_det"."c_godown_code",'-') = @GodownCode;
      update "st_track_det"
        set "n_complete" = (if @RemainingQty <= 0 then 8 else 0 endif),
        "n_bal_qty" = ("n_bal_qty"-@PickedQty),
        "c_user" = @UserId
        where "c_doc_no" = @DocNo
        and "n_inout" = @InOutFlag
        and "c_item_code" = @ItemCode
        and "n_seq" = @Seq
        and "isnull"("st_track_det"."c_godown_code",'-') = @GodownCode;
      set @RetStr
         = "uf_add_qarantine_stock"(
        @BrCode,@ItemCode,@BatchNo,@Godown_Tray_Code,@ItemSuppCode,@PickedQty,@DocNo,
        @Seq,@InOutFlag,@UserId,@cStinRefNo)
    elseif @ForwardFlag = 0 then -- shift back, 
      update "st_track_det"
        set "n_complete" = @ForwardFlag,
        "n_bal_qty" = ("n_bal_qty"+@PickedQty),
        "c_user" = null,
        "c_reason_code" = '-'
        where "c_doc_no" = @DocNo
        and "n_inout" = @InOutFlag
        and "c_item_code" = @ItemCode
        and "n_seq" = @Seq
        and "isnull"("st_track_det"."c_godown_code",'-') = @GodownCode;
      set @RetStr
         = "uf_add_qarantine_stock"(
        @BrCode,@ItemCode,@BatchNo,@Godown_Tray_Code,@ItemSuppCode,-1*@PickedQty,@DocNo,
        @Seq,@InOutFlag,@UserId,@cStinRefNo);
      --//Release godown tray code if there is no items in tht tray 
      if(select "isnull"("sum"("n_qty"),0) from "st_track_stock_eb" where "c_tray_code" = @Godown_Tray_Code and "c_doc_no" = @DocNo) <= 0 then //rels
        delete from "st_track_tray_move"
          where "c_tray_code" = @Godown_Tray_Code
          and "c_doc_no" = @DocNo
          and "isnull"("c_godown_code",'-') = @GodownCode;
        if sqlstate = '00000' or sqlstate = '02000' then
          commit work
        else
          rollback work
        -- item not found
        end if
      end if
    elseif @ForwardFlag = 2 then
      update "st_track_det"
        set "n_complete" = @ForwardFlag,
        "c_reason_code" = @ReasonCode
        where "c_doc_no" = @DocNo
        and "n_inout" = @InOutFlag
        and "c_item_code" = @ItemCode
        and "n_seq" = @Seq
        and "isnull"("st_track_det"."c_godown_code",'-') = @GodownCode
    elseif @ForwardFlag = 3 then -- shift back when item not found 
      update "st_track_det"
        set "n_complete" = 0,
        "c_user" = null,
        "c_reason_code" = '-'
        where "c_doc_no" = @DocNo
        and "n_inout" = @InOutFlag
        and "c_item_code" = @ItemCode
        and "n_seq" = @Seq
        and "isnull"("st_track_det"."c_godown_code",'-') = @GodownCode
    end if;
    if sqlstate = '00000' then
      commit work;
      select 'Success' as "c_message" for xml raw,elements
    else
      rollback work;
      select 'Failure' as "c_message" for xml raw,elements
    end if when 'document_done' then -----------------------------------------------------------------------
    --http://192.168.1.15:15503/ws_st_storein_quarantine?&cIndex=document_done&DocNo=1070819111510&HdrData=@detdata=InOutFlag^^Seq^^OrgSeq^^ItemCode^^BatchNo^^Qty^^HoldFlag^^cReason^^cNote^^CurrentTray^^RackCode^^CurrentGrp^^ItemNotFound^^Itemsuppcode^^Godown_Tray_Code||&GodownCode=5033&gsbr=503&UserId=SALES		
    set @DetData_for_stk_adj = @DetData;
    set @DetSuccessFlag = 0;
    while @DetData <> '' loop
      --@DetData : 1 InOutFlag~2 Seq~3 OrgSeq~4 ItemCode~5 BatchNo
      --~6 Qty~7 HoldFlag~8 cReason~9 cNote~10 CurrentTray
      --~11 RackCode~12 CurrentGrp~13 ItemNotFound
      --~14 Itemsuppcode ~15 Godown_Tray_Code
      --1 InOutFlag
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @InOutFlag = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --message 'InOutFlag '+string(@InOutFlag) type warning to client;
      --2 Seq
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @Seq = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --message 'Seq '+string(@Seq) type warning to client;
      --3 OrgSeq
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @OrgSeq = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --message 'OrgSeq '+String(@OrgSeq) type warning to client;
      --4 ItemCode
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @ItemCode = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --message 'ItemCode '+@ItemCode type warning to client;
      --5 BatchNo
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @BatchNo = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --message 'BatchNo '+@BatchNo type warning to client;
      --6 Qty
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @Qty = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --message 'Qty '+string(@Qty) type warning to client;
      --7 HoldFlag
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @HoldFlag = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --message 'HoldFlag '+string(@HoldFlag) type warning to client;
      --8 cReason
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @cReason = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --message 'cReason '+string(@cReason) type warning to client;
      --9 cNote
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @cNote = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --message 'cNote '+@cNote type warning to client;
      --10 CurrentTray
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @CurrentTray = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --message 'CurrentTray '+string(@CurrentTray) type warning to client;
      --print 'CurrentTray : '+string(@CurrentTray);
      --11 RackCode
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @RackCode = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --message 'RackCode '+@RackCode type warning to client;
      --12 CurrentGrp
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @CurrentGrp = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --message 'CurrentGrp '+@CurrentGrp type warning to client;
      --13 ItemNotFound
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @ItemNotFound = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --message 'ItemNotFound '+@ItemNotFound type warning to client;
      --14 ItemSuppCode
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @ItemSuppCode = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --15 Godown_Tray_Code
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @Godown_Tray_Code = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      select "Locate"(@DetData,@RowSep) into @RowPos;
      set @DetData = "SubString"(@DetData,@RowPos+@RowMaxLen);
      select "c_stin_ref_no","n_qty" into @cStinRefNo,@n_inward_qty
        from "st_track_det"
        where "c_tray_code" = @CurrentTray
        and "c_doc_no" = @DocNo
        and "n_seq" = @OrgSeq;
      --print @ItemNotFound ;
      if @ItemNotFound = 0 then
        set @an_item_pick_count = @an_item_pick_count+1;
        --Item is there in Tray 
        delete from "st_track_in"
          where "c_doc_no"+'/'+"string"("n_seq") = @cStinRefNo
          and "n_complete" = 9;
        --Delete from st_track_in will rels the item Hold
        select(if("n_bal_qty"-@Qty) < 0 then 0 else("n_bal_qty"-@Qty) endif)
          into @RemainingQty from "st_track_det"
          where "c_doc_no" = @DocNo
          and "n_inout" = @InOutFlag
          and "c_item_code" = @ItemCode
          and "n_seq" = @OrgSeq
          and "isnull"("st_track_det"."c_godown_code",'-') = @GodownCode
      else
        set @an_item_bounce_count = @an_item_bounce_count+1;
        delete from "st_track_in"
          where "c_doc_no"+'/'+"string"("n_seq") = @cStinRefNo
          and "n_complete" = 9;
        --Dalete from st_track_in will rels the item Hold
        update "st_track_det"
          set "n_complete" = 2 --item not found
          --, n_bal_qty = @RemainingQty
          where "c_doc_no" = @DocNo
          and "n_inout" = @InOutFlag
          and "c_item_code" = @ItemCode
          and "n_seq" = @OrgSeq
          and "isnull"("st_track_det"."c_godown_code",'-') = @GodownCode
      end if;
      if sqlstate = '00000' then
        commit work;
        set @DetSuccessFlag = 1
      else
        rollback work;
        set @DetSuccessFlag = 0
      end if;
      set @DetSuccessFlag = 1;
      -----------------------------------------------------------
      --saneesh 
      if((select "uf_table_check"('PROCEDURE','','uf_update_st_track_inward_history')) > 0) and(@ENABLE_INWARD_ITEM_TRACK = 1) then
        call "uf_update_st_track_inward_history"(
        @DocNo,
        @cStinRefNo,
        @ItemCode,
        @BatchNo,
        @Seq,
        @n_inward_qty,
        @Qty,
        @RackCode,
        @CurrentGrp,
        @StageCode,
        @CurrentTray,
        @Godown_Tray_Code,
        @GodownCode,
        @UserId)
      --saneesh 
      -----------------------------------------------------------
      --uf_pass_stock_adj_quarantine() was commented by saneesh Since Stock in pick /Exp godown already taken care.
      --set @RetStr = uf_pass_stock_adj_quarantine(@DetData_for_stk_adj,@gsBr,@GodownCode,@UserId,@DocNo);
      end if
    end loop;
    if @RetStr is null or "trim"(@RetStr) = '' then
    else
      select 'Failure'+@RetStr as "c_message" for xml raw,elements
    end if;
    if(select "count"("c_tray_code") from "st_track_tray_move" where "c_tray_code" = @CurrentTray) > 1 then
      if(select "count"() from "st_track_det" where "c_doc_no" = @DocNo and "c_tray_code" = @CurrentTray and "n_complete" in( 0 ) ) > 0 then --//Pend items are there ,Dont rels Tray 
      else
        --Tray need to clear from st_track_tray_move
        delete from "st_track_tray_move"
          where "c_tray_code" = @CurrentTray
          and "c_doc_no" = @DocNo
          and "isnull"("c_godown_code",'-') = @GodownCode;
        if sqlstate = '00000' or sqlstate = '02000' then
          commit work
        else
          rollback work
        end if end if end if;
    if(select "count"("c_doc_no") from "st_track_det" where("n_complete" = 0) and "c_doc_no" = @DocNo and "c_godown_code" = @GodownCode) = 0 then
      update "st_track_mst" set "c_phase_code" = 'PH0002',"n_complete" = 9 where "c_doc_no" = @DocNo;
      --update complete flag in st_track_stock_eb 
      update "st_track_stock_eb" set "n_complete" = 1 where "c_doc_no" = @DocNo;
      commit work
    end if;
    if @ItemsInDetail <> 1 then
      set @DetSuccessFlag = 1 --no det data to batch success flag
    end if;
    ---saneesh for capture Tray processing time 
    --//Rack grp and stage code will not getting in all serv call 
    select top 1 "c_user","c_rack_grp_code","c_stage_code"
      into @doc_user,@c_exp_rack_grp_code,@c_exp_stage_code
      from "st_track_det"
      where "st_track_det"."c_doc_no" = @DocNo
      and "isnull"("st_track_det"."c_godown_code",'-') = @GodownCode
      and "st_track_det"."n_complete" <> 8 and "st_track_det"."n_inout" = 1
      and "st_track_det"."c_tray_code" = @CurrentTray;
    call "uf_update_tray_time"(@DocNo,1,@CurrentTray,'STOREIN_EXP',@UserId,@c_exp_rack_grp_code,@c_exp_stage_code,2,null,@an_item_pick_count,@an_item_bounce_count);
    ---saneesh for capture Tray processing time 
    select '1|SUCCESS' as "c_message" for xml raw,elements
  when 'get_post_info' then
    --Index added By Saneesh on 20-06-2015 
    select "isnull"("c_post_user",'') as "c_post_user",
      "isnull"("t_post_time","now"()) as "t_time"
      from "pur_mst" where "n_post" = 1 and "c_br_code"+'/'+"c_year"+'/'+"c_prefix"+'/'+"string"("n_srno") = @HdrData union
    select "isnull"("c_post_user",'') as "c_post_user",
      "isnull"("t_post_time","now"()) as "t_time"
      from "grn_mst" where "n_post" = 1 and "c_br_code"+'/'+"c_year"+'/'+"c_prefix"+'/'+"string"("n_srno") = @HdrData for xml raw,elements;
    return
  when 'revert_doc' then
    --http://192.168.7.12:15503/ws_st_storein_quarantine?&cIndex=revert_doc&HdrData=15542^^&DocNo=155420160023751&GodownCode=-&gsbr=503&UserId=SALE
    --@HdrData-->CurrentTray~~
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @CurrentTray = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --@DetData
    --1 ItemCode~2 BatchNo~3 Seq~--4 Godown_Tray_Code--5 PickedQty--6 ItemSuppCode--7 @n_exp_ret_flag
    while @DetData <> '' loop
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @ItemCode = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --message 'ItemCode '+@ItemCode type warning to client;
      --2 BatchNo
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @BatchNo = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --message 'BatchNo '+@BatchNo type warning to client;	
      --3 Seq(OrgSeq)
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @Seq = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --4 Godown_Tray_Code
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @Godown_Tray_Code = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --5 PickedQty
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @PickedQty = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --6 ItemSuppCode
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @ItemSuppCode = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --7 @n_exp_ret_flag
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @n_exp_ret_flag = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      if @n_exp_ret_flag = 1 then --can't giv to supp ,Assign to dummy supp
        select top 1 "c_exp_ret_supp" into @c_exp_ret_SuppCode from "st_track_setup";
        if @c_exp_ret_SuppCode is null or "trim"(@c_exp_ret_SuppCode) = '' then
          select 'Warning!! ,Default Supplier Code is not updated !!' as "c_message" for xml raw,elements;
          return
        end if;
        set @ItemSuppCode = @c_exp_ret_SuppCode
      end if;
      --message 'Seq '+string(@Seq) type warning to client;	
      select "Locate"(@DetData,@RowSep) into @RowPos;
      set @DetData = "SubString"(@DetData,@RowPos+@RowMaxLen);
      update "st_track_det"
        set "n_bal_qty" = "n_qty","c_user" = null,"n_complete" = 0
        where "c_doc_no" = @DocNo
        and "c_tray_code" = @CurrentTray
        and "c_item_code" = @ItemCode
        and "c_batch_no" = @BatchNo
        and "n_seq" = @Seq
        and "st_track_det"."c_godown_code" = @GodownCode
        and "st_track_det"."c_user" = @UserId;
      select "n_qty_per_box" into @Qtp from "item_mst" where "c_code" = @ItemCode;
      if @Qtp is null then
        set @Qtp = 1
      end if;
      --set @PickedQty = @PickedQty * @Qtp ;
      set @RetStr
         = "uf_add_qarantine_stock"(
        @BrCode,@ItemCode,@BatchNo,@Godown_Tray_Code,@ItemSuppCode,-1*@PickedQty,@DocNo,
        @Seq,@InOutFlag,@UserId,@cStinRefNo);
      commit work;
      --//Release godown tray code if there is no items in tht tray 
      if(select "count"() from "st_track_tray_move" where "c_tray_code" = @Godown_Tray_Code and "c_doc_no" = @DocNo) > 0 then
        if(select "isnull"("sum"("n_qty"),0) from "st_track_stock_eb" where "c_tray_code" = @Godown_Tray_Code and "c_doc_no" = @DocNo) <= 0 then //rels
          delete from "st_track_tray_move"
            where "c_tray_code" = @Godown_Tray_Code
            and "c_doc_no" = @DocNo
            and "isnull"("c_godown_code",'-') = @GodownCode;
          if sqlstate = '00000' or sqlstate = '02000' then
            commit work
          else
            rollback work
          end if
        end if
      end if
    end loop;
    select '1|SUCCESS !!' as "c_message" for xml raw,elements
  when 'get_setup' then
    --http://192.168.7.12:15503/ws_st_storein_quarantine?&cIndex=get_setup
    select "c_exp_ret_supp",
      "act_mst"."c_name"
      from "st_track_setup"
        join "act_mst" on "act_mst"."c_code" = "st_track_setup"."c_exp_ret_supp" for xml raw,elements
  else
    select 'Invalid Index !!' as "c_message" for xml raw,elements
  end case
end;