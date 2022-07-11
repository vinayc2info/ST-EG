CREATE PROCEDURE "DBA"."usp_st_expiry_dash_board"( 
  in @gsBr char(6), --1
  in @devID char(200), --2
  in @sKey char(20), --3
  in @UserId char(20), --4
  in @cIndex char(30), --5
  in @GodownCode char(6), --6
  in @HdrData char(32767) )  --7
result( "is_xml_string" xml ) 
begin
  /*
Author 		: Saneesh C G
Procedure	: usp_st_expiry_dash_board
SERVICE		: ws_st_expiry_dash_board
Date 		: 25-01-2017
modified by : Saneesh C G 
Ldate 		: 
Purpose		: Dashboard for Expiry Godown
Input		: gsBr~devID~sKey~UserId~cIndex~GodownCode~HdrData
Service Call (Format): 
http://172.16.18.200:16503/ws_st_expiry_dash_board?&cIndex=get_summary&GodownCode=5033&gsbr=503&devID=3c824667f4396fc729062016041357979&sKEY=sKey&UserId=
http://172.16.18.200:16503/ws_st_expiry_dash_board?&cIndex=get_item&HdrData=70240&GodownCode=5033&gsbr=503&devID=3c824667f4396fc729062016041357979&sKEY=sKey&UserId=
*/
  declare @BrCode char(6);
  declare @t_ltime char(25);
  declare @d_ldate char(20);
  declare @nUserValid integer;
  declare @RackGrpList char(7000);
  --common >>
  declare @ColSep char(6);
  declare @RowSep char(6);
  declare @traycode char(6);
  declare @flag numeric(4);
  declare @Pos integer;
  declare @ColPos integer;
  declare @RowPos integer;
  declare @ColMaxLen numeric(4);
  declare @RowMaxLen numeric(4);
  declare @s_parm char(10);
  declare @c_item_code char(10);
  if @devID = '' or @devID is null then
    set @gsBr = "http_variable"('gsBr'); --1
    set @devID = "http_variable"('devID'); --2
    set @sKey = "http_variable"('sKey'); --3
    set @UserId = "http_variable"('UserId'); --4
    set @cIndex = "http_variable"('cIndex'); --5
    set @GodownCode = "http_variable"('GodownCode'); --6
    set @HdrData = "http_variable"('HdrData'); --7
    set @c_item_code = "http_variable"('c_item_code') --8
  end if;
  select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
  select "c_delim" into @RowSep from "ps_tab_delimiter" where "n_seq" = 1;
  set @ColMaxLen = "Length"(@ColSep);
  set @RowMaxLen = "Length"(@RowSep);
  set @GodownCode = '-';
  set @BrCode = "uf_get_br_code"(@gsBr);
  set @t_ltime = "left"("now"(),19);
  set @d_ldate = "uf_default_date"();
  //  if(select "count"() from "block_api") >= 1 then
  //    return
  //  end if;
  --select 'sani ' as a for xml raw,elements  ;
  case @cIndex
  when 'get_item' then
    select
      "isnull"(
      "reverse"("substr"("reverse"("st_track_det"."c_stin_ref_no"),"charindex"('/',"reverse"("st_track_det"."c_stin_ref_no"))+1)),
      "reverse"("substr"("reverse"("st_track_det_log"."c_stin_ref_no"),"charindex"('/',"reverse"("st_track_det_log"."c_stin_ref_no"))+1))) as "inward_ref_no",
      "st_track_stock_eb"."c_item_code",
      "item_mst"."c_name" as "itemname",
      "st_track_stock_eb"."c_batch_no",
      "st_track_stock_eb"."c_tray_code",
      --sum(st_track_stock_eb.n_qty )as n_qty ,
      cast("sum"("st_track_stock_eb"."n_qty"/"item_mst"."n_qty_per_box") as numeric(14)) as "pack_qty",
      cast("sum"("mod"("st_track_stock_eb"."n_qty","item_mst"."n_qty_per_box")) as numeric(14)) as "loose_qty",
      "st_track_stock_eb"."c_doc_no",
      "st_track_stock_eb"."c_supp_code",
      "act_mst"."c_name" as "suppname",
      "mfac_mst"."c_name"+'['+"mfac_mst"."c_code"+']' as "c_mfac_code",
      "st_track_stock_eb"."c_user"
      from "st_track_stock_eb"
        join "item_mst" on "item_mst"."c_code" = "st_track_stock_eb"."c_item_code"
        join "mfac_mst" on "mfac_mst"."c_code" = "item_mst"."c_mfac_code"
        join "act_mst" on "act_mst"."c_code" = "st_track_stock_eb"."c_supp_code"
        /*
(
select    c_doc_no,n_inout,c_item_code,c_batch_no,n_seq,n_qty,n_bal_qty,c_godown_code,c_stin_ref_no 
from st_track_det 
where st_track_det.c_godown_code ='5033'  and st_track_det.n_inout = 1
union 
select    c_doc_no,n_inout,c_item_code,c_batch_no,n_seq,n_qty,n_bal_qty,c_godown_code,c_stin_ref_no 
from st_track_det_log 
where st_track_det_log.c_godown_code ='5033' and st_track_det_log .n_inout = 1
)*/
        left outer join "st_track_det" on "st_track_det"."c_doc_no" = "st_track_stock_eb"."c_doc_no"
        and "st_track_det"."c_item_Code" = "st_track_stock_eb"."c_item_Code"
        and "st_track_det"."c_batch_no" = "st_track_stock_eb"."c_batch_no"
        left outer join "st_track_det_log" on "st_track_det_log"."c_doc_no" = "st_track_stock_eb"."c_doc_no"
        and "st_track_det_log"."c_item_Code" = "st_track_stock_eb"."c_item_Code"
        and "st_track_det_log"."c_batch_no" = "st_track_stock_eb"."c_batch_no"
      where "st_track_stock_eb"."c_tray_code" = @HdrData
      group by "st_track_stock_eb"."c_item_code","item_mst"."c_name","st_track_stock_eb"."c_batch_no","st_track_stock_eb"."c_tray_code",
      "st_track_stock_eb"."c_doc_no","st_track_stock_eb"."c_supp_code","act_mst"."c_name","c_mfac_code","inward_ref_no",
      "st_track_stock_eb"."c_user"
      having "sum"("st_track_stock_eb"."n_qty") > 0
      order by "c_supp_code" asc,"act_mst"."c_name" asc,"st_track_stock_eb"."c_tray_code" asc for xml raw,elements
  when 'get_summary' then
    /*	select 
count(distinct c_item_code)  item_count,
st_track_stock_eb.c_tray_code ,
st_track_stock_eb.c_supp_code ,
act_mst.c_name 

from st_track_stock_eb 
join act_mst on  act_mst.c_code = st_track_stock_eb.c_supp_code
Group by	st_track_stock_eb.c_tray_code ,
st_track_stock_eb.c_supp_code ,
act_mst.c_name ,c_item_code
having sum(n_qty )> 0 for xml raw,elements ;		
*/
    select distinct "t"."c_tray_Code" as "c_tray_code","t"."c_supp_code" as "c_supp_code","t"."actname" as "suppname",
      "count"("itemcode") as "item_count","t"."cat_code","cust_category_mst"."c_name" as "category_name"
      from(select distinct "c_item_code" as "itemcode",
          "sum"("n_qty") as "qty",
          "st_track_stock_eb"."c_tray_code",
          "st_track_stock_eb"."c_supp_code",
          "act_mst"."c_name" as "actname",
          "act_mst"."c_cust_category_code" as "cat_code"
          from "st_track_stock_eb"
            join "act_mst" on "act_mst"."c_code" = "st_track_stock_eb"."c_supp_code"
          group by "st_track_stock_eb"."c_tray_code",
          "st_track_stock_eb"."c_supp_code",
          "act_mst"."c_name","c_item_code","cat_code"
          having "sum"("n_qty") > 0
          order by "st_track_stock_eb"."c_tray_code" asc) as "t"
        join "cust_category_mst" on "t"."cat_code" = "cust_category_mst"."c_code"
      group by "t"."c_tray_Code","t"."c_supp_code","t"."actname","t"."cat_code","category_name" for xml raw,elements
  when 'tray_list' then
    select "list"(distinct "t"."c_tray_Code") as "c_tray_code"
      from(select distinct "c_item_code" as "itemcode","sum"("n_qty") as "qty",
          "st_track_stock_eb"."c_tray_code",
          "st_track_stock_eb"."c_supp_code",
          "act_mst"."c_name" as "actname"
          from "st_track_stock_eb"
            join "act_mst" on "act_mst"."c_code" = "st_track_stock_eb"."c_supp_code"
          group by "st_track_stock_eb"."c_tray_code",
          "st_track_stock_eb"."c_supp_code",
          "act_mst"."c_name","c_item_code"
          having "sum"("n_qty") > 0
          order by "st_track_stock_eb"."c_tray_code" asc) as "t"
      where "t"."itemcode" = @c_item_code for xml raw,elements
  end case
end;