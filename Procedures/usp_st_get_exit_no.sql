CREATE PROCEDURE "DBA"."usp_st_get_exit_no"()
result( "is_xml_string" xml ) 
begin
  declare @tray char(6);
  declare @cust_code char(6);
  declare @route_code char(6);
  declare @exit_no char(6);
  declare @doc_no char(25);
  set @tray = "http_variable"('tray');
  //  if @tray <> '15061' then
  select "st_track_mst"."c_cust_code","st_track_mst"."c_doc_no",
    "act_route"."c_route_code",
    "st_conveyer_det"."n_exit_seq" into @cust_code,@doc_no,@route_code,@exit_no
    from "st_track_tray_move"
      join "st_track_mst" on "st_track_mst"."c_doc_no" = "st_track_tray_move"."c_doc_no"
      left outer join "act_route" on "act_route"."c_code" = "uf_get_br_code"('000') and "act_route"."c_br_code" = "st_track_mst"."c_cust_code"
      left outer join "st_conveyer_det" on "st_conveyer_det"."c_br_code" = "act_route"."c_code" and "st_conveyer_det"."c_route_code" = "act_route"."c_route_code"
    where "st_track_tray_move"."n_inout" = 9 and "st_track_tray_move"."c_tray_code" = @tray;
  if @exit_no is null then
    set @exit_no = '0'
  end if;
  update "st_track_tray_move" set "st_track_tray_move"."n_flag" = 4
    where "st_track_tray_move"."c_doc_no" = @doc_no
    and "st_track_tray_move"."c_tray_code" = @tray
    and "st_track_tray_move"."n_inout" = 9;
  //  else
  //    set @exit_no = 8
  //  end if;
  select @exit_no as "exit_no" for xml raw,elements
end;