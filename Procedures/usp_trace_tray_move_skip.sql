CREATE PROCEDURE "DBA"."usp_trace_tray_move_skip"()
begin
  return;
  insert into "tray_move_skip" on existing skip
    select "c_tray_code","c_doc_no","c_stage_code","list"(distinct "c_rack_grp_code"),"COUNT"(),"getdate"()
      from "st_track_det" where "n_complete" = 0 and "c_tray_code" is not null and "n_inout" = 0
      and not "c_tray_code" = any(select "c_tray_code" from "DBA"."st_track_tray_move")
      and "LEFT"("C_DOC_NO",3) <> '503'
      group by "c_tray_code","c_doc_no","c_stage_code"
end;