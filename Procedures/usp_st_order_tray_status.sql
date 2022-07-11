CREATE PROCEDURE "DBA"."usp_st_order_tray_status"( 
  in @devID char(200),
  in @cIndex char(30),
  in @gsBr char(6),
  in @ad_date date ) 
result( "is_xml_string" xml ) 
begin
  --common >>
  declare @ColSep char(6);
  declare @RowSep char(6);
  declare @Pos integer;
  declare @ColPos integer;
  declare @RowPos integer;
  declare @ColMaxLen numeric(4);
  declare @RowMaxLen numeric(4);
  declare @DocNo char(30);
  declare @docbr char(6);
  print 'gd';
  if @devID = '' or @devID is null then
    set @gsBr = "http_variable"('gsBr'); --1
    set @devID = "http_variable"('devID'); --2
    set @cIndex = "http_variable"('cIndex'); --3
    set @ad_date = "http_variable"('date'); --4
    set @DocNo = "http_variable"('docno'); --5
    set @docbr = "http_variable"('docbr') --6
  end if;
  select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
  select "c_delim" into @RowSep from "ps_tab_delimiter" where "n_seq" = 1;
  set @ColMaxLen = "Length"(@ColSep);
  set @RowMaxLen = "Length"(@RowSep);
  case @cIndex
  when 'get_order_status' then
    select "m"."c_doc_no",
      "m"."c_cust_code" as "br_code",
      "act_mst"."c_name" as "br_name",
      cast("substr"(("substr"(("substr"("m"."c_doc_no","charindex"('/',"m"."c_doc_no")+1)),"charindex"('/',("substr"("m"."c_doc_no","charindex"('/',"m"."c_doc_no")+1)))+1)),"charindex"('/',("substr"(("substr"("m"."c_doc_no","charindex"('/',"m"."c_doc_no")+1)),"charindex"('/',("substr"("m"."c_doc_no","charindex"('/',"m"."c_doc_no")+1)))+1)))+1) as numeric(9)) as "nsrno",
      "isnull"("m"."c_user",'') as "c_user",
      (if "m"."n_confirm" = 0 then 'Pending For Confirm' else if "m"."n_complete" = 9 then 'Document done' else 'Confirmed' endif endif) as "stats",
      "left"("m"."t_time_in",16) as "t_time_in",
      "left"("isnull"("m"."t_confirm_time","t_time_in"),16) as "confirm_time",
      (if "m"."n_urgent" = 0 then 'Normal' else if "m"."n_urgent" = 1 then 'Urgent' else 'Very Urgent' endif endif) as "Priority",
      "isnull"(if "m"."n_complete" <> 9 then "isnull"((if "mov"."n_flag" = 0 and "mov"."c_rack_grp_code" <> '-' then 'Pick in Process'
        else if "mov"."c_rack_grp_code" = '-' and "mov"."n_flag" = 0 then 'Waiting For Label Print'
          else if "mov"."n_flag" = 1 then 'Label Print'
            else if "mov"."n_flag" = 2 then 'Barcode Verification Started'
              else if "mov"."n_flag" = 3 then 'Barcode Verification Completed'
                else if "mov"."n_flag" = 4 then 'Conveyor Belt'
                  else if "mov"."n_flag" = 5 then 'Passed Conveyor Belt'
                    else if "mov"."n_flag" = 6 then 'Picked From Conveyor Belt'
                      else 'Conversion Started'
                      endif
                    endif
                  endif
                endif
              endif
            endif
          endif
        endif),'Not Started') endif,'Order Completed') as "tray_stages",
      "replace"("list"(distinct "mov"."c_tray_code"),',',' ') as "Tray_List",
      "replace"("list"(distinct "mov"."c_rack_grp_code"),',',' ') as "Rack_Grp"
      from "st_track_mst" as "m" left outer join "st_track_tray_move" as "mov" on "m"."c_doc_no" = "mov"."c_doc_no"
        left outer join "act_mst" on "act_mst"."c_code" = "m"."c_cust_code"
      where "m"."n_inout" = 0
      and "m"."d_date" = @ad_date
      group by "m"."c_doc_no",
      "br_code",
      "c_user",
      "stats",
      "m"."t_time_in",
      "tray_stages",
      "confirm_time",
      "Priority",
      "nsrno",
      "br_name"
      order by "m"."c_doc_no" asc,"nsrno" asc for xml raw,elements
  when 'get_doc_details' then
    select "doc_no","slip_num","gdn_num","total_gdn"
      from(select "st_track_mst"."c_doc_no" as "doc_no",
          cast("isnull"("slip_det"."n_srno",'') as integer) as "slip_num",
          "LIST"("gdn_mst"."n_srno") as "gdn_num",
          "COUNT"("gdn_mst"."n_srno") as "total_gdn"
          from "gdn_mst" left outer join "slip_det" on "gdn_mst"."n_srno" = "slip_det"."n_inv_no"
            and "gdn_mst"."c_br_code" = "slip_det"."c_inv_br"
            and "gdn_mst"."c_year" = "slip_det"."c_inv_year"
            and "gdn_mst"."c_prefix" = "slip_det"."c_inv_prefix"
            join "st_track_mst" on(("gdn_mst"."c_ref_br_code")+'/'+("gdn_mst"."c_order_year")+'/'+("gdn_mst"."c_order_prefix")+'/'+"string"("gdn_mst"."n_order_no")) = ("st_track_mst"."c_doc_no")
          where "st_track_mst"."c_doc_no" = @DocNo
          group by "doc_no",
          "slip_num" union
        select "st_track_mst"."c_doc_no" as "doc_no",
          cast("isnull"("slip_det"."n_srno",'') as integer) as "slip_num",
          "LIST"("inv_mst"."n_srno") as "gdn_num",
          "COUNT"("inv_mst"."n_srno") as "total_gdn"
          from "inv_mst" left outer join "slip_det" on "inv_mst"."c_br_code" = "slip_det"."c_inv_br" and "inv_mst"."c_year" = "slip_det"."c_inv_year"
            and "inv_mst"."c_prefix" = "slip_det"."c_inv_prefix" and "inv_mst"."n_srno" = "slip_det"."n_inv_no"
            join "st_track_mst" on(("inv_mst"."c_br_code")+'/'+("inv_mst"."c_year")+'/'+("inv_mst"."c_prefix")+'/'+"string"("inv_mst"."n_order_no")) = ("st_track_mst"."c_doc_no")
          where "st_track_mst"."c_doc_no" = @DocNo
          group by "doc_no",
          "slip_num") as "a"
      order by "doc_no" asc for xml raw,elements
  when 'get_order_status_by_br_code' then
    select "m"."c_doc_no",
      "m"."c_cust_code" as "br_code",
      "act_mst"."c_name" as "br_name",
      cast("substr"(("substr"(("substr"("m"."c_doc_no","charindex"('/',"m"."c_doc_no")+1)),"charindex"('/',("substr"("m"."c_doc_no","charindex"('/',"m"."c_doc_no")+1)))+1)),"charindex"('/',("substr"(("substr"("m"."c_doc_no","charindex"('/',"m"."c_doc_no")+1)),"charindex"('/',("substr"("m"."c_doc_no","charindex"('/',"m"."c_doc_no")+1)))+1)))+1) as numeric(9)) as "nsrno",
      "isnull"("m"."c_user",'') as "c_user",
      (if "m"."n_confirm" = 0 then 'Pending For Confirm' else if "m"."n_complete" = 9 then 'Document done' else 'Confirmed' endif endif) as "stats",
      "left"("m"."t_time_in",16) as "t_time_in",
      "left"("isnull"("m"."t_confirm_time","t_time_in"),16) as "confirm_time",
      (if "m"."n_urgent" = 0 then 'Normal' else if "m"."n_urgent" = 1 then 'Urgent' else 'Very Urgent' endif endif) as "Priority",
      "isnull"(if "m"."n_complete" <> 9 then "isnull"((if "mov"."n_flag" = 0 and "mov"."c_rack_grp_code" <> '-' then 'Pick in Process'
        else if "mov"."c_rack_grp_code" = '-' and "mov"."n_flag" = 0 then 'Waiting For Label Print'
          else if "mov"."n_flag" = 1 then 'Label Print'
            else if "mov"."n_flag" = 2 then 'Barcode Verification Started'
              else if "mov"."n_flag" = 3 then 'Barcode Verification Completed'
                else if "mov"."n_flag" = 4 then 'Conveyor Belt'
                  else if "mov"."n_flag" = 5 then 'Passed Conveyor Belt'
                    else if "mov"."n_flag" = 6 then 'Picked From Conveyor Belt'
                      else 'Conversion Started'
                      endif
                    endif
                  endif
                endif
              endif
            endif
          endif
        endif),'Not Started') endif,'Order Completed') as "tray_stages",
      "replace"("list"(distinct "mov"."c_tray_code"),',',' ') as "Tray_List",
      "replace"("list"(distinct "mov"."c_rack_grp_code"),',',' ') as "Rack_Grp"
      from "st_track_mst" as "m" left outer join "st_track_tray_move" as "mov" on "m"."c_doc_no" = "mov"."c_doc_no"
        left outer join "act_mst" on "act_mst"."c_code" = "m"."c_cust_code"
      where "m"."n_inout" = 0
      and "m"."d_date" = @ad_date and "m"."c_cust_code" = @docbr
      group by "m"."c_doc_no",
      "br_code",
      "c_user",
      "stats",
      "m"."t_time_in",
      "tray_stages",
      "confirm_time",
      "Priority",
      "nsrno",
      "br_name"
      order by "m"."c_doc_no" asc,"nsrno" asc for xml raw,elements
  end case
end;