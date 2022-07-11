CREATE EVENT "DBA"."act_day"
SCHEDULE "act_day" START TIME '03:55' ON ( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' )
DISABLE
HANDLER
begin
  declare "lspath","lsfilename","ls_time","lsLastSyncTime","lsAppPath" char(200);
  declare "lddir" integer;
  declare "lsQuery" long varchar;
  select "LEFT"("db_property"('file'),"LENGTH"("db_property"('file'))-("LENGTH"("DB_NAME"())*2+4)) into "lsAppPath";
  select "lsAppPath"+'Data2Cloud\\Supp_visit_day' into "lspath";
  select "XP_CMDSHELL"('mkdir '+"lspath") into "lddir";
  select "lspath"+'\\'+"substring"("db_name"(),4,3)+"replace"("replace"("replace"("left"("string"("now"()),19),':',''),' ',''),'-','')+'.csv' into "lsfilename";
  set "lsfilename" = "replace"("lsfilename",'\\','/'); --return;
  set "lsQuery"
     = 'Unload Select * from (Select '+''''+'c_code'+''''+' as c_code,'
    +''''+'c_br_code'+''''+' as c_br_code,'
    +''''+'d_from'+''''+' as d_from,'
    +''''+'c_day'+''''+' as c_day,'
    +''''+'c_createuser'+''''+' as c_createuser,'
    +''''+'d_date'+''''+' as d_date,'
    +''''+'n_cancel_flag'+''''+' as n_cancel_flag,'
    +''''+'d_ldate'+''''+' as d_ldate,'
    +''''+'t_ltime'+''''+' as t_ltime,'
    +''''+'n_lead_days'+''''+' as n_lead_days,'
    +''''+'c_modiuser'+''''+' as c_modiuser,'
    +''''+'c_name'+''''+' as c_name'
    +' union all '
    +'select a.c_code,a.c_br_code,DATEFORMAT(a.d_from,'+''''+'YYYY-MM-DD'+''''
    +') as d_from,a.c_day,a.c_createuser,DATEFORMAT(a.d_date,'+''''+'YYYY-MM-DD'+''''
    +') as d_date,string(a.n_cancel_flag) as n_cancel_flag,DATEFORMAT(a.d_ldate,'+''''+'YYYY-MM-DD'+''''
    +') as d_ldate,string(a.t_ltime) as t_ltime,string(a.n_lead_days) as n_lead_days,a.c_modiuser,s.c_name as c_name from act_day as a left join act_mst as s on a.c_code=s.c_code  where a.c_br_code = substr(db_name(),4,3) '
    +') a to '+''''+"lsfilename"+''''+' HEXADECIMAL OFF ESCAPES OFF QUOTES OFF';
  execute immediate "lsQuery"
end;
CREATE EVENT "DBA"."Auto_Day_End"
SCHEDULE "Auto_Day_End" START TIME '23:59' EVERY 24 HOURS
HANDLER
begin
  call "usp_auto_day_end"()
end;
CREATE EVENT "DBA"."auto_get_bounce"
SCHEDULE "schedule_auto_get_bounce" BETWEEN '00:00' AND '23:59' EVERY 5 MINUTES
HANDLER
begin
  insert into "Serv_log"( "c_name","t_ltime" ) values( 'usp_get_gdn_bounce_data',"now"() ) ;
  call "usp_get_gdn_bounce_data"();
  insert into "Serv_log"( "c_name","t_ltime" ) values( 'usp_get_gdn_bounce_data1',"now"() ) 
--print 'usp_get_gdn_bounce_data called ';
end;
CREATE EVENT "DBA"."Auto_item_mst_br_det"
SCHEDULE "Auto_item_mst_br_det" START TIME '00:00' EVERY 15 MINUTES
DISABLE
HANDLER
begin
  call "usp_auto_fetch_item_mst_br_det"()
end;
CREATE EVENT "DBA"."auto_order_push"
SCHEDULE "schedule_auto_order_push" BETWEEN '00:00' AND '23:59' EVERY 5 MINUTES
HANDLER
begin
  call "usp_get_order"()
end;
CREATE EVENT "DBA"."Auto_pomst_post"
SCHEDULE "Auto_pomst_post" START TIME '06:30' ON ( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' )
HANDLER
begin
  update "order_mst" set "n_post" = 1 where "c_br_code" = '503' and "c_reason_code" = 'AUTOOR' and "n_post" = 0 and "n_cancel_flag" = 0 and "d_date" = "today"();
  commit work
end;
CREATE EVENT "DBA"."Auto_Wf_shift_update"
SCHEDULE "Auto_Wf_shift_update" START TIME '00:07' EVERY 15 MINUTES ON ( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' )
DISABLE
HANDLER
begin
  update "jv_mst" set "n_shift" = (select "max"("n_srno") from "dba"."shift_mst" where "C_YEAR" = (select "MAX"("C_YEAR") from "DBA"."shift_mst")),"d_ldate" = "today"(),"t_ltime" = "now"() where "D_DATE" = "TODAY"() and "ISNULL"("N_SHIFT",0) = 0;
  commit work;
  update "jv_det"
    join "jv_mst" on "jv_det"."c_br_code" = "jv_mst"."c_br_code" and "jv_det"."c_prefix" = "jv_mst"."c_prefix" and "jv_det"."c_year" = "jv_mst"."c_year" and "jv_det"."n_srno" = "jv_mst"."n_srno"
    set "jv_det"."n_shift" = "jv_mst"."n_shift","jv_det"."d_ldate" = "today"(),"jv_det"."t_ltime" = "now"() where "jv_det"."D_DATE" = "TODAY"() and "ISNULL"("jv_det"."N_SHIFT",0) = 0;
  commit work;
  update "inv_mst_cash_rcvd"
    join "jv_mst" on "inv_mst_cash_rcvd"."c_br_code" = "jv_mst"."c_br_code" and "inv_mst_cash_rcvd"."c_prefix" = "jv_mst"."c_prefix" and "inv_mst_cash_rcvd"."c_year" = "jv_mst"."c_year" and "inv_mst_cash_rcvd"."n_srno" = "jv_mst"."n_srno"
    set "inv_mst_cash_rcvd"."n_shift" = "jv_mst"."n_shift","inv_mst_cash_rcvd"."d_ldate" = "today"(),"inv_mst_cash_rcvd"."t_ltime" = "now"() where "inv_mst_cash_rcvd"."D_DATE" = "TODAY"() and "ISNULL"("inv_mst_cash_rcvd"."N_SHIFT",0) = 0;
  commit work;
  update "Inv_mst" set "n_shift" = (select "max"("n_srno") from "dba"."shift_mst" where "C_YEAR" = (select "MAX"("C_YEAR") from "DBA"."shift_mst")),"d_ldate" = "today"(),"t_ltime" = "now"() where "D_DATE" = "TODAY"() and "ISNULL"("N_SHIFT",0) = 0;
  commit work;
  update "Inv_det"
    join "Inv_mst" on "Inv_det"."c_br_code" = "Inv_mst"."c_br_code" and "Inv_det"."c_prefix" = "Inv_mst"."c_prefix" and "Inv_det"."c_year" = "Inv_mst"."c_year" and "Inv_det"."n_srno" = "Inv_mst"."n_srno"
    set "Inv_det"."n_shift" = "Inv_mst"."n_shift","Inv_det"."d_ldate" = "today"(),"Inv_det"."t_ltime" = "now"() where "Inv_det"."D_DATE" = "TODAY"() and "ISNULL"("Inv_det"."N_SHIFT",0) = 0;
  commit work;
  update "inv_mst_cash_rcvd"
    join "Inv_mst" on "inv_mst_cash_rcvd"."c_br_code" = "Inv_mst"."c_br_code" and "inv_mst_cash_rcvd"."c_prefix" = "Inv_mst"."c_prefix" and "inv_mst_cash_rcvd"."c_year" = "Inv_mst"."c_year" and "inv_mst_cash_rcvd"."n_srno" = "Inv_mst"."n_srno"
    set "inv_mst_cash_rcvd"."n_shift" = "Inv_mst"."n_shift","inv_mst_cash_rcvd"."d_ldate" = "today"(),"inv_mst_cash_rcvd"."t_ltime" = "now"() where "inv_mst_cash_rcvd"."D_DATE" = "TODAY"() and "ISNULL"("inv_mst_cash_rcvd"."N_SHIFT",0) = 0;
  commit work;
  update "Crnt_mst" set "n_shift" = (select "max"("n_srno") from "dba"."shift_mst" where "C_YEAR" = (select "MAX"("C_YEAR") from "DBA"."shift_mst")),"d_ldate" = "today"(),"t_ltime" = "now"() where "D_DATE" = "TODAY"() and "ISNULL"("N_SHIFT",0) = 0;
  commit work;
  update "Crnt_det"
    join "Crnt_mst" on "Crnt_det"."c_br_code" = "Crnt_mst"."c_br_code" and "Crnt_det"."c_prefix" = "Crnt_mst"."c_prefix" and "Crnt_det"."c_year" = "Crnt_mst"."c_year" and "Crnt_det"."n_srno" = "Crnt_mst"."n_srno"
    set "Crnt_det"."n_shift" = "Crnt_mst"."n_shift","Crnt_det"."d_ldate" = "today"(),"Crnt_det"."t_ltime" = "now"() where "Crnt_det"."D_DATE" = "TODAY"() and "ISNULL"("Crnt_det"."N_SHIFT",0) = 0;
  commit work;
  update "inv_mst_cash_rcvd"
    join "Crnt_mst" on "inv_mst_cash_rcvd"."c_br_code" = "Crnt_mst"."c_br_code" and "inv_mst_cash_rcvd"."c_prefix" = "Crnt_mst"."c_prefix" and "inv_mst_cash_rcvd"."c_year" = "Crnt_mst"."c_year" and "inv_mst_cash_rcvd"."n_srno" = "Crnt_mst"."n_srno"
    set "inv_mst_cash_rcvd"."n_shift" = "Crnt_mst"."n_shift","inv_mst_cash_rcvd"."d_ldate" = "today"(),"inv_mst_cash_rcvd"."t_ltime" = "now"() where "inv_mst_cash_rcvd"."D_DATE" = "TODAY"() and "ISNULL"("inv_mst_cash_rcvd"."N_SHIFT",0) = 0;
  commit work
end;
CREATE EVENT "DBA"."ClosingStock"
SCHEDULE "clsstk" START TIME '01:45' ON ( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' )
DISABLE
HANDLER
begin
  declare "lspath","lsfilename","ls_time","lsLastSyncTime","lsAppPath" char(200);
  declare "lddir" integer;
  declare "lsJson" long varchar;
  select "LEFT"("db_property"('file'),"LENGTH"("db_property"('file'))-("LENGTH"("DB_NAME"())*2+4)) into "lsAppPath";
  select "lsAppPath"+'Data2Cloud\\ClosingStock' into "lspath";
  select "XP_CMDSHELL"('mkdir '+"lspath") into "lddir";
  select "lspath"+'\\'+"substring"("db_name"(),4,3)+'-'+"replace"("replace"("replace"("string"("now"()),':',''),' ',''),'-','')+'.json' into "lsfilename";
  select "isnull"("xp_read_file"("lsAppPath"+'lastSyncClsStk.txt'),'1900-01-01 00:00:00') into "lsLastSyncTime";
  set "ls_time" = "string"("now"());
  select "xp_write_file"("lsAppPath"+'lastSyncClsStk.txt',"ls_time") into "lddir";
  select '[{"brCode": "'+"substring"("db_name"(),4,3)+'","currentTime": "'+"String"("now"())+'",'
    +'"itemList":['+"List"('{"itemCode": "'+"itemCode"+'","batch":'+'['+"batchList"+']}')+']}]'
    into "lsJson"
    from(select "a"."c_item_code" as "itemCode",
        "list"('{"batchNo":"'+"replace"("replace"("replace"("replace"("a"."c_batch_no",',',''),'"',''),'''',''),'\\','')+'","expDt":"'+"string"("b"."d_exp_dt")
        +'","UOM":'+"string"("b"."n_qty_per_box")+',"mrpLoose":"'+"string"("b"."n_mrp")+'","qtyLoose":'+"string"(cast("a"."n_bal_qty" as numeric(12)))
        +',"purRateLoose":"'+"trim"("b"."n_pur_rate")+'"}') as "batchList"
        from "stock" as "a" join "stock_mst" as "b" on "a"."c_item_code" = "b"."c_item_code" and "a"."c_batch_no" = "b"."c_batch_no"
        where "a"."t_ltime" >= "lsLastSyncTime"
        group by "a"."c_item_code") as "itemList";
  select "XP_WRITE_FILE"("lsfilename","lsJson")
    into "lddir"
end;
CREATE EVENT "DBA"."ClosingStock_full"
SCHEDULE "ClosingStock_full" START TIME '02:30' ON ( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' )
DISABLE
HANDLER
begin
  declare "lspath","lsfilename","ls_time","lsLastSyncTime","lsAppPath" char(200);
  declare "lddir" integer;
  declare "lcnt" integer;
  declare "lsJson" long varchar;
  select "LEFT"("db_property"('file'),"LENGTH"("db_property"('file'))-("LENGTH"("DB_NAME"())*2+4)) into "lsAppPath";
  select "lsAppPath"+'Data2Cloud\\ClosingStock' into "lspath";
  select "XP_CMDSHELL"('mkdir '+"lspath") into "lddir";
  select "lspath"+'\\'+"substring"("db_name"(),4,3)+'-'+"replace"("replace"("replace"("string"("now"()),':',''),' ',''),'-','')+'.json' into "lsfilename";
  select "isnull"("xp_read_file"("lsAppPath"+'lastSyncClsStk.txt'),'1900-01-01 00:00:00') into "lsLastSyncTime";
  set "ls_time" = "string"("now"());
  select "xp_write_file"("lsAppPath"+'lastSyncClsStk.txt',"ls_time") into "lddir";
  select '[{"brCode": "'+"substring"("db_name"(),4,3)+'","currentTime": "'+"String"("now"())+'",'
    +'"itemList":['+"List"('{"itemCode": "'+"itemCode"+'","batch":'+'['+"batchList"+']}')+']}]'
    into "lsJson"
    from(select "a"."c_item_code" as "itemCode",
        "list"('{"batchNo":"'+"replace"("replace"("replace"("replace"("a"."c_batch_no",',',''),'"',''),'''',''),'\\','')+'","expDt":"'+"string"("b"."d_exp_dt")
        +'","UOM":'+"string"("b"."n_qty_per_box")+',"mrpLoose":"'+"string"("b"."n_mrp")+'","qtyLoose":'+"string"(cast("a"."n_bal_qty" as numeric(12)))
        +',"purRateLoose":"'+"trim"("b"."n_pur_rate")+'"}') as "batchList"
        from "stock" as "a" join "stock_mst" as "b" on "a"."c_item_code" = "b"."c_item_code" and "a"."c_batch_no" = "b"."c_batch_no" where "a"."n_bal_qty" > 0
        group by "a"."c_item_code") as "itemList";
  select "XP_WRITE_FILE"("lsfilename","lsJson")
    into "lddir"
end;
CREATE EVENT "DBA"."delete_old_logs"
SCHEDULE "ev" START TIME '00:30' EVERY 24 HOURS
HANDLER
begin
  declare @dbPath,@filePath varchar(1000);
  declare @retentionDays integer = 7;
  declare @diffMins,@fileSize numeric(18) = 0;
  declare @logPath varchar(1000) = 'dbEventLog.txt';
  declare @crTime,@modTime,@accTime "datetime";
  set @dbPath = "substr"("DB_PROPERTY"('LogName'),1,"length"("DB_PROPERTY"('LogName'))-"length"("db_property"('Name'))-4);
  set @logPath = @dbPath || @logPath;
  unload select '----Event - Delete Old Logs----' into file @logPath append on delimited by '' quotes off;
  unload select 'Started at: ' || "dateformat"("now"(),'yyyy-mm-dd hh:mm:ss') into file @logPath append on delimited by '' quotes off;
  unload select "t1"."server_name" || ': ' || "t1"."last_updated" || ', Diff: ' || "datediff"("minute","t1"."last_updated","max"("t1"."last_updated") over()) as "diffMin"
      from "sa_mirror_server_status"() as "t1"
        join "SYSMIRRORSERVER" as "t2" on "t1"."server_name" = "t2"."server_name"
      order by "t2"."parent" asc into file @logPath append on delimited by '' quotes off;
  select "max"("diffMin")
    into @diffMins
    from(select "datediff"("minute","t1"."last_updated","max"("t1"."last_updated") over()) as "diffMin",
         * from "sa_mirror_server_status"() as "t1"
          join "SYSMIRRORSERVER" as "t2" on "t1"."server_name" = "t2"."server_name"
        order by "t2"."parent" asc) as "t";
  unload select 'Max Sync Diff: ' || @diffMins into file @logPath append on delimited by '' quotes off;
  unload select '' into file @logPath append on delimited by '' quotes off;
  "lbl": loop
    select top 1 "file_path","file_size","create_date_time","modified_date_time","access_date_time"
      into @filePath,@fileSize,@crTime,@modTime,@accTime
      from "sp_list_directory"(@dbPath) as "t" where "t"."file_type" = 'F'
      and "t"."access_date_time" < "dateadd"("day",-@retentionDays,"today"())
      and "t"."file_path" <> "DB_PROPERTY"('LogName')
      and "t"."file_path" <> "DB_PROPERTY"('File')
      and "right"("t"."file_path",4) = '.LOG'
      and "isnumeric"("substr"("right"("t"."file_path",12),1,6)) = 1
      order by "t"."create_date_time" asc;
    if sqlcode = 100 then
      leave "lbl"
    end if;
    message 'File: ' || @filePath || ', File Size: ' || @fileSize || ', Created Time: ' || @crTime to client;
    unload select 'File: ' || @filePath into file @logPath append on delimited by '' quotes off;
    unload select 'File Size: ' || @fileSize into file @logPath append on delimited by '' quotes off;
    unload select 'Created Time: ' || @crTime into file @logPath append on delimited by '' quotes off;
    unload select 'Modified Time: ' || @modTime into file @logPath append on delimited by '' quotes off;
    unload select 'Accessed Time: ' || @accTime into file @logPath append on delimited by '' quotes off;
    unload select '' into file @logPath append on delimited by '' quotes off;
    call "xp_cmdshell"('attrib -r ' || @filePath);
    call "xp_cmdshell"('del ' || @filePath)
  end loop "lbl";
  unload select 'Ended at: ' || "dateformat"("now"(),'yyyy-mm-dd hh:mm:ss') into file @logPath append on delimited by '' quotes off;
  unload select '' into file @logPath append on delimited by '' quotes off
end;
CREATE EVENT "DBA"."Det_missing"
SCHEDULE "Det_missing" START TIME '22:45' ON ( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' )
DISABLE
HANDLER
begin
  declare "lspath","lsfilename","ls_time","lsLastSyncTime","lsAppPath" char(200);
  declare "lddir" integer;
  declare "lsQuery" long varchar;
  select "LEFT"("db_property"('file'),"LENGTH"("db_property"('file'))-("LENGTH"("DB_NAME"())*2+4)) into "lsAppPath";
  select "lsAppPath"+'Data2Cloud\\Det_missing' into "lspath";
  select "XP_CMDSHELL"('mkdir '+"lspath") into "lddir";
  select "lspath"+'\\'+"substring"("db_name"(),4,3)+"replace"("replace"("replace"("left"("string"("now"()),19),':',''),' ',''),'-','')+'.csv' into "lsfilename";
  set "lsfilename" = "replace"("lsfilename",'\\','/'); --return;
  set "lsQuery"
     = 'Unload Select * from (Select '+''''+'Tranno'+''''+' as Tranno,'
    +''''+'D_date'+''''+' as D_date,'
    +''''+'n_cancel_flag'+''''+' as n_cancel_flag,'
    +''''+'Missing'+''''+' as Missing,'
    +''''+'Trans'+''''+' as Trans'
    +' union all '
    +'select  c_br_code+'+'''/'''+'+c_year+'+'''/'''+'+c_prefix+'+'''/'''+'+string(n_srno) tranno,DATEFORMAT(d_date,'+''''+'YYYY-MM-DD'+''''+') as D_date,string(n_cancel_flag)n_cancel_flag,'+''''+'DET'+''''+' Missing,trans from ( '
    +' select m.c_br_code,m.c_year,m.c_prefix,m.n_srno,m.D_date,m.n_cancel_flag,'+''''+'inv'+''''+' as trans from inv_mst as m '
    +' left join inv_det d on '
    +' m.c_br_code=d.c_br_code and m.c_year=d.c_year and m.c_prefix=d.c_prefix and m.n_srno=d.n_srno'
    +' where m.d_date between Today()-7 and Today() and  m.c_br_code = substr(db_name(),4,3)   and d.c_br_code is null'
    +' union ALL '
    +' select m.c_br_code,m.c_year,m.c_prefix,m.n_srno,m.D_date,m.n_cancel_flag,'+''''+'crnt'+''''+' as trans from crnt_mst as m '
    +' left join crnt_det d on '
    +' m.c_br_code=d.c_br_code and m.c_year=d.c_year and m.c_prefix=d.c_prefix and m.n_srno=d.n_srno'
    +' where m.d_date between Today()-7 and Today() and  m.c_br_code = substr(db_name(),4,3)   and d.c_br_code is null'
    +' union ALL '
    +' select m.c_br_code,m.c_year,m.c_prefix,m.n_srno,m.D_date,m.n_cancel_flag,'+''''+'pur'+''''+' as  trans from pur_mst as m '
    +' left join pur_det d on '
    +' m.c_br_code=d.c_br_code and m.c_year=d.c_year and m.c_prefix=d.c_prefix and m.n_srno=d.n_srno'
    +' where m.d_date between Today()-7 and Today() and  m.c_br_code = substr(db_name(),4,3)   and d.c_br_code is null'
    +' union ALL '
    +' select m.c_br_code,m.c_year,m.c_prefix,m.n_srno,m.D_date,m.n_cancel_flag,'+''''+'nt_pur'+''''+' as  trans from nt_pur_mst as m '
    +' left join nt_pur_det d on '
    +' m.c_br_code=d.c_br_code and m.c_year=d.c_year and m.c_prefix=d.c_prefix and m.n_srno=d.n_srno'
    +' where m.d_date between Today()-7 and Today() and  m.c_br_code = substr(db_name(),4,3)   and d.c_br_code is null'
    +' union ALL '
    +' select m.c_br_code,m.c_year,m.c_prefix,m.n_srno,m.D_date,m.n_cancel_flag,'+''''+'Rtn_inv'+''''+' as  trans from rtn_inv_mst as m '
    +' left join rtn_inv_det d on '
    +' m.c_br_code=d.c_br_code and m.c_year=d.c_year and m.c_prefix=d.c_prefix and m.n_srno=d.n_srno'
    +' where m.d_date between Today()-7 and Today() and  m.c_br_code = substr(db_name(),4,3)   and d.c_br_code is null'
    +' union ALL '
    +' select m.c_br_code,m.c_year,m.c_prefix,m.n_srno,m.D_date,m.n_cancel_flag,'+''''+'GDN'+''''+' as  trans from gdn_mst as m '
    +' left join gdn_det d on '
    +' m.c_br_code=d.c_br_code and m.c_year=d.c_year and m.c_prefix=d.c_prefix and m.n_srno=d.n_srno'
    +' where m.d_date between Today()-7 and Today() and  m.c_br_code = substr(db_name(),4,3)   and d.c_br_code is null'
    +' union ALL '
    +' select m.c_br_code,m.c_year,m.c_prefix,m.n_srno,m.D_date,m.n_cancel_flag,'+''''+'GRN'+''''+' as  trans from grn_mst as m '
    +' left join grn_det d on '
    +' m.c_br_code=d.c_br_code and m.c_year=d.c_year and m.c_prefix=d.c_prefix and m.n_srno=d.n_srno'
    +' where m.d_date between Today()-7 and Today() and  m.c_br_code = substr(db_name(),4,3)   and d.c_br_code is null'
    +' union ALL '
    +' select m.c_br_code,m.c_year,m.c_prefix,m.n_srno,m.D_date,m.n_cancel_flag,'+''''+'Stckadj'+''''+' as  trans from stock_adj_mst as m '
    +' left join stock_adj_det d on '
    +' m.c_br_code=d.c_br_code and m.c_year=d.c_year and m.c_prefix=d.c_prefix and m.n_srno=d.n_srno'
    +' where m.d_date between Today()-7 and Today() and  m.c_br_code = substr(db_name(),4,3)   and d.c_br_code is null'
    +' union ALL '
    +' select m.c_br_code,m.c_year,m.c_prefix,m.n_srno,m.D_date,m.n_cancel_flag,'+''''+'Ord'+''''+' as  trans from ord_mst as m '
    +' left join ord_det d on '
    +' m.c_br_code=d.c_br_code and m.c_year=d.c_year and m.c_prefix=d.c_prefix and m.n_srno=d.n_srno'
    +' where m.d_date between Today()-7 and Today() and  m.c_br_code = substr(db_name(),4,3)   and d.c_br_code is null'
    +' union ALL '
    +' select m.c_br_code,m.c_year,m.c_prefix,m.n_srno,m.D_date,m.n_cancel_flag,'+''''+'Order'+''''+' as  trans from order_mst as m '
    +' left join order_det d on '
    +' m.c_br_code=d.c_br_code and m.c_year=d.c_year and m.c_prefix=d.c_prefix and m.n_srno=d.n_srno'
    +' where m.d_date between Today()-7 and Today() and  m.c_br_code = substr(db_name(),4,3)   and d.c_br_code is null'
    +' union ALL '
    +' select m.c_br_code,m.c_year,m.c_prefix,m.n_srno,m.D_date,m.n_cancel_flag,'+''''+'Godown'+''''+' as  trans from godown_tran_mst as m '
    +' left join godown_tran_det d on '
    +' m.c_br_code=d.c_br_code and m.c_year=d.c_year and m.c_prefix=d.c_prefix and m.n_srno=d.n_srno'
    +' where m.d_date between Today()-7 and Today() and  m.c_br_code = substr(db_name(),4,3)   and d.c_br_code is null'
    +' union ALL '
    +' select m.c_br_code,m.c_year,m.c_prefix,m.n_srno,m.D_date,m.n_cancel_flag,'+''''+'DBNT'+''''+' as  trans from DBNT_mst as m '
    +' left join DBNT_det d on '
    +' m.c_br_code=d.c_br_code and m.c_year=d.c_year and m.c_prefix=d.c_prefix and m.n_srno=d.n_srno'
    +' where m.d_date between Today()-7 and Today() and  m.c_br_code = substr(db_name(),4,3)   and d.c_br_code is null'
    +' ) as b'
    +') a to '+''''+"lsfilename"+''''+' HEXADECIMAL OFF ESCAPES OFF QUOTES OFF';
  execute immediate "lsQuery"
end;
CREATE EVENT "DBA"."Einvoice_l_date"
SCHEDULE "Einvoice_l_date" START TIME '23:15' ON ( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' )
DISABLE
HANDLER
begin
  update "gst_service_log" set "d_ldate" = "today"(),"t_ltime" = "now"() where "d_date" between "today"()-7 and "today"();
  commit work
end;
CREATE EVENT "DBA"."ev_rename_log"
SCHEDULE "e" START TIME '23:00' EVERY 24 HOURS
DISABLE
HANDLER
begin
  backup database directory
    '' transaction log only transaction log rename
end;
CREATE EVENT "DBA"."ev_rename_log_on_size" TYPE "GrowLog"
WHERE EVENT_CONDITION('LogSize') > 1000
HANDLER
begin
  backup database directory
    '' transaction log only transaction log rename
end;
CREATE EVENT "DBA"."event_get_gdn_bounce_data"
SCHEDULE "schedule_event_get_gdn_bounce_data" BETWEEN '00:00' AND '23:59' EVERY 5 MINUTES
HANDLER
begin
  declare @s_br_code char(6);
  declare @t_ltime "datetime";
  set @s_br_code = "uf_st_get_br_code"();
  select "max"("t_ltime")
    into @t_ltime from "gdn_bounced_items_import";
  insert into "Serv_log"( "c_name","t_ltime" ) values( 'uf_import_gdn_bounce_data',"now"() ) ;
  call "uf_import_gdn_bounce_data"(@s_br_code,@t_ltime);
  insert into "Serv_log"( "c_name","t_ltime" ) values( 'uf_import_gdn_bounce_data_1',"now"() ) 
end;
CREATE EVENT "DBA"."event_ord_status_04m503"
SCHEDULE "sch" BETWEEN '01:00' AND '23:59' EVERY 30 MINUTES
HANDLER
begin
  declare "s_app_path" char(1000);
  select "left"("db_property"('file'),"length"("db_property"('file'))-("length"("db_name"())*2+4))+'ecogreen.exe' into "s_app_path";
  set "s_app_path" = "s_app_path"+' '+"s_app_path"+'#04M503#orderstatus@#';
  call "xp_cmdshell"("s_app_path")
end;
CREATE EVENT "DBA"."event_trace_tray_move"
SCHEDULE "tray_sch" BETWEEN '01:00' AND '23:00' EVERY 10 MINUTES
DISABLE
HANDLER
begin
  call "usp_trace_tray_move_skip"()
end;
CREATE EVENT "DBA"."event_usp_send_email"
SCHEDULE "event_usp_send_email" BETWEEN '00:00' AND '23:59' EVERY 30 MINUTES
DISABLE
HANDLER
begin
  call "usp_send_email"()
end;
CREATE EVENT "DBA"."event_usp_send_email_err"
SCHEDULE "event_usp_send_email_err" BETWEEN '00:00' AND '23:59' EVERY 30 MINUTES
DISABLE
HANDLER
begin
  call "usp_send_email_err"()
end;
CREATE EVENT "DBA"."event_zero_stock_report"
SCHEDULE "sch" START TIME '00:05' EVERY 24 HOURS
DISABLE
HANDLER
begin
  call "usp_04m_zero_stock_report"()
end;
CREATE EVENT "DBA"."gdn_imp_mst"
SCHEDULE "gdn_imp_mst" START TIME '08:00' ON ( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' )
HANDLER
begin
  declare "lspath","lsfilename","ls_time","lsLastSyncTime","lsAppPath" char(200);
  declare "lddir" integer;
  declare "lsQuery" long varchar;
  select "LEFT"("db_property"('file'),"LENGTH"("db_property"('file'))-("LENGTH"("DB_NAME"())*2+4)) into "lsAppPath";
  select "lsAppPath"+'Data2Cloud\\gdn_imp_mst' into "lspath";
  select "XP_CMDSHELL"('mkdir '+"lspath") into "lddir";
  select "lspath"+'\\'+"substring"("db_name"(),4,3)+"replace"("replace"("replace"("left"("string"("now"()),19),':',''),' ',''),'-','')+'.csv' into "lsfilename";
  set "lsfilename" = "replace"("lsfilename",'\\','/'); --return;
  set "lsQuery"
     = 'Unload Select * from (Select '+''''+'c_br_code'+''''+' as c_br_code,'
    +''''+'c_year'+''''+' as c_year,'
    +''''+'c_prefix'+''''+' as c_prefix,'
    +''''+'n_srno'+''''+' as n_srno,'
    +''''+'d_date'+''''+' as d_date,'
    +''''+'c_ref_br_code'+''''+' as c_ref_br_code,'
    +''''+'n_total'+''''+' as n_total,'
    +''''+'c_reason_code'+''''+' as c_reason_code,'
    +''''+'n_cancel_flag'+''''+' as n_cancel_flag,'
    +''''+'d_ldate'+''''+' as d_ldate,'
    +''''+'c_order_year'+''''+' as c_order_year,'
    +''''+'c_order_prefix'+''''+' as c_order_prefix,'
    +''''+'n_order_no'+''''+' as n_order_no,'
    +''''+'n_approved'+''''+' as n_approved,'
    +''''+'c_user'+''''+' as c_user,'
    +''''+'t_time'+''''+' as t_time,'
    +''''+'n_shift'+''''+' as n_shift,'
    +''''+'t_ltime'+''''+' as t_ltime,'
    +''''+'gdnday'+''''+' as gdnday,'
    +''''+'gdnmonth'+''''+' as gdnmonth,'
    +''''+'gdnyear'+''''+' as gdnyear,'
    +''''+'n_cnt_no'+''''+' as n_cnt_no,'
    +''''+'gdnrefbr'+''''+' as gdnrefbr,'
    +''''+'n_gst_enabled'+''''+' as n_gst_enabled,'
    +''''+'c_from_gst_no'+''''+' as c_from_gst_no,'
    +''''+'n_from_gst_type'+''''+' as n_from_gst_type,'
    +''''+'c_to_gst_no'+''''+' as c_to_gst_no,'
    +''''+'n_gdn_type'+''''+' as n_gdn_type,'
    +''''+'c_cgst_act_code'+''''+' as c_cgst_act_code,'
    +''''+'n_cgst_amt'+''''+' as n_cgst_amt,'
    +''''+'c_sgst_act_code'+''''+' as c_sgst_act_code,'
    +''''+'n_sgst_amt'+''''+' as n_sgst_amt,'
    +''''+'c_igst_act_code'+''''+' as c_igst_act_code,'
    +''''+'n_igst_amt'+''''+' as n_igst_amt,'
    +''''+'c_cess_act_code'+''''+' as c_cess_act_code,'
    +''''+'n_cess_amt'+''''+' as n_cess_amt,'
    +''''+'c_state_code'+''''+' as c_state_code,'
    +''''+'c_eway_bill_no'+''''+' as c_eway_bill_no,'
    +''''+'n_pk'+''''+' as n_pk,'
    +''''+'n_to_gst_type'+''''+' as n_to_gst_type,'
    +''''+'c_order_br_code'+''''+' as c_order_br_code,'
    +''''+'n_cogs_amt'+''''+' as n_cogs_amt,'
    +''''+'n_tcs_per'+''''+' as n_tcs_per,'
    +''''+'n_tcs_taxable_amt'+''''+' as n_tcs_taxable_amt,'
    +''''+'n_tcs_amt'+''''+' as n_tcs_amt,'
    +''''+'c_note'+''''+' as c_note'
    +' union all '
    +' select c_br_code,c_year,c_prefix,string(n_srno) as n_srno,DATEFORMAT(d_date,'+''''+'YYYY-MM-DD'+''''+') as d_date,c_ref_br_code,string(n_total) as n_total,c_reason_code,'
    +' string(n_cancel_flag) as n_cancel_flag,DATEFORMAT(d_ldate,'+''''+'YYYY-MM-DD'+''''+') as d_ldate,c_order_year,c_order_prefix,string(n_order_no) as n_order_no,string(n_approved) as n_approved,  '
    +' c_user,string(t_time) as t_time,string(n_shift) as n_shift,string(t_ltime) as t_ltime,string(gdnday) as gdnday,string(gdnmonth) as gdnmonth,string(gdnyear) as gdnyear,string(n_cnt_no) as n_cnt_no, '
    +' string(gdnrefbr) as gdnrefbr,string(n_gst_enabled) as n_gst_enabled,c_from_gst_no,string(n_from_gst_type) as n_from_gst_type,c_to_gst_no,string(n_gdn_type) as n_gdn_type,c_cgst_act_code, '
    +' string(n_cgst_amt) as n_cgst_amt,c_sgst_act_code,string(n_sgst_amt) as n_sgst_amt,c_igst_act_code,string(n_igst_amt) as n_igst_amt,c_cess_act_code, '
    +' string(n_cess_amt) as n_cess_amt,c_state_code,c_eway_bill_no,string(n_pk) as n_pk,string(n_to_gst_type) as n_to_gst_type,c_order_br_code,string(n_cogs_amt) as n_cogs_amt, '
    +' string(n_tcs_per) as n_tcs_per,string(n_tcs_taxable_amt) as n_tcs_taxable_amt,string(n_tcs_amt) as n_tcs_amt,replace(c_note,'+''''+','+''''+','+''''+'-'+''''+') as c_note from gdn_imp_mst  where c_year=(select max(c_year) from gdn_imp_mst) '
    +') a to '+''''+"lsfilename"+''''+' HEXADECIMAL OFF ESCAPES OFF QUOTES OFF';
  print "lsQuery";
  execute immediate "lsQuery"
end;
CREATE EVENT "DBA"."Item_mst_br_det"
SCHEDULE "Item_mst_br_det" START TIME '04:00' ON ( 'Monday' )
HANDLER
begin
  declare "lspath","lsfilename","ls_time","lsLastSyncTime","lsAppPath" char(200);
  declare "lddir" integer;
  declare "lsQuery" long varchar;
  select "LEFT"("db_property"('file'),"LENGTH"("db_property"('file'))-("LENGTH"("DB_NAME"())*2+4)) into "lsAppPath";
  select "lsAppPath"+'Data2Cloud\\Item_mst_br_det' into "lspath";
  select "XP_CMDSHELL"('mkdir '+"lspath") into "lddir";
  select "lspath"+'\\'+"substring"("db_name"(),4,3)+"replace"("replace"("replace"("left"("string"("now"()),19),':',''),' ',''),'-','')+'.csv' into "lsfilename";
  set "lsfilename" = "replace"("lsfilename",'\\','/'); --return;
  set "lsQuery"
     = 'Unload Select * from (Select '+''''+'c_code'+''''+' as c_code,'
    +''''+'c_br_code'+''''+' as c_br_code,'
    +''''+'n_reorder_qty'+''''+' as n_reorder_qty,'
    +''''+'n_max_qty'+''''+' as n_max_qty,'
    +''''+'c_supp_code'+''''+' as c_supp_code,'
    +''''+'n_stock_day'+''''+' as n_stock_day,'
    +''''+'n_sale_days'+''''+' as n_sale_days,'
    +''''+'c_dc_div'+''''+' as c_dc_div,'
    +''''+'d_ldate'+''''+' as d_ldate,'
    +''''+'n_min_stock_day'+''''+' as n_min_stock_day,'
    +''''+'t_ltime'+''''+' as t_ltime,'
    +''''+'c_order_type_code'+''''+' as c_order_type_code,'
    +''''+'n_order_lot'+''''+' as n_order_lot,'
    +''''+'n_lock_po'+''''+' as n_lock_po,'
    +''''+'n_lock_ord_level_reset'+''''+' as n_lock_ord_level_reset,'
    +''''+'t_last_minmax_reset_time'+''''+' as t_last_minmax_reset_time,'
    +''''+'n_consumption'+''''+' as n_consumption,'
    +''''+'n_weight_loss'+''''+' as n_weight_loss,'
    +''''+'d_maxmin_till_date'+''''+' as d_maxmin_till_date,'
    +''''+'n_squot_required'+''''+' as n_squot_required,'
    +''''+'n_normal_max_sale_qty'+''''+' as n_normal_max_sale_qty,'
    +''''+'n_order_lot_calc'+''''+' as n_order_lot_calc,'
    +''''+'n_reset_tolerance_per'+''''+' as n_reset_tolerance_per,'
    +''''+'n_upd_dynamic_minmax_days'+''''+' as n_upd_dynamic_minmax_days,'
    +''''+'c_createuser'+''''+' as c_createuser,'
    +''''+'c_modiuser'+''''+' as c_modiuser,'
    +''''+'n_order_lot_qty'+''''+' as n_order_lot_qty'
    +' union all '
    +'select "c_code",\x0D\x0A"c_br_code",\x0D\x0Astring("n_reorder_qty") as n_reorder_qty,\x0D\x0Astring("n_max_qty") as n_max_qty,\x0D\x0A"c_supp_code",\x0D\x0Astring("n_stock_day") as n_stock_day,\x0D\x0Astring("n_sale_days") as n_sale_days,\x0D\x0A"c_dc_div",\x0D\x0ADATEFORMAT("d_ldate",'+''''+'YYYY-MM-DD'+''''
    +') as d_ldate,string("n_min_stock_day") as n_min_stock_day,string("t_ltime") as t_ltime,"c_order_type_code",string("n_order_lot") as n_order_lot,string("n_lock_po") as n_lock_po,\x0D\x0Astring("n_lock_ord_level_reset") as n_lock_ord_level_reset,string("t_last_minmax_reset_time") as t_last_minmax_reset_time,string("n_consumption") as n_consumption,string("n_weight_loss") as n_weight_loss,\x0D\x0ADATEFORMAT("d_maxmin_till_date",'+''''+'YYYY-MM-DD'+''''
    +') as d_maxmin_till_date,string("n_squot_required") as n_squot_required,string("n_normal_max_sale_qty") as n_normal_max_sale_qty,\x0D\x0Astring("n_order_lot_calc") as n_order_lot_calc,string("n_reset_tolerance_per") as n_reset_tolerance_per,string("n_upd_dynamic_minmax_days") as n_upd_dynamic_minmax_days,\x0D\x0A"c_createuser","c_modiuser",string("n_order_lot_qty") as n_order_lot_qty from Item_mst_br_det where c_br_code = substr(db_name(),4,3)'
    +') a to '+''''+"lsfilename"+''''+' HEXADECIMAL OFF ESCAPES OFF QUOTES OFF';
  execute immediate "lsQuery"
end;
CREATE EVENT "DBA"."kill_all_cmd_line_con_autoupdn" TYPE "DatabaseStart"
DISABLE
HANDLER
begin
  update "app_usage_log" set "t_end_time" = "now"(),"n_force_closed" = 1;
  commit work
end;
CREATE EVENT "DBA"."ledger_issue"
SCHEDULE "tt" START TIME '00:00' EVERY 20 MINUTES
DISABLE
HANDLER
begin
  insert into "led_mis"( "c_item_code","c_batch_no","bal_qty","lqty" ) 
    select "stock"."c_item_code","stock"."c_batch_no","stock"."n_bal_qty" as "bal_qty","lqty"
      from(select "stock_ledger"."c_item_code" as "i","stock_ledger"."c_batch_no" as "b","sum"("n_qty"+"n_sch_qty") as "lqty" from "stock_ledger"
          group by "i","b") as "l" left outer join "stock" on "stock"."c_item_code" = "l"."i"
        and "stock"."c_batch_no" = "l"."b" and "stock"."c_br_code" = '503'
      where "lqty" <> "bal_qty";
  commit work
end;
CREATE EVENT "DBA"."live_stock_detail_sync"
SCHEDULE "live_stock_detail_sync" BETWEEN '00:00' AND '23:59' EVERY 10 MINUTES
DISABLE
HANDLER
begin
  call "usp_live_stock_detail_sync"()
end;
CREATE EVENT "DBA"."live_stock_sync"
SCHEDULE "live_stock_sync" BETWEEN '00:00' AND '23:59' EVERY 10 MINUTES
DISABLE
HANDLER
begin
  call "usp_live_stock_sync"()
end;
CREATE EVENT "DBA"."Mst_missing"
SCHEDULE "Mst_missing" START TIME '22:50' ON ( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' )
DISABLE
HANDLER
begin
  declare "lspath","lsfilename","ls_time","lsLastSyncTime","lsAppPath" char(200);
  declare "lddir" integer;
  declare "lsQuery" long varchar;
  select "LEFT"("db_property"('file'),"LENGTH"("db_property"('file'))-("LENGTH"("DB_NAME"())*2+4)) into "lsAppPath";
  select "lsAppPath"+'Data2Cloud\\Mst_missing' into "lspath";
  select "XP_CMDSHELL"('mkdir '+"lspath") into "lddir";
  select "lspath"+'\\'+"substring"("db_name"(),4,3)+"replace"("replace"("replace"("left"("string"("now"()),19),':',''),' ',''),'-','')+'.csv' into "lsfilename";
  set "lsfilename" = "replace"("lsfilename",'\\','/'); --return;
  set "lsQuery"
     = 'Unload Select * from (Select '+''''+'Tranno'+''''+' as Tranno,'
    +''''+'D_date'+''''+' as D_date,'
    +''''+'n_cancel_flag'+''''+' as n_cancel_flag,'
    +''''+'Missing'+''''+' as Missing,'
    +''''+'Trans'+''''+' as Trans'
    +' union all '
    +'select DISTINCT (c_br_code+'+'''/'''+'+c_year+'+'''/'''+'+c_prefix+'+'''/'''+'+string(n_srno)) tranno,DATEFORMAT(D_date,'+''''+'YYYY-MM-DD'+''''+') as D_date,string(n_cancel_flag) as n_cancel_flag,'+''''+'MST'+''''+' Missing,trans from ( '
    +' select m.c_br_code,m.c_year,m.c_prefix,m.n_srno,m.D_date,m.n_cancel_flag,'+''''+'inv'+''''+' as trans from inv_det as m '
    +' left join inv_mst d on '
    +' m.c_br_code=d.c_br_code and m.c_year=d.c_year and m.c_prefix=d.c_prefix and m.n_srno=d.n_srno '
    +' where m.d_date between Today()-7 and Today() and  m.c_br_code = substr(db_name(),4,3)   and d.c_br_code is null '
    +' union ALL  '
    +' select m.c_br_code,m.c_year,m.c_prefix,m.n_srno,m.D_date,m.n_cancel_flag,'+''''+'crnt'+''''+' as trans from crnt_det as m  '
    +' left join crnt_mst d on  '
    +' m.c_br_code=d.c_br_code and m.c_year=d.c_year and m.c_prefix=d.c_prefix and m.n_srno=d.n_srno '
    +' where m.d_date between Today()-7 and Today() and  m.c_br_code = substr(db_name(),4,3)   and d.c_br_code is null '
    +' union ALL  '
    +' select m.c_br_code,m.c_year,m.c_prefix,m.n_srno,m.D_date,m.n_cancel_flag,'+''''+'pur'+''''+' as  trans from pur_det as m  '
    +' left join pur_mst d on  '
    +' m.c_br_code=d.c_br_code and m.c_year=d.c_year and m.c_prefix=d.c_prefix and m.n_srno=d.n_srno '
    +' where m.d_date between Today()-7 and Today() and  m.c_br_code = substr(db_name(),4,3)   and d.c_br_code is null '
    +' union ALL  '
    +' select m.c_br_code,m.c_year,m.c_prefix,m.n_srno,m.D_date,m.n_cancel_flag,'+''''+'nt_pur'+''''+' as  trans from nt_pur_det as m  '
    +' left join nt_pur_mst d on  '
    +' m.c_br_code=d.c_br_code and m.c_year=d.c_year and m.c_prefix=d.c_prefix and m.n_srno=d.n_srno '
    +' where m.d_date between Today()-7 and Today() and  m.c_br_code = substr(db_name(),4,3)   and d.c_br_code is null '
    +' union ALL  '
    +' select m.c_br_code,m.c_year,m.c_prefix,m.n_srno,m.D_date,m.n_cancel_flag,'+''''+'Rtn_inv'+''''+' as  trans from rtn_inv_det as m  '
    +' left join rtn_inv_mst d on  '
    +' m.c_br_code=d.c_br_code and m.c_year=d.c_year and m.c_prefix=d.c_prefix and m.n_srno=d.n_srno '
    +' where m.d_date between Today()-7 and Today() and  m.c_br_code = substr(db_name(),4,3)   and d.c_br_code is null'
    +' union ALL '
    +' select m.c_br_code,m.c_year,m.c_prefix,m.n_srno,m.D_date,m.n_cancel_flag,'+''''+'GDN'+''''+' as  trans from gdn_det as m '
    +' left join gdn_mst d on '
    +' m.c_br_code=d.c_br_code and m.c_year=d.c_year and m.c_prefix=d.c_prefix and m.n_srno=d.n_srno'
    +' where m.d_date between Today()-7 and Today() and  m.c_br_code = substr(db_name(),4,3)   and d.c_br_code is null'
    +' union ALL '
    +' select m.c_br_code,m.c_year,m.c_prefix,m.n_srno,m.D_date,m.n_cancel_flag,'+''''+'GRN'+''''+' as  trans from grn_det as m '
    +' left join grn_mst d on '
    +' m.c_br_code=d.c_br_code and m.c_year=d.c_year and m.c_prefix=d.c_prefix and m.n_srno=d.n_srno'
    +' where m.d_date between Today()-7 and Today() and  m.c_br_code = substr(db_name(),4,3)   and d.c_br_code is null'
    +' union ALL '
    +' select m.c_br_code,m.c_year,m.c_prefix,m.n_srno,m.D_date,m.n_cancel_flag,'+''''+'Stckadj'+''''+' as  trans from stock_adj_det as m '
    +' left join stock_adj_mst d on '
    +' m.c_br_code=d.c_br_code and m.c_year=d.c_year and m.c_prefix=d.c_prefix and m.n_srno=d.n_srno'
    +' where m.d_date between Today()-7 and Today() and  m.c_br_code = substr(db_name(),4,3)   and d.c_br_code is null'
    +' union ALL '
    +' select m.c_br_code,m.c_year,m.c_prefix,m.n_srno,m.D_date,m.n_cancel_flag,'+''''+'Ord'+''''+' as  trans from ord_det as m '
    +' left join ord_mst d on '
    +' m.c_br_code=d.c_br_code and m.c_year=d.c_year and m.c_prefix=d.c_prefix and m.n_srno=d.n_srno'
    +' where m.d_date between Today()-7 and Today() and  m.c_br_code = substr(db_name(),4,3)   and d.c_br_code is null'
    +' union ALL '
    +' select m.c_br_code,m.c_year,m.c_prefix,m.n_srno,m.D_date,m.n_cancel_flag,'+''''+'Order'+''''+' as  trans from order_det as m '
    +' left join order_mst d on '
    +' m.c_br_code=d.c_br_code and m.c_year=d.c_year and m.c_prefix=d.c_prefix and m.n_srno=d.n_srno'
    +' where m.d_date between Today()-7 and Today() and  m.c_br_code = substr(db_name(),4,3)   and d.c_br_code is null'
    +' union ALL '
    +' select m.c_br_code,m.c_year,m.c_prefix,m.n_srno,m.D_date,m.n_cancel_flag,'+''''+'Godown'+''''+' as  trans from godown_tran_det as m '
    +' left join godown_tran_mst d on '
    +' m.c_br_code=d.c_br_code and m.c_year=d.c_year and m.c_prefix=d.c_prefix and m.n_srno=d.n_srno'
    +' where m.d_date between Today()-7 and Today() and  m.c_br_code = substr(db_name(),4,3)   and d.c_br_code is null'
    +' union ALL '
    +' select m.c_br_code,m.c_year,m.c_prefix,m.n_srno,m.D_date,m.n_cancel_flag,'+''''+'DBNT'+''''+' as  trans from DBNT_det as m '
    +' left join DBNT_mst d on '
    +' m.c_br_code=d.c_br_code and m.c_year=d.c_year and m.c_prefix=d.c_prefix and m.n_srno=d.n_srno'
    +' where m.d_date between Today()-7 and Today() and  m.c_br_code = substr(db_name(),4,3)   and d.c_br_code is null'
    +' ) as b'
    +') a to '+''''+"lsfilename"+''''+' HEXADECIMAL OFF ESCAPES OFF QUOTES OFF';
  execute immediate "lsQuery"
end;
CREATE EVENT "DBA"."Order_mst"
SCHEDULE "Order_mst" BETWEEN '02:20' AND '10:30' EVERY 4 HOURS ON ( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' )
DISABLE
HANDLER
begin
  begin
    declare "lspath","lsfilename","ls_time","lsLastSyncTime","lsAppPath" char(200);
    declare "lddir" integer;
    declare "lsQuery" long varchar;
    select "LEFT"("db_property"('file'),"LENGTH"("db_property"('file'))-("LENGTH"("DB_NAME"())*2+4)) into "lsAppPath";
    select "lsAppPath"+'Data2Cloud\\Order_mst' into "lspath";
    select "XP_CMDSHELL"('mkdir '+"lspath") into "lddir";
    select "lspath"+'\\'+"substring"("db_name"(),4,3)+"replace"("replace"("replace"("left"("string"("now"()),19),':',''),' ',''),'-','')+'.csv' into "lsfilename";
    set "lsfilename" = "replace"("lsfilename",'\\','/'); --return;
    set "lsQuery"
       = 'Unload Select * from (Select '+''''+'c_br_code'+''''+' as c_br_code,'
      +''''+'c_year'+''''+' as c_year,'
      +''''+'c_prefix'+''''+' as c_prefix,'
      +''''+'n_srno'+''''+' as n_srno,'
      +''''+'d_date'+''''+' as d_date,'
      +''''+'c_ref_br_code'+''''+' as c_ref_br_code,'
      +''''+'c_cust_code'+''''+' as c_cust_code,'
      +''''+'n_total'+''''+' as n_total,'
      +''''+'n_cancel_flag'+''''+' as n_cancel_flag,'
      +''''+'d_ldate'+''''+' as d_ldate,'
      +''''+'n_post'+''''+' as n_post,'
      +''''+'c_user'+''''+' as c_user,'
      +''''+'c_remark'+''''+' as c_remark,'
      +''''+'Reason'+''''+' as Reason,'
      +''''+'t_ltime'+''''+' as t_ltime,'
      +''''+'n_status'+''''+' as n_status,'
      +''''+'c_approved_by'+''''+' as c_approved_by,'
      +''''+'t_time'+''''+' ast_time,'
      +''''+'c_sys_ip'+''''+' as c_sys_ip,'
      +''''+'t_valid_till'+''''+' as t_valid_till,'
      +''''+'t_valid_till_old'+''''+' as t_valid_till_old,'
      +''''+'c_modiuser'+''''+' as c_modiuser,'
      +''''+'n_pk'+''''+' as n_pk,'
      +''''+'Item_cnt'+''''+' as Item_cnt,'
      +''''+'Mail_Status'+''''+' as Mail_Status,'
      +''''+'c_name'+''''+' as c_name'
      +' union all '
      +'select o.c_br_code, o.c_year,o.c_prefix,string(o.n_srno) as n_srno,DATEFORMAT(o.d_date,'+''''+'YYYY-MM-DD'+''''
      +') as d_date,o.c_ref_br_code,o.c_cust_code,string(o.n_total) as n_total,string(o.n_cancel_flag) as n_cancel_flag,DATEFORMAT(o.d_ldate,'+''''+'YYYY-MM-DD'+''''
      +') as d_ldate,string(o.n_post) as n_post,o.c_user,o.c_remark,R.c_name as Reason,string(o.t_ltime) as t_ltime,string(o.n_status) as n_status,o.c_approved_by,'
      +' string(o.t_time) as t_time,o.c_sys_ip,string(o.t_valid_till) as t_valid_till,'
      +' string(o.t_valid_till_old) as t_valid_till_old,o.c_modiuser,string(o.n_pk) as n_pk,string(cnt) as Item_cnt,'
      +' (Case when M.c_br_code is null then '+''''+'Mail not sent'+''''+' else '+''''+'Mail sent'+''''+' end) as Mail_Status,a.c_name from order_mst  as o '
      +' left join act_mst as a on o.c_cust_code=a.c_code '
      +' left join Reason_mst as r on o.c_reason_code=r.c_code '
      +' left join mail_log as M ON o.c_br_code=M.c_br_code and o.c_year=M.c_year and o.c_prefix=M.c_prefix and o.n_srno=M.n_srno'
      +' left join (select count(*) as cnt,c_br_code,c_year,c_prefix,n_srno from order_det group by c_br_code,c_year,c_prefix,n_srno)  d on o.c_br_code=d.c_br_code and o.c_year=d.c_year and o.c_prefix=d.c_prefix and o.n_srno=d.n_srno'
      +' where o.N_cancel_flag=0 and o.d_date = today()'
      +') a to '+''''+"lsfilename"+''''+' HEXADECIMAL OFF ESCAPES OFF QUOTES OFF';
    execute immediate "lsQuery"
  end
end;
CREATE EVENT "DBA"."Po_Bounce_auto"
SCHEDULE "Po_Bounce_auto" START TIME '03:45' ON ( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' )
DISABLE
HANDLER
begin
  declare "lspath","lsfilename","ls_time","lsLastSyncTime","lsAppPath" char(200);
  declare "lddir" integer;
  declare "lsQuery" long varchar;
  select "LEFT"("db_property"('file'),"LENGTH"("db_property"('file'))-("LENGTH"("DB_NAME"())*2+4)) into "lsAppPath";
  select "lsAppPath"+'Data2Cloud\\Po_Bounce_auto' into "lspath";
  select "XP_CMDSHELL"('mkdir '+"lspath") into "lddir";
  select "lspath"+'\\'+"substring"("db_name"(),4,3)+"replace"("replace"("replace"("left"("string"("now"()),19),':',''),' ',''),'-','')+'.csv' into "lsfilename";
  set "lsfilename" = "replace"("lsfilename",'\\','/'); --return;
  set "lsQuery"
     = 'Unload Select * from (Select '+''''+'c_br_code'+''''+' as c_br_code,'
    +''''+'c_year'+''''+' as c_year,'
    +''''+'C_prefix'+''''+' as C_prefix,'
    +''''+'n_srno'+''''+' as n_srno,'
    +''''+'n_seq'+''''+' as n_seq,'
    +''''+'c_item_code'+''''+' as c_item_code,'
    +''''+'n_qty'+''''+' as n_qty,'
    +''''+'n_issue_qty'+''''+' as n_issue_qty,'
    +''''+'n_cancel_qty'+''''+' as n_cancel_qty,'
    +''''+'c_ref_br_code'+''''+' as c_ref_br_code,'
    +''''+'n_out_qty'+''''+' as n_out_qty,'
    +''''+'n_sch_qty'+''''+' as n_sch_qty,'
    +''''+'n_sch_issue_qty'+''''+' as n_sch_issue_qty,'
    +''''+'n_sch_cancel_qty'+''''+' as n_sch_cancel_qty,'
    +''''+'n_rate'+''''+' as n_rate,'
    +''''+'n_disc_per'+''''+' as n_disc_per,'
    +''''+'n_mrp'+''''+' as n_mrp,'
    +''''+'n_ptr'+''''+' as n_ptr,'
    +''''+'n_pk'+''''+' as n_pk,'
    +''''+'T_VALID_TILL'+''''+' as T_VALID_TILL'
    +' union all '
    +' select Sl.c_br_code,Sl.c_year,Sl.c_prefix,string(Sl.n_srno) as n_srno ,string(Sl.n_seq) as n_seq,Sl.c_item_code,string(Sl.n_qty) as n_qty,string(Sl.n_issue_qty) as n_issue_qty,string(Sl.n_cancel_qty) as n_cancel_qty,'
    +' Sl.c_ref_br_code,string(Sl.n_out_qty) as n_out_qty,string(Sl.n_sch_qty) as n_sch_qty,string(Sl.n_sch_issue_qty) as n_sch_issue_qty,string(Sl.n_sch_cancel_qty) as n_sch_cancel_qty,string(Sl.n_rate) as n_rate,'
    +' string(Sl.n_disc_per) as n_disc_per,string(Sl.n_mrp) as n_mrp,string(Sl.n_ptr) as n_ptr,string(Sl.n_pk) as n_pk,DATEFORMAT(oM.T_VALID_TILL,'+''''+'YYYY-MM-DD'+''''+') as T_VALID_TILL '
    +' from dba.supp_ord_ledger as Sl '
    +'   left join order_det od on Sl.c_br_code=Od.c_br_code and Sl.c_year=Od.c_year and Sl.c_prefix=Od.c_prefix and Sl.n_srno=Od.n_srno and Sl.c_item_code=Od.c_item_code'
    +'   left join order_MST oM on Sl.c_br_code=Om.c_br_code and Sl.c_year=OM.c_year and Sl.c_prefix=OM.c_prefix and Sl.n_srno=Om.n_srno '
    +' left join Act_mst  Am on od.c_ord_supp_code=Am.c_code WHERE Om.T_VALID_TILL = TODAY()-1 AND Sl.N_CANCEL_QTY > 0 AND Sl.c_br_code=substr(db_name(),4,3) AND oM.C_USER='+''''+'AUTO'+''''+' AND 1=1'
    +') a to '+''''+"lsfilename"+''''+' HEXADECIMAL OFF ESCAPES OFF QUOTES OFF';
  execute immediate "lsQuery"
end;
CREATE EVENT "DBA"."purge_order_list"
SCHEDULE "purge_order_list" START TIME '01:10' ON ( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' )
HANDLER
begin
  update "order_list" set "n_qty" = 0,"d_ldate" = "uf_default_date"(),"t_ltime" = "now"()
    where "n_qty"-"n_ord_qty" > 0 and("isnull"("trim"("c_to_supp_code"),'') <> '' or "d_date"+8 < "uf_default_date"())
end;
CREATE EVENT "DBA"."purge_order_list_1"
SCHEDULE "purge_order_list_1" START TIME '00:10' ON ( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' )
HANDLER
begin
  update "order_list" set "n_qty" = 0,"d_ldate" = "uf_default_date"(),"t_ltime" = "now"()
    where "n_qty"-"n_ord_qty" > 0 and("isnull"("trim"("c_to_supp_code"),'') <> '' or "d_date"+8 < "uf_default_date"())
end;
CREATE EVENT "DBA"."Stk_adj_godown_mismatch"
SCHEDULE "Stk_adj_godown_mismatch" START TIME '02:15' ON ( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' )
DISABLE
HANDLER
begin
  declare "lspath","lsfilename","ls_time","lsLastSyncTime","lsAppPath" char(200);
  declare "lddir" integer;
  declare "lsQuery" long varchar;
  select "LEFT"("db_property"('file'),"LENGTH"("db_property"('file'))-("LENGTH"("DB_NAME"())*2+4)) into "lsAppPath";
  select "lsAppPath"+'Data2Cloud\\Stk_adj_godown_mismatch' into "lspath";
  select "XP_CMDSHELL"('mkdir '+"lspath") into "lddir";
  select "lspath"+'\\'+"substring"("db_name"(),4,3)+"replace"("replace"("replace"("left"("string"("now"()),19),':',''),' ',''),'-','')+'.csv' into "lsfilename";
  set "lsfilename" = "replace"("lsfilename",'\\','/'); --return;
  set "lsQuery"
     = 'Unload Select * from (Select '+''''+'c_br_code'+''''+' as c_br_code,'
    +''''+'c_year'+''''+' as c_year,'
    +''''+'c_prefix'+''''+' as c_prefix,'
    +''''+'n_srno'+''''+' as n_srno,'
    +''''+'D_date'+''''+' as D_date,'
    +''''+'mst_godown'+''''+' as mst_godown,'
    +''''+'det_godown'+''''+' as det_godown,'
    +''''+'n_seq'+''''+' as n_seq,'
    +''''+'n_cancel_flag'+''''+' as n_cancel_flag'
    +' union all '
    +' Select r.c_br_code,r.c_year,r.c_prefix,string(r.n_srno)n_srno,string(r.D_date)D_date,r.c_godown_code as mst_godown,m.c_godown_code as det_godown,string(m.n_seq) as n_seq,string(r.n_cancel_flag) n_cancel_flag\x0Afrom Stock_adj_mst as r  \x0Aleft join Stock_adj_det as m on r.c_br_code=m.c_br_code and r.c_year=m.c_year and r.c_prefix=m.c_prefix and r.n_srno=m.n_srno\x0Awhere r.c_br_code= substr(db_name(),4,3) and r.d_date between  today()-8 and today()-1 and mst_godown<> det_godown'
    +') a to '+''''+"lsfilename"+''''+' HEXADECIMAL OFF ESCAPES OFF QUOTES OFF';
  execute immediate "lsQuery"
end;
CREATE EVENT "DBA"."Supplierswise_Dividing_Report"
SCHEDULE "Supplierswise_Dividing_Report" START TIME '23:57' ON ( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' )
DISABLE
HANDLER
begin
  declare "lspath","lsfilename","ls_time","lsLastSyncTime","lsAppPath" char(200);
  declare "lddir" integer;
  declare "lsQuery" long varchar;
  select "LEFT"("db_property"('file'),"LENGTH"("db_property"('file'))-("LENGTH"("DB_NAME"())*2+4)) into "lsAppPath";
  select "lsAppPath"+'Data2Cloud\\Supplierswise_Dividing_Report' into "lspath";
  select "XP_CMDSHELL"('mkdir '+"lspath") into "lddir";
  select "lspath"+'\\'+"substring"("db_name"(),4,3)+"replace"("replace"("replace"("left"("string"("now"()),19),':',''),' ',''),'-','')+'.csv' into "lsfilename";
  set "lsfilename" = "replace"("lsfilename",'\\','/'); --return;
  set "lsQuery"
     = 'Unload Select * from (Select '+''''+'dbnt_No'+''''+' as dbnt_No,'
    +''''+'c_item_code'+''''+' as c_item_code,'
    +''''+'c_tray_code'+''''+' as c_tray_code,'
    +''''+'n_qty'+''''+' as n_qty,'
    +''''+'c_batch_no'+''''+' as c_batch_no'
    +' union all '
    +' select string(db.n_srno) as dbnt_No,seb.c_item_code ,seb.c_batch_no, db.c_tray_code,String(seb.n_qty) as n_qty from st_track_stock_eb seb'
    +' join grn_det grd on grd.c_item_code = seb.c_item_code and grd.c_batch_no = seb.c_batch_no and grd.c_br_code +'+''''+'/'+''''+'+ grd.c_year +'+''''+'/'+''''+'+ grd.c_prefix +'+''''+'/'+''''+'+ trim(str(grd.n_srno)) +'+''''+'/'+''''+'+ trim(str(grd.n_seq)) = seb.c_stin_ref_no'
    +' join dbnt_det db on seb.c_item_code = db.c_item_code'
    +' and db.c_batch_no = seb.c_batch_no'
    +'   and seb.c_doc_no = db.c_doc_no'
    +'   and seb.n_qty>0'
    +') a to '+''''+"lsfilename"+''''+' HEXADECIMAL OFF ESCAPES OFF QUOTES OFF';
  execute immediate "lsQuery"
end;
CREATE EVENT "DBA"."track_connection"
SCHEDULE "schedule_track_connection" BETWEEN '00:00' AND '23:59' EVERY 1 MINUTES
DISABLE
HANDLER
begin
  insert into "track_connections"( "number","name","userid","reqtype","commlink","nodeaddr","d_date" ) 
    select "number","name","userid","reqtype","commlink","nodeaddr","getdate"()
      from "conn_info" where "name" not like 'INT%' and "name" not like '%EG%' and "name" not like '%StoreTrack%' and "name" not like 'ws_%'
      and "nodeaddr" not in( '192.168.250.58','192.168.250.68' ) 
      and "name" not in( 'tray_time','track_connection','auto_order_push','auto_get_bounce','event_ord_status_04m503',
      'event_trace_tray_move',
      'event_get_gdn_bounce_data',
      'ledger_issue',
      'update_Payroll_ot',
      'update_dayend_values',
      'Auto_Day_End',
      'event_zero_stock_report' ) 
      and "commlink" <> 'local'
end;
CREATE EVENT "DBA"."track_event"
SCHEDULE "track_event" START TIME '05:00' EVERY 30 SECONDS ON ( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' )
HANDLER
begin
  call "sa_server_option"('RememberLastStatement','YES');
  insert into "connection_track"
    select "getdate"() as "dt",
      "sd"."Number",
      (select "value" from "sa_conn_properties"("si"."Number") where "PropName" = 'LoginTime') as "logtime",
      "sd"."Name","ParentConnection","sd"."UserId","sd"."LoginTime","connection_property"('ApproximateCPUTime',"sd"."Number") as "cpu","sd"."ReqType",
      cast("DATEDIFF"("second","sd"."LastReqTime",current timestamp) as double) as "ReqTime","sd"."LastStatement","sd"."AppInfo",
      "nodeaddr"
      //into connection_track
      from "dbo"."sa_performance_diagnostics"() as "sd"
        join "dbo"."sa_conn_info"() as "si" on "sd"."number" = "si"."number"
      where "ReqStatus" <> 'IDLE' and "si"."name" <> 'INT: Exchange'
end;
CREATE EVENT "DBA"."tray_empty"
SCHEDULE "tray_empty" START TIME '02:20' ON ( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' )
DISABLE
HANDLER
begin
  declare "lspath","lsfilename","ls_time","lsLastSyncTime","lsAppPath" char(200);
  declare "lddir" integer;
  declare "lsQuery" long varchar;
  select "LEFT"("db_property"('file'),"LENGTH"("db_property"('file'))-("LENGTH"("DB_NAME"())*2+4)) into "lsAppPath";
  select "lsAppPath"+'Data2Cloud\\tray_empty' into "lspath";
  select "XP_CMDSHELL"('mkdir '+"lspath") into "lddir";
  select "lspath"+'\\'+"substring"("db_name"(),4,3)+"replace"("replace"("replace"("left"("string"("now"()),19),':',''),' ',''),'-','')+'.csv' into "lsfilename";
  set "lsfilename" = "replace"("lsfilename",'\\','/'); --return;
  set "lsQuery"
     = 'Unload Select * from (Select '+''''+'c_br_code'+''''+' as c_br_code,'
    +''''+'c_year'+''''+' as c_year,'
    +''''+'c_prefix'+''''+' as c_prefix,'
    +''''+'n_srno'+''''+' as n_srno,'
    +''''+'D_date'+''''+' as D_date,'
    +''''+'c_tray_code'+''''+' as c_tray_code,'
    +''''+'n_cancel_flag'+''''+' as n_cancel_flag,'
    +''''+'n_seq'+''''+' as n_seq'
    +' union all '
    +' Select r.c_br_code,r.c_year,r.c_prefix,string(r.n_srno)n_srno,string(r.D_date)D_date,r.c_tray_code,string(r.n_cancel_flag ) as n_cancel_flag,string(r.n_seq) as n_seq\x0Afrom rtn_inv_det as r  \x0Awhere r.c_br_code= substr(db_name(),4,3) and r.d_date between  today()-8 and today()-1 and r.c_godown_code='+''''+'5033'+''''+' and isnull(r.c_tray_code,'+''''+''+''''+') = '+''''+''+''''
    +'\x0A\x0Aunion all\x0ASelect r.c_br_code,r.c_year,r.c_prefix,string(r.n_srno)n_srno,string(r.D_date)D_date,r.c_tray_code,string(r.n_cancel_flag ) as n_cancel_flag,string(r.n_seq) as n_seq\x0Afrom Stock_adj_det as r  \x0A\x0Awhere r.c_br_code= substr(db_name(),4,3) and r.d_date between  today()-8 and today()-1 and r.c_godown_code='+''''+'5033'+''''+' and isnull(r.c_tray_code,'+''''+''+''''+') = '+''''+''+''''+''
    +') a to '+''''+"lsfilename"+''''+' HEXADECIMAL OFF ESCAPES OFF QUOTES OFF';
  execute immediate "lsQuery"
end;
CREATE EVENT "DBA"."tray_mismatch"
SCHEDULE "tray_mismatch" START TIME '02:00' ON ( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' )
DISABLE
HANDLER
begin
  declare "lspath","lsfilename","ls_time","lsLastSyncTime","lsAppPath" char(200);
  declare "lddir" integer;
  declare "lsQuery" long varchar;
  select "LEFT"("db_property"('file'),"LENGTH"("db_property"('file'))-("LENGTH"("DB_NAME"())*2+4)) into "lsAppPath";
  select "lsAppPath"+'Data2Cloud\\tray_mismatch' into "lspath";
  select "XP_CMDSHELL"('mkdir '+"lspath") into "lddir";
  select "lspath"+'\\'+"substring"("db_name"(),4,3)+"replace"("replace"("replace"("left"("string"("now"()),19),':',''),' ',''),'-','')+'.csv' into "lsfilename";
  set "lsfilename" = "replace"("lsfilename",'\\','/'); --return;
  set "lsQuery"
     = 'Unload Select * from (Select '+''''+'c_br_code'+''''+' as c_br_code,'
    +''''+'c_year'+''''+' as c_year,'
    +''''+'c_prefix'+''''+' as c_prefix,'
    +''''+'n_srno'+''''+' as n_srno,'
    +''''+'D_date'+''''+' as D_date,'
    +''''+'n_qty'+''''+' as n_qty,'
    +''''+'c_item_code'+''''+' as c_item_code,'
    +''''+'c_tray_code'+''''+' as c_tray_code,'
    +''''+'n_eb_seq'+''''+' as n_eb_seq,'
    +''''+'c_doc_no'+''''+' as c_doc_no,'
    +''''+'c_cust_code'+''''+' as c_cust_code,'
    +''''+'c_godown_code'+''''+' as c_godown_code,'
    +''''+'st_track_qty'+''''+' as st_track_qty,'
    +''''+'diff'+''''+' as diff,'
    +''''+'c_batch_no'+''''+' as c_batch_no'
    +' union all '
    +' Select r.c_br_code,r.c_year,r.c_prefix,string(r.n_srno)n_srno,string(r.D_date)D_date,string(r.n_qty) n_qty,r.c_item_code,r.c_tray_code,string(r.n_eb_seq)n_eb_seq,r.c_doc_no,r.c_cust_code,c_godown_code,\x0Astring(eb.n_qty) as st_track_qty,string(abs(eb.n_qty)-abs(r.n_qty)) diff ,r.c_batch_no\x0Afrom rtn_inv_det as r  \x0Ainner join st_track_stock_eb as eb on eb.c_br_code = r.c_br_code\x0A        and eb.c_item_code = r.c_item_code\x0A        and eb.c_batch_no = r.c_batch_no\x0A        and eb.c_tray_code = r.c_tray_code\x0A        and eb.c_supp_code = r.c_cust_code\x0A        and eb.c_doc_no = r.c_doc_no\x0A        -----and eb.n_seq = r.n_eb_seq\x0Awhere r.c_br_code= substr(db_name(),4,3) and r.d_date between  today()-8 and today()-1 and eb.n_qty<>0 and abs(eb.n_qty)-abs(r.n_qty) <> 0\x0A\x0Aunion all\x0ASelect r.c_br_code,r.c_year,r.c_prefix,string(r.n_srno)n_srno,string(r.D_date)D_date,string(r.n_qty) n_qty,r.c_item_code,r.c_tray_code,string(r.n_eb_seq)n_eb_seq,r.c_doc_no,r.c_supp_code,c_godown_code,\x0Astring(eb.n_qty) as st_track_qty,string(abs(eb.n_qty)-abs(r.n_qty)) diff ,r.c_batch_no\x0Afrom Stock_adj_det as r  \x0Ainner join st_track_stock_eb as eb on eb.c_br_code = r.c_br_code\x0A        and eb.c_item_code = r.c_item_code\x0A        and eb.c_batch_no = r.c_batch_no\x0A        and eb.c_tray_code = r.c_tray_code\x0A        and eb.c_supp_code = r.c_supp_code\x0A        and eb.c_doc_no = r.c_doc_no\x0A        ------and eb.n_seq = r.n_eb_seq\x0Awhere r.c_br_code= substr(db_name(),4,3) and r.d_date between  today()-8 and today()-1 and eb.n_qty<>0 and abs(eb.n_qty)-abs(r.n_qty) <> 0 '
    +') a to '+''''+"lsfilename"+''''+' HEXADECIMAL OFF ESCAPES OFF QUOTES OFF';
  execute immediate "lsQuery"
end;
CREATE EVENT "DBA"."tray_time"
SCHEDULE "tt" START TIME '00:00' EVERY 15 MINUTES
DISABLE
HANDLER
begin
  declare "max_time" "datetime";
  select "max"("t_time") into "max_time" from "tray_time_incr";
  if "max_time" is null then set "max_time" = "uf_default_date"() end if;
  insert into "tray_time_incr"
    ( "c_doc_no","n_inout","c_tray_code","c_work_place","c_user","c_rack_grp_code","c_stage_code","t_time","t_action_start_time","t_action_end_time",
    "n_bounce_count","n_pick_count" ) on existing skip
    select "c_doc_no","n_inout","c_tray_code","c_work_place","c_user","c_rack_grp_code","c_stage_code","t_time","t_action_start_time","t_action_end_time",
      "n_bounce_count","n_pick_count"
      from "st_track_tray_time"
      where "t_time" > "max_time";
  commit work
end;
CREATE EVENT "DBA"."update_dayend_values" TYPE "DatabaseStart"
HANDLER
begin
  declare "br" char(6);
  declare "adate" date;
  declare "err_notfound" exception for sqlstate value '02000';
  declare "day_end_update_list" dynamic scroll cursor for select "c_br_code","d_date"
      from "day_end_values"
      where "c_br_code" <> '000' and("n_updated" = 0
      or "d_date" = if "substr"("db_name"(0),4,3) = '000' then cast('1900-01-01' as date)
      else(select "min"("d_date")
          from "day_end_values"
          where "d_date" >= (select "min"("d_date")
            from "pur_mst"
            where "pur_mst"."c_br_code" = "day_end_values"."c_br_code"
            and "pur_mst"."d_date" <= "day_end_Values"."d_date"
            and "t_post_time" > "day_end_values"."t_ltime"))
      endif) order by 1 asc,2 asc;
  open "day_end_update_list";
  "dayendLoop": loop
    fetch next "day_end_update_list" into "br","adate";
    if sqlstate = "err_notfound" then
      leave "dayendLoop"
    end if;
    insert into "day_end_values"( "c_br_code","d_date","d_ldate","n_stock_value","n_sale_value","n_crnt_value","n_grn_value",
      "n_gdn_value","n_pur_value","n_pur_ret_value","n_rtn_inv_value","n_rtn_pur_value","t_ltime","n_updated" ) on existing update defaults off
      select "brcode",
        cast("adate" as date) as "d_date",
        "uf_default_date"() as "d_ldate",
        cast("sum"("clsstk"*"rate") as numeric(13,2)) as "n_stock_value",
        cast("isnull"((select "sum"(("inv_det"."n_amount"-"inv_det"."n_sch_disc")*(1-"inv_det"."n_disc_per"/100))
          from "inv_det"
          where("inv_det"."c_br_code" = "brcode")
          and("inv_det"."d_date" = "adate")
          and("inv_det"."n_cancel_flag" = 0)),0) as numeric(13,2)) as "n_sale_value",
        cast("isnull"((select "sum"((("crnt_det"."n_qty"*"crnt_det"."n_sale_rate")-"crnt_det"."n_sch_disc")*(1-"crnt_det"."n_disc_per"/100))
          from "crnt_det"
          where("crnt_det"."c_br_code" = "brcode")
          and("crnt_det"."d_date" = "adate")
          and("crnt_det"."n_cancel_flag" = 0)),0) as numeric(13,2)) as "n_crnt_value",
        cast("isnull"((select "sum"(("grn_mst"."n_total")-("grn_mst"."n_cgst_amt")-("grn_mst"."n_sgst_amt")-("grn_mst"."n_igst_amt"))
          from "grn_mst"
          where("grn_mst"."n_cancel_flag" = 0)
          and("grn_mst"."c_br_code" = "brcode")
          and("grn_mst"."d_date" = "adate")),0) as numeric(13,2)) as "n_grn_value",
        cast("isnull"((select "sum"(("gdn_mst"."n_total")-("gdn_mst"."n_cgst_amt")-("gdn_mst"."n_sgst_amt")-("gdn_mst"."n_igst_amt"))
          from "gdn_mst"
          where("gdn_mst"."c_br_code" = "brcode")
          and("gdn_mst"."d_date" = "adate")
          and("gdn_mst"."n_cancel_flag" = 0)),0) as numeric(13,2)) as "n_gdn_value",
        cast("isnull"((select "sum"(if "pur_det"."n_vatts_mrp" = 1 then
            if "n_sale_rate" = "n_pur_rate" then
              ("pur_det"."n_qty"*"n_eff_pur_rate")
            else
              ("n_qty"*"n_pur_rate")-"n_sch_disc"-((("n_qty"*"n_pur_rate")-"n_sch_disc")*"pur_det"."n_item_disc"/100)
            endif
          else
            ("n_qty"*"n_pur_rate")-"n_sch_disc"-((("n_qty"*"n_pur_rate")-"n_sch_disc")*"pur_det"."n_item_disc"/100)
          endif)
          from "pur_det"
          where("pur_det"."c_br_code" = "brcode")
          and("pur_det"."d_date" = "adate")
          and("pur_det"."n_post" >= 1)
          and("pur_det"."n_cancel_flag" = 0) and("left"("pur_det"."c_prefix",1) = 'K')),0) as numeric(13,2)) as "n_pur_value",
        cast("isnull"((select "sum"(if "pur_det"."n_vatts_mrp" = 1 then
            if "n_sale_rate" = "n_pur_rate" then
              ("pur_det"."n_qty"*"n_eff_pur_rate")
            else
              ("n_qty"*"n_pur_rate")-"n_sch_disc"-((("n_qty"*"n_pur_rate")-"n_sch_disc")*"pur_det"."n_item_disc"/100)
            endif
          else
            ("n_qty"*"n_pur_rate")-"n_sch_disc"-((("n_qty"*"n_pur_rate")-"n_sch_disc")*"pur_det"."n_item_disc"/100)
          endif)
          from "pur_det"
          where("pur_det"."c_br_code" = "brcode")
          and("pur_det"."d_date" = "adate")
          and("pur_det"."n_post" >= 1)
          and("pur_det"."n_cancel_flag" = 0) and("left"("pur_det"."c_prefix",1) = 'I')),0) as numeric(13,2)) as "n_pur_ret_value",
        cast("isnull"((select "sum"("n_taxable_amt")
          from "rtn_inv_mst"
          where("rtn_inv_mst"."c_br_code" = "brcode")
          and("rtn_inv_mst"."d_date" = "adate")
          and("rtn_inv_mst"."n_approved" = 1)
          and("rtn_inv_mst"."n_cancel_flag" = 0)),0) as numeric(13,2)) as "n_rtn_inv_value",
        cast("isnull"((select "sum"("n_taxable_amt")
          from "rtn_pur_mst"
          where("rtn_pur_mst"."c_br_code" = "brcode")
          and("rtn_pur_mst"."d_date" = "adate")
          and("rtn_pur_mst"."n_post" >= 1)
          and("rtn_pur_mst"."n_cancel_flag" = 0)),0) as numeric(13,2)) as "n_rtn_pur_value",
        cast("now"() as "DATETIME") as "t_ltime",
        1 as "n_update"
        from(select *,(select "n_rate"
              from "DBA"."usp_get_cls_cost_val"("brcode","itemcode","batchno","adate",0,"clsstk")) as "rate"
            from(select "c_br_code" as "brcode",
                "c_item_code" as "itemcode",
                "c_batch_no" as "batchno",
                "isnull"("sum"("n_qty"+"n_sch_qty"),0) as "clsstk"
                from "stock_ledger"
                where "c_br_code" = "br"
                and "d_date" <= "adate"
                group by "c_br_code","c_item_code","c_batch_no"
                having "clsstk" <> 0) as "t1") as "t2"
        group by "brcode"
  end loop "dayendLoop";
  close "day_end_update_list";
  commit work
end;
CREATE EVENT "DBA"."update_los_data" DISABLE
HANDLER
begin
  declare @dbname char(10);
  declare @year char(2);
  declare @as_br char(6);
  declare @gi_admin numeric(1);
  declare @li_multi numeric(1);
  set @year = "right"("db_name"(),2);
  if "left"("db_name"(),1) = '0' then
    set @dbname = "left"("db_name"(),6)
  else
    set @dbname = "left"("db_name"(),4)
  end if;
  //set defalt values..
  set @gi_admin = 0;
  set @as_br = "right"(@dbname,3);
  if @as_br = '000' then
    set @gi_admin = 1
  else
    set @gi_admin = 0
  end if;
  select "n_multi_login" into @li_multi from "br_setup_param" where "c_code" = @as_br;
  if @gi_admin = 0 and @li_multi = 0 then
    call "usp_update_los_data"()
  end if
end;
CREATE EVENT "DBA"."Update_n_grn_type"
SCHEDULE "Update_n_grn_type" START TIME '23:30' ON ( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' )
DISABLE
HANDLER
begin
  update "grn_det" as "a" left outer join "grn_mst" as "b"
    on "a"."c_br_code" = "b"."c_br_code"
    and "a"."c_year" = "b"."c_year"
    and "a"."c_prefix" = "b"."c_prefix"
    and "a"."n_Srno" = "b"."n_srno"
    set "a"."n_grn_type" = 1 where "a"."d_date" between "today"()-7 and "today"() and "b"."c_ref_br_code" < '500';
  commit work
end;
CREATE EVENT "DBA"."update_Payroll_ot"
SCHEDULE "update_Payroll_ot" BETWEEN '00:00' AND '23:59' EVERY 60 MINUTES
HANDLER
begin
  declare @c_emp_code char(6);
  declare @weekoffcode char(6);
  declare @holiday_code char(6);
  declare @night_shift_code char(6);
  declare @extra_time_code char(6);
  declare @n_weekoff_flag numeric(1);
  declare @holiday_flag numeric(1);
  declare @d_count numeric(4);
  declare @n_night_shift_flag numeric(1);
  declare @dayname char(25);
  declare @cmonth char(10);
  declare @cyear char(10);
  declare @n_extra_hour numeric(5,2);
  declare "holiday_flag" numeric(1);
  declare "cur_srno" dynamic scroll cursor for
    select "payroll_emp_checkin_det"."c_emp_code",
      "dayname"("payroll_emp_checkin_det"."d_date") as "dayname",
      if "upper"("dayname") = "upper"("payroll_div_setup"."c_week_off_day1") or "upper"("dayname") = "upper"("payroll_div_setup"."c_week_off_day2") then
        1
      else
        0
      endif as "n_weekoff_flag",
      if "n_weekoff_flag" = 1 then
        (select top 1 "c_code" from "payroll_sal_comp_mst" where "payroll_sal_comp_mst"."n_ot" = 1 and "payroll_sal_comp_mst"."n_ot_type" = 3)
      else
        null
      endif as "weekoffcode",
      /*If payroll_emp_checkin_det.d_date = payroll_holiday_det.d_holiday_Date  then 
1
else 
0
end if  holiday_flag ,*/
      (select "count"() into "holiday_flag" from "payroll_holiday_det"
          ,"payroll_emp_checkin_det" where "payroll_emp_checkin_det"."d_date" = "payroll_holiday_det"."d_holiday_date") as "holiday_flag",
      if "holiday_flag" >= 1 then
        (select top 1 "c_code" from "payroll_sal_comp_mst" where "payroll_sal_comp_mst"."n_ot" = 1 and "payroll_sal_comp_mst"."n_ot_type" = 2)
      else
        null
      endif as "holiday_code",
      if "payroll_emp_checkin_det"."t_check_in" >= "payroll_div_setup"."t_night_shift_start_time" and "payroll_emp_checkin_det"."t_check_out" <= "payroll_div_setup"."t_night_shift_end_time" then
        1
      else
        0
      endif as "n_night_shift_flag",
      if "n_night_shift_flag" = 1 then
        (select top 1 "c_code" from "payroll_sal_comp_mst" where "payroll_sal_comp_mst"."n_ot" = 1 and "payroll_sal_comp_mst"."n_ot_type" = 4)
      else
        null
      endif as "night_shift_code",
      if "weekoffcode" is null and "night_shift_code" is null and "holiday_code" is null then
        (select top 1 "c_code" from "payroll_sal_comp_mst" where "payroll_sal_comp_mst"."n_ot" = 1 and "payroll_sal_comp_mst"."n_ot_type" = 1)
      endif as "extra_time_code","payroll_emp_checkin_det"."n_extra_hour",
      "month"("payroll_emp_checkin_det"."d_date") as "c_month",
      "right"("Year"("payroll_emp_checkin_det"."d_date"),2) as "c_year"
      from "payroll_emp_checkin_det"
        join "payroll_emp_det" on "payroll_emp_det"."c_emp_code" = "payroll_emp_checkin_det"."c_emp_code"
        join "payroll_div_setup" on "payroll_div_setup"."c_div_code" = "payroll_emp_det"."c_div_code"
      --Left join payroll_holiday_det on payroll_div_setup.c_div_code =payroll_holiday_det.c_div_code
      where "payroll_emp_checkin_det"."n_extra_hour" <> 0 and "payroll_emp_checkin_det"."d_date" = "DBA"."uf_default_date"()
      and "payroll_emp_checkin_det"."n_cancel_flag" = 0;
  open "cur_srno";
  "lp0": loop
    fetch next "cur_srno" into @c_emp_code,@dayname,@n_weekoff_flag,@weekoffcode,@holiday_flag,@holiday_code,@n_night_shift_flag,@night_shift_code,@extra_time_code,
      @n_extra_hour,@cmonth,@cyear;
    if sqlcode <> 0 then leave "lp0" end if;
    if @weekoffcode is not null then
      select "count"()
        into @d_count
        from "payroll_emp_ot"
        where "payroll_emp_ot"."c_year" = @cyear
        and "payroll_emp_ot"."c_month" = @cmonth
        and "payroll_emp_ot"."c_emp_code" = @c_emp_code
        and "payroll_emp_ot"."c_sal_comp_code" = @weekoffcode;
      if @d_count > 0 then //Update 
        update "payroll_emp_ot" set "n_hour" = "n_hour"+@n_extra_hour
          where "payroll_emp_ot"."c_year" = @cyear
          and "payroll_emp_ot"."c_month" = @cmonth
          and "payroll_emp_ot"."c_emp_code" = @c_emp_code
          and "payroll_emp_ot"."c_sal_comp_code" = @weekoffcode
      else
        insert into "payroll_emp_ot"
          ( "c_year","c_month","c_emp_code","c_sal_comp_code","n_hour","d_ldate","c_createuser","t_ltime","n_cancel_flag","n_complete" ) on existing skip
          select @cyear,@cmonth,@c_emp_code,@weekoffcode,@n_extra_hour,"today"(),'AUTO',"NOw"(),0,0
      end if end if;
    if @holiday_code is not null then
      select "count"()
        into @d_count
        from "payroll_emp_ot"
        where "payroll_emp_ot"."c_year" = @cyear
        and "payroll_emp_ot"."c_month" = @cmonth
        and "payroll_emp_ot"."c_emp_code" = @c_emp_code
        and "payroll_emp_ot"."c_sal_comp_code" = @holiday_code;
      if @d_count > 0 then //Update 
        update "payroll_emp_ot" set "n_hour" = "n_hour"+@n_extra_hour
          where "payroll_emp_ot"."c_year" = @cyear
          and "payroll_emp_ot"."c_month" = @cmonth
          and "payroll_emp_ot"."c_emp_code" = @c_emp_code
          and "payroll_emp_ot"."c_sal_comp_code" = @holiday_code
      else
        insert into "payroll_emp_ot"
          ( "c_year","c_month","c_emp_code","c_sal_comp_code","n_hour","d_ldate","c_createuser","t_ltime","n_cancel_flag","n_complete" ) on existing skip
          select @cyear,@cmonth,@c_emp_code,@holiday_code,@n_extra_hour,"today"(),'AUTO',"NOw"(),0,0
      end if end if;
    if @night_shift_code is not null then
      select "count"()
        into @d_count
        from "payroll_emp_ot"
        where "payroll_emp_ot"."c_year" = @cyear
        and "payroll_emp_ot"."c_month" = @cmonth
        and "payroll_emp_ot"."c_emp_code" = @c_emp_code
        and "payroll_emp_ot"."c_sal_comp_code" = @night_shift_code;
      if @d_count > 0 then //Update 
        update "payroll_emp_ot" set "n_hour" = "n_hour"+@n_extra_hour
          where "payroll_emp_ot"."c_year" = @cyear
          and "payroll_emp_ot"."c_month" = @cmonth
          and "payroll_emp_ot"."c_emp_code" = @c_emp_code
          and "payroll_emp_ot"."c_sal_comp_code" = @night_shift_code
      else
        insert into "payroll_emp_ot"
          ( "c_year","c_month","c_emp_code","c_sal_comp_code","n_hour","d_ldate","c_createuser","t_ltime","n_cancel_flag","n_complete" ) on existing skip
          select @cyear,@cmonth,@c_emp_code,@night_shift_code,@n_extra_hour,"today"(),'AUTO',"NOw"(),0,0
      end if end if;
    if @extra_time_code is not null then
      select "count"()
        into @d_count
        from "payroll_emp_ot"
        where "payroll_emp_ot"."c_year" = @cyear
        and "payroll_emp_ot"."c_month" = @cmonth
        and "payroll_emp_ot"."c_emp_code" = @c_emp_code
        and "payroll_emp_ot"."c_sal_comp_code" = @extra_time_code;
      if @d_count > 0 then //Update 
        update "payroll_emp_ot" set "n_hour" = "n_hour"+@n_extra_hour
          where "payroll_emp_ot"."c_year" = @cyear
          and "payroll_emp_ot"."c_month" = @cmonth
          and "payroll_emp_ot"."c_emp_code" = @c_emp_code
          and "payroll_emp_ot"."c_sal_comp_code" = @extra_time_code
      else
        insert into "payroll_emp_ot"
          ( "c_year","c_month","c_emp_code","c_sal_comp_code","n_hour","d_ldate","c_createuser","t_ltime","n_cancel_flag","n_complete" ) on existing skip
          select @cyear,@cmonth,@c_emp_code,@extra_time_code,@n_extra_hour,"today"(),'AUTO',"NOw"(),0,0
      end if
    end if
  end loop "lp0";
  close "cur_srno"
end;
CREATE EVENT "DBA"."Updated_day_end_trigger"
SCHEDULE "Updated_day_end_trigger" START TIME '11:00' ON ( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' )
HANDLER
begin
  update "day_end_values" set "n_updated" = '0' where "d_date" between "today"()-35 and "today"()-1;
  commit work;
  trigger event "update_dayend_values";
  commit work
end;
CREATE EVENT "DBA"."updating_supp_ord_ledger"
SCHEDULE "updating_supp_ord_ledger" START TIME '03:40' ON ( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' )
DISABLE
HANDLER
begin
  declare "lspath","lsfilename","ls_time","lsLastSyncTime","lsAppPath" char(200);
  declare "lddir" integer;
  declare "lsQuery" long varchar;
  select "LEFT"("db_property"('file'),"LENGTH"("db_property"('file'))-("LENGTH"("DB_NAME"())*2+4)) into "lsAppPath";
  select "lsAppPath"+'Data2Cloud\\Bfr_updating_supp_ord_ledger' into "lspath";
  select "XP_CMDSHELL"('mkdir '+"lspath") into "lddir";
  select "lspath"+'\\'+"substring"("db_name"(),4,3)+"replace"("replace"("replace"("left"("string"("now"()),19),':',''),' ',''),'-','')+'.csv' into "lsfilename";
  set "lsfilename" = "replace"("lsfilename",'\\','/'); --return;
  set "lsQuery"
     = 'Unload Select * from (Select '+''''+'c_br_code'+''''+' as c_br_code,'
    +''''+'c_year'+''''+' as c_year,'
    +''''+'C_prefix'+''''+' as C_prefix,'
    +''''+'n_srno'+''''+' as n_srno,'
    +''''+'n_seq'+''''+' as n_seq,'
    +''''+'c_item_code'+''''+' as c_item_code,'
    +''''+'n_qty'+''''+' as n_qty,'
    +''''+'n_issue_qty'+''''+' as n_issue_qty,'
    +''''+'n_cancel_qty'+''''+' as n_cancel_qty,'
    +''''+'c_ref_br_code'+''''+' as c_ref_br_code,'
    +''''+'n_out_qty'+''''+' as n_out_qty,'
    +''''+'n_sch_qty'+''''+' as n_sch_qty,'
    +''''+'n_sch_issue_qty'+''''+' as n_sch_issue_qty,'
    +''''+'n_sch_cancel_qty'+''''+' as n_sch_cancel_qty,'
    +''''+'n_rate'+''''+' as n_rate,'
    +''''+'n_disc_per'+''''+' as n_disc_per,'
    +''''+'n_mrp'+''''+' as n_mrp,'
    +''''+'n_ptr'+''''+' as n_ptr,'
    +''''+'n_pk'+''''+' as n_pk,'
    +''''+'T_VALID_TILL'+''''+' as T_VALID_TILL'
    +' union all '
    +' select Sl.c_br_code,Sl.c_year,Sl.c_prefix,string(Sl.n_srno) as n_srno ,string(Sl.n_seq) as n_seq,Sl.c_item_code,string(Sl.n_qty) as n_qty,string(Sl.n_issue_qty) as n_issue_qty,string(Sl.n_cancel_qty) as n_cancel_qty,'
    +' Sl.c_ref_br_code,string(Sl.n_out_qty) as n_out_qty,string(Sl.n_sch_qty) as n_sch_qty,string(Sl.n_sch_issue_qty) as n_sch_issue_qty,string(Sl.n_sch_cancel_qty) as n_sch_cancel_qty,string(Sl.n_rate) as n_rate,'
    +' string(Sl.n_disc_per) as n_disc_per,string(Sl.n_mrp) as n_mrp,string(Sl.n_ptr) as n_ptr,string(Sl.n_pk) as n_pk,DATEFORMAT(oM.T_VALID_TILL,'+''''+'YYYY-MM-DD'+''''+') as T_VALID_TILL '
    +' from dba.supp_ord_ledger as Sl '
    +'   left join order_det od on Sl.c_br_code=Od.c_br_code and Sl.c_year=Od.c_year and Sl.c_prefix=Od.c_prefix and Sl.n_srno=Od.n_srno and Sl.c_item_code=Od.c_item_code'
    +'   left join order_MST oM on Sl.c_br_code=Om.c_br_code and Sl.c_year=OM.c_year and Sl.c_prefix=OM.c_prefix and Sl.n_srno=Om.n_srno '
    +' left join Act_mst  Am on od.c_ord_supp_code=Am.c_code WHERE Om.T_VALID_TILL < TODAY() AND (Sl.N_QTY > Sl.N_ISSUE_QTY+Sl.N_CANCEL_QTY) AND Sl.c_br_code=substr(db_name(),4,3)'
    +') a to '+''''+"lsfilename"+''''+' HEXADECIMAL OFF ESCAPES OFF QUOTES OFF';
  execute immediate "lsQuery";
  update "supp_ord_ledger" as "Sl"
    left outer join "order_det" as "od" on "Sl"."c_br_code" = "Od"."c_br_code" and "Sl"."c_year" = "Od"."c_year" and "Sl"."c_prefix" = "Od"."c_prefix" and "Sl"."n_srno" = "Od"."n_srno" and "Sl"."c_item_code" = "Od"."c_item_code"
    set "N_CANCEL_QTY" = "Sl"."N_QTY"-"N_ISSUE_QTY"
    where "Sl"."c_br_code" = "substr"("db_name"(),4,3) and "Od"."c_br_code" is null and "Sl"."N_QTY" > "N_ISSUE_QTY";
  commit work;
  update "supp_ord_ledger" as "Sl"
    left outer join "order_det" as "od" on "Sl"."c_br_code" = "Od"."c_br_code" and "Sl"."c_year" = "Od"."c_year" and "Sl"."c_prefix" = "Od"."c_prefix" and "Sl"."n_srno" = "Od"."n_srno" and "Sl"."c_item_code" = "Od"."c_item_code"
    left outer join "order_MST" as "oM" on "Sl"."c_br_code" = "Om"."c_br_code" and "Sl"."c_year" = "OM"."c_year" and "Sl"."c_prefix" = "OM"."c_prefix" and "Sl"."n_srno" = "Om"."n_srno"
    set "N_CANCEL_QTY" = "Sl"."N_QTY"-"N_ISSUE_QTY"
    where "Om"."T_VALID_TILL" < "TODAY"() and("Sl"."N_QTY" > "N_ISSUE_QTY"+"N_CANCEL_QTY") and "Sl"."c_br_code" = "substr"("db_name"(),4,3);
  commit work
end;
CREATE EVENT "DBA"."Userperformance"
SCHEDULE "Userperformance" START TIME '23:30' ON ( 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' )
DISABLE
HANDLER
begin
  declare "lspath","lsfilename","ls_time","lsLastSyncTime","lsAppPath" char(200);
  declare "lddir" integer;
  declare "lsQuery" long varchar;
  select "LEFT"("db_property"('file'),"LENGTH"("db_property"('file'))-("LENGTH"("DB_NAME"())*2+4)) into "lsAppPath";
  select "lsAppPath"+'Data2Cloud\\Userperformance' into "lspath";
  select "XP_CMDSHELL"('mkdir '+"lspath") into "lddir";
  select "lspath"+'\\'+"substring"("db_name"(),4,3)+"replace"("replace"("replace"("left"("string"("now"()),19),':',''),' ',''),'-','')+'.csv' into "lsfilename";
  set "lsfilename" = "replace"("lsfilename",'\\','/'); --return;
  set "lsQuery"
     = 'Unload Select * from (Select '+''''+'ddate'+''''+' as ddate,'
    +''''+'pick_user'+''''+' as pick_user,'
    +''''+'no_of_items'+''''+' as no_of_items,'
    +''''+'no_of_trays'+''''+' as no_of_trays,'
    +''''+'diff'+''''+' as diff,'
    +''''+'tot_login_time'+''''+' as tot_login_time'
    +' union all '
    +' select dateformat(ddate,'+''''+'YYYY-MM-DD'+''''+')  as ddate,pick_user,string(no_of_items) as no_of_items,string(no_of_trays) as no_of_trays,string(diff) as diff,string(tot_login_time) as tot_login_time from usp_datewise_empwise_avg_time_auto (today(),string(year(today()))+'+''''+'-'+''''+'+string(month(today()))+'+''''+'-01'+''''+')  '
    +') a to '+''''+"lsfilename"+''''+' HEXADECIMAL OFF ESCAPES OFF QUOTES OFF';
  execute immediate "lsQuery"
end;
