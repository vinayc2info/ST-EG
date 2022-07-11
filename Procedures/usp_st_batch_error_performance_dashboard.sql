CREATE PROCEDURE "DBA"."usp_st_batch_error_performance_dashboard"( 
  in @gsBr char(6),
  in @devID char(200),
  in @sKey char(20),
  in @cIndex char(50),
  in @grp_code char(6) ) 
result( "is_xml_string" xml ) 
begin
  declare @d_ldate date;
  declare @c_user char(15);
  --for get_cnt_for_last_month_with_weekwise
  declare @today_date date;
  declare @curr_month_start_date date;
  declare @last_month_prev_date date;
  declare @dys numeric(2);
  declare @wk numeric(2);
  declare @start_week date;
  declare @first_week date;
  declare @second_week date;
  declare @third_week date;
  declare @fourth_week date;
  declare @fifth_week date;
  declare @Month_NO integer;
  if @devID = '' or @devID is null then
    set @gsBr = "http_variable"('gsBr'); --1
    set @devID = "http_variable"('devID'); --2
    set @sKey = "http_variable"('sKey'); --3
    set @cIndex = "http_variable"('cIndex'); --4
    set @grp_code = "http_variable"('grp_code'); --6
    set @c_user = "http_variable"('userid')
  end if;
  set @d_ldate = "uf_default_date"();
  //http://172.16.18.201:18513/ws_st_batch_error_performance_dashboard?&cIndex=get_cnt&grp_code=STGP&gsbr=503&devID=eb4604b2594f3a4e20042017010511664&sKEY=sKey&UserId=
  case @cIndex
  when 'get_userwise_todays_cnt' then
    select("st_batch_error"."c_user") as "c_user",
      "count"("st_batch_error"."c_item_code") as "Total_item",
      "count"(distinct "st_batch_error"."c_item_code") as "distinct_item_cnt"
      from "st_batch_error" join "st_store_stage_mst" on "st_store_stage_mst"."c_code" = "st_batch_error"."c_stage_code"
      where cast("st_batch_error"."d_date" as date) = @d_ldate
      and "st_store_stage_mst"."c_stage_grp_code" = @grp_code
      group by "c_user" for xml raw,elements
  when 'get_cnt' then
    select "count"("st_batch_error"."c_item_code") as "Total_item",
      "count"(distinct "st_batch_error"."c_item_code") as "distinct_item_cnt"
      from "st_batch_error" join "st_store_stage_mst" on "st_store_stage_mst"."c_code" = "st_batch_error"."c_stage_code"
      where "st_store_stage_mst"."c_stage_grp_code" = @grp_code
      and cast("st_batch_error"."d_date" as date) = @d_ldate for xml raw,elements
  when 'get_cnt_for_current_month' then
    select cast("st_batch_error"."d_date" as date) as "ddate",
      "count"("st_batch_error"."c_item_code") as "Total_item",
      "count"(distinct "st_batch_error"."c_item_code") as "distinct_item_cnt"
      from "st_batch_error" join "st_store_stage_mst" on "st_store_stage_mst"."c_code" = "st_batch_error"."c_stage_code"
      --month(uf_default_date()) = month(st_batch_error.d_date) and 
      where "month"(@d_ldate) = "month"("st_batch_error"."d_date")
      and "st_store_stage_mst"."c_stage_grp_code" = @grp_code
      group by "ddate" for xml raw,elements
  when 'get_cnt_for_last_month_with_weekwise' then
    //http://172.16.18.201:18513/ws_st_batch_error_performance_dashboard?&cIndex=get_cnt_for_last_month_with_weekwise&grp_code=STGP&gsbr=503&devID=eb4604b2594f3a4e20042017010511664&sKEY=sKey&UserId=
    set @today_date = "uf_default_date"();
    select "dateadd"("dd",-("day"(@today_date)-1),@today_date) as @curr_month_start_date into @curr_month_start_date;
    select @curr_month_start_date-1 as @last_month_prev_date into @last_month_prev_date; --2019-01-31
    set @Month_NO = "month"(@last_month_prev_date);
    set @start_week = "date"("dateadd"("dd",-("day"(@last_month_prev_date)-1),@last_month_prev_date));
    set @first_week = @start_week-("datepart"("dw",@start_week)-8);
    select if "month"(cast(@first_week as date)) = @Month_NO then @first_week else cast(0 as date) endif as "First_Week",
      if "month"("First_Week") = @Month_NO then "First_Week"+7 else cast(0 as date) endif as "Second_Week",
      if "month"("Second_Week") = @Month_NO then "Second_Week"+7 else cast(0 as date) endif as "third_week",
      if "month"("third_week") = @Month_NO then "third_week"+7 else cast(0 as date) endif as "four_week",
      if "month"("four_week"+7) = @Month_NO then "four_week"+7 endif as "fifth_week"
      into @first_week,@second_week,@third_week,@fourth_week,@fifth_week;
    select "sum"("First_week_item_cnt") as "first_week_item_cnt",
      "sum"("second_week_item_cnt") as "second_week_item_cnt",
      "sum"("third_week_item_cnt") as "third_week_item_cnt",
      "sum"("Fourth_week_item_cnt") as "fourth_week_item_cnt",
      "sum"("fifth_week_item_cnt") as "fifth_week_item_cnt"
      from(select "count"(distinct "c_item_code") as "First_week_item_cnt",
          0 as "second_week_item_cnt",
          0 as "third_week_item_cnt",
          0 as "Fourth_week_item_cnt",
          0 as "Fifth_week_item_cnt"
          from "st_batch_error" join "st_store_stage_mst" on "st_store_stage_mst"."c_code" = "st_batch_error"."c_stage_code"
          where cast("st_batch_error"."d_date" as date) >= @start_week
          and cast("st_batch_error"."d_date" as date) <= @first_week
          and "st_store_stage_mst"."c_stage_grp_code" = @grp_code union all
        select 0 as "First_week_item_cnt",
          "count"(distinct "c_item_code") as "second_week_item_cnt",
          0 as "third_week_item_cnt",
          0 as "Fourth_week_item_cnt",
          0 as "Fifth_week_item_cnt"
          from "st_batch_error" join "st_store_stage_mst" on "st_store_stage_mst"."c_code" = "st_batch_error"."c_stage_code"
          where cast("st_batch_error"."d_date" as date) > @first_week
          and cast("st_batch_error"."d_date" as date) <= @second_week
          and "st_store_stage_mst"."c_stage_grp_code" = @grp_code union all
        select 0 as "First_week_item_cnt",
          0 as "second_week_item_cnt",
          "count"(distinct "c_item_code") as "third_week_item_cnt",
          0 as "Fourth_week_item_cnt",
          0 as "Fifth_week_item_cnt"
          from "st_batch_error" join "st_store_stage_mst" on "st_store_stage_mst"."c_code" = "st_batch_error"."c_stage_code"
          where cast("st_batch_error"."d_date" as date) > @second_week
          and cast("st_batch_error"."d_date" as date) <= @third_week
          and "st_store_stage_mst"."c_stage_grp_code" = @grp_code union all
        select 0 as "First_week_item_cnt",
          0 as "second_week_item_cnt",
          0 as "third_week_item_cnt",
          "count"(distinct "c_item_code") as "Fourth_week_item_cnt",
          0 as "Fifth_week_item_cnt"
          from "st_batch_error" join "st_store_stage_mst" on "st_store_stage_mst"."c_code" = "st_batch_error"."c_stage_code"
          where cast("st_batch_error"."d_date" as date) > @third_week
          and cast("st_batch_error"."d_date" as date) <= @fourth_week
          and "st_store_stage_mst"."c_stage_grp_code" = @grp_code union all
        select 0 as "First_week_item_cnt",
          0 as "second_week_item_cnt",
          0 as "third_week_item_cnt",
          0 as "Fourth_week_item_cnt",
          "count"(distinct "c_item_code") as "Fifth_week_item_cnt"
          from "st_batch_error" join "st_store_stage_mst" on "st_store_stage_mst"."c_code" = "st_batch_error"."c_stage_code"
          where cast("st_batch_error"."d_date" as date) > @fourth_week
          and cast("st_batch_error"."d_date" as date) <= @fifth_week
          and "st_store_stage_mst"."c_stage_grp_code" = @grp_code) as "a" for xml raw,elements
  when 'get_cnt_for_yearwise_month' then
    select "month"("st_batch_error"."d_date") as "mnth",
      "count"("st_batch_error"."c_item_code") as "Total_item",
      "count"(distinct "st_batch_error"."c_item_code") as "distinct_item_cnt"
      from "st_batch_error" join "st_store_stage_mst" on "st_store_stage_mst"."c_code" = "st_batch_error"."c_stage_code"
      where "st_store_stage_mst"."c_stage_grp_code" = @grp_code
      group by "mnth" for xml raw,elements
  end case
end;