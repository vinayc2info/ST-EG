CREATE PROCEDURE "DBA"."usp_st_critical_items"( 
  in @gsBr char(6) ) 
begin
  declare local temporary table "temp_stock"(
    "c_br_code" char(6) not null,
    "c_item_code" char(6) not null,
    "n_bal_qty" numeric(11,3) null,
    primary key("c_br_code" asc,"c_item_code" asc),) on commit preserve rows;
  insert into "temp_stock"
    select "c_br_code" as "c_br_code",
      "c_item_code" as "c_item_code",
      "sum"("n_bal_qty") as "n_bal_qty"
      from "stock"
      group by "c_br_code","c_item_code"
      having "isnull"("n_bal_qty",0) > 0;
  select distinct "supp_ord_ledger"."c_item_code" as "itemcode",
    "item_mst"."c_name" as "ItemName",
    0 as "Pallete_no",
    "act_mst"."c_code" as "Supp_code",
    "left"("act_mst"."c_name",if "charindex"(' ',"act_mst"."c_name") = 0 then "len"("act_mst"."c_name") else if "charindex"(' ',"act_mst"."c_name") < 5 then
        if "charindex"(' ',"substring"("act_mst"."c_name",6)) = 0 then "len"("act_mst"."c_name") else "charindex"(' ',"substring"("act_mst"."c_name",6))+5 endif else "charindex"(' ',"act_mst"."c_name") endif endif) as "Supplier_name",
    0 as "Invoice_no"
    from "order_mst" join "supp_ord_ledger" on "order_mst"."c_br_code" = "supp_ord_ledger"."c_br_code"
      and "order_mst"."n_srno" = "supp_ord_ledger"."n_srno"
      and "order_mst"."c_year" = "supp_ord_ledger"."c_year"
      and "order_mst"."c_prefix" = "supp_ord_ledger"."c_prefix"
      join "item_mst" on "item_mst"."c_code" = "supp_ord_ledger"."c_item_code"
      join "item_mst_br_info" on "supp_ord_ledger"."c_item_code" = "item_mst_br_info"."c_code"
      and "item_mst_br_info"."c_br_code" = @gsBr
      left outer join "temp_stock" on "temp_stock"."c_item_code" = "supp_ord_ledger"."c_item_code"
      and "temp_stock"."c_br_code" = "supp_ord_ledger"."c_br_code"
      join "act_mst" on "order_mst"."c_cust_code" = "act_mst"."c_code"
      join(select "c_item_code","c_supp_code" from "pur_det" where "n_post" = 0 and "c_prefix" = 'K'
        group by "c_item_code","c_supp_code") as "pur_det"
      on "pur_det"."c_item_code" = "supp_ord_ledger"."c_item_code"
      and "pur_det"."c_supp_code" = "order_mst"."c_cust_code"
    where("order_mst"."c_br_code" = @gsbr
    and "order_mst"."n_post" = 1
    and(("supp_ord_ledger"."n_qty"+"supp_ord_ledger"."n_sch_qty"-"supp_ord_ledger"."n_issue_qty"-"supp_ord_ledger"."n_sch_issue_qty"
    -"supp_ord_ledger"."n_sch_issue_qty"-"supp_ord_ledger"."n_cancel_qty"-"supp_ord_ledger"."n_sch_cancel_qty" > 0))
    and "isnull"("temp_stock"."n_bal_qty",0) < "isnull"("item_mst_br_info"."n_rack_min_qty",0))
    order by "Supp_code" asc
end;