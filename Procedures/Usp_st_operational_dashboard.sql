CREATE PROCEDURE "DBA"."Usp_st_operational_dashboard"( 
  in @gsBr char(6),
  in @devID char(200),
  in @sKey char(20),
  in @cIndex char(30),
  in @workplace char(100),
  in @grp_code char(6) ) 
result( "is_xml_string" xml ) 
begin
  declare local temporary table "scan_user_pend_count"(
    "c_user" char(10) not null,
    "n_pend_count" numeric(10) null,
    primary key("c_user"),) on commit delete rows;declare local temporary table "temp_login_user"(
    "c_user" char(10) not null,
    "c_rack_grp_list" char(500) null,
    primary key("c_user" asc),) on commit preserve rows;declare local temporary table "temp_activ_user"(
    "c_user" char(10) not null,) on commit preserve rows;
  declare "total_avg_time" numeric(10,2);
  declare @c_user char(10);
  declare @stage_grp_code char(6);
  declare @dt_prev_working_date date;
  set @dt_prev_working_date = (if "dayname"("uf_default_date"()-1) = 'Sunday' then "uf_default_date"()-2 else "uf_default_date"()-1 endif);
  if(select "count"("d_non_working_date") from "non_working_dates" where "d_non_working_date" = @dt_prev_working_date) > 0 then
    set @dt_prev_working_date = @dt_prev_working_date-1;
    if(select "count"("d_non_working_date") from "non_working_dates" where "d_non_working_date" = @dt_prev_working_date) > 0 then
      set @dt_prev_working_date = @dt_prev_working_date-1
    end if end if;
  if @devID = '' or @devID is null then
    set @gsBr = "http_variable"('gsBr'); --1
    set @devID = "http_variable"('devID'); --2
    set @sKey = "http_variable"('sKey'); --3
    set @cIndex = "http_variable"('cIndex'); --4
    set @workplace = "http_variable"('workplace'); --5
    if @workplace = 'SCANNING' then set @workplace = 'SCANNIG' end if;
    set @grp_code = "http_variable"('grp_code') --6
  end if;
  set @c_user = "http_variable"('userid');
  --set @stage_grp_code = http_variable('stage_code');
  --set @workplace='PICKING';
  case @cIndex
  when 'get_stage_grp_list' then
    -- http://172.16.18.201:18513/ws_st_operational_dashboard?&cIndex=get_stage_grp_list&gsbr=503&devID=93041163b2d45c0208102015103228463&sKEY=sKey&UserId=AKSHAY%20BS
    select "st_store_stage_grp_mst"."c_code" as "stage_code",
      "st_store_stage_grp_mst"."c_name" as "grp_name"
      from "st_store_stage_grp_mst" for xml raw,elements
  when 'get_performance' then
    if @workplace = 'SCANNIG' then
      insert into "scan_user_pend_count"
        select "st_track_tray_move"."c_user","count"("st_track_det"."c_item_code") as "pending_item"
          from "st_track_det"
            left outer join "st_branch_user_det"
            on "left"(("st_track_det"."c_doc_no"),"charindex"('/',("st_track_det"."c_doc_no"))-1) = "st_branch_user_det"."br_code"
            left outer join "st_track_tray_move" on "st_track_det"."c_doc_no" = "st_track_tray_move"."c_doc_no"
            and "st_track_det"."c_tray_code" = "st_track_tray_move"."c_tray_code"
          where "n_complete" = 1 and "n_complete" <> 9 and "n_flag" = 7 and "st_track_det"."n_inout" = 0
          group by "st_track_tray_move"."c_user"
    end if;
    --http://192.168.250.101:18503/ws_st_operational_dashboard?&cIndex=get_performance&workplace=PICKING&grp_code=STGP&gsbr=503&devID=eb4604b2594f3a4e20042017010511664&sKEY=sKey&UserId=
    if @workplace = 'PICKING' then
      insert into "temp_login_user"
        select "st_store_login_det"."c_user_id","list"(distinct "st_store_login_det"."c_rack_grp_code")
          from "st_store_login_det" join "st_store_stage_det" on "st_store_login_det"."c_br_code" = "st_store_stage_det"."c_br_code"
            and "st_store_login_det"."c_rack_grp_code" = "st_store_stage_det"."c_rack_grp_code"
            and "st_store_login_det"."c_stage_code" = "st_store_stage_det"."c_stage_code"
            join "st_store_stage_mst" on "st_store_stage_mst"."c_br_code" = "st_store_stage_det"."c_br_code"
            and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
            left outer join "st_store_stage_grp_mst" on "st_store_stage_grp_mst"."c_code" = "st_store_stage_mst"."c_stage_grp_code"
          where "st_store_stage_mst"."n_flag" = 1
          and "st_store_login_det"."t_login_time" is not null
          and "st_store_stage_grp_mst"."c_code" = @grp_code
          group by "st_store_login_det"."c_user_id"
    else
      insert into "temp_login_user"
        select "st_store_login_det"."c_user_id","list"(distinct "st_store_login_det"."c_rack_grp_code")
          from "st_store_login_det" join "st_store_stage_det" on "st_store_login_det"."c_br_code" = "st_store_stage_det"."c_br_code"
            and "st_store_login_det"."c_rack_grp_code" = "st_store_stage_det"."c_rack_grp_code"
            and "st_store_login_det"."c_stage_code" = "st_store_stage_det"."c_stage_code"
            join "st_store_stage_mst" on "st_store_stage_mst"."c_br_code" = "st_store_stage_det"."c_br_code"
            and "st_store_stage_mst"."c_code" = "st_store_stage_det"."c_stage_code"
          where "st_store_stage_mst"."n_flag" = 1
          and "st_store_login_det"."t_login_time" is not null
          group by "st_store_login_det"."c_user_id"
    end if;
    select "c_user",
      "sum"("isnull"("Pending_count",0)) as "Pending_count",
      "sum"("isnull"("Tot_avg_time_today"/if "today_pick_count" = 0 then 1 else "today_pick_count" endif,0)) as "Tot_avg_time_today",
      "sum"("isnull"("Tot_avg_time_yestr"/if "yday_pick_count" = 0 then 1 else "yday_pick_count" endif,0)) as "Tot_avg_time_yestr",
      "sum"("isnull"("overall_pick_time"/if "overall_pick_count" = 0 then 1 else "overall_pick_count" endif,0)) as "overall_pick_time",
      "sum"("isnull"("Lw_avg"/if "Lw_pick_count" = 0 then 1 else "Lw_pick_count" endif,0)) as "Lw_avg",
      "sum"("today_pick_count") as "pick_count",
      "Pending_count" as "n_alloted",
      "target"
      -- 0 as "Pending_count",
      // and "st_track_det"."c_user" = "st"."c_user"
      /* if @workplace = 'SCANNIG' then
(select "count"("st_track_det"."c_item_code") as "pending_item"
from "st_track_det"
left outer join "st_branch_user_det"
on "left"(("st_track_det"."c_doc_no"),"charindex"('/',("st_track_det"."c_doc_no"))-1) = "st_branch_user_det"."br_code"
left outer join "st_track_tray_move" on "st_track_det"."c_doc_no" = "st_track_tray_move"."c_doc_no"
and "st_track_det"."c_tray_code" = "st_track_tray_move"."c_tray_code"
where "n_complete" = 1 and "n_complete" <> 9 and "n_flag" = 7 and "st"."c_user" = "st_track_tray_move"."c_user")
else
0
endif */
      from(select "st"."c_user"+'  -['+"isnull"("temp_login_user"."c_rack_grp_list",'NA')+']' as "c_user",
          if @workplace = 'PICKING' then
            (select "count"("st_track_det"."c_item_code")
              from "st_track_det"
                left outer join "st_store_stage_mst" on "st_store_stage_mst"."c_code" = "st_track_det"."c_stage_code"
                left outer join "st_store_stage_grp_mst" on "st_store_stage_grp_mst"."c_code" = "st_store_stage_mst"."c_stage_grp_code"
              where "n_complete" = 0 and "st_track_det"."n_inout" = 0 and "st_track_det"."c_godown_code" = '-'
              and "st_store_stage_grp_mst"."c_code" = @grp_code
              and "temp_login_user"."c_rack_grp_list" is not null
              and "c_rack_grp_code" = any(select "c_rack_grp_code" from "st_store_login_det" join "st_store_login" on "st_store_login_det"."c_br_code" = "st_store_login"."c_br_code"
                  and "st_store_login_det"."c_user_id" = "st_store_login"."c_user_id"
                where "st_store_login_det"."t_login_time" is not null and "st_store_login_det"."c_rack_grp_code" = "temp_login_user"."c_rack_grp_list"))
          else
            0
          endif as "Pending_count",
          "sum"("st"."n_avg_time_in_seconds") as "Tot_avg_time_today",
          0 as "Tot_avg_time_yestr",
          0 as "overall_pick_time",
          "sum"("st"."n_item_count") as "today_pick_count",
          0 as "yday_pick_count",
          0 as "overall_pick_count",
          0 as "Lw_avg",
          0 as "Lw_pick_count",
          0 as "target"
          from "st_daywise_emp_performance" as "st"
            left outer join "st_track_target" on "st_track_target"."c_stage_grp_code" = "st"."c_stage_grp_code"
            left outer join "temp_login_user" on "st"."c_user" = "temp_login_user"."c_user"
          where "d_date" = "uf_default_date"()
          and "st"."c_work_place" = 'PICKING'
          and "st"."c_stage_grp_code" = @grp_code
          and @workplace = 'PICKING'
          group by "st"."c_user","temp_login_user"."c_rack_grp_list" union all
        select "st"."c_user"+'  -['+"isnull"("temp_login_user"."c_rack_grp_list",'NA')+']' as "c_user",
          if @workplace = 'STOREIN' then
            (select "count"("st_track_det"."c_item_code")
              from "st_track_det" left outer join "st_store_stage_mst" on "st_store_stage_mst"."c_code" = "st_track_det"."c_stage_code"
                left outer join "st_store_stage_grp_mst" on "st_store_stage_grp_mst"."c_code" = "st_store_stage_mst"."c_stage_grp_code"
              where "n_complete" = 0 and "st_track_det"."n_inout" = 1 and "st_track_det"."c_godown_code" = '-'
              and "st_store_stage_grp_mst"."c_code" = @grp_code
              and "temp_login_user"."c_rack_grp_list" is not null
              and "c_rack_grp_code" = any(select "c_rack_grp_code" from "st_store_login_det" join "st_store_login" on "st_store_login_det"."c_br_code" = "st_store_login"."c_br_code"
                  and "st_store_login_det"."c_user_id" = "st_store_login"."c_user_id"
                where "st_store_login_det"."t_login_time" is not null and "st_store_login_det"."c_rack_grp_code" = "temp_login_user"."c_rack_grp_list"))
          else
            0
          endif as "Pending_count",
          "sum"("st"."n_avg_time_in_seconds") as "Tot_avg_time_today",
          0 as "Tot_avg_time_yestr",
          0 as "overall_pick_time",
          "sum"("st"."n_item_count") as "today_pick_count",
          0 as "yday_pick_count",
          0 as "overall_pick_count",
          0 as "Lw_avg",
          0 as "Lw_pick_count",
          0 as "target"
          from "st_daywise_emp_performance" as "st"
            left outer join "st_track_target" on "st_track_target"."c_stage_grp_code" = "st"."c_stage_grp_code"
            left outer join "temp_login_user" on "st"."c_user" = "temp_login_user"."c_user"
          where "d_date" = "uf_default_date"()
          and "st"."c_work_place" = 'STOREIN'
          and "st"."c_stage_grp_code" = @grp_code
          and @workplace = 'STOREIN'
          group by "st"."c_user","temp_login_user"."c_rack_grp_list" union all
        select "st"."c_user" as "c_user",
          0 as "pending_count",
          "sum"("st"."n_avg_time_in_seconds") as "Tot_avg_time_today",
          0 as "Tot_avg_time_yestr",
          0 as "overall_pick_time",
          "sum"("st"."n_item_count") as "today_pick_count",
          0 as "yday_pick_count",
          0 as "overall_pick_count",
          0 as "Lw_avg",
          0 as "Lw_pick_count",
          0 as "target"
          from "st_daywise_emp_performance" as "st"
          where "d_date" = "uf_default_date"()
          and "st"."c_work_place" = 'BARCODE PRINT'
          and @workplace = 'BARCODE PRINT'
          group by "c_user" union all
        select "st"."c_user" as "c_user",
          if @workplace = 'BARCODE VERIFICATION' then
            (select "count"() as "pending_item" from "st_track_tray_move" left outer join "st_branch_user_det"
                on "left"(("st_track_tray_move"."c_doc_no"),"charindex"('/',("st_track_tray_move"."c_doc_no"))-1) = "st_branch_user_det"."br_code"
              where "n_flag" = 0)
          else
            0
          endif as "Pending_count",
          "sum"("st"."n_avg_time_in_seconds") as "Tot_avg_time_today",
          0 as "Tot_avg_time_yestr",
          0 as "overall_pick_time",
          "sum"("st"."n_item_count") as "today_pick_count",
          0 as "yday_pick_count",
          0 as "overall_pick_count",
          0 as "Lw_avg",
          0 as "Lw_pick_count",
          0 as "target"
          from "st_daywise_emp_performance" as "st"
          where "d_date" = "uf_default_date"()
          and "st"."c_work_place" = 'BARCODE VERIFICATION'
          and @workplace = 'BARCODE VERIFICATION'
          group by "c_user" union all
        select "st"."c_user" as "c_user",
          "isnull"("max"("scan_user_pend_count"."n_pend_count"),0) as "Pending_count",
          "sum"("st"."n_avg_time_in_seconds") as "Tot_avg_time_today",
          0 as "Tot_avg_time_yestr",
          0 as "overall_pick_time",
          "sum"("st"."n_item_count") as "today_pick_count",
          0 as "yday_pick_count",
          0 as "overall_pick_count",
          0 as "Lw_avg",
          0 as "Lw_pick_count",
          0 as "target"
          from "st_daywise_emp_performance" as "st"
            left outer join "scan_user_pend_count" on "scan_user_pend_count"."c_user" = "st"."c_user"
          where "d_date" = "uf_default_date"()
          and "st"."c_work_place" = 'SCANNIG'
          and @workplace = 'SCANNIG'
          group by "c_user" union all
        select "st"."c_user"+'  -['+"isnull"("temp_login_user"."c_rack_grp_list",'NA')+']' as "c_user",
          0 as "Pending_count",
          0 as "Tot_avg_time_today",
          "sum"("st"."n_avg_time_in_seconds") as "Tot_avg_time_yestr",
          0 as "overall_pick_time",
          0 as "today_pick_count",
          "sum"("st"."n_item_count") as "yday_pick_count",
          0 as "overall_pick_count",
          0 as "Lw_avg",
          0 as "Lw_pick_count",
          0 as "target"
          from "st_daywise_emp_performance" as "st"
            join "st_store_stage_grp_mst" on "st_store_stage_grp_mst"."c_code" = "st"."c_stage_grp_code"
            join "temp_login_user" on "st"."c_user" = "temp_login_user"."c_user"
          where "d_date" = @dt_prev_working_date
          and "st"."c_work_place" = 'PICKING'
          and @workplace = 'PICKING'
          and "st"."c_stage_grp_code" = @grp_code
          group by "c_user" union all
        select "st"."c_user"+'  -['+"isnull"("temp_login_user"."c_rack_grp_list",'NA')+']' as "c_user",
          if @workplace = 'STOREIN' then
            (select "count"("st_track_det"."c_item_code")
              from "st_track_det" left outer join "st_store_stage_mst" on "st_store_stage_mst"."c_code" = "st_track_det"."c_stage_code"
                left outer join "st_store_stage_grp_mst" on "st_store_stage_grp_mst"."c_code" = "st_store_stage_mst"."c_stage_grp_code"
              where "n_complete" = 0 and "st_track_det"."n_inout" = 1 and "st_track_det"."c_godown_code" = '-'
              and "st_store_stage_grp_mst"."c_code" = @grp_code
              and "temp_login_user"."c_rack_grp_list" is not null
              and "c_rack_grp_code" = any(select "c_rack_grp_code" from "st_store_login_det" join "st_store_login" on "st_store_login_det"."c_br_code" = "st_store_login"."c_br_code"
                  and "st_store_login_det"."c_user_id" = "st_store_login"."c_user_id"
                where "st_store_login_det"."t_login_time" is not null and "st_store_login_det"."c_rack_grp_code" = "temp_login_user"."c_rack_grp_list"))
          else
            0
          endif as "Pending_count",
          "sum"("st"."n_avg_time_in_seconds") as "Tot_avg_time_today",
          0 as "Tot_avg_time_yestr",
          0 as "overall_pick_time",
          "sum"("st"."n_item_count") as "today_pick_count",
          0 as "yday_pick_count",
          0 as "overall_pick_count",
          0 as "Lw_avg",
          0 as "Lw_pick_count",
          0 as "target"
          from "st_daywise_emp_performance" as "st"
            left outer join "st_track_target" on "st_track_target"."c_stage_grp_code" = "st"."c_stage_grp_code"
            left outer join "temp_login_user" on "st"."c_user" = "temp_login_user"."c_user"
          where "d_date" = @dt_prev_working_date
          and "st"."c_work_place" = 'STOREIN'
          and "st"."c_stage_grp_code" = @grp_code
          and @workplace = 'STOREIN'
          group by "st"."c_user","temp_login_user"."c_rack_grp_list" union all
        select "st"."c_user" as "c_user",
          0 as "Pending_count",
          0 as "Tot_avg_time_today",
          "sum"("st"."n_avg_time_in_seconds") as "Tot_avg_time_yestr",
          0 as "overall_pick_time",
          0 as "today_pick_count",
          "sum"("st"."n_item_count") as "yday_pick_count",
          0 as "overall_pick_count",
          0 as "Lw_avg",
          0 as "Lw_pick_count",
          0 as "target"
          from "st_daywise_emp_performance" as "st"
          where "d_date" = @dt_prev_working_date
          and "st"."c_work_place" = 'BARCODE PRINT'
          and @workplace = 'BARCODE PRINT'
          group by "c_user" union all
        select "st"."c_user" as "c_user",
          0 as "Pending_count",
          0 as "Tot_avg_time_today",
          "sum"("st"."n_avg_time_in_seconds") as "Tot_avg_time_yestr",
          0 as "overall_pick_time",
          0 as "today_pick_count",
          "sum"("st"."n_item_count") as "yday_pick_count",
          0 as "overall_pick_count",
          0 as "Lw_avg",
          0 as "Lw_pick_count",
          0 as "target"
          from "st_daywise_emp_performance" as "st"
          where "d_date" = @dt_prev_working_date
          and "st"."c_work_place" = 'BARCODE VERIFICATION'
          and @workplace = 'BARCODE VERIFICATION'
          group by "c_user" union all
        select "st"."c_user" as "c_user",
          0 as "Pending_count",
          0 as "Tot_avg_time_today",
          "sum"("st"."n_avg_time_in_seconds") as "Tot_avg_time_yestr",
          0 as "overall_pick_time",
          0 as "today_pick_count",
          "sum"("st"."n_item_count") as "yday_pick_count",
          0 as "overall_pick_count",
          0 as "Lw_avg",
          0 as "Lw_pick_count",
          0 as "target"
          from "st_daywise_emp_performance" as "st"
          where "d_date" = @dt_prev_working_date
          and "st"."c_work_place" = 'SCANNIG'
          and @workplace = 'SCANNIG'
          group by "c_user" union all
        select "st"."c_user"+'  -['+"isnull"("temp_login_user"."c_rack_grp_list",'NA')+']' as "c_user",
          0 as "Pending_count",
          0 as "Tot_avg_time_today",
          0 as "Tot_avg_time_yestr",
          "sum"("st"."n_avg_time_in_seconds") as "overall_pick_time",
          0 as "today_pick_count",
          0 as "yday_pick_count",
          "sum"("st"."n_item_count") as "overall_pick_count",
          0 as "Lw_avg",
          0 as "Lw_pick_count",
          0 as "target"
          from "st_daywise_emp_performance" as "st"
            join "st_store_stage_grp_mst" on "st_store_stage_grp_mst"."c_code" = "st"."c_stage_grp_code"
            join "temp_login_user" on "st"."c_user" = "temp_login_user"."c_user"
          where "st"."c_work_place" = 'PICKING'
          and "st"."c_stage_grp_code" = @grp_code
          and @workplace = 'PICKING'
          group by "c_user" union all
        select "st"."c_user"+'  -['+"isnull"("temp_login_user"."c_rack_grp_list",'NA')+']' as "c_user",
          if @workplace = 'STOREIN' then
            (select "count"("st_track_det"."c_item_code")
              from "st_track_det" left outer join "st_store_stage_mst" on "st_store_stage_mst"."c_code" = "st_track_det"."c_stage_code"
                left outer join "st_store_stage_grp_mst" on "st_store_stage_grp_mst"."c_code" = "st_store_stage_mst"."c_stage_grp_code"
              where "n_complete" = 0 and "st_track_det"."n_inout" = 1 and "st_track_det"."c_godown_code" = '-'
              and "st_store_stage_grp_mst"."c_code" = @grp_code
              and "temp_login_user"."c_rack_grp_list" is not null
              and "c_rack_grp_code" = any(select "c_rack_grp_code" from "st_store_login_det" join "st_store_login" on "st_store_login_det"."c_br_code" = "st_store_login"."c_br_code"
                  and "st_store_login_det"."c_user_id" = "st_store_login"."c_user_id"
                where "st_store_login_det"."t_login_time" is not null and "st_store_login_det"."c_rack_grp_code" = "temp_login_user"."c_rack_grp_list"))
          else
            0
          endif as "Pending_count",
          "sum"("st"."n_avg_time_in_seconds") as "Tot_avg_time_today",
          0 as "Tot_avg_time_yestr",
          0 as "overall_pick_time",
          "sum"("st"."n_item_count") as "today_pick_count",
          0 as "yday_pick_count",
          0 as "overall_pick_count",
          0 as "Lw_avg",
          0 as "Lw_pick_count",
          0 as "target"
          from "st_daywise_emp_performance" as "st"
            left outer join "st_track_target" on "st_track_target"."c_stage_grp_code" = "st"."c_stage_grp_code"
            left outer join "temp_login_user" on "st"."c_user" = "temp_login_user"."c_user"
          where "st"."c_work_place" = 'STOREIN'
          and "st"."c_stage_grp_code" = @grp_code
          and @workplace = 'STOREIN'
          group by "st"."c_user","temp_login_user"."c_rack_grp_list" union all
        select "st"."c_user" as "c_user",
          0 as "Pending_count",
          0 as "Tot_avg_time_today",
          0 as "Tot_avg_time_yestr",
          "sum"("st"."n_avg_time_in_seconds") as "overall_pick_time",
          0 as "today_pick_count",
          0 as "yday_pick_count",
          "sum"("st"."n_item_count") as "overall_pick_count",
          0 as "Lw_avg",
          0 as "Lw_pick_count",
          0 as "target"
          from "st_daywise_emp_performance" as "st"
          where "st"."c_work_place" = 'BARCODE PRINT'
          and @workplace = 'BARCODE PRINT'
          group by "c_user" union all
        select "st"."c_user" as "c_user",
          0 as "Pending_count",
          0 as "Tot_avg_time_today",
          0 as "Tot_avg_time_yestr",
          "sum"("st"."n_avg_time_in_seconds") as "overall_pick_time",
          0 as "today_pick_count",
          0 as "yday_pick_count",
          "sum"("st"."n_item_count") as "overall_pick_count",
          0 as "Lw_avg",
          0 as "Lw_pick_count",
          0 as "target"
          from "st_daywise_emp_performance" as "st"
          where "st"."c_work_place" = 'BARCODE VERIFICATION'
          and @workplace = 'BARCODE VERIFICATION'
          group by "c_user" union all
        select "st"."c_user" as "c_user",
          0 as "Pending_count",
          0 as "Tot_avg_time_today",
          0 as "Tot_avg_time_yestr",
          "sum"("st"."n_avg_time_in_seconds") as "overall_pick_time",
          0 as "today_pick_count",
          0 as "yday_pick_count",
          "sum"("st"."n_item_count") as "overall_pick_count",
          0 as "Lw_avg",
          0 as "Lw_pick_count",
          0 as "target"
          from "st_daywise_emp_performance" as "st"
          where "st"."c_work_place" = 'SCANNIG'
          and @workplace = 'SCANNIG'
          group by "c_user" union all
        select "st"."c_user"+'  -['+"isnull"("temp_login_user"."c_rack_grp_list",'NA')+']' as "c_user",
          0 as "Pending_count",
          0 as "Tot_avg_time_today",
          0 as "Tot_avg_time_yestr",
          0 as "overall_pick_time",
          0 as "today_pick_count",
          0 as "yday_pick_count",
          0 as "overall_pick_count",
          "sum"("st"."n_avg_time_in_seconds") as "Lw_avg",
          "sum"("st"."n_item_count") as "Lw_pick_count",
          0 as "target"
          from "st_daywise_emp_performance" as "st"
            join "st_store_stage_grp_mst" on "st_store_stage_grp_mst"."c_code" = "st"."c_stage_grp_code"
            join "temp_login_user" on "st"."c_user" = "temp_login_user"."c_user"
          where "d_date"
          between if "trim"("left"("uf_date_of_previous_week"("uf_default_date"()),"charindex"('|',"uf_date_of_previous_week"("uf_default_date"()))-1)) = '' then
            null else "left"("uf_date_of_previous_week"("uf_default_date"()),"charindex"('|',"uf_date_of_previous_week"("uf_default_date"()))-1) endif
          and if "trim"("right"("uf_date_of_previous_week"("uf_default_date"()),"charindex"('|',"uf_date_of_previous_week"("uf_default_date"()))-1)) = '' then
            null else "right"("uf_date_of_previous_week"("uf_default_date"()),"charindex"('|',"uf_date_of_previous_week"("uf_default_date"()))-1) endif
          and "st"."c_work_place" = 'PICKING'
          and @workplace = 'PICKING'
          and "st"."c_stage_grp_code" = @grp_code
          group by "c_user" union all
        select "st"."c_user"+'  -['+"isnull"("temp_login_user"."c_rack_grp_list",'NA')+']' as "c_user",
          if @workplace = 'STOREIN' then
            (select "count"("st_track_det"."c_item_code")
              from "st_track_det" left outer join "st_store_stage_mst" on "st_store_stage_mst"."c_code" = "st_track_det"."c_stage_code"
                left outer join "st_store_stage_grp_mst" on "st_store_stage_grp_mst"."c_code" = "st_store_stage_mst"."c_stage_grp_code"
              where "n_complete" = 0 and "st_track_det"."n_inout" = 1 and "st_track_det"."c_godown_code" = '-'
              and "st_store_stage_grp_mst"."c_code" = @grp_code
              and "temp_login_user"."c_rack_grp_list" is not null
              and "c_rack_grp_code" = any(select "c_rack_grp_code" from "st_store_login_det" join "st_store_login" on "st_store_login_det"."c_br_code" = "st_store_login"."c_br_code"
                  and "st_store_login_det"."c_user_id" = "st_store_login"."c_user_id"
                where "st_store_login_det"."t_login_time" is not null and "st_store_login_det"."c_rack_grp_code" = "temp_login_user"."c_rack_grp_list"))
          else
            0
          endif as "Pending_count",
          "sum"("st"."n_avg_time_in_seconds") as "Tot_avg_time_today",
          0 as "Tot_avg_time_yestr",
          0 as "overall_pick_time",
          "sum"("st"."n_item_count") as "today_pick_count",
          0 as "yday_pick_count",
          0 as "overall_pick_count",
          0 as "Lw_avg",
          0 as "Lw_pick_count",
          0 as "target"
          from "st_daywise_emp_performance" as "st"
            left outer join "st_track_target" on "st_track_target"."c_stage_grp_code" = "st"."c_stage_grp_code"
            left outer join "temp_login_user" on "st"."c_user" = "temp_login_user"."c_user"
          where "d_date"
          between if "trim"("left"("uf_date_of_previous_week"("uf_default_date"()),"charindex"('|',"uf_date_of_previous_week"("uf_default_date"()))-1)) = '' then
            null else "left"("uf_date_of_previous_week"("uf_default_date"()),"charindex"('|',"uf_date_of_previous_week"("uf_default_date"()))-1) endif
          and if "trim"("right"("uf_date_of_previous_week"("uf_default_date"()),"charindex"('|',"uf_date_of_previous_week"("uf_default_date"()))-1)) = '' then
            null else "right"("uf_date_of_previous_week"("uf_default_date"()),"charindex"('|',"uf_date_of_previous_week"("uf_default_date"()))-1) endif
          and "st"."c_work_place" = 'STOREIN'
          and "st"."c_stage_grp_code" = @grp_code
          and @workplace = 'STOREIN'
          group by "st"."c_user","temp_login_user"."c_rack_grp_list" union all
        select "st"."c_user" as "c_user",
          0 as "Pending_count",
          0 as "Tot_avg_time_today",
          0 as "Tot_avg_time_yestr",
          0 as "overall_pick_time",
          0 as "today_pick_count",
          0 as "yday_pick_count",
          0 as "overall_pick_count",
          "sum"("st"."n_avg_time_in_seconds") as "Lw_avg",
          "sum"("st"."n_item_count") as "Lw_pick_count",
          0 as "target"
          from "st_daywise_emp_performance" as "st"
          where "d_date"
          between if "trim"("left"("uf_date_of_previous_week"("uf_default_date"()),"charindex"('|',"uf_date_of_previous_week"("uf_default_date"()))-1)) = '' then
            null else "left"("uf_date_of_previous_week"("uf_default_date"()),"charindex"('|',"uf_date_of_previous_week"("uf_default_date"()))-1) endif
          and if "trim"("right"("uf_date_of_previous_week"("uf_default_date"()),"charindex"('|',"uf_date_of_previous_week"("uf_default_date"()))-1)) = '' then
            null else "right"("uf_date_of_previous_week"("uf_default_date"()),"charindex"('|',"uf_date_of_previous_week"("uf_default_date"()))-1) endif
          and "st"."c_work_place" = 'BARCODE PRINT'
          and @workplace = 'BARCODE PRINT'
          group by "c_user" union all
        select "st"."c_user" as "c_user",
          0 as "Pending_count",
          0 as "Tot_avg_time_today",
          0 as "Tot_avg_time_yestr",
          0 as "overall_pick_time",
          0 as "today_pick_count",
          0 as "yday_pick_count",
          0 as "overall_pick_count",
          "sum"("st"."n_avg_time_in_seconds") as "Lw_avg",
          "sum"("st"."n_item_count") as "Lw_pick_count",
          0 as "target"
          from "st_daywise_emp_performance" as "st"
          where "d_date"
          between if "trim"("left"("uf_date_of_previous_week"("uf_default_date"()),"charindex"('|',"uf_date_of_previous_week"("uf_default_date"()))-1)) = '' then
            null else "left"("uf_date_of_previous_week"("uf_default_date"()),"charindex"('|',"uf_date_of_previous_week"("uf_default_date"()))-1) endif
          and if "trim"("right"("uf_date_of_previous_week"("uf_default_date"()),"charindex"('|',"uf_date_of_previous_week"("uf_default_date"()))-1)) = '' then
            null else "right"("uf_date_of_previous_week"("uf_default_date"()),"charindex"('|',"uf_date_of_previous_week"("uf_default_date"()))-1) endif
          and "st"."c_work_place" = 'BARCODE VERIFICATION'
          and @workplace = 'BARCODE VERIFICATION'
          group by "c_user" union all
        select "st"."c_user" as "c_user",
          0 as "Pending_count",
          0 as "Tot_avg_time_today",
          0 as "Tot_avg_time_yestr",
          0 as "overall_pick_time",
          0 as "today_pick_count",
          0 as "yday_pick_count",
          0 as "overall_pick_count",
          "sum"("st"."n_avg_time_in_seconds") as "Lw_avg",
          "sum"("st"."n_item_count") as "Lw_pick_count",
          0 as "target"
          from "st_daywise_emp_performance" as "st"
          where "d_date"
          between if "trim"("left"("uf_date_of_previous_week"("uf_default_date"()),"charindex"('|',"uf_date_of_previous_week"("uf_default_date"()))-1)) = '' then
            null else "left"("uf_date_of_previous_week"("uf_default_date"()),"charindex"('|',"uf_date_of_previous_week"("uf_default_date"()))-1) endif
          and if "trim"("right"("uf_date_of_previous_week"("uf_default_date"()),"charindex"('|',"uf_date_of_previous_week"("uf_default_date"()))-1)) = '' then
            null else "right"("uf_date_of_previous_week"("uf_default_date"()),"charindex"('|',"uf_date_of_previous_week"("uf_default_date"()))-1) endif
          and "st"."c_work_place" = 'SCANNIG'
          and @workplace = 'SCANNIG'
          group by "c_user" union all
        select 'UN-ALLOCATED' as "c_user",
          if @workplace = 'PICKING' then "count"("c_item_code") else 0 endif as "Pending_count",
          0 as "Tot_avg_time_today",
          0 as "Tot_avg_time_yestr",
          0 as "overall_pick_time",
          0 as "today_pick_count",
          0 as "yday_pick_count",
          0 as "overall_pick_count",
          0 as "Lw_avg",
          0 as "Lw_pick_count",
          "st_track_target"."n_target" as "target"
          from "st_track_det" left outer join "st_store_login_det" on "st_track_det"."c_rack_grp_code" = "st_store_login_det"."c_rack_grp_code"
            and "st_track_det"."c_stage_code" = "st_store_login_det"."c_stage_code"
            join "st_store_stage_mst" on "st_store_stage_mst"."c_code" = "st_track_det"."c_stage_code"
            join "st_store_stage_grp_mst" on "st_store_stage_grp_mst"."c_code" = "st_store_stage_mst"."c_stage_grp_code"
            left outer join "st_track_target" on "st_track_target"."c_stage_grp_code" = "st_store_stage_grp_mst"."c_code"
          where "st_track_det"."n_complete" = 0 and "st_track_det"."c_tray_code" is null and "st_track_det"."n_inout" = 0
          and "st_store_stage_grp_mst"."c_code" = @grp_code
          and "st_store_login_det"."t_login_time" is null
          group by "target") as "tem"
      group by "c_user","target"
      -- having pick_count > 0
      --  having("pending_count"+"pick_count") > 0
      order by "pick_count" desc,"Tot_avg_time_today" desc,"Tot_avg_time_yestr" desc for xml raw,elements
  when 'get_break_time' then
    select cast("dateadd"("minute","abs"("DATEDIFF"("minute","t_from_time","t_to_time"))/"isnull"("n_brk_time_per",0),"t_from_time") as time) as "From_time",
      "st_dept_brk_time"."t_to_time" as "To_time"
      from "st_dept_brk_time","st_track_setup"
      where "st_dept_brk_time"."c_work_place" = @workplace for xml raw,elements
  when 'get_estimated_time' then
    insert into "temp_activ_user"
      select distinct "c_user" from "st_daywise_emp_performance" where cast("d_date" as "datetime") > "DATEADD"("hour",-1,"GETDATE"()) and "c_work_place" = 'scannig';
    --select * from temp_activ_user
    select "isnull"("avg"("overal_time"),0) as "avg_pick_time",
      (select "count"("temp_activ_user"."c_user") from "temp_activ_user") as "loged_in_user",
      --8 as loged_in_user,
      (select "count"(distinct "c_doc_no"+"c_item_code") from "st_track_pick" where "st_track_pick"."n_inout" = 0
        and "st_track_pick"."n_qty"-("st_track_pick"."n_confirm_qty"+"st_track_pick"."n_reject_qty") > 0) as "pending_count"
      from(select "n_item_count" as "total_cnt",
          "n_avg_time_in_seconds" as "overall_pick_time",
          "overall_pick_time"/"total_cnt" as "overal_time"
          from "st_daywise_emp_performance","temp_activ_user"
          where "st_daywise_emp_performance"."c_user" = "temp_activ_user"."c_user"
          and "d_date" > "uf_default_date"()-3
          and "c_work_place" = @workplace
          group by "total_cnt","n_avg_time_in_seconds") as "a" for xml raw,elements
  when 'get_summary' then
    select cast("avg"("Tot_avg_time_today") as decimal(10,2)) as "Run_rate",cast("max"("Tot_avg_time_today") as decimal(10,2)) as "worst",
      cast("min"("Tot_avg_time_today") as decimal(10,2)) as "best","c_work_place","count"(distinct "c_user") as "user_count",
      if "c_work_place" = 'PICKING' then(select "count"("st_track_det"."c_item_code") from "st_track_det" where "n_complete" = 0 and "st_track_det"."n_inout" = 0
          and "c_godown_code" = '-')
      else if "c_work_place" = 'SCANNING' then(select "count"(distinct "c_item_code") from "st_track_pick" where "n_qty"-("n_confirm_qty"+"n_reject_qty") > 0)
        else 0
        endif
      endif as "pending_count","target"
      from(select "c_user" as "c_user","n_avg_time_in_seconds"/"n_item_count" as "Tot_avg_time_today",
          "st_daywise_emp_performance"."c_work_place" as "c_work_place","n_target" as "target"
          from "st_daywise_emp_performance" join "st_track_target" on "st_track_target"."c_work_place" = "st_daywise_emp_performance"."c_work_place"
          where "d_date" = "uf_default_date"()) as "t"
      group by "c_work_place","target" for xml raw,elements
  when 'get_user_performance' then
    if(select "count"("c_code") from "st_track_module_mst" where "c_code" = 'M00043' and "n_active" = 1) = 0 then
      select '' as "c_message" for xml raw,elements;
      return
    end if;
    select top 1 "c_stage_grp_code" into @stage_grp_code from "st_store_stage_mst" where "c_code" = @grp_code;
    select "avg"("overall_pick_time")
      --for barcode_02-02-19
      into "total_avg_time"
      from(select "c_user",
          "sum"("isnull"("overall_pick_time"/if "overall_pick_count" = 0 then 1 else "overall_pick_count" endif,0)) as "overall_pick_time"
          from(select "st_daywise_emp_performance"."c_user" as "c_user",
              "sum"("n_avg_time_in_seconds") as "overall_pick_time",
              "sum"("n_item_count") as "overall_pick_count"
              from "st_daywise_emp_performance"
                join "st_store_stage_grp_mst" on "st_store_stage_grp_mst"."c_code" = "st_daywise_emp_performance"."c_stage_grp_code"
              where "st_daywise_emp_performance"."c_work_place" = 'PICKING'
              and "st_daywise_emp_performance"."c_stage_grp_code" = @stage_grp_code
              and @workplace = 'PICKING'
              and "d_date" = "uf_default_date"()
              group by "c_user") as "tem"
          group by "c_user" union all
        select "c_user",
          "sum"("isnull"("overall_pick_time"/if "overall_pick_count" = 0 then 1 else "overall_pick_count" endif,0)) as "overall_pick_time"
          from(select "st_daywise_emp_performance"."c_user" as "c_user",
              "sum"("n_avg_time_in_seconds") as "overall_pick_time",
              "sum"("n_item_count") as "overall_pick_count"
              from "st_daywise_emp_performance"
                join "st_store_stage_grp_mst" on "st_store_stage_grp_mst"."c_code" = "st_daywise_emp_performance"."c_stage_grp_code"
              where "st_daywise_emp_performance"."c_work_place" = 'BARCODE VERIFICATION'
              and "st_daywise_emp_performance"."c_stage_grp_code" = @stage_grp_code
              and @workplace = 'BARCODE VERIFICATION'
              and "d_date" = "uf_default_date"()
              group by "c_user") as "tem"
          group by "c_user") as "ovrl";
    select "isnull"("sum"("Tot_avg_time_today"/if "today_pick_count" = 0 then 1 else "today_pick_count" endif),0) as "my_avg_time",
      "total_avg_time",
      "isnull"("sum"("Pending_count"),0) as "pending_count"
      -- added for barcode 02-02-19
      --c_user_id = @c_user and
      from(select if @workplace = 'PICKING' then
            (select "count"("st_track_det"."c_item_code")
              from "st_track_det"
              where "n_complete" = 0 and "st_track_det"."n_inout" = 0 and "st_track_det"."c_godown_code" = '-'
              and "c_rack_grp_code" = any(select "c_rack_grp_code" from "st_store_login_det" join "st_store_login" on "st_store_login_det"."c_br_code" = "st_store_login"."c_br_code"
                  and "st_store_login_det"."c_user_id" = "st_store_login"."c_user_id"
                where "st_store_login"."t_login_time" is not null and "st_store_login_det"."t_login_time" is not null
                and "st"."c_user" = "st_store_login"."c_user_id"))
          else
            0
          endif as "pending_count",
          "sum"("n_avg_time_in_seconds") as "Tot_avg_time_today",
          "sum"("n_item_count") as "today_pick_count"
          from "st_daywise_emp_performance" as "st"
            join "st_store_stage_grp_mst" on "st_store_stage_grp_mst"."c_code" = "st"."c_stage_grp_code"
          where "d_date" = "uf_default_date"()
          and "st"."c_work_place" = @workplace
          and "st"."c_work_place" = 'PICKING'
          and "st"."c_stage_grp_code" = @stage_grp_code
          and "st"."c_user" = @c_user
          group by "st"."c_user" union all
        select if @workplace = 'BARCODE VERIFICATION' then
            (select "count"("st_track_pick"."c_item_code")
              from "st_track_pick"
              where "st_track_pick"."n_inout" = 0 and "st_track_pick"."c_godown_code" = '-'
              and "c_barcode_user" = (select "c_user_id" from "st_store_login"
                where "st_store_login"."t_login_time" is not null
                and "st_store_login"."c_user_id" = "st"."c_user")
              and "st_track_pick"."c_barcode_user" is not null
              and "n_qty"-("n_confirm_qty"+"n_reject_qty") > 0)
          else
            0
          endif as "pending_count",
          "sum"("n_avg_time_in_seconds") as "Tot_avg_time_today",
          "sum"("n_item_count") as "today_pick_count"
          from "st_daywise_emp_performance" as "st"
            join "st_store_stage_grp_mst" on "st_store_stage_grp_mst"."c_code" = "st"."c_stage_grp_code"
          where "d_date" = "uf_default_date"()
          and "st"."c_work_place" = @workplace
          and "st"."c_work_place" = 'BARCODE VERIFICATION'
          and "st"."c_stage_grp_code" = @stage_grp_code
          and "st"."c_user" = @c_user
          group by "st"."c_user") as "tem" for xml raw,elements
  // added for getting workplaces
  when 'get_workplace' then
    select 'PICKING' as "c_name" from "dummy" union all
    select 'STOREIN' from "dummy" union all
    --  select 'BARCODE PRINT' from "dummy" union all
    select 'BARCODE VERIFICATION' from "dummy" union all
    select 'SCANNING' from "dummy" for xml raw,elements
  end case --  select 'STOREIN_EXP' from "dummy" for xml raw,elements
end;