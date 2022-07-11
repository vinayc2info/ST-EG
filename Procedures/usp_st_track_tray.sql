CREATE PROCEDURE "DBA"."usp_st_track_tray"()
result( "is_xml_string" xml ) 
begin
  declare @tray char(6);
  declare @cIndex char(50);
  set @cIndex = "http_variable"('cIndex');
  set @tray = "http_variable"('Tray');
  case @cIndex
  when 'Tray_track' then
    select if "sm"."c_cust_code" <> "left"("st"."c_doc_no","charindex"('/',"st"."c_doc_no")-1) then "sm"."c_cust_code" else "left"("st"."c_doc_no","charindex"('/',"st"."c_doc_no")-1) endif as "br_code",
      --"left"("st"."c_doc_no","charindex"('/',"st"."c_doc_no")-1) as "br_code",
      "act_mst"."c_name" as "br_name",
      "st"."c_doc_no" as "doc_no",
      "st"."c_stage_code" as "stage_code",
      (if "st"."c_rack_grp_code" = '-' then '' else "st"."c_rack_grp_code" endif) as "Rack_grp",
      if "st"."n_inout" = 0 then
        'Pick In Progress'
      else if "st"."n_flag" = 0 then 'Pick Completed'
        else if "st"."n_flag" = 1 then 'Label Print'
          else if "st"."n_flag" = 2 then 'Barcode Verification Started'
            else if "st"."n_flag" = 3 then 'Barcode Verification Completed'
              else if "st"."n_flag" = 4 then 'Passed Conveyor Belt'
                else if "st"."n_flag" = 5 then 'Picked From Conveyor Belt'
                  else if "st"."n_flag" = 6 then 'Assigned to counter'
                    else 'Final Conversion'
                    endif
                  endif
                endif
              endif
            endif
          endif
        endif
      endif as "tray_Status",
      "act_route"."c_route_code" as "route_code",
      "route_mst"."c_name"
      from "st_track_tray_move" as "st"
        left outer join "st_track_mst" as "sm" on "sm"."c_doc_no" = "st"."c_doc_no"
        left outer join "act_mst" on "br_code" = "act_mst"."c_code"
        left outer join "act_route" on "br_code" = "act_route"."c_br_code" and "act_route"."c_code" = "sm"."c_br_code"
        left outer join "route_mst" on "act_route"."c_route_code" = "route_mst"."c_code"
      where "st"."c_tray_code" = @tray for xml raw,elements
  end case
end;