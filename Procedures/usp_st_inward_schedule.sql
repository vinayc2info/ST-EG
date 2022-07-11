CREATE PROCEDURE "DBA"."usp_st_inward_schedule"( 
  in @gsBr char(6),
  in @devID char(200),
  in @sKey char(20),
  in @UserId char(20),
  in @PhaseCode char(6),
  in @StageCode char(6),
  in @RackGrpCode char(300),
  in @cIndex char(30),
  in @HdrData char(7000),
  in @DetData char(32767),
  in @GodownCode char(6) ) 
result( "is_xml_string" xml ) 
begin
  declare @reschedule_date char(10);
  declare @reschedule_time char(5);
  declare @reschedule_to_date char(10);
  declare @reschedule_to_time char(5);
  declare @ColPos integer;
  declare @RowPos integer;
  declare @ColMaxLen numeric(4);
  declare @RowMaxLen numeric(4);
  declare @driver_name char(25);
  declare @c_mobile char(10);
  declare @vehicle_no char(15);
  declare @n_seq numeric(2);
  declare @Tranbrcode char(6);
  declare @TranYear char(6);
  declare @TranPrefix char(6);
  declare @TranSrno numeric(15);
  declare @TranSeq numeric(15);
  declare @ColSep char(6);
  declare @RowSep char(6);
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
    set @GodownCode = "http_variable"('GodownCode'); --12	
    set @Tranbrcode = "http_variable"('custBrcode'); --12	
    set @TranYear = "http_variable"('custYear'); --12	
    set @TranPrefix = "http_variable"('custPrefix'); --12	
    set @TranSrno = "http_variable"('custSrno'); --12	reschdate	
    set @reschedule_date = "http_variable"('reschdate');
    set @reschedule_time = "http_variable"('reschtime'); --Toreschdate , Toreschtime
    set @reschedule_to_date = "http_variable"('Toreschdate');
    set @reschedule_to_time = "http_variable"('Toreschtime');
    set @HdrData = "http_variable"('HdrData'); --9
    set @DetData = "http_variable"('DetData') --10
  end if;
  select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
  select "c_delim" into @RowSep from "ps_tab_delimiter" where "n_seq" = 1;
  set @ColMaxLen = "Length"(@ColSep);
  set @RowMaxLen = "Length"(@RowSep);
  case @cIndex
  when 'day_wise_asn_det' then
    //http://10.89.209.19:49503/ws_st_inward_schedule?&cIndex=day_wise_asn_det&GodownCode=&gsbr=000&StageCode=&RackGrpCode=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=
    select "order_trans_det"."c_br_code",
      "order_trans_det"."c_year",
      "order_trans_det"."c_prefix",
      "order_trans_det"."n_srno",
      "order_trans_det"."n_seq",
      "order_trans_det"."c_br_code"+'/'+"order_trans_det"."c_year"+'/'+"order_trans_det"."c_prefix"+'/'+"trim"("str"("order_trans_det"."n_srno")) as "c_doc_no",
      "order_trans_det"."d_date" as "d_date",
      cast("order_trans_det"."t_ltime" as time) as "t_time",
      "order_mst"."c_cust_code" as "c_supp_code",
      "act_mst"."c_name" as "c_supp_name",
      "order_trans_det"."n_case" as "n_total_cases",
      "order_trans_det"."c_gate_no" as "c_gate_code",
      "order_trans_det"."c_lr_no" as "c_vehicle_no",
      "c_driver_name" as "c_driver_name",
      "c_driver_mobille_no" as "c_driver_mobille_no",
      cast("order_trans_det"."d_remind_from_date" as date) as "d_scheduled_date",
      cast("order_trans_det"."d_remind_from_date" as time) as "t_scheduled_time",
      cast("order_trans_det"."d_remind_to_date" as date) as "d_scheduled_to_date",
      cast("order_trans_det"."d_remind_to_date" as time) as "t_scheduled_to_time",
      "t_in_time" as "t_in_time",
      "t_out_time" as "t_out_time"
      from "order_trans_det"
        join "order_mst" on "order_mst"."c_br_code" = "order_trans_det"."c_br_code"
        and "order_trans_det"."c_year" = "order_mst"."c_year"
        and "order_trans_det"."c_prefix" = "order_mst"."c_prefix"
        and "order_trans_det"."n_srno" = "order_mst"."n_srno"
        join "act_mst" on "act_mst"."c_code" = "order_mst"."c_cust_code"
      where("order_trans_det"."n_cancel_flag" = 0
      and cast("d_remind_from_date" as date) = "uf_default_date"()
      and("t_in_time" is null and "t_out_time" is null)
      or("t_in_time" is not null and "t_out_time" is null))
      order by "d_scheduled_date" desc for xml raw,elements
  when 'expected_vehicle_det' then
    //http://10.89.209.19:49503/ws_st_inward_schedule?&cIndex=expected_vehicle_det&GodownCode=&gsbr=000&StageCode=&RackGrpCode=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=
    select "order_trans_det"."c_br_code",
      "order_trans_det"."c_year",
      "order_trans_det"."c_prefix",
      "order_trans_det"."n_srno",
      "order_trans_det"."n_seq",
      "order_trans_det"."c_br_code"+'/'+"order_trans_det"."c_year"+'/'+"order_trans_det"."c_prefix"+'/'+"trim"("str"("order_trans_det"."n_srno")) as "c_doc_no",
      "order_trans_det"."d_date" as "d_date",
      cast("order_trans_det"."t_ltime" as time) as "t_time",
      "order_mst"."c_cust_code" as "c_supp_code",
      "act_mst"."c_name" as "c_supp_name",
      "order_trans_det"."n_case" as "n_total_cases",
      "order_trans_det"."c_gate_no" as "c_gate_code",
      "order_trans_det"."c_lr_no" as "c_vehicle_no",
      "c_driver_name" as "c_driver_name",
      "c_driver_mobille_no" as "c_driver_mobille_no",
      cast("order_trans_det"."d_remind_from_date" as date) as "d_scheduled_date",
      cast("order_trans_det"."d_remind_from_date" as time) as "t_scheduled_time",
      cast("order_trans_det"."d_remind_to_date" as date) as "d_scheduled_to_date",
      cast("order_trans_det"."d_remind_to_date" as time) as "t_scheduled_to_time",
      "t_in_time" as "t_in_time",
      "t_out_time" as "t_out_time"
      from "order_trans_det"
        join "order_mst" on "order_mst"."c_br_code" = "order_trans_det"."c_br_code"
        and "order_trans_det"."c_year" = "order_mst"."c_year"
        and "order_trans_det"."c_prefix" = "order_mst"."c_prefix"
        and "order_trans_det"."n_srno" = "order_mst"."n_srno"
        join "act_mst" on "act_mst"."c_code" = "order_mst"."c_cust_code"
      where "t_in_time" is null and "t_out_time" is null and "order_trans_det"."n_cancel_flag" = 0
      and "order_trans_det"."d_remind_to_date" > "now"() and "order_trans_det"."d_remind_from_date" <= "now"() for xml raw,elements
  when 'arrived_vehicle_det' then
    //http://10.89.209.19:49503/ws_st_inward_schedule?&cIndex=arrived_vehicle_det&GodownCode=&gsbr=000&StageCode=&RackGrpCode=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=
    select "order_trans_det"."c_br_code",
      "order_trans_det"."c_year",
      "order_trans_det"."c_prefix",
      "order_trans_det"."n_srno",
      "order_trans_det"."n_seq",
      "order_trans_det"."c_br_code"+'/'+"order_trans_det"."c_year"+'/'+"order_trans_det"."c_prefix"+'/'+"trim"("str"("order_trans_det"."n_srno")) as "c_doc_no",
      "order_trans_det"."d_date" as "d_date",
      cast("order_trans_det"."t_ltime" as time) as "t_time",
      "order_mst"."c_cust_code" as "c_supp_code",
      "act_mst"."c_name" as "c_supp_name",
      "order_trans_det"."n_case" as "n_total_cases",
      "order_trans_det"."c_gate_no" as "c_gate_code",
      "isnull"("order_trans_det"."c_lr_no","order_trans_mst_det"."c_lr_no") as "c_vehicle_no",
      "c_driver_name" as "c_driver_name",
      "c_driver_mobille_no" as "c_driver_mobille_no",
      cast("order_trans_det"."d_remind_from_date" as date) as "d_scheduled_date",
      cast("order_trans_det"."d_remind_from_date" as time) as "t_scheduled_time",
      cast("order_trans_det"."d_remind_to_date" as date) as "d_scheduled_to_date",
      cast("order_trans_det"."d_remind_to_date" as time) as "t_scheduled_to_time",
      "t_in_time" as "t_in_time",
      "t_out_time" as "t_out_time"
      from "order_trans_det"
        left outer join "order_trans_mst_det"
        on "order_trans_det"."c_br_code" = "order_trans_mst_det"."c_br_code"
        and "order_trans_det"."c_year" = "order_trans_mst_det"."c_year"
        and "order_trans_det"."c_prefix" = "order_trans_mst_det"."c_prefix"
        and "order_trans_det"."n_srno" = "order_trans_mst_det"."n_srno"
        join "order_mst" on "order_mst"."c_br_code" = "order_trans_det"."c_br_code"
        and "order_trans_det"."c_year" = "order_mst"."c_year"
        and "order_trans_det"."c_prefix" = "order_mst"."c_prefix"
        and "order_trans_det"."n_srno" = "order_mst"."n_srno"
        join "act_mst" on "act_mst"."c_code" = "order_mst"."c_cust_code"
      where "t_in_time" is not null and(cast("t_in_time" as date) = "uf_default_date"() or "t_out_time" is null) and "order_trans_det"."n_cancel_flag" = 0 for xml raw,elements
  when 'delayed_vehicle_det' then
    //http://10.89.209.19:49503/ws_st_inward_schedule?&cIndex=delayed_vehicle_det&GodownCode=&gsbr=000&StageCode=&RackGrpCode=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=
    select "order_trans_det"."c_br_code",
      "order_trans_det"."c_year",
      "order_trans_det"."c_prefix",
      "order_trans_det"."n_srno",
      "order_trans_det"."n_seq",
      "order_trans_det"."c_br_code"+'/'+"order_trans_det"."c_year"+'/'+"order_trans_det"."c_prefix"+'/'+"trim"("str"("order_trans_det"."n_srno")) as "c_doc_no",
      "order_trans_det"."d_date" as "d_date",
      cast("order_trans_det"."t_ltime" as time) as "t_time",
      "order_mst"."c_cust_code" as "c_supp_code",
      "act_mst"."c_name" as "c_supp_name",
      "order_trans_det"."n_case" as "n_total_cases",
      "order_trans_det"."c_gate_no" as "c_gate_code",
      "order_trans_det"."c_lr_no" as "c_vehicle_no",
      "c_driver_name" as "c_driver_name",
      "c_driver_mobille_no" as "c_driver_mobille_no",
      cast("order_trans_det"."d_remind_from_date" as date) as "d_scheduled_date",
      cast("order_trans_det"."d_remind_from_date" as time) as "t_scheduled_time",
      cast("order_trans_det"."d_remind_to_date" as date) as "d_scheduled_to_date",
      cast("order_trans_det"."d_remind_to_date" as time) as "t_scheduled_to_time",
      "t_in_time" as "t_in_time",
      "t_out_time" as "t_out_time",
      "DATEDIFF"("hour","order_trans_det"."d_remind_from_date","now"()) as "delayed_hours",
      ("DATEDIFF"("minute","order_trans_det"."d_remind_from_date","now"()))-("delayed_hours"*60) as "delayed_minutes"
      from "order_trans_det"
        join "order_mst" on "order_mst"."c_br_code" = "order_trans_det"."c_br_code"
        and "order_trans_det"."c_year" = "order_mst"."c_year"
        and "order_trans_det"."c_prefix" = "order_mst"."c_prefix"
        and "order_trans_det"."n_srno" = "order_mst"."n_srno"
        join "act_mst" on "act_mst"."c_code" = "order_mst"."c_cust_code"
      where "t_in_time" is null and "order_trans_det"."d_remind_to_date" < "now"() and "order_trans_det"."n_cancel_flag" = 0 for xml raw,elements /*t_scheduled_time */ /*cast(now() as time) */
  when 'cancel_asn_schedule' then
    //http://10.89.209.19:49503/ws_st_inward_schedule?&cIndex=cancel_asn_schedule&GodownCode=&gsbr=000&StageCode=&RackGrpCode=&custBrcode=117&custYear=19&custPrefix=O&custSrno=4119&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=
    update "order_trans_det" set "order_trans_det"."n_cancel_flag" = 1
      where "order_trans_det"."c_br_code" = @TranbrCode
      and "order_trans_det"."c_year" = @TranYear
      and "order_trans_det"."c_prefix" = @TranPrefix
      and "order_trans_det"."n_srno" = @TranSrno;
    if sqlstate = '00000' then
      commit work;
      select 1 as "c_status",
        'Success' as "c_message" for xml raw,elements
    else
      rollback work;
      select 0 as "c_status",
        'Failure' as "c_message" for xml raw,elements
    end if when 'asn_reschedule' then
    //http://172.16.18.20:19503/ws_st_inward_schedule?&cIndex=asn_reschedule&custBrcode=503&custYear=19&custPrefix=O&custSrno=14594&
    //reschdate=2021-07-13&reschtime=9:00&Toreschdate=2021-07-13&Toreschtime=9:30&GodownCode=-&gsbr=503&devID=a3dcefdf75bc646d105092019064846055&sKEY=sKey&UserId=s kamble
    update "order_trans_det" set "d_remind_from_date" = @reschedule_date+' '+@reschedule_time+':00:000',
      "d_remind_to_date" = @reschedule_to_date+' '+@reschedule_to_time+':00:000'
      where "order_trans_det"."c_br_code" = @Tranbrcode
      and "order_trans_det"."c_year" = @TranYear
      and "order_trans_det"."c_prefix" = @TranPrefix
      and "order_trans_det"."n_srno" = @Transrno;
    if sqlstate = '00000' then
      commit work;
      select 1 as "c_status",
        'Success' as "c_message" for xml raw,elements
    else
      rollback work;
      select 0 as "c_status",
        'Failure' as "c_message" for xml raw,elements
    end if when 'driver_details' then
    //http://10.89.209.19:49503/ws_st_inward_schedule?&cIndex=driver_details&GodownCode=&gsbr=000&HdrData=165^^19^^O^^3978^^||&DetData=3^^KUMAR^^9901088888^^KA 01 EY 1234^^||4^^BHOOMIKA^^9901088888^^KA 01 EY 1234^^||&RackGrpCode=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=VKS
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @Tranbrcode = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --2 TranYear
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranYear = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --3 TranPrefix
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranPrefix = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --4 TranSrno
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranSrno = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --5 seq
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranSeq = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    while @DetData <> '' loop
      --1 n_seq
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @n_seq = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --2 Seq
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @driver_name = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --3 ItemCode
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @c_mobile = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      --4 batchreason
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @vehicle_no = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      select "Locate"(@DetData,@RowSep) into @RowPos;
      set @DetData = "SubString"(@DetData,@RowPos+@RowMaxLen);
      if @n_seq = 1 then
        update "order_trans_det" set "c_lr_no" = "replace"(@vehicle_no,' ',''),"c_driver_name" = @driver_name
          where "c_br_code" = @Tranbrcode
          and "c_year" = @TranYear
          and "c_prefix" = @TranPrefix
          and "n_srno" = @Transrno
      end if;
      insert into "order_trans_mst_det"
        ( "c_br_code","c_year","c_prefix","n_srno","n_seq","c_name","c_mobile_no","c_lr_no","d_date","t_time","n_cancel_flag","d_ldate","t_ltime","c_user","c_modiuser" ) on existing update defaults off values
        ( @Tranbrcode,@TranYear,@TranPrefix,@Transrno,@n_seq,@driver_name,@c_mobile,"replace"(@vehicle_no,' ',''),"today"(),"now"(),0,"today"(),"now"(),@UserId,@UserId ) 
    end loop;
    if sqlstate = '00000' then
      commit work;
      select 1 as "c_status",
        'Success' as "c_message" for xml raw,elements
    else
      rollback work;
      select 0 as "c_status",
        'Failure' as "c_message" for xml raw,elements
    end if when 'in_time' then
    //http://10.89.209.19:49503/ws_st_inward_schedule?&cIndex=in_time&GodownCode=&gsbr=000&HdrData=117^^19^^O^^4119^^1^^||&DetData=14:42:25&RackGrpCode=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=VKS
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @Tranbrcode = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --2 TranYear
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranYear = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --3 TranPrefix
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranPrefix = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --4 TranSrno
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranSrno = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --5 seq
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranSeq = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    if @DetData = '' or @DetData is null then
      set @DetData = null
    end if;
    update "order_trans_det" set "t_in_time" = @DetData,"d_ldate" = "today"(),"t_ltime" = "now"()
      where "c_br_code" = @Tranbrcode and "c_Year" = @TranYear
      and "n_seq" = @TranSeq and "c_prefix" = @TranPrefix and "n_srno" = @Transrno;
    select 1 as "c_status",
      'Success' as "c_message" for xml raw,elements
  when 'out_time' then
    //http://10.89.209.19:49503/ws_st_inward_schedule?&cIndex=out_time&GodownCode=&gsbr=000&HdrData=117^^19^^O^^4119^^1^^||&DetData=14:42:25&RackGrpCode=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=VKS
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @Tranbrcode = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --2 TranYear
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranYear = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --3 TranPrefix
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranPrefix = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --4 TranSrno
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranSrno = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --5 seq
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranSeq = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    if @DetData = '' or @DetData is null then
      set @DetData = null
    end if;
    update "order_trans_det" set "t_out_time" = @DetData,"d_ldate" = "today"(),"t_ltime" = "now"()
      where "c_br_code" = @Tranbrcode and "c_Year" = @TranYear
      and "n_seq" = @TranSeq and "c_prefix" = @TranPrefix and "n_srno" = @Transrno;
    if sqlstate = '00000' then
      commit work;
      select 1 as "c_status",
        'Success' as "c_message" for xml raw,elements
    else
      rollback work;
      select 0 as "c_status",
        'Failure' as "c_message" for xml raw,elements
    end if when 'update_gate_no' then
    //http://10.89.209.19:49503/ws_st_inward_schedule?&cIndex=update_gate_no&GodownCode=&gsbr=000&HdrData=117^^19^^O^^4119^^1^^||&DetData=GATE2&RackGrpCode=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=VKS
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @Tranbrcode = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --2 TranYear
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranYear = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --3 TranPrefix
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranPrefix = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --4 TranSrno
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranSrno = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --5 seq
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranSeq = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    if @DetData = '' or @DetData is null then
      set @DetData = null
    end if;
    update "order_trans_det" set "order_trans_det"."c_gate_no" = @DetData,"d_ldate" = "today"(),"t_ltime" = "now"()
      where "c_br_code" = @Tranbrcode and "c_Year" = @TranYear and "c_prefix" = @TranPrefix and "n_srno" = @Transrno
      and "n_seq" = @TranSeq and "order_trans_det"."n_cancel_flag" = 0;
    if sqlstate = '00000' then
      commit work;
      select 1 as "c_status",
        'Success' as "c_message" for xml raw,elements
    else
      rollback work;
      select 0 as "c_status",
        'Failure' as "c_message" for xml raw,elements
    end if when 'get_driver_details' then
    //http://10.89.209.19:49503/ws_st_inward_schedule?&cIndex=get_driver_details&GodownCode=&gsbr=000&HdrData=117^^19^^O^^4119^^||&DetData=&RackGrpCode=&devID=bc4009171fdf58c115112018104912239&sKEY=sKey&UserId=VKS
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @Tranbrcode = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --2 TranYear
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranYear = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --3 TranPrefix
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranPrefix = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --4 TranSrno
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranSrno = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    select "c_br_code","c_year","c_prefix","n_srno","n_seq","c_name","c_mobile_no","replace"("c_lr_no",' ','') as "c_lr_no"
      from "order_trans_mst_det" where "c_br_code" = @Tranbrcode and "c_Year" = @TranYear and "c_prefix" = @TranPrefix and "n_srno" = @Transrno order by "n_seq" asc for xml raw,elements
  end case
end;