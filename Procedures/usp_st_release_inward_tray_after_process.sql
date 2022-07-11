CREATE PROCEDURE "DBA"."usp_st_release_inward_tray_after_process"()
result( 
  "is_xml_string" xml ) 
begin
  /*
Author 		: Saneesh
Procedure	: usp_st_release_inward_tray_after_process
SERVICE		: ws_usp_st_stock_audit
Date 		: 
Modified By : Saneesh C G 
Ldate 		: 19-04-2016
Purpose		: 
Input		: 
Note		:
*/
  begin
    for "c_code" as "release_tray_after_process" dynamic scroll cursor for
      select distinct "st_track_in"."c_doc_no" as "inw_c_doc_no","st_track_in"."c_tray_code" as "inw_c_tray_code",
        "left"("st_track_det"."c_stin_ref_no","len"("st_track_det"."c_stin_ref_no")-"charindex"('/',"reverse"("st_track_det"."c_stin_ref_no"))) as "c_sin_ref_no",
        "st_track_det"."c_doc_no" as "det_doc_no"
        from "st_track_in"
          join(select "c_doc_no","n_inout","c_item_code","c_batch_no","n_seq","n_qty","n_bal_qty","n_complete","C_godown_code","c_stin_ref_no" from "st_track_det" union
          select "c_doc_no","n_inout","c_item_code","c_batch_no","n_seq","n_qty","n_bal_qty","n_complete","C_godown_code","c_stin_ref_no" from "st_track_det_log") as "st_track_det"
          on "st_track_det"."c_stin_ref_no" = "st_track_in"."c_doc_no"+'/'+"string"("st_track_in"."n_seq")
        where "st_track_in"."n_complete" = 9 and "st_track_in"."c_tray_code" is not null
        and "st_track_det"."n_complete" = 8 order by 1 asc,2 asc
    do
      if(select "count"("c_doc_no") from "st_track_det" where("n_complete" = 0) and "c_doc_no" = "det_doc_no" and "c_tray_code" = "inw_c_tray_code") = 0 then
        -- print inw_c_tray_code;
        -- print inw_c_doc_no ;
        if(select "count"("c_doc_no") from "st_track_det_log" where("n_complete" = 0) and "c_doc_no" = "det_doc_no" and "c_tray_code" = "inw_c_tray_code") = 0 then
          delete from "st_track_in" where "c_doc_no" = "inw_c_doc_no" and "c_tray_code" = "inw_c_tray_code" and "st_track_in"."n_complete" = 9
        end if
      end if
    end for
  end
end;