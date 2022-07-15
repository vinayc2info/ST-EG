create or replace procedure usp_st_err_tracking(  
  in @gsBr char(6),
  in @devID char(200),
  in @sKey char(20),
  in @UserId char(20),
  in @StageCode char(6),
  in @RackGrpCode char(300),
  in @cIndex char(30),
  in @HdrData char(7000),
  in @DetData char(32767),
  in @GodownCode char(6)) 
result( "is_xml_string" xml ) 
begin
declare @carton_no char(6);
  if @devID = '' or @devID is null then
    set @gsBr = "http_variable"('gsBr'); 
    set @devID = "http_variable"('devID'); 
    set @sKey = "http_variable"('sKey');
    set @UserId = "http_variable"('UserId');
    set @RackGrpCode = "http_variable"('RackGrpCode'); 
    set @StageCode = "http_variable"('StageCode'); 
    set @cIndex = "http_variable"('cIndex'); 
    set @HdrData = "http_variable"('HdrData'); 
    set @DetData = "http_variable"('DetData'); 
    set @GodownCode = "http_variable"('GodownCode') 		
  end if;
  case @cIndex
  when 'supervisor_dashboard' then
    select 
        c_err_mark_user as conversion_user,
        c_item_code as item_code,
        item_mst.c_name as item_name,
        c_batch_no as batch_no,
        n_qty as err_qty,
        n_err_type as err_type,
        c_err_mark_user as err_mark_user,
        t_err_time as err_req_time,
        c_supervisor as spvr_name,
        t_spvr_err_marked_time as spvr_err_marked_time
    from st_err_track_det
    join item_mst on item_mst.c_code = st_err_track_det.c_item_code
    where st_err_track_det.n_complete = 0 for xml raw,elements
  end case
end;
commit work;
go


if (select count() from syswebservice where service_name = 'ws_st_err_tracking') = 0 then
    CREATE SERVICE "ws_st_err_tracking" TYPE 'RAW' AUTHORIZATION OFF USER "DBA" URL ELEMENTS AS select '<root>'+"is_xml_string"+'</root>'
      from "DBA"."usp_st_err_tracking"(:url1,:url2,:url3,:url4,:url5,:url6,:url7,:url8,:url9,:url10);
end if ;
commit work;
go