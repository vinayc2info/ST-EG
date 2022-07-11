CREATE PROCEDURE "DBA"."usp_st_pick_in_pocess_tray"( 
  in @devID char(200),
  in @cIndex char(30),
  in @gsBr char(6) ) 
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
  --print 'gd';
  if @devID = '' or @devID is null then
    set @gsBr = "http_variable"('gsBr'); --1
    set @devID = "http_variable"('devID'); --2
    set @cIndex = "http_variable"('cIndex') --3
  end if;
  select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
  select "c_delim" into @RowSep from "ps_tab_delimiter" where "n_seq" = 1;
  set @ColMaxLen = "Length"(@ColSep);
  set @RowMaxLen = "Length"(@RowSep);
  case @cIndex
  when 'get_in_process_tray' then
    select "s"."stage","s"."rack_group","s"."tray_count_Doc_no","s"."tray_list","s"."pending_item"
      from(select "mov"."c_stage_code" as "stage",
          "mov"."c_rack_grp_code" as "Rack_group",
          "count"(distinct "mov"."c_tray_code") as "tray_count_Doc_no",
          "replace"("list"(distinct "mov"."c_tray_code"),',',' ') as "tray_list",
          "count"("st"."c_item_code") as "pending_item"
          from "st_track_tray_move" as "mov" left outer join "st_track_det" as "st" on "st"."c_doc_no" = "mov"."c_doc_no"
            and "st"."n_inout" = "mov"."n_inout"
            and "st"."c_stage_code" = "mov"."c_stage_code"
            and "st"."c_rack_grp_code" = "mov"."c_rack_grp_code"
            and "st"."n_complete" = 0
          where "mov"."n_inout" = 0
          and "mov"."n_flag" = 0
          and "mov"."c_godown_code" = '-'
          group by "stage","Rack_group") as "s" for xml raw,elements
  end case
end;