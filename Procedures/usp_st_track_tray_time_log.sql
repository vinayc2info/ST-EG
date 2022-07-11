CREATE PROCEDURE "DBA"."usp_st_track_tray_time_log"()
result( "is_xml_string" xml ) 
begin
  /*
Author 		: Saneesh C G
Procedure	: usp_st_track_tray_time
SERVICE		: 
Date 		: 16-03-2015
Modified By :  
Ldate 		: 
Purpose		: Move the data from st_track_tray_time to st_track_tray_time_log on dayend/week end /month end 
Input		: 
IndexDetails: 
Tags		: 
Note		:
*/
  insert into "st_track_tray_time_log"
    ( "c_doc_no","n_inout","c_tray_code","c_work_place","c_user",
    "c_rack_grp_code","c_stage_code","t_time","t_action_start_time",
    "t_action_end_time" ) on existing skip
    select "c_doc_no","n_inout","c_tray_code","c_work_place","c_user",
      "c_rack_grp_code","c_stage_code","t_time","t_action_start_time","t_action_end_time"
      from "st_track_tray_time";
  delete from "st_track_tray_time";
  select '' as "column1" for xml raw,elements;
  return
end;