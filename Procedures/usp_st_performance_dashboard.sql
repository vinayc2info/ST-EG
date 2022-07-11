CREATE PROCEDURE "DBA"."usp_st_performance_dashboard"( 
  in @gsBr char(6), --1
  in @devID char(200), --2
  in @sKey char(20), --3
  in @UserId char(20), --4
  in @cIndex char(30), --5
  in @GodownCode char(6), --6
  in @HdrData char(7000), --7
  in @DetData char(7000) )  --8
result( 
  "is_xml_string" xml ) 
begin
  /*
Author 		: Saneesh C G
Procedure	: usp_st_performance_dashboard
SERVICE		: ws_st_performance_dashboard
Date 		: 29-06-2016
modified by : 
Ldate 		: 
Purpose		: Performance Dashboard
Input		: 
Service Call (Format): 
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
  declare @cUser char(20);
  declare @d_date date;
  declare @total_login_time_picking numeric(15);
  declare @total_login_time_barcode numeric(15);
  declare @total_login_time_InwardAssignment numeric(15);
  --common <<
  if @devID = '' or @devID is null then
    set @gsBr = "http_variable"('gsBr'); --1
    set @devID = "http_variable"('devID'); --2
    set @sKey = "http_variable"('sKey'); --3
    set @UserId = "http_variable"('UserId'); --4
    set @cIndex = "http_variable"('cIndex'); --5
    set @GodownCode = "http_variable"('GodownCode'); --6
    set @HdrData = "http_variable"('HdrData'); --7
    set @DetData = "http_variable"('DetData') --8
  end if;
  //  if(select "count"() from "block_api") >= 1 then
  //    return
  //  end if;
  select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
  select "c_delim" into @RowSep from "ps_tab_delimiter" where "n_seq" = 1;
  set @ColMaxLen = "Length"(@ColSep);
  set @RowMaxLen = "Length"(@RowSep);
  set @GodownCode = '-';
  set @BrCode = "uf_get_br_code"(@gsBr);
  set @t_ltime = "left"("now"(),19);
  --set @d_ldate = uf_default_date();
  set @d_ldate = cast(@HdrData as date);
  case @cIndex
  when 'pick_summary' then
    --http://192.168.7.12:16503/ws_st_performance_dashboard?&cIndex=pick_summary&GodownCode=&gsbr=503&devID=1c59c2d63406d0f919052016053432103&sKEY=sKey&UserId=LAWRENCE&HdrData=2016-07-01
    select "sum"(if "c_stage" = 'RACK OPERATIONS' then "DATEDIFF"("second","isnull"("st_store_login_log"."t_login_time","now"()),"isnull"("st_store_login_log"."t_logout_time","now"())) else 0 endif),
      "sum"(if "c_stage" = 'Barcoding' then "DATEDIFF"("second","isnull"("st_store_login_log"."t_login_time","now"()),"isnull"("st_store_login_log"."t_logout_time","now"())) else 0 endif)
      into @total_login_time_picking,@total_login_time_barcode --1796252
      from "st_store_login_log"
      where cast("t_login_time" as date) = @d_ldate;
    select "st_daywise_emp_performance"."c_work_place" as "c_mode",
      ("st_daywise_emp_performance"."d_date") as "d_date",
      "count"("st_daywise_emp_performance"."c_user") as "user_count",
      @total_login_time_picking as "tot_login_time",
      "sum"("isnull"("st_daywise_emp_performance"."n_item_count",0)) as "tot_pick_item_count",
      "sum"("isnull"("st_daywise_emp_performance"."n_avg_time_in_seconds",0))/"sum"("isnull"("st_daywise_emp_performance"."n_item_count",0)) as "avg_picking_speed"
      from "st_daywise_emp_performance"
      where "c_work_place" = 'PICKING' and "d_date" = @d_ldate
      group by "d_date","st_daywise_emp_performance"."c_work_place" for xml raw,elements
  when 'pick_detail' then
    --http://192.168.7.12:16503/ws_st_performance_dashboard?&cIndex=pick_detail&GodownCode=&gsbr=503&devID=1c59c2d63406d0f919052016053432103&sKEY=sKey&UserId=LAWRENCE&HdrData=2016-07-01
    select "sum"(if "c_stage" = 'RACK OPERATIONS' then "DATEDIFF"("second","isnull"("st_store_login_log"."t_login_time","now"()),"isnull"("st_store_login_log"."t_logout_time","now"())) else 0 endif),
      "sum"(if "c_stage" = 'Barcoding' then "DATEDIFF"("second","isnull"("st_store_login_log"."t_login_time","now"()),"isnull"("st_store_login_log"."t_logout_time","now"())) else 0 endif)
      into @total_login_time_picking,@total_login_time_barcode --1796252
      from "st_store_login_log"
      where cast("t_login_time" as date) = @d_ldate;
    select "st_daywise_emp_performance"."d_date" as "d_date",
      "upper"(("st_daywise_emp_performance"."c_user")) as "c_user_id",
      @total_login_time_picking as "tot_login_time",
      "sum"("st_daywise_emp_performance"."n_item_count") as "item_count",
      "sum"("st_daywise_emp_performance"."n_avg_time_in_seconds")/"sum"("st_daywise_emp_performance"."n_item_count") as "avg_picking_speed"
      from "st_daywise_emp_performance"
      where "c_work_place" = 'PICKING'
      and "d_date" = @d_ldate
      group by "d_date","st_daywise_emp_performance"."c_user","c_user_id" for xml raw,elements
  when 'barcode_detail' then
    --http://192.168.7.12:16503/ws_st_performance_dashboard?&cIndex=barcode_detail&GodownCode=&gsbr=503&devID=1c59c2d63406d0f919052016053432103&sKEY=sKey&UserId=LAWRENCE&HdrData=2016-07-01
    select "sum"(if "c_stage" = 'RACK OPERATIONS' then "DATEDIFF"("second","isnull"("st_store_login_log"."t_login_time","now"()),"isnull"("st_store_login_log"."t_logout_time","now"())) else 0 endif),
      "sum"(if "c_stage" = 'Barcoding' then "DATEDIFF"("second","isnull"("st_store_login_log"."t_login_time","now"()),"isnull"("st_store_login_log"."t_logout_time","now"())) else 0 endif)
      into @total_login_time_picking,@total_login_time_barcode --1796252
      from "st_store_login_log"
      where cast("t_login_time" as date) = @d_ldate;
    select "st_daywise_emp_performance"."d_date" as "d_date",
      "upper"(("st_daywise_emp_performance"."c_user")) as "c_user_id",
      @total_login_time_barcode as "tot_login_time",
      "sum"("st_daywise_emp_performance"."n_item_count") as "item_count",
      "sum"("st_daywise_emp_performance"."n_avg_time_in_seconds")/"sum"("st_daywise_emp_performance"."n_item_count") as "avg_picking_speed"
      from "st_daywise_emp_performance"
      where "c_work_place" = 'BARCODE PRINT' and "d_date" = @d_ldate
      group by "c_user_id","c_user","d_date" for xml raw,elements
  when 'barcode_summary' then
    --http://192.168.7.12:16503/ws_st_performance_dashboard?&cIndex=barcode_summary&GodownCode=&gsbr=503&devID=1c59c2d63406d0f919052016053432103&sKEY=sKey&UserId=LAWRENCE&HdrData=2016-07-01
    select "sum"(if "c_stage" = 'RACK OPERATIONS' then "DATEDIFF"("second","isnull"("st_store_login_log"."t_login_time","now"()),"isnull"("st_store_login_log"."t_logout_time","now"())) else 0 endif),
      "sum"(if "c_stage" = 'Barcoding' then "DATEDIFF"("second","isnull"("st_store_login_log"."t_login_time","now"()),"isnull"("st_store_login_log"."t_logout_time","now"())) else 0 endif)
      into @total_login_time_picking,@total_login_time_barcode --1796252
      from "st_store_login_log"
      where cast("t_login_time" as date) = @d_ldate;
    select("st_daywise_emp_performance"."d_date") as "d_date",
      "count"("st_daywise_emp_performance"."c_user") as "user_count",
      @total_login_time_barcode as "tot_login_time",
      "sum"("st_daywise_emp_performance"."n_item_count") as "tot_pick_item_count",
      "sum"("st_daywise_emp_performance"."n_avg_time_in_seconds")/"sum"("st_daywise_emp_performance"."n_item_count") as "avg_picking_speed"
      from "st_daywise_emp_performance"
      where "c_work_place" = 'BARCODE PRINT' and "d_date" = @d_ldate
      group by "d_date" for xml raw,elements
  when 'inward_summary' then
    --http://192.168.7.12:16503/ws_st_performance_dashboard?&cIndex=inward_summary&GodownCode=&gsbr=503&devID=1c59c2d63406d0f919052016053432103&sKEY=sKey&UserId=LAWRENCE&HdrData=2016-07-01	
    select "sum"(if "c_stage" = 'RACK OPERATIONS' then "DATEDIFF"("second","isnull"("st_store_login_log"."t_login_time","now"()),"isnull"("st_store_login_log"."t_logout_time","now"())) else 0 endif),
      "sum"(if "c_stage" = 'Barcoding' then "DATEDIFF"("second","isnull"("st_store_login_log"."t_login_time","now"()),"isnull"("st_store_login_log"."t_logout_time","now"())) else 0 endif),
      "sum"(if "c_stage" = 'Inward Assignment' then "DATEDIFF"("second","isnull"("st_store_login_log"."t_login_time","now"()),"isnull"("st_store_login_log"."t_logout_time","now"())) else 0 endif)
      into @total_login_time_picking,@total_login_time_barcode,@total_login_time_InwardAssignment --1796252
      from "st_store_login_log"
      where cast("t_login_time" as date) = @d_ldate;
    select("st_daywise_emp_performance"."d_date") as "d_date",
      "count"("st_daywise_emp_performance"."c_user") as "user_count",
      @total_login_time_InwardAssignment as "tot_login_time",
      "sum"("st_daywise_emp_performance"."n_item_count") as "tot_pick_item_count",
      "sum"("st_daywise_emp_performance"."n_avg_time_in_seconds")/"sum"("st_daywise_emp_performance"."n_item_count") as "avg_picking_speed"
      from "st_daywise_emp_performance"
      where "c_work_place" = 'STOREIN'
      and "d_date" = @d_ldate
      group by "d_date" for xml raw,elements
  when 'inward_detail' then
    --http://192.168.7.12:16503/ws_st_performance_dashboard?&cIndex=inward_detail&GodownCode=&gsbr=503&devID=1c59c2d63406d0f919052016053432103&sKEY=sKey&UserId=LAWRENCE&HdrData=2016-07-01
    select "sum"(if "c_stage" = 'RACK OPERATIONS' then "DATEDIFF"("second","isnull"("st_store_login_log"."t_login_time","now"()),"isnull"("st_store_login_log"."t_logout_time","now"())) else 0 endif),
      "sum"(if "c_stage" = 'Barcoding' then "DATEDIFF"("second","isnull"("st_store_login_log"."t_login_time","now"()),"isnull"("st_store_login_log"."t_logout_time","now"())) else 0 endif),
      "sum"(if "c_stage" = 'Inward Assignment' then "DATEDIFF"("second","isnull"("st_store_login_log"."t_login_time","now"()),"isnull"("st_store_login_log"."t_logout_time","now"())) else 0 endif)
      into @total_login_time_picking,@total_login_time_barcode,@total_login_time_InwardAssignment --1796252
      from "st_store_login_log"
      where cast("t_login_time" as date) = @d_ldate;
    select "st_daywise_emp_performance"."d_date" as "d_date",
      "upper"(("st_daywise_emp_performance"."c_user")) as "c_user_id",
      @total_login_time_InwardAssignment as "tot_login_time",
      "sum"("st_daywise_emp_performance"."n_item_count") as "item_count",
      "sum"("st_daywise_emp_performance"."n_avg_time_in_seconds")/"sum"("st_daywise_emp_performance"."n_item_count") as "avg_picking_speed"
      from "st_daywise_emp_performance"
      where "c_work_place" = 'STOREIN'
      and "d_date" = @d_ldate
      group by "d_date","st_daywise_emp_performance"."c_user","c_user_id" for xml raw,elements
  when 'Gre_detail' then
    --http://192.168.7.12:16503/ws_st_performance_dashboard?&cIndex=Gre_detail&GodownCode=&gsbr=503&devID=1c59c2d63406d0f919052016053432103&sKEY=sKey&UserId=LAWRENCE&HdrData=2016-07-01
    select @d_ldate as "d_date",
      "c_user" as "c_user_id",
      "sum"("DATEDIFF"("second","t_st_time","isnull"("t_en_time","now"()))) as "tot_login_time",
      (select "count"()
        from "goods_rec_det" join "goods_rec_mst"
          on "goods_rec_det"."c_br_code" = "goods_rec_mst"."c_br_code"
          and "goods_rec_det"."c_year" = "goods_rec_mst"."c_year"
          and "goods_rec_det"."c_prefix" = "goods_rec_mst"."c_prefix"
          and "goods_rec_det"."n_srno" = "goods_rec_mst"."n_srno"
        where "goods_rec_mst"."c_user" = "report_log"."c_user"
        and "date"("goods_rec_det"."d_ldate") = "date"("report_log"."t_st_time")
        and "date"("goods_rec_det"."d_ldate") = @d_ldate) as "item_count",
      if "item_count" = 0 then
        0
      else
        "tot_login_time"/"item_count"
      endif as "avg_picking_speed"
      from "report_log"
      where "c_menu_name" = 'm_goodsreceiptentry'
      and "date"("t_st_time") = @d_ldate
      group by "c_user","item_count" for xml raw,elements
  when 'Gre_summary' then
    --http://192.168.7.12:16503/ws_st_performance_dashboard?&cIndex=Gre_summary&GodownCode=&gsbr=503&devID=1c59c2d63406d0f919052016053432103&sKEY=sKey&UserId=LAWRENCE&HdrData=2016-07-01	
    select "t"."d_date",
      "count"("c_user_id") as "user_count",
      "sum"("tot_login_time") as "tot_login_time",
      "sum"("item_count") as "tot_pick_item_count",
      if "tot_pick_item_count" = 0 then
        0
      else
        "tot_login_time"/"tot_pick_item_count"
      endif as "avg_picking_speed"
      from(select @d_ldate as "d_date",
          "c_user" as "c_user_id",
          "sum"("DATEDIFF"("second","t_st_time","isnull"("t_en_time","now"()))) as "tot_login_time",
          (select "count"()
            from "goods_rec_det" join "goods_rec_mst"
              on "goods_rec_det"."c_br_code" = "goods_rec_mst"."c_br_code"
              and "goods_rec_det"."c_year" = "goods_rec_mst"."c_year"
              and "goods_rec_det"."c_prefix" = "goods_rec_mst"."c_prefix"
              and "goods_rec_det"."n_srno" = "goods_rec_mst"."n_srno"
            where "goods_rec_mst"."c_user" = "report_log"."c_user"
            and "date"("goods_rec_det"."d_ldate") = "date"("report_log"."t_st_time")
            and "date"("goods_rec_det"."d_ldate") = @d_ldate) as "item_count",
          if "item_count" = 0 then
            "tot_login_time"
          else
            "tot_login_time"/"item_count"
          endif as "avg_picking_speed"
          from "report_log"
          where "c_menu_name" = 'm_goodsreceiptentry'
          and "date"("t_st_time") = @d_ldate
          group by "c_user","item_count") as "t"
      group by "t"."d_date" for xml raw,elements
  when 'Grn_detail' then
    --http://192.168.7.12:16503/ws_st_performance_dashboard?&cIndex=Grn_detail&GodownCode=&gsbr=503&devID=1c59c2d63406d0f919052016053432103&sKEY=sKey&UserId=LAWRENCE&HdrData=2016-07-01
    select @d_ldate as "d_date",
      "c_user" as "c_user_id",
      "sum"("DATEDIFF"("second","t_st_time","isnull"("t_en_time","now"()))) as "tot_login_time",
      (select "count"()
        from "grn_det" join "grn_mst"
          on "grn_det"."c_br_code" = "grn_mst"."c_br_code"
          and "grn_det"."c_year" = "grn_mst"."c_year"
          and "grn_det"."c_prefix" = "grn_mst"."c_prefix"
          and "grn_det"."n_srno" = "grn_mst"."n_srno"
          //        where "grn_mst"."c_user" = "report_log"."c_user"
          //        and "date"("grn_det"."d_ldate") = "date"("report_log"."t_st_time")
          and "date"("grn_det"."d_ldate") = @d_ldate) as "item_count",
      if "item_count" = 0 then
        0
      else
        "tot_login_time"/"item_count"
      endif as "avg_picking_speed"
      from "report_log"
      where "c_menu_name" = 'm_goodsreceiptnote'
      and "date"("t_st_time") = @d_ldate
      group by "c_user","item_count" for xml raw,elements
  when 'Grn_summary' then
    --http://192.168.7.12:16503/ws_st_performance_dashboard?&cIndex=Grn_summary&GodownCode=&gsbr=503&devID=1c59c2d63406d0f919052016053432103&sKEY=sKey&UserId=LAWRENCE&HdrData=2016-07-01	
    select "t"."d_date",
      "count"("c_user_id") as "user_count",
      "sum"("tot_login_time") as "tot_login_time",
      "sum"("item_count") as "tot_pick_item_count",
      if "tot_pick_item_count" = 0 then
        0
      else
        "tot_login_time"/"tot_pick_item_count"
      endif as "avg_picking_speed"
      //            where "grn_mst"."c_user" = "report_log"."c_user"
      //            and "date"("grn_det"."d_ldate") = "date"("report_log"."t_st_time")
      from(select @d_ldate as "d_date",
          "c_user" as "c_user_id",
          "sum"("DATEDIFF"("second","t_st_time","isnull"("t_en_time","now"()))) as "tot_login_time",
          (select "count"()
            from "grn_det" join "grn_mst"
              on "grn_det"."c_br_code" = "grn_mst"."c_br_code"
              and "grn_det"."c_year" = "grn_mst"."c_year"
              and "grn_det"."c_prefix" = "grn_mst"."c_prefix"
              and "grn_det"."n_srno" = "grn_mst"."n_srno"
              and "date"("grn_det"."d_ldate") = @d_ldate) as "item_count",
          if "item_count" = 0 then
            "tot_login_time"
          else
            "tot_login_time"/"item_count"
          endif as "avg_picking_speed"
          from "report_log"
          where "c_menu_name" = 'm_goodsreceiptnote'
          and "date"("t_st_time") = @d_ldate
          group by "c_user","item_count") as "t"
      group by "t"."d_date" for xml raw,elements
  when 'Get_summary' then
    --http://192.168.7.12:16503/ws_st_performance_dashboard?&cIndex=Get_summary&GodownCode=&gsbr=503&devID=1c59c2d63406d0f919052016053432103&sKEY=sKey&UserId=LAWRENCE&HdrData=2016-07-01
    select "sum"(if "c_stage" = 'RACK OPERATIONS' then "DATEDIFF"("second","isnull"("st_store_login_log"."t_login_time","now"()),"isnull"("st_store_login_log"."t_logout_time","now"())) else 0 endif),
      "sum"(if "c_stage" = 'Barcoding' then "DATEDIFF"("second","isnull"("st_store_login_log"."t_login_time","now"()),"isnull"("st_store_login_log"."t_logout_time","now"())) else 0 endif),
      "sum"(if "c_stage" = 'Inward Assignment' then "DATEDIFF"("second","isnull"("st_store_login_log"."t_login_time","now"()),"isnull"("st_store_login_log"."t_logout_time","now"())) else 0 endif)
      into @total_login_time_picking,@total_login_time_barcode,@total_login_time_InwardAssignment --1796252
      from "st_store_login_log"
      where cast("t_login_time" as date) = @d_ldate;
    select 'Picking' as "c_mode",
      ("st_daywise_emp_performance"."d_date") as "d_date",
      "count"("st_daywise_emp_performance"."c_user") as "user_count",
      @total_login_time_picking as "tot_login_time",
      "sum"("isnull"("st_daywise_emp_performance"."n_item_count",0)) as "tot_pick_item_count",
      "sum"("isnull"("st_daywise_emp_performance"."n_avg_time_in_seconds",0))/"sum"("isnull"("st_daywise_emp_performance"."n_item_count",0)) as "avg_picking_speed"
      from "st_daywise_emp_performance"
      where "c_work_place" = 'PICKING' and "d_date" = @d_ldate
      group by "d_date","st_daywise_emp_performance"."c_work_place" union
    select 'Barcoding' as "c_mode",
      ("st_daywise_emp_performance"."d_date") as "d_date",
      "count"("st_daywise_emp_performance"."c_user") as "user_count",
      @total_login_time_picking as "tot_login_time",
      "sum"("isnull"("st_daywise_emp_performance"."n_item_count",0)) as "tot_pick_item_count",
      "sum"("isnull"("st_daywise_emp_performance"."n_avg_time_in_seconds",0))/"sum"("isnull"("st_daywise_emp_performance"."n_item_count",0)) as "avg_picking_speed"
      from "st_daywise_emp_performance"
      where "c_work_place" = 'BARCODE PRINT' and "d_date" = @d_ldate
      group by "d_date","st_daywise_emp_performance"."c_work_place" union all
    select 'STOREIN(Inward Assignment )' as "c_mode",
      ("st_daywise_emp_performance"."d_date") as "d_date",
      "count"("st_daywise_emp_performance"."c_user") as "user_count",
      @total_login_time_InwardAssignment as "tot_login_time",
      "sum"("st_daywise_emp_performance"."n_item_count") as "tot_pick_item_count",
      "sum"("st_daywise_emp_performance"."n_avg_time_in_seconds")/"sum"("st_daywise_emp_performance"."n_item_count") as "avg_picking_speed"
      from "st_daywise_emp_performance"
      where "c_work_place" = 'STOREIN' and "d_date" = @d_ldate
      group by "d_date" union all
    select 'Goods Receipt Entry' as "c_mode",
      cast("t"."d_date" as date) as "d_date",
      "count"("c_user_id") as "user_count",
      "sum"("tot_login_time") as "tot_login_time",
      "sum"("item_count") as "tot_pick_item_count",
      if "tot_pick_item_count" = 0 then
        0
      else
        "tot_login_time"/"tot_pick_item_count"
      endif as "avg_picking_speed"
      --@d_ldate as "d_date",
      //            where "goods_rec_mst"."c_user" = "report_log"."c_user"
      //            and "date"("goods_rec_det"."d_ldate") = "date"("report_log"."t_st_time")
      from(select "date"("t_st_time") as "d_date",
          "c_user" as "c_user_id",
          "sum"("DATEDIFF"("second","t_st_time","isnull"("t_en_time","now"()))) as "tot_login_time",
          (select "count"()
            from "goods_rec_det" join "goods_rec_mst"
              on "goods_rec_det"."c_br_code" = "goods_rec_mst"."c_br_code"
              and "goods_rec_det"."c_year" = "goods_rec_mst"."c_year"
              and "goods_rec_det"."c_prefix" = "goods_rec_mst"."c_prefix"
              and "goods_rec_det"."n_srno" = "goods_rec_mst"."n_srno"
              and "goods_rec_det"."d_ldate" = @d_ldate) as "item_count",
          if "item_count" = 0 then
            "tot_login_time"
          else
            "tot_login_time"/"item_count"
          endif as "avg_picking_speed"
          from "report_log"
          where "c_menu_name" = 'm_goodsreceiptentry'
          and "date"("t_st_time") = @d_ldate
          group by "c_user","item_count","t_st_time") as "t"
      group by "t"."d_date" union all
    select 'Goods Receipt Note' as "c_mode",
      cast("t"."d_date" as date) as "d_date",
      "count"("c_user_id") as "user_count",
      "sum"("tot_login_time") as "tot_login_time",
      "sum"("item_count") as "tot_pick_item_count",
      if "tot_pick_item_count" = 0 then
        0
      else
        "tot_login_time"/"tot_pick_item_count"
      endif as "avg_picking_speed"
      --@d_ldate as "d_date",
      --"grn_mst"."c_user" = "report_log"."c_user"and 
      from(select "date"("t_st_time") as "d_date",
          "c_user" as "c_user_id",
          "sum"("DATEDIFF"("second","t_st_time","isnull"("t_en_time","now"()))) as "tot_login_time",
          (select "count"()
            from "grn_det" join "grn_mst"
              on "grn_det"."c_br_code" = "grn_mst"."c_br_code"
              and "grn_det"."c_year" = "grn_mst"."c_year"
              and "grn_det"."c_prefix" = "grn_mst"."c_prefix"
              and "grn_det"."n_srno" = "grn_mst"."n_srno"
            where "grn_det"."d_ldate" = @d_ldate) as "item_count",
          if "item_count" = 0 then
            "tot_login_time"
          else
            "tot_login_time"/"item_count"
          endif as "avg_picking_speed"
          from "report_log"
          where "c_menu_name" = 'm_goodsreceiptnote'
          and "date"("t_st_time") = @d_ldate
          group by "c_user","item_count","t_st_time") as "t"
      group by "t"."d_date" for xml raw,elements
  else
  end case
end;