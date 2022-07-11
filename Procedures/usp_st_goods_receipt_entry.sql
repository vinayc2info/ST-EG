CREATE PROCEDURE "DBA"."usp_st_goods_receipt_entry"( 
  in @gsBr char(6),
  in @devID char(200),
  in @UserId char(20),
  in @cIndex char(30),
  in @HdrData char(7000),
  in @item_code char(6),
  in @batch_no char(15),
  in @expiry_dt date,
  in @mrp char(6),
  in @recvd_qty char(6),
  in @tray_code char(6),
  in @carton_no char(6),
  in @reason_flag char(6),
  in @return_tray char(6),
  in @return_qty char(6) ) 
result( "is_xml_string" xml ) 
begin
  declare "ls_exception" long varchar;declare @sql_code numeric(20);
  declare @ire_srno numeric(18);
  declare @ire_prefix char(6);
  declare @year char(6);
  declare @BrCode char(6);
  declare @enable_log numeric(1);
  declare @gp_cnt_flag numeric(1);
  declare @TranBrCode char(6);
  declare @TranSrno numeric(18);
  declare @supp_code char(6);
  declare @rk_grp char(6);
  declare @min_qty numeric(8);
  declare @n_per_lock numeric(1);
  declare @n_lock numeric(1);
  declare @pending_ord_qty numeric(11);
  declare @sum_qty numeric(11);
  declare @sum_sch_qty numeric(11);
  declare @item_cnt numeric(2);
  declare @matched_row_cnt numeric(2);
  declare @recvd_avail_qty numeric(8);
  declare @pur_n_qty numeric(8);
  declare @pur_n_sch_qty numeric(8);
  declare @pur_srno numeric(18);
  declare @pur_seq numeric(4);
  declare @n_save numeric(1);
  declare @n_dynamic_flag integer;
  declare local temporary table "temp_batch_list"(
    "c_item_code" char(6) null,
    "c_batch_no" char(15) null,
    "d_exp_dt" date null,
    "n_mrp" numeric(11,3) null,
    "n_pur_rate" numeric(11,3) null,
    "n_sale_rate" numeric(11,3) null,
    "n_lock" numeric(1) null,
    "n_mrp_box" numeric(10,2) null,
    "n_pur_rate_box" numeric(11,3) null,
    "n_qty_per_box" numeric(4) null,
    "d_ldate" date null,
    "n_bal_qty" numeric(11,3) null,
    "n_hold_qty" numeric(11,3) null,
    "n_permanent_lock" numeric(1) null,
    "n_ptr_box" numeric(11,3) null,
    "n_ptr" numeric(11,3) null,) on commit preserve rows;
  declare local temporary table "temp_po_pending_list"(
    "n_order_srno" numeric(18) null,
    "d_order_dt" date null,
    "c_item_name" char(30) null,
    "c_item_code" char(6) null,
    "n_order_qty" numeric(11,3) null,
    "n_order_value" numeric(11) null,
    "n_order_pending_qty" numeric(11,3) null,
    "n_cancel" numeric(1) null,
    "n_order_seq" numeric(4) null,
    "n_act_type" numeric(2) null,
    "n_act_flag" numeric(1) null,
    "c_order_year" char(6) null,
    "n_stock_bal_qty" numeric(11,3) null,
    "c_mfac_name" char(30) null,
    "c_br_code" char(30) null,) on commit preserve rows;
  declare local temporary table "TEMP_PUR_MST_DET"(
    "c_br_code" char(30) null,
    "c_year" char(6) null,
    "c_prefix" char(6) null,
    "n_srno" numeric(18) null,
    "n_seq" numeric(4) null,
    "n_qty" numeric(11,3) null,
    "n_sch_qty" numeric(11,3) null,
    "c_item_code" char(6) null,
    "c_batch_no" char(15) null,) on commit preserve rows;
  if @devID = '' or @devID is null then
    set @gsBr = "http_variable"('gsBr');
    set @HdrData = "http_variable"('HdrData');
    set @devID = "http_variable"('devID');
    set @UserId = "http_variable"('UserId');
    set @cIndex = "http_variable"('cIndex');
    set @item_code = "http_variable"('itemCode');
    set @batch_no = "http_variable"('batchNo');
    set @expiry_dt = "http_variable"('ExpDt');
    set @mrp = "http_variable"('mrp');
    set @recvd_qty = "http_variable"('recvdQty');
    set @tray_code = "http_variable"('trayCode');
    set @carton_no = "http_variable"('cartonNo');
    set @reason_flag = "http_variable"('reasonFlag');
    set @return_tray = "http_variable"('returnTray');
    set @return_qty = "http_variable"('returnQty');
    set @n_save = "http_variable"('saveFlag')
  --    set @line_item_match_flag = "http_variable"('lineItemMatchFlag');
  end if;
  set @ire_prefix = '187';
  select "n_active" into @enable_log from "st_track_module_mst" where "st_track_module_mst"."c_code" = 'M00039';
  if @enable_log is null then
    set @enable_log = 0
  end if;
  set @BrCode = "uf_get_br_code"(@gsBr);
  set @TranSrno = @HdrData;
  case @cIndex
  when 'get_gate_pass_number' then
    /*
http://172.16.18.100:29503/ws_st_goods_receipt_entry?&cIndex=get_gate_pass_number&gsbr=503&HdrData=6262&UserId=MYBOSS
*/
    select "count"() into @gp_cnt_flag from "gate_pass_mst"
      where "gate_pass_mst"."c_br_code" = @BrCode
      and "gate_pass_mst"."c_prefix" = '163'
      and "gate_pass_mst"."n_srno" = @TranSrno;
    if
      @gp_cnt_flag = 0 then
      select 0 as "c_status",
        'Warning!! Gate Pass Number not available..' as "c_message" for xml raw,elements
    else
      select "c_supp_code" into @supp_code from "gate_pass_mst" where "n_srno" = @TranSrno;
      if
        (select "count"("ord_br"."n_srno")
          from "supp_ord_ledger" as "ord_br"
            ,"settle_mst_header" as "order_det"
            ,"act_mst"
            ,"item_mst","mfac_mst"
          where("order_det"."c_br_code" = @BrCode
          or if @BrCode = '000' then "order_det"."c_br_code" else 'xyz' endif <> if @BrCode = '000' then "order_det"."c_ref_br_code" else 'xyz' endif)
          and("order_det"."c_act_code" = @supp_code)
          and "ord_br"."c_br_code" = "order_det"."c_br_code"
          and "ord_br"."c_year" = "order_det"."c_year"
          and "ord_br"."c_prefix" = "order_det"."c_prefix"
          and "ord_br"."n_srno" = "order_det"."n_srno"
          and "ord_br"."c_item_code" = "item_mst"."c_code"
          and "item_mst"."c_mfac_code" = "mfac_mst"."c_code"
          and("ord_br"."n_qty"-"ord_br"."n_issue_qty"-"ord_br"."n_cancel_qty") > 0
          and "order_det"."c_act_code" = "act_mst"."c_code") <= 0 then
        select 0 as "c_status",
          'No Pending PO!, Cannot Select Supplier '+@supp_code+'. Since No Pending PO(s) Found.' as "c_message" for xml raw,elements
      else
        select 1 as "c_status",
          'Success' as "c_message" for xml raw,elements
      end if end if when 'item_check' then
    /*
http://172.16.18.100:29503/ws_st_goods_receipt_entry?&cIndex=item_check&gsbr=503&HdrData=6262&itemCode=203845&UserId=MYBOSS
*/
    select "c_rack_group","isnull"("Item_mst_br_det"."n_reorder_qty",0) into @rk_grp,@min_qty
      from "item_mst_br_info" join "rack_mst" on "item_mst_br_info"."c_br_code" = "rack_mst"."c_br_code" and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
        left outer join "Item_mst_br_det" on "Item_mst_br_det"."c_br_code" = "item_mst_br_info"."c_br_code" and "item_mst_br_info"."c_code" = "Item_mst_br_det"."c_code"
      where "item_mst_br_info"."c_br_code" = @BrCode
      and "item_mst_br_info"."c_code" = @item_code;
    if "isnull"(@rk_grp,'') = '' then
      select 0 as "c_status",
        'Rack Not Defined , Please define Rack in Item Rack Detail' as "c_message" for xml raw,elements
    else
      select "c_supp_code" into @supp_code from "gate_pass_mst" where "n_srno" = @TranSrno;
      if
        (select "count"("ord_br"."n_srno")
          from "supp_ord_ledger" as "ord_br"
            ,"settle_mst_header" as "order_det"
            ,"act_mst"
            ,"item_mst","mfac_mst"
          where("order_det"."c_br_code" = @BrCode
          or if @BrCode = '000' then "order_det"."c_br_code" else 'xyz' endif <> if @BrCode = '000' then "order_det"."c_ref_br_code" else 'xyz' endif)
          and("order_det"."c_act_code" = @supp_code)
          and "ord_br"."c_br_code" = "order_det"."c_br_code"
          and "ord_br"."c_year" = "order_det"."c_year"
          and "ord_br"."c_prefix" = "order_det"."c_prefix"
          and "ord_br"."n_srno" = "order_det"."n_srno"
          and "ord_br"."c_item_code" = "item_mst"."c_code"
          and "item_mst"."c_mfac_code" = "mfac_mst"."c_code"
          and("ord_br"."n_qty"-"ord_br"."n_issue_qty"-"ord_br"."n_cancel_qty") > 0
          and "order_det"."c_act_code" = "act_mst"."c_code"
          and "ord_br"."c_item_code" = @item_code) <= 0 then
        select 0 as "c_status",
          'Warning!!,  Item Code '+@item_code+' Not Found In Pending Order List, You Cannot Select This Item!!' as "c_message" for xml raw,elements
      else
        select 1 as "c_status",
          'Success' as "c_message" for xml raw,elements
      end if end if when 'get_batch_list' then
    /*
http://172.16.18.100:29503/ws_st_goods_receipt_entry?&cIndex=get_batch_list&gsbr=503&HdrData=6262&itemCode=202776UserId=MYBOSS
*/
    insert into "temp_batch_list"
      select "stock_mst"."c_item_code","stock_mst"."c_batch_no",
        "stock_mst"."d_exp_dt",
        if "item_mst"."n_rate_item_batchwise" = 0 then "stock_mst"."n_mrp" else "isnull"("item_rate"."n_mrp","stock_mst"."n_mrp") endif as "n_mrp",
        "stock_mst"."n_pur_rate",
        if "item_mst"."n_rate_item_batchwise" = 0 then "stock_mst"."n_sale_rate" else "isnull"("item_rate"."n_ptr","stock_mst"."n_sale_rate") endif as "n_sale_rate",
        "stock_mst"."n_lock",
        if "item_mst"."n_rate_item_batchwise" = 0 then "stock_mst"."n_mrp_box" else "isnull"("item_rate"."n_mrp_box","stock_mst"."n_mrp_box") endif as "n_mrp_box",
        "stock_mst"."n_pur_rate_box",
        "stock_mst"."n_qty_per_box",
        "stock_mst"."d_ldate",
        0 as "n_bal_qty",0 as "n_hold_qty",
        "stock_mst"."n_permanent_lock",
        "stock_mst"."n_ptr_box",
        "stock_mst"."n_ptr"
        from "stock_mst" /*left outer join "stock" on "stock_mst"."c_item_code" = "stock"."c_item_code" and "stock_mst"."c_batch_no" = "stock"."c_batch_no"*/
          left outer join(select "a"."c_item_code","a"."d_from_date","a"."n_ptr","a"."n_mrp","a"."n_ptr_box","a"."n_mrp_box"
            from "item_mst_rate" as "a"
              join(select "c_item_code","max"("d_from_date") as "dt"
                from "item_mst_rate","def_date" where "n_cancel_flag" = 0 and "d_from_date" <= "def_date"."d_date" group by "c_item_code") as "b" on "a"."c_item_code" = "b"."c_item_code" and "a"."d_from_date" = "b"."dt" and "a"."n_cancel_flag" = 0) as "item_rate"
          on "item_rate"."c_item_Code" = "stock_mst"."c_item_code"
          ,"item_mst"
        where("stock_mst"."c_item_code" = "item_mst"."c_code")
        /* and("stock"."c_br_code" = @BrCode)*/
        and("stock_mst"."c_item_code" = @item_code);
    select "c_item_code","c_batch_no","d_exp_dt","n_mrp","n_pur_rate",
      "n_sale_rate","n_lock","n_mrp_box","n_pur_rate_box","n_qty_per_box",
      "d_ldate","n_bal_qty","n_hold_qty","n_permanent_lock","n_ptr_box","n_ptr"
      from "temp_batch_list" where "c_item_code" = @item_code order by "d_exp_dt" desc for xml raw,elements
  when 'validate_batch' then
    /*
http://172.16.18.100:29503/ws_st_goods_receipt_entry?&cIndex=validate_batch&gsbr=503&HdrData=6262&itemCode=202776&batchNo=9S379&ExpDt=2031-03-31&mrp=1176.610recvdQty=35&UserId=MYBOSS
*/
    insert into "temp_batch_list"
      select "stock_mst"."c_item_code","stock_mst"."c_batch_no",
        "stock_mst"."d_exp_dt",
        if "item_mst"."n_rate_item_batchwise" = 0 then "stock_mst"."n_mrp" else "isnull"("item_rate"."n_mrp","stock_mst"."n_mrp") endif as "n_mrp",
        "stock_mst"."n_pur_rate",
        if "item_mst"."n_rate_item_batchwise" = 0 then "stock_mst"."n_sale_rate" else "isnull"("item_rate"."n_ptr","stock_mst"."n_sale_rate") endif as "n_sale_rate",
        "stock_mst"."n_lock",
        if "item_mst"."n_rate_item_batchwise" = 0 then "stock_mst"."n_mrp_box" else "isnull"("item_rate"."n_mrp_box","stock_mst"."n_mrp_box") endif as "n_mrp_box",
        "stock_mst"."n_pur_rate_box",
        "stock_mst"."n_qty_per_box",
        "stock_mst"."d_ldate",
        ("isnull"("stock"."n_bal_qty",0)-"isnull"("stock"."n_dc_inv_qty",0)-"isnull"("stock"."n_hold_qty",0)) as "n_bal_qty",
        ("isnull"("stock"."n_hold_qty",0)) as "n_hold_qty",
        "stock_mst"."n_permanent_lock",
        "stock_mst"."n_ptr_box",
        "stock_mst"."n_ptr"
        from "stock_mst" left outer join "stock" on "stock_mst"."c_item_code" = "stock"."c_item_code" and "stock_mst"."c_batch_no" = "stock"."c_batch_no"
          left outer join(select "a"."c_item_code","a"."d_from_date","a"."n_ptr","a"."n_mrp","a"."n_ptr_box","a"."n_mrp_box"
            from "item_mst_rate" as "a"
              join(select "c_item_code","max"("d_from_date") as "dt"
                from "item_mst_rate","def_date" where "n_cancel_flag" = 0 and "d_from_date" <= "def_date"."d_date" group by "c_item_code") as "b" on "a"."c_item_code" = "b"."c_item_code"
              and "a"."d_from_date" = "b"."dt" and "a"."n_cancel_flag" = 0) as "item_rate"
          on "item_rate"."c_item_Code" = "stock_mst"."c_item_code"
          ,"item_mst"
        where("stock_mst"."c_item_code" = "item_mst"."c_code")
        and("stock"."c_br_code" = @BrCode)
        and("stock_mst"."c_item_code" = @item_code);
    select "count"("c_item_code") into @n_per_lock from "temp_batch_list" where "c_item_code" = @item_code and "c_batch_no" = @batch_no and "n_permanent_lock" = 1;
    select "count"("c_item_code") into @n_lock from "temp_batch_list" where "c_item_code" = @item_code and "c_batch_no" = @batch_no and "n_lock" = 1;
    if @n_per_lock > 0 then
      select 0 as "c_status",
        'Batch has Locked Permanently!','As batch '+@batch_no+' of item '+@item_code+' is locked Permanently, You cannot make invoice.' as "c_message" for xml raw,elements
    else
      if @n_lock > 0 then
        select 0 as "c_status",
          'Batch has locked!','As batch '+@batch_no+' of item '+@item_code+' is locked, You Cannot Bill.' as "c_message" for xml raw,elements
      else
        select 1 as "c_status",
          'Success' as "c_message" for xml raw,elements
      end if end if when 'get_carton' then
    /*
http://172.16.18.100:29503/ws_st_goods_receipt_entry?&cIndex=get_carton&gsbr=503&HdrData=6262&itemCode=202776&batchNo=9S379&ExpDt=2031-03-31&mrp=1176.610recvdQty=35&UserId=MYBOSS
*/
    select top 50 "a"."c_code" as "c_code"
      from "st_tray_mst" as "a"
        join "st_tray_type_mst" as "c" on "a"."c_tray_type_code" = "c"."c_code"
        left outer join "st_track_in" as "b" on "a"."c_code" = "b"."c_tray_code"
        left outer join "st_track_tray_move" as "d" on "a"."c_code" = "d"."c_tray_code"
        left outer join(select "m"."c_doc_no","m"."d_date","d"."c_tray_code"
          from "st_track_det" as "d" join "st_track_mst" as "m" on "m"."c_doc_no" = "d"."c_doc_no" and "m"."n_inout" = "d"."n_inout" and "date"("m"."t_time_in") = "today"()) as "st"
        on "st"."c_tray_code" = "b"."c_tray_code"
      where "b"."c_tray_code" is null and "d"."c_tray_code" is null and "st"."c_tray_code" is null
      and "a"."n_in_out_flag" = 3 order by 1 asc for xml raw,elements
  when 'qty_check' then
    /*
http://172.16.18.100:29503/ws_st_goods_receipt_entry?&cIndex=qty_check&gsbr=503&HdrData=6262&itemCode=202776&batchNo=9S379&ExpDt=2031-03-31&mrp=1176.610&recvdQty=35&UserId=MYBOSS
*/
    select "c_supp_code" into @supp_code from "gate_pass_mst" where "n_srno" = @TranSrno;
    insert into "temp_po_pending_list"
      select("ord_br"."n_srno") as "OrdNo",
        ("order_det"."d_date") as "PoDt",
        ("item_mst"."c_name") as "ItemName",
        ("ord_br"."c_item_code") as "ItemCode",
        cast((("ord_br"."n_qty"-"ord_br"."n_issue_qty"-"ord_br"."n_cancel_qty")/"item_mst"."n_qty_per_box") as numeric(8)) as "PoQty",
        cast((("ord_br"."n_qty"-"ord_br"."n_issue_qty"-"ord_br"."n_cancel_qty")/"item_mst"."n_qty_per_box")*"n_rate"*(1-"n_disc_per"/100) as numeric(14,2)) as "PoVal",
        ("ord_br"."n_qty"-"ord_br"."n_issue_qty"-"ord_br"."n_cancel_qty") as "qty",
        0 as "n_cancel",
        ("ord_br"."n_seq") as "ordseq",
        ("act_mst"."n_type") as "ActType",
        ("act_mst"."n_flag") as "Actflag",("ord_br"."c_year") as "Ordyear",
        "Isnull"((select "sum"("stock"."n_bal_qty"-"stock"."n_dc_inv_qty"-"stock"."n_hold_qty")/"item_mst"."n_qty_per_box" from "stock"
          where "stock"."c_br_code" = "ord_br"."c_br_code"
          and "stock"."c_item_code" = "ord_br"."c_item_code"),0) as "n_bal_qty",
        "mfac_mst"."c_name","ord_br"."c_ref_br_code"
        from "supp_ord_ledger" as "ord_br"
          ,"settle_mst_header" as "order_det"
          ,"act_mst"
          ,"item_mst","mfac_mst"
        where("order_det"."c_br_code" = @BrCode
        or if @BrCode = '000' then "order_det"."c_br_code" else 'xyz' endif <> if @BrCode = '000' then "order_det"."c_ref_br_code" else 'xyz' endif)
        and("order_det"."c_act_code" = @supp_code)
        and "ord_br"."c_br_code" = "order_det"."c_br_code"
        and "ord_br"."c_year" = "order_det"."c_year"
        and "ord_br"."c_prefix" = "order_det"."c_prefix"
        and "ord_br"."n_srno" = "order_det"."n_srno"
        and "ord_br"."c_item_code" = "item_mst"."c_code"
        and "item_mst"."c_mfac_code" = "mfac_mst"."c_code"
        and("ord_br"."n_qty"-"ord_br"."n_issue_qty"-"ord_br"."n_cancel_qty") > 0
        and "order_det"."c_act_code" = "act_mst"."c_code" and "ord_br"."c_item_code" = @item_code
        group by "OrdNo",
        "PoDt",
        "ItemName",
        "ItemCode",
        "PoQty",
        "PoVal",
        "Ordseq",
        "ActType",
        "Actflag","qty","Ordyear","ord_br"."c_br_code","item_mst"."n_qty_per_box",
        "mfac_mst"."c_name","ord_br"."c_ref_br_code";
    select "sum"("n_order_qty") into @pending_ord_qty from "temp_po_pending_list" where "c_item_code" = @item_code;
    if "isnull"(@pending_ord_qty,0) < "isnull"(@recvd_qty,0) then
      select 2 as "c_status",
        @recvd_qty-@pending_ord_qty as "diff_qty",
        'Excess Qty: Received Qty is More than the Order Pending Qty, Order Pending Qty is: '+"trim"("str"(@pending_ord_qty))+' and the Excess Qty is: '+"trim"("str"(@recvd_qty-@pending_ord_qty)) as "c_message" for xml raw,elements
    else
      select 0 as "c_status",
        'Success' as "c_message" for xml raw,elements
    end if when 'line_item_done' then
    /*
http://172.16.18.100:29503/ws_st_goods_receipt_entry?&cIndex=line_item_done&gsbr=503&HdrData=6262&itemCode=202776&batchNo=9S379&ExpDt=2031-03-31&mrp=1176.610
&recvdQty=19&trayCode=&cartonNo=2941&reasonFlag=0&returnTray=&returnQty=&saveFlag=9&devID=&UserId=MYBOSS
*/
    select if "c_default_godown_code" = '-' then
        if "max"("n_rack_max_qty") < "sum"("n_bal_qty")+@recvd_qty then 1 else 0 endif
      else
        if "max"("n_max_qty_capacity") < "sum"("n_bal_qty")+@recvd_qty then 1 else 0 endif
      endif as "dynamic_flag"
      into @n_dynamic_flag
      from "stock"
        join "item_mst_br_info" on "stock"."c_item_code" = "item_mst_br_info"."c_code" and "stock"."c_br_code" = "item_mst_br_info"."c_br_code"
        left outer join "item_mst_br_info_godown" on "item_mst_br_info_godown"."c_br_code" = "item_mst_br_info"."c_br_code"
        and "item_mst_br_info_godown"."c_code" = "item_mst_br_info"."c_code"
        and "item_mst_br_info_godown"."c_godown_code" = "item_mst_br_info"."c_default_godown_code"
      where "item_mst_br_info"."c_br_code" = "uf_get_br_code"(@gsbr) and "item_mst_br_info"."c_code" = @item_code --'243472'
      group by "c_default_godown_code";
    insert into "temp_pur_mst_det"
      select "pur_det"."c_br_code",
        "pur_det"."c_year",
        "pur_det"."c_prefix",
        "pur_det"."n_srno",
        "n_seq",
        "n_qty",
        "n_sch_qty",
        "c_item_code",
        "c_batch_no"
        from "pur_mst" join "pur_det" on "pur_mst"."c_br_code" = "pur_det"."c_br_code" and "pur_mst"."c_year" = "pur_det"."c_year" and "pur_mst"."c_prefix" = "pur_det"."c_prefix" and "pur_mst"."n_srno" = "pur_det"."n_srno"
        where "pur_mst"."n_gate_pass_no" = @TranSrno
        and "c_item_code" = @item_code
        and if "uf_get_para_value"(@BrCode,@UserId,'P00403','W00286') = 1 then
          "replace"("replace"("replace"("replace"("c_batch_no",'O','0'),'I','1'),'B','8'),'S','5')
        else
          "c_batch_no"
        endif
         = if "uf_get_para_value"(@BrCode,@UserId,'P00403','W00286') = 1 then
          "replace"("replace"("replace"("replace"(@batch_no,'O','0'),'I','1'),'B','8'),'S','5')
        else
          @batch_no
        endif
        and "month"(@expiry_dt) = "month"("pur_det"."d_expiry_date")
        and "year"(@expiry_dt) = "year"("pur_det"."d_expiry_date")
        and "pur_det"."n_mrp" = @mrp
        and "pur_det"."n_post" = 0;
    //print '1';
    select "count"("c_item_code") into @item_cnt from "temp_pur_mst_det";
    //print '2';
    select "sum"("n_qty"),"sum"("n_sch_qty") into @sum_qty,@sum_sch_qty from "temp_pur_mst_det";
    //print '3';
    select "count"("c_item_code") into @matched_row_cnt from "temp_pur_mst_det" where(@sum_qty+@sum_sch_qty) = @recvd_qty;
    //print '4';
    if @recvd_qty = (@sum_qty+@sum_sch_qty) or @matched_row_cnt > 0 then
      //print '5';
      //PRINT '@matched_row_cnt';
      //PRINT @matched_row_cnt;
      //PRINT '@recvd_qty';
      //PRINT @recvd_qty;
      //PRINT '@sum_qty';
      //PRINT @sum_qty;
      //PRINT '@sum_sch_qty';
      //PRINT @sum_sch_qty;
      if @recvd_qty <> (@sum_qty+@sum_sch_qty) and @matched_row_cnt > 0 then
        //print '6';
        select "right"("db_name"(),2) into @year;
        //print '7';
        update "prefix_serial_no" set "n_sr_number" = "n_sr_number"+1 where "c_br_code" = @BrCode and "c_year" = @year and "c_prefix" = @ire_prefix and "C_TRANS" = 'ITRE';
        //print '8';
        select "n_sr_number" into @ire_srno from "prefix_serial_no" where "c_br_code" = @BrCode and "c_year" = @year and "c_prefix" = @ire_prefix and "C_TRANS" = 'ITRE';
        //print '9';
        if @tray_code = '' then
          set @tray_code = null
        end if;
        insert into "item_receipt_entry"
          ( "c_br_code","c_year","c_prefix","n_srno","n_seq","n_pk","c_user","n_gate_pass_no","c_item_code","c_batch_no","n_mrp","d_expiry_date","n_type","c_tray_code","n_carton_no",
          "n_qty","n_pur_pk","c_pur_br_code","c_pur_year","c_pur_prefix","n_pur_srno","n_pur_seq","d_date","d_ldate","t_time","t_ltime","t_start_time","t_end_time","c_posted_user",
          "d_posted_date","d_store_in_time","c_store_in_user","n_dynamic_flag" ) 
          select top 1
            @BrCode,@year,@ire_prefix,@ire_srno,1,null,@UserId,@TranSrno,@item_code,@batch_no,@mrp,@expiry_dt,1,@tray_code,@carton_no,@recvd_qty,null,
            "c_br_code","c_year","c_prefix","n_srno","n_seq","today"(),null,null,"now"(),"now"(),"now"(),@UserId,"today"(),null,null,@n_dynamic_flag
            from "temp_pur_mst_det" where("n_qty"+"n_sch_qty") = @recvd_qty and "c_item_code" = @item_code and "c_batch_no" = @batch_no;
        if sqlstate = '00000' then
          commit work;
          select 1 as "c_status",
            'Success' as "c_message" for xml raw,elements
        else
          rollback work;
          select 0 as "c_status",
            'Failure' as "c_message" for xml raw,elements
        //PRINT '1A';
        end if
      else if @matched_row_cnt > 1 and @recvd_qty = (@sum_qty+@sum_sch_qty) then
          //PRINT '1B';
          set @recvd_avail_qty = @recvd_qty;
          while @recvd_avail_qty <> 0 loop
            select top 1 "pur_det"."n_qty","pur_det"."n_sch_qty","pur_det"."n_srno","pur_det"."n_seq" into @pur_n_qty,@pur_n_sch_qty,@pur_srno,@pur_seq
              from "pur_mst" join "pur_det" on "pur_mst"."c_br_code" = "pur_det"."c_br_code" and "pur_mst"."c_year" = "pur_det"."c_year" and "pur_mst"."c_prefix" = "pur_det"."c_prefix" and "pur_mst"."n_srno" = "pur_det"."n_srno"
              where "pur_mst"."n_gate_pass_no" = @TranSrno
              and "c_item_code" = @item_code
              and "replace"("replace"("replace"("replace"("c_batch_no",'O','0'),'I','1'),'B','8'),'S','5') = "replace"("replace"("replace"("replace"(@batch_no,'O','0'),'I','1'),'B','8'),'S','5')
              and "month"(@expiry_dt) = "month"("pur_det"."d_expiry_date")
              and "year"(@expiry_dt) = "year"("pur_det"."d_expiry_date")
              and "pur_det"."n_mrp" = @mrp
              and "pur_det"."n_post" = 0;
            select "right"("db_name"(),2) into @year;
            update "prefix_serial_no" set "n_sr_number" = "n_sr_number"+1 where "c_br_code" = @BrCode and "c_year" = @year and "c_prefix" = @ire_prefix and "C_TRANS" = 'ITRE';
            select "n_sr_number" into @ire_srno from "prefix_serial_no" where "c_br_code" = @BrCode and "c_year" = @year and "c_prefix" = @ire_prefix and "C_TRANS" = 'ITRE';
            if @tray_code = '' then
              set @tray_code = null
            end if;
            insert into "item_receipt_entry"
              ( "c_br_code","c_year","c_prefix","n_srno","n_seq","n_pk","c_user","n_gate_pass_no","c_item_code","c_batch_no","n_mrp","d_expiry_date","n_type","c_tray_code","n_carton_no",
              "n_qty","n_pur_pk","c_pur_br_code","c_pur_year","c_pur_prefix","n_pur_srno","n_pur_seq","d_date","d_ldate","t_time","t_ltime","t_start_time","t_end_time","c_posted_user",
              "d_posted_date","d_store_in_time","c_store_in_user","n_dynamic_flag" ) 
              select top 1
                @BrCode,@year,@ire_prefix,@ire_srno,1,null,@UserId,@TranSrno,@item_code,@batch_no,@mrp,@expiry_dt,1,@tray_code,@carton_no,@pur_n_qty+@pur_n_sch_qty,null,
                "c_br_code","c_year","c_prefix",@pur_srno,@pur_seq,"today"(),null,null,"now"(),"now"(),"now"(),@UserId,"today"(),null,null,@n_dynamic_flag
                from "temp_pur_mst_det" where @sum_qty+@sum_sch_qty = @recvd_qty and "c_item_code" = @item_code and "c_batch_no" = @batch_no and "n_srno" = @pur_srno and "n_seq" = @pur_seq;
            set @recvd_avail_qty = @recvd_avail_qty-(@pur_n_qty+@pur_n_sch_qty);
            if sqlstate = '00000' then
              commit work
            else
              rollback work
            end if
          end loop;
          if sqlstate = '00000' then
            commit work;
            select 1 as "c_status",
              'Success' as "c_message" for xml raw,elements
          else
            rollback work;
            select 0 as "c_status",
              'Failure' as "c_message" for xml raw,elements
          //PRINT '2A'; 
          end if
        else select "right"("db_name"(),2) into @year;
          if @tray_code = '' then
            set @tray_code = null
          end if;
          update "prefix_serial_no" set "n_sr_number" = "n_sr_number"+1 where "c_br_code" = @BrCode and "c_year" = @year and "c_prefix" = @ire_prefix and "C_TRANS" = 'ITRE';
          //PRINT '2B'; 
          select "n_sr_number" into @ire_srno from "prefix_serial_no" where "c_br_code" = @BrCode and "c_year" = @year and "c_prefix" = @ire_prefix and "C_TRANS" = 'ITRE';
          //PRINT '2C'; 
          insert into "item_receipt_entry"
            ( "c_br_code","c_year","c_prefix","n_srno","n_seq","n_pk","c_user","n_gate_pass_no","c_item_code","c_batch_no","n_mrp","d_expiry_date","n_type","c_tray_code","n_carton_no",
            "n_qty","n_pur_pk","c_pur_br_code","c_pur_year","c_pur_prefix","n_pur_srno","n_pur_seq","d_date","d_ldate","t_time","t_ltime","t_start_time","t_end_time","c_posted_user",
            "d_posted_date","d_store_in_time","c_store_in_user","n_dynamic_flag" ) 
            select top 1
              @BrCode,@year,@ire_prefix,@ire_srno,1,null,@UserId,@TranSrno,@item_code,@batch_no,@mrp,@expiry_dt,1,@tray_code,@carton_no,@recvd_qty,null,
              "c_br_code","c_year","c_prefix","n_srno","n_seq","today"(),null,null,"now"(),"now"(),"now"(),@UserId,"today"(),null,null,@n_dynamic_flag
              from "temp_pur_mst_det" where @sum_qty+@sum_sch_qty = @recvd_qty and "c_item_code" = @item_code and "c_batch_no" = @batch_no;
          if sqlstate = '00000' then
            commit work;
            select 1 as "c_status",
              'Success' as "c_message" for xml raw,elements
          else
            rollback work;
            select 0 as "c_status",
              'Failure' as "c_message" for xml raw,elements
          end if
        end if
      end if
    else select "right"("db_name"(),2) into @year;
      if @recvd_qty <> (@sum_qty+@sum_sch_qty) or @matched_row_cnt <= 0 and @n_save <> 1 then
        if @n_save = 9 then //default value  = 9 to save the record 
          select 'Did not find any match, Do you want to save?' as "c_message" for xml raw,elements
        else
          return
        end if
      else update "prefix_serial_no" set "n_sr_number" = "n_sr_number"+1 where "c_br_code" = @BrCode and "c_year" = @year and "c_prefix" = @ire_prefix and "C_TRANS" = 'ITRE';
        select "n_sr_number" into @ire_srno from "prefix_serial_no" where "c_br_code" = @BrCode and "c_year" = @year and "c_prefix" = @ire_prefix and "C_TRANS" = 'ITRE';
        if @tray_code = '' then
          set @tray_code = null
        end if;
        insert into "item_receipt_entry"
          ( "c_br_code","c_year","c_prefix","n_srno","n_seq","n_pk","c_user","n_gate_pass_no","c_item_code","c_batch_no","n_mrp","d_expiry_date","n_type","c_tray_code","n_carton_no","n_qty","n_pur_pk",
          "c_pur_br_code","c_pur_year","c_pur_prefix","n_pur_srno","n_pur_seq","d_date","d_ldate","t_time","t_ltime","t_start_time","t_end_time","c_posted_user","d_posted_date","d_store_in_time","c_store_in_user","n_dynamic_flag" ) values
          ( @BrCode,@year,@ire_prefix,@ire_srno,1,null,@UserId,@TranSrno,@item_code,@batch_no,@mrp,@expiry_dt,0,@tray_code,@carton_no,@recvd_qty,
          null,null,null,null,null,null,"today"(),null,null,"now"(),"now"(),"now"(),null,null,null,null,@n_dynamic_flag ) ;
        if sqlstate = '00000' then
          commit work;
          select 1 as "c_status",
            'Success' as "c_message" for xml raw,elements
        else
          rollback work;
          select 0 as "c_status",
            'Failure' as "c_message" for xml raw,elements
        end if end if end if when 'post_result' then
    /*
http://172.16.18.100:19503/ws_st_goods_receipt_entry?&cIndex=post_result&gsbr=503&HdrData=6425&itemCode=322968&batchNo=AMES0054&trayCode=10016&cartonNo=&devID=&UserId=MYBOSS
*/
    select "item_receipt_entry"."n_gate_pass_no" as "gate_pass_no",
      "item_receipt_entry"."c_item_code" as "item_code",
      "item_mst"."c_name" as "item_name",
      "item_receipt_entry"."c_batch_no" as "batch_no",
      "item_receipt_entry"."d_expiry_date" as "exp_date",
      "item_receipt_entry"."n_mrp" as "mrp",
      if "item_receipt_entry"."n_type" = 1 then 'Post' else 'Un Post' endif as "post_status",
      "item_receipt_entry"."c_tray_code" as "tray_code",
      "item_receipt_entry"."n_carton_no" as "carton_no",
      "item_receipt_entry"."n_qty" as "qty",
      "rack_mst"."c_rack_grp_code" as "rack_grp_code",
      "rack_mst"."c_code" as "rack_code",
      "item_receipt_entry"."c_pur_br_code"+'/'+"item_receipt_entry"."c_pur_year"+'/'+"item_receipt_entry"."c_pur_prefix"+'/'+"string"("item_receipt_entry"."n_pur_srno") as "doc_no"
      from "item_receipt_entry"
        left outer join "item_mst_br_info" on "item_mst_br_info"."c_code" = "item_receipt_entry"."c_item_code" and "item_mst_br_info"."c_br_code" = "item_receipt_entry"."c_br_code"
        left outer join "item_mst" on "item_mst"."c_code" = "item_receipt_entry"."c_item_code"
        left outer join "rack_mst" on "rack_mst"."c_code" = "item_mst_br_info"."c_rack" and "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
      where("item_receipt_entry"."c_tray_code" = @tray_code or "item_receipt_entry"."n_carton_no" = @carton_no)
      and "item_receipt_entry"."c_item_code" = @item_code
      and "item_receipt_entry"."c_batch_no" = @batch_no
      and "item_receipt_entry"."n_gate_pass_no" = @TranSrno for xml raw,elements
  when 'barcode_reprint' then
    /*
http://172.16.18.100:19503/ws_st_goods_receipt_entry?&cIndex=barcode_reprint&gsbr=503&itemCode=322968&devID=&UserId=MYBOSS
*/
    select "item_receipt_entry"."n_pk",
      "item_receipt_entry"."n_seq",
      "item_receipt_entry"."c_user",
      "item_receipt_entry"."n_gate_pass_no",
      ("gate_pass_mst"."d_date") as "gate_pass_date",
      ("act_mst"."c_name") as "supp_name",
      ("item_receipt_entry"."d_date") as "conflict_date",
      "item_receipt_entry"."c_item_code",
      "item_receipt_entry"."c_batch_no",
      "item_receipt_entry"."n_mrp",
      "item_receipt_entry"."d_expiry_date",
      "item_receipt_entry"."n_type",
      "item_receipt_entry"."c_tray_code",
      "item_receipt_entry"."n_carton_no",
      "item_receipt_entry"."n_qty",
      "item_receipt_entry"."n_pur_pk",
      "item_receipt_entry"."c_pur_br_code",
      "item_receipt_entry"."c_pur_year",
      "item_receipt_entry"."c_pur_prefix",
      "item_receipt_entry"."n_pur_srno",
      "item_receipt_entry"."n_pur_seq",
      "item_receipt_entry"."c_br_code",
      "item_receipt_entry"."c_year",
      "item_receipt_entry"."c_prefix",
      "item_receipt_entry"."n_srno",
      "item_mst"."c_name",
      ("rack_mst"."c_rack_grp_code") as "pick_rg",
      ("item_mst_br_info"."c_rack") as "pick_rack",
      "c_default_godown_code",
      ("item_mst_br_info_godown"."c_rack") as "gdwn_rack",
      ("rg"."c_rack_grp_code") as "gdwn_rg",
      "rsm"."c_stage_grp_code"
      from "item_receipt_entry" join "item_mst" on "item_mst"."c_code" = "item_receipt_entry"."c_item_code"
        join "gate_pass_mst" on "item_receipt_entry"."n_gate_pass_no" = "gate_pass_mst"."n_srno"
        join "act_mst" on "gate_pass_mst"."c_supp_code" = "act_mst"."c_code"
        left outer join "st_track_in" on "st_track_in"."c_doc_no" = "item_receipt_entry"."c_pur_br_code"+'/'+"item_receipt_entry"."c_pur_year"+'/'+"item_receipt_entry"."c_pur_prefix"+'/'+"string"("item_receipt_entry"."n_pur_srno")
        and "st_track_in"."n_seq" = "item_receipt_entry"."n_pur_seq"
        left outer join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "item_receipt_entry"."c_br_code" and "item_receipt_entry"."c_item_code" = "item_mst_br_info"."c_code"
        left outer join "rack_mst" on "item_mst_br_info"."c_br_code" = "rack_mst"."c_br_code" and "rack_mst"."c_code" = "item_mst_br_info"."c_rack"
        left outer join "item_mst_br_info_godown" on "item_mst_br_info_godown"."c_code" = "item_mst_br_info"."c_code"
        and "item_mst_br_info_godown"."c_br_code" = "item_mst_br_info"."c_br_code"
        and "item_mst_br_info_godown"."c_godown_code" = "item_mst_br_info"."c_default_godown_code"
        left outer join "rack_mst" as "rg" on "item_mst_br_info_godown"."c_br_code" = "rg"."c_br_code" and "rg"."c_code" = "item_mst_br_info_godown"."c_rack"
        left outer join "st_store_stage_det" as "rsd" on "rsd"."c_rack_grp_code" = "rack_mst"."c_rack_grp_code"
        left outer join "st_store_stage_mst" as "rsm" on "rsm"."c_code" = "rsd"."c_stage_code" and "rsm"."c_br_code" = "rsd"."c_br_code"
      where "item_receipt_entry"."n_type" in( 1,3,4 ) and "item_receipt_entry"."c_item_code" = @item_code
      and "item_receipt_entry"."n_carton_no" >= 0
      and "st_track_in"."n_complete" = 0 for xml raw,elements
  when 'pending_line_item_list' then
    /*
http://172.16.18.201:19503/ws_st_goods_receipt_entry?&cIndex=pending_line_item_list&gsbr=503&devID=&UserId=MYBOSS
*/
    select "item_receipt_entry"."n_pk",
      "item_receipt_entry"."n_seq",
      "item_receipt_entry"."c_user",
      "item_receipt_entry"."n_gate_pass_no",
      ("gate_pass_mst"."d_date") as "gate_pass_date",
      ("act_mst"."c_name") as "supp_name",
      ("item_receipt_entry"."d_date") as "conflict_date",
      "item_receipt_entry"."c_item_code",
      "item_receipt_entry"."c_batch_no",
      "item_receipt_entry"."n_mrp",
      "item_receipt_entry"."d_expiry_date",
      "item_receipt_entry"."n_type",
      "item_receipt_entry"."c_tray_code",
      "item_receipt_entry"."n_carton_no",
      "item_receipt_entry"."n_qty",
      "item_receipt_entry"."n_pur_pk",
      "item_receipt_entry"."c_pur_br_code",
      "item_receipt_entry"."c_pur_year",
      "item_receipt_entry"."c_pur_prefix",
      "item_receipt_entry"."n_pur_srno",
      "item_receipt_entry"."n_pur_seq",
      "item_receipt_entry"."c_br_code",
      "item_receipt_entry"."c_year",
      "item_receipt_entry"."c_prefix",
      "item_receipt_entry"."n_srno",
      "item_mst"."c_name",
      "item_mst_br_info"."c_rack",
      "rack_mst"."c_rack_grp_code"
      from "item_receipt_entry" join "item_mst" on "item_mst"."c_code" = "item_receipt_entry"."c_item_code"
        join "gate_pass_mst" on "item_receipt_entry"."n_gate_pass_no" = "gate_pass_mst"."n_srno"
        join "item_mst_br_info" on "item_mst_br_info"."C_CODE" = "item_receipt_entry"."C_ITEM_CODE"
        and "item_mst_br_info"."C_BR_CODE" = "item_receipt_entry"."c_br_code"
        join "rack_mst" on "rack_mst"."c_code" = "item_mst_br_info"."c_rack" and "item_mst_br_info"."C_br_CODE" = "rack_mst"."c_br_code"
        join "act_mst" on "gate_pass_mst"."c_supp_code" = "act_mst"."c_code"
      where "item_receipt_entry"."n_type" = 0 for xml raw,elements
  when 'barcode_scan' then
    /*
http://172.16.18.100:29503/ws_st_goods_receipt_entry?&cIndex=get_batch_list&gsbr=503&HdrData=6262&itemCode=202776UserId=MYBOSS
*/
    select "stock_mst"."c_batch_no",
      "stock_mst"."d_exp_dt",
      "stock_mst"."n_sale_rate",
      "stock_mst"."n_mrp",
      "stock_mst"."n_pur_rate",
      "stock_mst"."n_eff_pur_rate",
      "stock_mst"."n_lock",
      "stock_mst"."n_mrp_box",
      "stock_mst"."n_pur_rate_box",
      "stock_mst"."n_qty_per_box",
      "stock_mst"."d_ldate",
      "isnull"("stock"."n_bal_qty",0)-"isnull"("stock"."n_dc_inv_qty",0)-"isnull"("stock"."n_hold_qty",0) as "n_bal_qty",
      "item_mst"."c_name",
      "pack_mst"."c_name",
      "stock_mst"."c_item_code",
      "uf_default_date"() as "def_Date",
      "item_mst"."c_barcode"
      from "stock_mst"
        ,"stock"
        ,"item_mst"
        ,"pack_mst"
      where("stock"."c_item_code" = "stock_mst"."c_item_code")
      and("stock"."c_batch_no" = "stock_mst"."c_batch_no")
      and("stock_mst"."c_item_code" = "item_mst"."c_code")
      and("item_mst"."c_pack_code" = "pack_mst"."c_code")
      and("stock"."c_br_code" = @gsBr)
      and("item_mst"."c_barcode" = @HdrData or "item_mst"."c_code" = @HdrData) union
    //			AND  ( stock.n_bal_qty > 0 or item_mst.n_service_item=1 ) 
    select "stock_mst"."c_batch_no",
      "stock_mst"."d_exp_dt",
      "stock_mst"."n_sale_rate",
      "stock_mst"."n_mrp",
      "stock_mst"."n_pur_rate",
      "stock_mst"."n_eff_pur_rate",
      "stock_mst"."n_lock",
      "stock_mst"."n_mrp_box",
      "stock_mst"."n_pur_rate_box",
      "stock_mst"."n_qty_per_box",
      "stock_mst"."d_ldate",
      "isnull"("stock"."n_bal_qty",0)-"isnull"("stock"."n_dc_inv_qty",0)-"isnull"("stock"."n_hold_qty",0) as "n_bal_qty",
      "item_mst"."c_name",
      "pack_mst"."c_name",
      "stock_mst"."c_item_code",
      "uf_default_date"() as "def_Date",
      "item_mst"."c_barcode"
      from "stock_mst"
        ,"stock"
        ,"item_mst"
        ,"pack_mst"
        ,"item_multi_barcode_det"
      where("stock"."c_item_code" = "stock_mst"."c_item_code")
      and("stock"."c_batch_no" = "stock_mst"."c_batch_no")
      and("stock_mst"."c_item_code" = "item_mst"."c_code")
      and("item_mst"."c_pack_code" = "pack_mst"."c_code")
      and("stock"."c_br_code" = @gsBr)
      and("item_multi_barcode_det"."c_item_code" = "item_mst"."c_code")
      and("item_multi_barcode_det"."n_cancel_flag" = 0)
      and("item_multi_barcode_det"."c_barcode" = @HdrData) union
    //			and ( stock.n_bal_qty > 0 or item_mst.n_service_item=1)
    select "stock_mst"."c_batch_no",
      "stock_mst"."d_exp_dt",
      "stock_mst"."n_sale_rate",
      "stock_mst"."n_mrp",
      "stock_mst"."n_pur_rate",
      "stock_mst"."n_eff_pur_rate",
      "stock_mst"."n_lock",
      "stock_mst"."n_mrp_box",
      "stock_mst"."n_pur_rate_box",
      "stock_mst"."n_qty_per_box",
      "stock_mst"."d_ldate",
      "isnull"("stock"."n_bal_qty",0)-"isnull"("stock"."n_dc_inv_qty",0)-"isnull"("stock"."n_hold_qty",0) as "n_bal_qty",
      "item_mst"."c_name",
      "pack_mst"."c_name",
      "stock_mst"."c_item_code",
      "uf_default_date"() as "def_Date",
      "item_mst"."c_barcode"
      from "barcode_det"
        ,"stock_mst"
        ,"stock"
        ,"item_mst"
        ,"pack_mst"
      where("barcode_det"."c_key" = @HdrData)
      and("barcode_det"."c_item_code" = "stock_mst"."c_item_code")
      and("barcode_det"."c_batch_no" = "stock_mst"."c_batch_no")
      and("stock"."c_item_code" = "stock_mst"."c_item_code")
      and("stock"."c_batch_no" = "stock_mst"."c_batch_no")
      and("stock_mst"."c_item_code" = "item_mst"."c_code")
      and("item_mst"."c_pack_code" = "pack_mst"."c_code")
      and("stock"."c_br_code" = @gsBr) union
    //			AND ( stock.n_bal_qty > 0 or item_mst.n_service_item=1) 
    select "stock_mst"."c_batch_no",
      "stock_mst"."d_exp_dt",
      "stock_mst"."n_sale_rate",
      "stock_mst"."n_mrp",
      "stock_mst"."n_pur_rate",
      "stock_mst"."n_eff_pur_rate",
      "stock_mst"."n_lock",
      "stock_mst"."n_mrp_box",
      "stock_mst"."n_pur_rate_box",
      "stock_mst"."n_qty_per_box",
      "stock_mst"."d_ldate",
      "isnull"("stock"."n_bal_qty",0)-"isnull"("stock"."n_dc_inv_qty",0)-"isnull"("stock"."n_hold_qty",0) as "n_bal_qty",
      "item_mst"."c_name",
      "pack_mst"."c_name",
      "stock_mst"."c_item_code",
      "uf_default_date"() as "def_Date",
      "item_mst"."c_barcode"
      from "supplier_barcode_det"
        ,"stock_mst"
        ,"stock"
        ,"item_mst"
        ,"pack_mst"
      where("supplier_barcode_det"."c_key" = @HdrData)
      and("supplier_barcode_det"."c_item_code" = "stock_mst"."c_item_code")
      and("supplier_barcode_det"."c_batch_no" = "trim"("replace"("replace"("replace"("replace"("replace"("replace"("replace"("replace"("replace"("replace"("replace"("replace"("replace"("replace"("replace"("replace"("replace"("replace"("replace"("stock_mst"."c_batch_no",'*',''),'@',''),'#',''),'%',''),'^',''),'&',''),'(',''),')',''),'-',''),'_',''),'+',''),'?',''),'/',''),'\\',''),'>',''),'<',''),'$',''),'.',''),',','')))
      and("stock"."c_item_code" = "stock_mst"."c_item_code")
      and("stock"."c_batch_no" = "stock_mst"."c_batch_no")
      and("stock_mst"."c_item_code" = "item_mst"."c_code")
      and("item_mst"."c_pack_code" = "pack_mst"."c_code")
      and("stock"."c_br_code" = @gsBr) union
    //         	AND ( stock.n_bal_qty > 0 or item_mst.n_service_item=1)
    select "stock_mst"."c_batch_no",
      "stock_mst"."d_exp_dt",
      "stock_mst"."n_sale_rate",
      "stock_mst"."n_mrp",
      "stock_mst"."n_pur_rate",
      "stock_mst"."n_eff_pur_rate",
      "stock_mst"."n_lock",
      "stock_mst"."n_mrp_box",
      "stock_mst"."n_pur_rate_box",
      "stock_mst"."n_qty_per_box",
      "stock_mst"."d_ldate",
      "isnull"("stock"."n_bal_qty",0)-"isnull"("stock"."n_dc_inv_qty",0)-"isnull"("stock"."n_hold_qty",0) as "n_bal_qty",
      "item_mst"."c_name",
      "pack_mst"."c_name",
      "stock_mst"."c_item_code",
      "uf_default_date"() as "def_Date",
      "item_mst"."c_barcode"
      from "ucode_batchkey"
        ,"stock_mst"
        ,"stock"
        ,"item_mst"
        ,"pack_mst"
      where("ucode_batchkey"."c_batchkey" = @HdrData)
      and("ucode_batchkey"."c_item_code" = "stock_mst"."c_item_code")
      and("ucode_batchkey"."c_batch_no" = "stock_mst"."c_batch_no")
      and("stock"."c_item_code" = "stock_mst"."c_item_code")
      and("stock"."c_batch_no" = "stock_mst"."c_batch_no")
      and("stock_mst"."c_item_code" = "item_mst"."c_code")
      and("item_mst"."c_pack_code" = "pack_mst"."c_code")
      and("stock"."c_br_code" = @gsBr) union
    //         	AND ( stock.n_bal_qty > 0 or item_mst.n_service_item=1)  
    select "stock_mst"."c_batch_no",
      "stock_mst"."d_exp_dt",
      "stock_mst"."n_sale_rate",
      "stock_mst"."n_mrp",
      "stock_mst"."n_pur_rate",
      "stock_mst"."n_eff_pur_rate",
      "stock_mst"."n_lock",
      "stock_mst"."n_mrp_box",
      "stock_mst"."n_pur_rate_box",
      "stock_mst"."n_qty_per_box",
      "stock_mst"."d_ldate",
      "isnull"("stock"."n_bal_qty",0)-"isnull"("stock"."n_dc_inv_qty",0)-"isnull"("stock"."n_hold_qty",0) as "n_bal_qty",
      "item_mst"."c_name",
      "pack_mst"."c_name",
      "stock_mst"."c_item_code",
      "uf_default_date"() as "def_Date",
      "item_mst"."c_barcode"
      from "stock_mst"
        ,"stock"
        ,"item_mst"
        ,"pack_mst"
        ,"stock_serial_no"
      where("stock"."c_item_code" = "stock_mst"."c_item_code")
      and("stock"."c_batch_no" = "stock_mst"."c_batch_no")
      and("stock_mst"."c_item_code" = "item_mst"."c_code")
      and("item_mst"."c_pack_code" = "pack_mst"."c_code")
      and("stock"."c_br_code" = @gsBr)
      and("stock_serial_no"."c_item_code" = "item_mst"."c_code")
      and("stock_serial_no"."c_batch_no" = "stock_mst"."c_batch_no")
      and("stock_serial_no"."n_cancel_flag" = 0)
      and("stock_serial_no"."c_serial_no" = @HdrData) for xml raw,elements
  end case
end;