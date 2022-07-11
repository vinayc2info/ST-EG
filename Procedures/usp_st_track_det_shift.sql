CREATE PROCEDURE "DBA"."usp_st_track_det_shift"()
begin
  /* 
Author          : Saneesh C G 
Procedure       : usp_update_st_track_det_log_from_st_track_det
SERVICE         : ws_st_track_det_shift
Date            : 22-06-2015
--------------------------------------------------------------------------------------------------------------------------
Modified By     ModifiedDate                TicketNo                    Purpose                                 
---------------------------------------------------------------------------------------------------------------------------
Gargee             NILL                                                Move the data from st_track_det to st_track_log on dayend/week end /month end 
Pratheesh       2022-02-22 16:42:36.816     C78055                     IN DAY END PROCESS SHIFT ST_TRACK_TRAY_TIME TAB                                  
---------------------------------------------------------------------------------------------------------------------------
*/
  insert into "st_track_det_log"
    ( "c_doc_no","n_inout","c_item_code","c_batch_no","n_seq",
    "n_qty","n_bal_qty","c_note","c_rack","c_rack_grp_code",
    "c_stage_code","n_complete","c_reason_code","n_hold_flag","c_tray_code",
    "c_user","c_godown_code","c_stin_ref_no",
    "c_user_2" ) on existing skip
    select "d"."c_doc_no","d"."n_inout","d"."c_item_code","d"."c_batch_no","d"."n_seq",
      "d"."n_qty","d"."n_bal_qty","d"."c_note","d"."c_rack","d"."c_rack_grp_code",
      "d"."c_stage_code","d"."n_complete","d"."c_reason_code","d"."n_hold_flag","d"."c_tray_code",
      "d"."c_user","d"."c_godown_code","d"."c_stin_ref_no","d"."c_user_2"
      from "st_track_mst" as "m" join "st_track_det" as "d"
        on "m"."c_doc_no" = "d"."c_doc_no" and "m"."n_inout" = "d"."n_inout"
      where "m"."n_complete" in( 9,2 ) and "m"."n_inout" = 0 union
    select "d"."c_doc_no","d"."n_inout","d"."c_item_code","d"."c_batch_no","d"."n_seq",
      "d"."n_qty","d"."n_bal_qty","d"."c_note","d"."c_rack","d"."c_rack_grp_code",
      "d"."c_stage_code","d"."n_complete","d"."c_reason_code","d"."n_hold_flag","d"."c_tray_code",
      "d"."c_user","d"."c_godown_code","d"."c_stin_ref_no","d"."c_user_2"
      from "st_track_mst" as "m" join "st_track_det" as "d"
        on "m"."c_doc_no" = "d"."c_doc_no" and "m"."n_inout" = "d"."n_inout"
      where "m"."n_complete" in( 8,2,9 ) and "m"."n_inout" = 1;
  -- print 'St_track_log_insert rows';
  --  print @@rowcount;
  delete from "st_track_det" as "d" from "st_track_mst" as "m"
    where "m"."c_doc_no" = "d"."c_doc_no" and "m"."n_inout" = "d"."n_inout"
    and "m"."n_complete" in( 9,2 ) and "m"."n_inout" = 0;
  --  print 'St_track_delete inout 0 9,2  rows';
  --  print @@rowcount;
  delete from "st_track_det" as "d" from "st_track_mst" as "m"
    where "m"."c_doc_no" = "d"."c_doc_no" and "m"."n_inout" = "d"."n_inout"
    and "m"."n_complete" in( 8,2,9 ) and "m"."n_inout" = 1;
  --  print 'St_track_delete inout 1 9,2  rows';
  --  print @@rowcount;
  -- deletion of st_track_complete_date 
  delete from "st_track_complete_date"
    where "date"("t_time") <= "uf_default_date"()-7;
  ---insertion in tray_mov backup table by gargee
  insert into "st_track_in_history_bkp"
    ( "c_doc_no","n_seq","c_item_code","c_batch_no","n_qty","c_tray_code","n_complete","t_time","t_time_out","c_godown_code","c_user" ) on existing skip
    select "c_doc_no","n_seq","c_item_code","c_batch_no","n_qty","c_tray_code","n_complete","t_time","t_time_out","c_godown_code","c_user"
      from "st_track_in_history";
  delete from "DBA"."st_track_in_history";
  --Need to clear st_store_login ,st_store_login_det   tables also,the same data wil be triggering  into st_login_history amd st_login_history_det
  delete from "st_store_login" where "t_login_time" is null;
  delete from "st_store_login_det" where "t_login_time" is null;
  --select '1' as C_MESSAGE for xml raw,elements;
  insert into "st_track_tray_time_backup"
    ( "c_doc_no","n_inout","c_tray_code","c_work_place","c_user","c_rack_grp_code","c_stage_code","t_time","t_action_start_time",
    "t_action_end_time","n_bounce_count","n_pick_count" ) on existing skip
    select "c_doc_no","n_inout","c_tray_code","c_work_place","c_user","c_rack_grp_code","c_stage_code","t_time","t_action_start_time",
      "t_action_end_time","n_bounce_count","n_pick_count" from "st_track_tray_time" where "t_time" < "today"()-1;
  delete from "st_track_tray_time" where "t_time" < "today"()-1;
  return
end;