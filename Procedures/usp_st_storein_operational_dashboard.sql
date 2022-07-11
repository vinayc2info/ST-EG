CREATE PROCEDURE "DBA"."usp_st_storein_operational_dashboard"( 
  in @gsBr char(6),
  in @devID char(200),
  in @sKey char(20),
  in @cIndex char(30) ) 
result(  //  in @UserId char(15)) 
  "is_xml_string" xml ) 
begin
  declare "ddate" date;
  declare "ttime" "datetime";
  declare @pur_cnt numeric(9);
  declare @item_cnt numeric(9);
  declare @item_cnt_conflict numeric(9);
  declare @user_cnt numeric(9);
  declare @open_po numeric(9);
  declare @po_added numeric(9);
  declare @po_compl numeric(9);
  declare @invoice_cnt numeric(9);
  declare @line_item_cnt numeric(9);
  declare @critical_item numeric(9);
  declare @first_per char(4);
  declare @part_per_80 numeric(9);
  declare @second_per char(4);
  declare @part_per_60 numeric(9);
  declare @third_per char(4);
  declare @part_per_40 numeric(9);
  declare local temporary table "table_data"(
    "total_bill_first" numeric(9) null default 0,
    "incmplt_cnt_first" numeric(9) null default 0,
    "date_cmplt_first" numeric(9) null default 0,
    "no_of_gate_entry" numeric(9) null default 0,
    "percentage_first" numeric(11,2) null default 0,
    "total_bill_secnd" numeric(9) null default 0,
    "incmplt_cnt_secnd" numeric(9) null default 0,
    "date_cmplt_secnd" numeric(9) null default 0,
    "percentage_secnd" numeric(11,2) null default 0,
    "item_cnt_conflict" numeric(9) null default 0,
    "user_cnt" numeric(9) null default 0,
    "open_po" numeric(9) null default 0,
    "po_added" numeric(9) null default 0,
    "po_compl" numeric(9) null default 0,
    "po_per" numeric(11,2) null default 0,
    "invoice_cnt" numeric(9) null default 0,
    "line_item_cnt" numeric(9) null default 0,
    "gre_per" numeric(11,2) null default 0,
    "critical_item" numeric(9) null,
    "first_per" char(5) null,
    "part_per_80" numeric(9) null default 0,
    "second_per" char(5) null,
    "part_per_60" numeric(9) null default 0,
    "third_per" char(5) null,
    "part_per_40" numeric(9) null default 0,
    "age" numeric(9) null default 0,) on commit preserve rows;
  declare local temporary table "temp_gate_pass"(
    "c_br_code" char(6) not null,
    "c_year" char(2) not null,
    "c_prefix" numeric(4) not null,
    "n_srno" numeric(9) not null,
    "d_date" date null,
    primary key("c_br_code" asc,"c_year" asc,"c_prefix" asc,"n_srno" asc),) on commit preserve rows;
  declare local temporary table "conv_gate_pass"(
    "c_br_code" char(6) not null,
    "c_year" char(2) not null,
    "c_prefix" numeric(4) not null,
    "n_srno" numeric(9) not null,
    primary key("c_br_code" asc,"c_year" asc,"c_prefix" asc,"n_srno" asc),) on commit preserve rows;
  declare local temporary table "temp_stock"(
    "c_br_code" char(6) not null,
    "c_item_code" char(6) not null,
    "n_bal_qty" numeric(11,3) null,
    primary key("c_br_code" asc,"c_item_code" asc),
    ) on commit preserve rows;
  if @devID = '' or @devID is null then
    set @gsBr = "http_variable"('gsBr'); --1
    set @devID = "http_variable"('devID'); --2
    set @sKey = "http_variable"('sKey'); --3
    set @cIndex = "http_variable"('cIndex') --4
  //    set @UserId = "http_variable"('UserId')
  end if;
  set "ddate" = "uf_default_date"();
  set "ttime" = "DATEADD"("hour",-1,"DBA"."uf_default_date"());
  //  if(select "count"() from "block_api") >= 1 then
  //    return
  //  end if;
  //  insert into "API_LOG"
  //    ( "c_api_name","c_index","t_start_time","c_remark","c_note","c_user","n_n1" ) values
  //    ( 'usp_st_storein_operational_dashboard',@cIndex,"GETDATE"(),'',@devID,@UserId,"connection_property"('NUMBER') ) ;
  //  commit work;
  case @cIndex
  when 'get_gate_pass' then
    insert into "temp_stock"
      select "c_br_code" as "c_br_code",
        "c_item_code" as "c_item_code",
        "sum"("n_bal_qty") as "n_bal_qty"
        from "stock"
        group by "c_br_code","c_item_code";
    //    print 'gg';
    insert into "temp_gate_pass"( "c_br_code","c_year","c_prefix","n_srno","d_date" ) 
      select "gate_pass_mst"."c_br_code" as "c_br_code",
        "gate_pass_mst"."c_year" as "c_year",
        "gate_pass_mst"."c_prefix" as "c_prefix",
        "gate_pass_mst"."n_srno" as "n_srno",
        "max"("gate_pass_mst"."d_date") as "d_date"
        from "gate_pass_mst" join "gate_pass_det" on "gate_pass_mst"."c_br_code" = "gate_pass_det"."c_br_code"
          and "gate_pass_mst"."c_year" = "gate_pass_det"."c_year"
          and "gate_pass_mst"."c_prefix" = "gate_pass_det"."c_prefix"
          and "gate_pass_mst"."n_srno" = "gate_pass_det"."n_srno"
          and "gate_pass_mst"."c_supp_code" = "gate_pass_det"."c_supp_code"
          left outer join "pur_mst" on "gate_pass_det"."c_supp_code" = "pur_mst"."c_supp_code"
          and "gate_pass_det"."c_ref_no" = "pur_mst"."c_bill_no"
          and "pur_mst"."c_prefix" = 'K' and "pur_mst"."d_date" < "ddate"
        where "gate_pass_det"."d_date" < "ddate"
        and "gate_pass_det"."n_cancel_flag" = 0
        and "gate_pass_mst"."n_cancel_flag" = 0
        and "gate_pass_det"."n_approved" = 1
        and "gate_pass_mst"."n_approved" = 1
        group by "c_br_code","c_year","c_prefix","n_srno"
        having "count"("gate_pass_det"."c_ref_no") <> "isnull"("count"("pur_mst"."c_bill_no"),0);
    //    print 'end ';
    --select * FROM  temp_gate_pass
    insert into "table_data"( "total_bill_first","incmplt_cnt_first","date_cmplt_first","percentage_first","no_of_gate_entry","age" ) 
      select("incmplt_cnt"+"date_cmplt") as "total_bill",
        "count"("status") as "incmplt_cnt",
        "sum"("date_cmpletn_cnt") as "date_cmplt",
        cast("date_cmplt" as numeric(11,2))/cast("no_of_gate_entry" as numeric(11,2))*100 as "percentage",
        "sum"("gate_pass_bill_cnt") as "no_of_gate_entry",
        "max"("ag") as "age"
        from(select "gate_pass_det"."n_srno" as "gate_pass_no",
            "count"("gate_pass_det"."c_ref_no") as "gate_pass_bill_cnt",
            "isnull"("count"("pur_mst"."c_bill_no"),0) as "bill_cnt",
            (if "gate_pass_bill_cnt" = "bill_cnt" then 1 else 0 endif) as "status",
            0 as "date_cmpletn_cnt",
            "max"("gate_pass_mst"."d_date") as "d_date",
            "uf_default_date"()-"d_date" as "ag"
            from "gate_pass_mst" join "gate_pass_det" on "gate_pass_mst"."c_br_code" = "gate_pass_det"."c_br_code"
              and "gate_pass_mst"."c_year" = "gate_pass_det"."c_year"
              and "gate_pass_mst"."c_prefix" = "gate_pass_det"."c_prefix"
              and "gate_pass_mst"."n_srno" = "gate_pass_det"."n_srno"
              and "gate_pass_mst"."c_supp_code" = "gate_pass_det"."c_supp_code"
              left outer join "pur_mst" on "gate_pass_det"."c_supp_code" = "pur_mst"."c_supp_code"
              and "gate_pass_det"."c_ref_no" = "pur_mst"."c_bill_no"
              and "pur_mst"."c_prefix" = 'K' and "pur_mst"."d_date" < "ddate"
            where "gate_pass_det"."d_date" < "ddate"
            and "gate_pass_det"."n_cancel_flag" = 0
            and "gate_pass_mst"."n_cancel_flag" = 0
            and "gate_pass_det"."n_approved" = 1
            and "gate_pass_mst"."n_approved" = 1
            group by "gate_pass_no" union all
          select "gate_pass_det"."n_srno" as "gate_pass_no",
            "count"("gate_pass_det"."c_ref_no") as "gate_pass_bill_cnt",
            "isnull"("count"("pur_mst"."c_bill_no"),0) as "bill_cnt",
            0 as "status",
            (if "gate_pass_bill_cnt" = "bill_cnt" then 1 else 0 endif) as "date_cmpletn_cnt",
            "max"("gate_pass_mst"."d_date") as "d_date",
            "uf_default_date"()-"d_date" as "ag"
            from "gate_pass_mst" join "gate_pass_det" on "gate_pass_mst"."c_br_code" = "gate_pass_det"."c_br_code"
              and "gate_pass_mst"."c_year" = "gate_pass_det"."c_year"
              and "gate_pass_mst"."c_prefix" = "gate_pass_det"."c_prefix"
              and "gate_pass_mst"."n_srno" = "gate_pass_det"."n_srno"
              and "gate_pass_mst"."c_supp_code" = "gate_pass_det"."c_supp_code"
              left outer join "pur_mst" on "gate_pass_det"."c_supp_code" = "pur_mst"."c_supp_code"
              and "gate_pass_det"."c_ref_no" = "pur_mst"."c_bill_no"
              and "pur_mst"."c_prefix" = 'K'
            where "gate_pass_det"."d_date" = "ddate"
            and "gate_pass_det"."n_cancel_flag" = 0
            and "gate_pass_mst"."n_cancel_flag" = 0
            and "gate_pass_det"."n_approved" = 1
            and "gate_pass_mst"."n_approved" = 1
            group by "gate_pass_no" union all
          select "gate_pass_det"."n_srno" as "gate_pass_no",
            "count"("gate_pass_det"."c_ref_no") as "gate_pass_bill_cnt",
            "isnull"("count"("pur_mst"."c_bill_no"),0) as "bill_cnt",
            0 as "status",
            (if "gate_pass_bill_cnt" = "bill_cnt" then 1 else 0 endif) as "date_cmpletn_cnt",
            "temp_gate_pass"."d_date" as "d_date",
            "uf_default_date"()-"d_date" as "ag"
            from "temp_gate_pass" join "gate_pass_det" on "temp_gate_pass"."c_br_code" = "gate_pass_det"."c_br_code"
              and "temp_gate_pass"."c_year" = "gate_pass_det"."c_year"
              and "temp_gate_pass"."c_prefix" = "gate_pass_det"."c_prefix"
              and "temp_gate_pass"."n_srno" = "gate_pass_det"."n_srno"
              join "pur_mst" on "gate_pass_det"."c_supp_code" = "pur_mst"."c_supp_code"
              and "gate_pass_det"."c_ref_no" = "pur_mst"."c_bill_no"
            where "gate_pass_det"."n_cancel_flag" = 0
            and "gate_pass_det"."n_approved" = 1
            and "pur_mst"."d_date" = "ddate"
            and "pur_mst"."c_prefix" = 'K'
            group by "gate_pass_no","d_date") as "a"
        where "status" = 0;
    --select * from table_data 
    -- index : Converted
    insert into "temp_gate_pass"
      select "gate_pass_mst"."c_br_code" as "c_br_code",
        "gate_pass_mst"."c_year" as "c_year",
        "gate_pass_mst"."c_prefix" as "c_prefix",
        "gate_pass_mst"."n_srno" as "n_srno",
        "max"("gate_pass_mst"."d_date") as "d_date"
        from "gate_pass_mst" join "gate_pass_det" on "gate_pass_mst"."c_br_code" = "gate_pass_det"."c_br_code"
          and "gate_pass_mst"."c_year" = "gate_pass_det"."c_year"
          and "gate_pass_mst"."c_prefix" = "gate_pass_det"."c_prefix"
          and "gate_pass_mst"."n_srno" = "gate_pass_det"."n_srno"
          and "gate_pass_mst"."c_supp_code" = "gate_pass_det"."c_supp_code"
          left outer join "pur_mst" on "gate_pass_det"."c_supp_code" = "pur_mst"."c_supp_code"
          and "gate_pass_det"."c_ref_no" = "pur_mst"."c_bill_no"
          and "pur_mst"."c_prefix" = 'K'
        where "gate_pass_det"."d_date" = "ddate"
        and "gate_pass_det"."n_cancel_flag" = 0
        and "gate_pass_mst"."n_cancel_flag" = 0
        group by "c_br_code","c_year","c_prefix","n_srno"
        having "count"("gate_pass_det"."c_ref_no") <> "isnull"("count"("pur_mst"."c_bill_no"),0);
    insert into "conv_gate_pass"(
      select distinct "gate_pass_br","gate_pass_yr","gate_pass_pfx","gate_pass_no"
        --,
        from(select "gate_pass_det"."c_br_code" as "gate_pass_br",
            "gate_pass_det"."c_year" as "gate_pass_yr",
            "gate_pass_det"."c_prefix" as "gate_pass_pfx",
            "gate_pass_det"."n_srno" as "gate_pass_no"
            from "gate_pass_mst" join "gate_pass_det" on "gate_pass_mst"."c_br_code" = "gate_pass_det"."c_br_code"
              and "gate_pass_mst"."c_year" = "gate_pass_det"."c_year"
              and "gate_pass_mst"."c_prefix" = "gate_pass_det"."c_prefix"
              and "gate_pass_mst"."n_srno" = "gate_pass_det"."n_srno"
              and "gate_pass_mst"."c_supp_code" = "gate_pass_det"."c_supp_code"
              left outer join "pur_mst" on "gate_pass_det"."c_supp_code" = "pur_mst"."c_supp_code"
              and "gate_pass_det"."c_ref_no" = "pur_mst"."c_bill_no"
              and "pur_mst"."c_prefix" = 'K' and "pur_mst"."d_date" < "uf_default_date"()
            where "gate_pass_det"."d_date" < "uf_default_date"()
            and "gate_pass_det"."n_cancel_flag" = 0
            and "gate_pass_mst"."n_cancel_flag" = 0
            and "gate_pass_det"."n_approved" = 1
            and "gate_pass_mst"."n_approved" = 1 union all
          select "gate_pass_det"."c_br_code" as "gate_pass_br",
            "gate_pass_det"."c_year" as "gate_pass_yr",
            "gate_pass_det"."c_prefix" as "gate_pass_pfx",
            "gate_pass_det"."n_srno" as "gate_pass_no"
            from "gate_pass_mst" join "gate_pass_det" on "gate_pass_mst"."c_br_code" = "gate_pass_det"."c_br_code"
              and "gate_pass_mst"."c_year" = "gate_pass_det"."c_year"
              and "gate_pass_mst"."c_prefix" = "gate_pass_det"."c_prefix"
              and "gate_pass_mst"."n_srno" = "gate_pass_det"."n_srno"
              and "gate_pass_mst"."c_supp_code" = "gate_pass_det"."c_supp_code"
              left outer join "pur_mst" on "gate_pass_det"."c_supp_code" = "pur_mst"."c_supp_code"
              and "gate_pass_det"."c_ref_no" = "pur_mst"."c_bill_no"
              and "pur_mst"."c_prefix" = 'K'
            where "gate_pass_det"."d_date" = "uf_default_date"()
            and "gate_pass_det"."n_cancel_flag" = 0
            and "gate_pass_mst"."n_cancel_flag" = 0
            and "gate_pass_det"."n_approved" = 1
            and "gate_pass_mst"."n_approved" = 1 union all
          select "gate_pass_det"."c_br_code" as "gate_pass_br",
            "gate_pass_det"."c_year" as "gate_pass_yr",
            "gate_pass_det"."c_prefix" as "gate_pass_pfx",
            "gate_pass_det"."n_srno" as "gate_pass_no"
            from "temp_gate_pass" join "gate_pass_det" on "temp_gate_pass"."c_br_code" = "gate_pass_det"."c_br_code"
              and "temp_gate_pass"."c_year" = "gate_pass_det"."c_year"
              and "temp_gate_pass"."c_prefix" = "gate_pass_det"."c_prefix"
              and "temp_gate_pass"."n_srno" = "gate_pass_det"."n_srno"
              join "pur_mst" on "gate_pass_det"."c_supp_code" = "pur_mst"."c_supp_code"
              and "gate_pass_det"."c_ref_no" = "pur_mst"."c_bill_no"
            where "gate_pass_det"."n_cancel_flag" = 0
            and "gate_pass_det"."n_approved" = 1
            and "pur_mst"."d_date" = "uf_default_date"()
            and "pur_mst"."c_prefix" = 'K') as "a");
    select "count"(distinct "pur_no") as "pur_cnt","count"("item") as "item_cnt"
      into @pur_cnt,@item_cnt
      from(select distinct "pur_det"."c_item_code" as "item","pur_mst"."n_srno" as "pur_no",
          "gate_pass_mst"."n_srno"
          from "gate_pass_mst" join "gate_pass_det" on "gate_pass_mst"."c_br_code" = "gate_pass_det"."c_br_code"
            and "gate_pass_mst"."c_year" = "gate_pass_det"."c_year"
            and "gate_pass_mst"."c_prefix" = "gate_pass_det"."c_prefix"
            and "gate_pass_mst"."n_srno" = "gate_pass_det"."n_srno"
            join "conv_gate_pass" on "conv_gate_pass"."c_br_code" = "gate_pass_mst"."c_br_code"
            and "conv_gate_pass"."c_year" = "gate_pass_mst"."c_year"
            and "conv_gate_pass"."c_prefix" = "gate_pass_mst"."c_prefix"
            and "conv_gate_pass"."n_srno" = "gate_pass_mst"."n_srno"
            join "pur_mst" on "gate_pass_det"."c_supp_code" = "pur_mst"."c_supp_code"
            and "gate_pass_det"."c_ref_no" = "pur_mst"."c_bill_no"
            join "pur_det" on "pur_mst"."c_br_code" = "pur_det"."c_br_code"
            and "pur_mst"."c_year" = "pur_det"."c_year"
            and "pur_mst"."c_prefix" = "pur_det"."c_prefix"
            and "pur_mst"."n_srno" = "pur_det"."n_srno"
          where "pur_mst"."c_prefix" = 'K') as "a";
    --Index : Active User 
    select "count"(distinct "c_user") into @user_cnt from "item_receipt_entry" where "t_start_time" > "ttime";
    --Index : Conflict 
    select "count"("c_item_code") into @item_cnt_conflict from "item_receipt_entry" where "n_type" in( 0,2 ) ;
    /*update table_data set total_bill_secnd = @pur_cnt,incmplt_cnt_secnd = @item_cnt,percentage_secnd = (@pur_cnt/total_bill_first)*100,
item_cnt_conflict = @item_cnt_conflict;*/
    -- Index : Pending PO
    select "count"("open_po") as "open_po"
      into @open_po
      from(select distinct "order_mst"."n_srno" as "open_po",
          0 as "po_added",
          0 as "po_compl"
          from "order_mst" join "supp_ord_ledger" on "order_mst"."c_br_code" = "supp_ord_ledger"."c_br_code"
            and "order_mst"."n_srno" = "supp_ord_ledger"."n_srno"
            and "order_mst"."c_year" = "supp_ord_ledger"."c_year"
            and "order_mst"."c_prefix" = "supp_ord_ledger"."c_prefix"
            join "act_mst" on "order_mst"."c_cust_code" = "act_mst"."c_code"
          where("order_mst"."c_ref_br_code" = @gsBr
          and "order_mst"."n_post" = 1
          and(("supp_ord_ledger"."n_qty"+"supp_ord_ledger"."n_sch_qty"-"supp_ord_ledger"."n_issue_qty"-"supp_ord_ledger"."n_sch_issue_qty"
          -"supp_ord_ledger"."n_sch_issue_qty"-"supp_ord_ledger"."n_cancel_qty"-"supp_ord_ledger"."n_sch_cancel_qty" > 0)))
          and "datepart"("month","order_mst"."d_date") = "datepart"("month","ddate")
          group by "order_mst"."n_srno") as "t1";
    select "COUNT"("order_mst"."n_srno") as "po_added"
      into @po_added from "order_mst"
      where "c_br_code" = @gsBr
      and "n_post" = 1
      and "datepart"("month","order_mst"."d_date") = "datepart"("month","ddate");
    select "count"("po_compl")
      into @po_compl
      from(select distinct "order_mst"."n_srno" as "po_compl"
          from "order_mst" join "supp_ord_ledger" on "order_mst"."c_br_code" = "supp_ord_ledger"."c_br_code"
            and "order_mst"."n_srno" = "supp_ord_ledger"."n_srno"
            and "order_mst"."c_year" = "supp_ord_ledger"."c_year"
            and "order_mst"."c_prefix" = "supp_ord_ledger"."c_prefix"
          where("order_mst"."c_ref_br_code" = @gsBr
          and "order_mst"."n_post" = 1
          and(("supp_ord_ledger"."n_qty"+"supp_ord_ledger"."n_sch_qty"-"supp_ord_ledger"."n_issue_qty"-"supp_ord_ledger"."n_sch_issue_qty"
          -"supp_ord_ledger"."n_sch_issue_qty"-"supp_ord_ledger"."n_cancel_qty"-"supp_ord_ledger"."n_sch_cancel_qty" = 0))
          and "datepart"("month","order_mst"."d_date") = "datepart"("month","ddate"))
          group by "order_mst"."n_srno") as "t2";
    -- Index :Goods Receipt 
    select "count"(distinct "pur_mst"."n_srno") as "invoice_cnt" into @invoice_cnt from "pur_mst" join "pur_det"
        on "pur_mst"."c_br_code" = "pur_det"."c_br_code"
        and "pur_mst"."c_year" = "pur_det"."c_year"
        and "pur_mst"."c_prefix" = "pur_det"."c_prefix"
        and "pur_mst"."n_srno" = "pur_det"."n_srno"
      where "pur_mst"."c_prefix" = 'K'
      and "pur_det"."n_post" in( 2,1 )  --and pur_mst.n_srno=337
      and "pur_mst"."d_date" = "ddate";
    select "sum"(if "n_post" >= 1 then 1 else 0 endif) as "posted_cnt"
      into @line_item_cnt
      from(select distinct "pur_det"."c_item_code" as "item","pur_mst"."n_srno" as "pur_no",
          "gate_pass_mst"."n_srno","pur_det"."n_post"
          from "gate_pass_mst" join "gate_pass_det" on "gate_pass_mst"."c_br_code" = "gate_pass_det"."c_br_code"
            and "gate_pass_mst"."c_year" = "gate_pass_det"."c_year"
            and "gate_pass_mst"."c_prefix" = "gate_pass_det"."c_prefix"
            and "gate_pass_mst"."n_srno" = "gate_pass_det"."n_srno"
            join "conv_gate_pass" on "conv_gate_pass"."c_br_code" = "gate_pass_mst"."c_br_code"
            and "conv_gate_pass"."c_year" = "gate_pass_mst"."c_year"
            and "conv_gate_pass"."c_prefix" = "gate_pass_mst"."c_prefix"
            and "conv_gate_pass"."n_srno" = "gate_pass_mst"."n_srno"
            join "pur_mst" on "gate_pass_det"."c_supp_code" = "pur_mst"."c_supp_code"
            and "gate_pass_det"."c_ref_no" = "pur_mst"."c_bill_no"
            join "pur_det" on "pur_mst"."c_br_code" = "pur_det"."c_br_code"
            and "pur_mst"."c_year" = "pur_det"."c_year"
            and "pur_mst"."c_prefix" = "pur_det"."c_prefix"
            and "pur_mst"."n_srno" = "pur_det"."n_srno"
          where "pur_mst"."c_prefix" = 'K') as "a";
    -- Index : Critical Items 
    select "count"() into @critical_item from "usp_st_critical_items"(@gsbr);
    --Index :Partial Document 
    select '80' as "first_per",
      "sum"(if "part_per" >= 80 then 1 else 0 endif) as "part_per_80",
      '60' as "second_per",
      "sum"(if "part_per" > 60 and "part_per" < 80 then 1 else 0 endif) as "part_per_60",
      '40' as "third_per",
      "sum"(if "part_per" < 40 then 1 else 0 endif) as "part_per_40"
      into @first_per,@part_per_80,@second_per,@part_per_60,@third_per,@part_per_40
      from(select "pur_det"."n_srno" as "doc_no",
          "sum"(if "pur_det"."n_post" = 0 then 1 else 0 endif) as "unpost",
          "sum"(if "pur_det"."n_post" = 1 or "pur_det"."n_post" = 2 then 1 else 0 endif) as "post",
          "unpost"+"post" as "det_cnt",
          cast("post" as numeric(12,2))/cast("det_cnt" as numeric(12,2))*100 as "part_per"
          from "pur_det"
          where "d_date" = "ddate" and "pur_det"."c_prefix" = 'K'
          group by "pur_det"."n_srno"
          having "det_cnt" <> "unpost"
          order by 5 asc) as "t1";
    update "table_data" set "total_bill_secnd" = @pur_cnt,"incmplt_cnt_secnd" = @item_cnt,"percentage_secnd" = (@pur_cnt/@item_cnt)*100,
      "item_cnt_conflict" = @item_cnt_conflict,"user_cnt" = @user_cnt,"open_po" = @open_po,"po_added" = @po_added,"po_compl" = @po_compl,
      "po_per" = if(@open_po+@po_added) = 0 then 0 else @po_compl/(@open_po+@po_added)*100 endif,
      "invoice_cnt" = @invoice_cnt,"line_item_cnt" = @line_item_cnt,"gre_per" = (@line_item_cnt/@item_cnt)*100,
      "critical_item" = @critical_item,"first_per" = @first_per,
      "part_per_80" = @part_per_80,"second_per" = @second_per,
      "part_per_60" = @part_per_60,"third_per" = @third_per,
      "part_per_40" = @part_per_40;
    select * from "table_data" for xml raw,elements
  when 'get_critical_item_list' then
    select "itemcode",
      "ItemName",
      "Pallete_no",
      "Supp_code",
      "Supplier_name",
      "Invoice_no",
      0 as "PO_no"
      from "usp_st_critical_items"(@gsbr) for xml raw,elements
  when 'get_partial_doc' then
    select "doc_no",
      "part_per",
      "item" as "critical_cnt"
      from(select "pur_det"."n_srno" as "doc_no",
          "count"("critical"."cd") as "item",
          "sum"(if "pur_det"."n_post" = 0 then 1 else 0 endif) as "unpost",
          "sum"(if "pur_det"."n_post" >= 1 then 1 else 0 endif) as "post",
          "unpost"+"post" as "det_cnt",
          cast("post" as numeric(12,2))/cast("det_cnt" as numeric(12,2))*100 as "part_per"
          from "pur_det"
            left outer join(select distinct "itemcode" as "cd" from "usp_st_critical_items"(@gsbr)) as "critical"
            on "pur_det"."c_item_code" = "cd"
            join "item_mst" on "item_mst"."c_code" = "pur_det"."c_item_code"
          group by "doc_no"
          having "det_cnt" <> "unpost") as "t1"
      where "part_per" < 100
      order by "critical_cnt" asc for xml raw,elements
  end case
end;