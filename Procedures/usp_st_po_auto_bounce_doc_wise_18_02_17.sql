CREATE PROCEDURE "DBA"."usp_st_po_auto_bounce_doc_wise_18_02_17"( 
  --Modified
  @br char(6),@yr char(6),@pr char(6),@sr numeric(9) ) 
begin
  declare @n_type numeric(9);
  declare @s_br_code char(10);
  declare @s_year char(10);
  declare @s_prefix char(10);
  declare @d_srno numeric(9);
  declare @pos numeric(9);
  declare @s_cust_code char(50);
  if "upper"("left"("db_name"(),6)) <> '04M503' then
    return ''
  end if;
  set @s_br_code = @br;
  set @s_year = @yr;
  set @s_prefix = @pr;
  set @d_srno = @sr;
  select "c_cust_code" into @s_cust_code from "order_mst" where "c_br_code" = @s_br_code and "c_year" = @s_year and "c_prefix" = @s_prefix and "n_srno" = @d_srno;
  select "n_type" into @n_type from "act_mst" where "c_code" = @s_cust_code;
  insert into "gdn_bounced_items"
    ( "c_br_code","c_year","c_prefix","n_srno","c_item_code","n_qty","c_po_no","d_ldate","t_ltime","n_seq",
    "n_flag" ) on existing skip
    select "order_det"."c_br_Code",
      "order_det"."c_year",
      "order_det"."c_prefix",
      "order_det"."n_srno",
      "order_det"."c_item_code",
      ("order_det"."n_qty"+"order_det"."n_sch_qty") as "n_qty",
      "order_det"."c_br_Code"+'/'+"order_det"."c_year"+'/'+"order_det"."c_prefix"+'/'+"string"("order_det"."n_srno") as "c_po_no",
      "uf_default_date"() as "d_ldate",
      "now"() as "t_ltime",
      "order_det"."n_seq",
      1 as "n_flag"
      from "order_det"
        --Gdn
        --isnull(sum(isnull(stock_godown.n_qty,0)-isnull(stock_godown.n_hold_qty,0)),0) as stk_godown_qty
        join(select "stock"."c_item_code",
          "sum"("stock"."n_bal_qty"-"stock"."n_hold_qty") as "curr_stk",
          if @n_type = 3 then
            "isnull"("item_group_mst"."n_gdn_exp_days",'50')
          else
            if @n_type = 2 then
              "isnull"("item_group_mst"."n_sale_exp_days",'50')
            else
              50
            endif
          endif as "tran_exp_days",
          "max"("stock_mst"."d_exp_dt") as "d_exp_dt",
          "isnull"("sum"(if "isnull"("godown_mst"."n_flag",0) = 0 then 0 else "isnull"("stock_godown"."n_qty",0)-"isnull"("stock_godown"."n_hold_qty",0) endif),0) as "stk_godown_qty"
          from "stock" join "stock_mst" on "stock"."c_item_code" = "stock_mst"."c_item_code"
            and "stock"."c_batch_no" = "stock_mst"."c_batch_no"
            left outer join "stock_godown"
            on "stock_godown"."c_br_code" = "stock"."c_br_code"
            and "stock_godown"."c_item_code" = "stock"."c_item_code"
            and "stock_godown"."c_batch_no" = "stock"."c_batch_no"
            left outer join "godown_mst" on "godown_mst"."c_code" = "stock_godown"."c_godown_code" and "isnull"("godown_mst"."n_flag",0) = 1
            join "Item_mst" on "item_mst"."c_code" = "stock"."c_item_code"
            join "item_group_mst" on "item_group_mst"."c_code" = "item_mst"."c_group_code"
          where "dateadd"("day",(-1)*"tran_exp_days","stock_mst"."d_exp_dt") >= "uf_default_date"()
          and "item_mst"."n_lock" = 0
          group by "stock"."c_item_code","tran_exp_days"
          having "isnull"("curr_stk",0)-"isnull"("stk_godown_qty",0) <= 0 union
        select "order_det"."c_item_code",
          0 as "curr_stk",
          0 as "tran_exp_days",
          null as "d_exp_dt",
          0 as "stk_godown_qty"
          from "order_det"
            left outer join(select "c_item_code",
              "sum"("n_bal_qty") as "n_bal_qty"
              from "stock"
              group by "c_item_code") as "stock"
            on "order_det"."c_item_code" = "stock"."c_item_code"
          where("order_det"."c_br_code" = @s_br_code)
          and("order_det"."c_year" = @s_year)
          and("order_det"."c_prefix" = @s_prefix)
          and("order_det"."n_srno" = @d_srno)
          and("stock"."c_item_code" is null)) as "stk"
        on "stk"."c_item_code" = "order_det"."c_item_code"
        left outer join "order_allocation_det" on "order_det"."c_br_code" = "order_allocation_det"."c_ord_br_code"
        and "order_det"."c_year" = "order_allocation_det"."c_ord_year"
        and "order_det"."c_prefix" = "order_allocation_det"."c_ord_prefix"
        and "order_det"."n_srno" = "order_allocation_det"."n_ord_srno"
        and "order_det"."n_seq" = "order_allocation_det"."n_ord_seq"
        left outer join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "order_det"."c_ord_supp_code"
        and "item_mst_br_info"."c_code" = "order_det"."c_item_code"
        left outer join "rack_mst" on "item_mst_br_info"."c_rack" = "rack_mst"."c_code"
        and "rack_mst"."c_br_code" = "item_mst_br_info"."c_br_code"
        left outer join "rack_group_det" on "rack_mst"."c_br_code" = "rack_group_det"."c_br_code"
        and "rack_mst"."c_code" = "rack_group_det"."c_rack_code"
        left outer join(select "c_item_code","sum"("n_qty") as "pick_qty" from "st_track_det" where "n_inout" = 0 and "n_complete" = 0 and "n_hold_flag" = 1
          group by "c_item_code") as "pending_pick"
        on "pending_pick"."c_item_code" = "order_det"."c_item_code"
        join "st_track_mst" on "st_track_mst"."c_doc_no" = "order_det"."c_br_Code"+'/'+"order_det"."c_year"+'/'+"order_det"."c_prefix"+'/'+"string"("order_det"."n_srno")
      where("order_det"."c_br_Code" = @s_br_code)
      and("order_det"."c_year" = @s_year)
      and("order_det"."c_prefix" = @s_prefix)
      and("order_det"."n_srno" = @d_srno)
      and("st_track_mst"."n_confirm" = 0)
      and "isnull"("curr_stk",0) <= 0
      order by "order_det"."n_srno" asc
end;