create or replace PROCEDURE "DBA"."usp_slip_reprint_from_sp"( 
  --call "DBA"."usp_slip_print_from_sp"( '503','16','7',6278);
  in "as_br" char(6),in "as_yr" char(2),in "as_prefix" char(4),in "an_srno" numeric(9) ) 
begin
  declare "s_app_path" char(100);
  declare @br_code char(6);
  declare @yr char(2);
  declare @pfx char(3);
  declare @srno numeric(9);
  set @br_code = "as_br";
  set @yr = "as_yr";
  set @pfx = "as_prefix";
  set @srno = "an_srno";
  --http://192.168.7.12:15503/ws_slip_print?BrCode=503&year=15&pfx=7&srno=2545
  select "left"("db_property"('file'),"length"("db_property"('file'))-("length"("db_name"())*2+4))+'ecogreen.exe' into "s_app_path";
  set "s_app_path" = "s_app_path"+' '+"s_app_path"+'#'+"db_name"()+'#'+'slipreprint@'+@br_code+'@'+@yr+'@'+@pfx+'@'+"string"(@srno)+'@';
  call "xp_cmdshell"("s_app_path",'no_output')
end;
commit work;
go
