CREATE PROCEDURE "DBA"."usp_tray_barcode_print"( in "as_para" char(500) ) 
begin
  declare "s_app_path" char(7000);
  declare @Item_code char(6);
  declare @batch_no char(15);
  declare @Rack char(15);
  declare @dev_id char(100);
  declare @rack_group char(15);
  declare @doc_no char(50);
  declare @tray char(50);
  declare @carton char(4);
  declare @qtyflag char(2);
  declare @godwoncode char(6);
  declare @gsBr char(6);
  declare @stg_grp_code char(6);
  set @gsBr = "http_variable"('gsBr'); --1
  set @dev_id = "http_variable"('dev_id');
  set @Item_code = "http_variable"('item_code');
  set @batch_no = "http_variable"('batch_no');
  set @Rack = "http_variable"('rack');
  set @rack_group = "http_variable"('rack_group');
  set @doc_no = "http_variable"('docno');
  set @tray = "http_variable"('tray');
  set @carton = "http_variable"('carton');
  if @gsBr is null or "length"(@gsBr) = 0 then
    select "substring"("db_name"(),4,3)
      into @gsBr end if;
  select "rsm"."c_stage_grp_code"
    into @stg_grp_code from "item_mst_br_info" as "ib","item_mst" as "i","rack_mst" as "r"
      ,"st_store_stage_det" as "rsd","st_store_stage_mst" as "rsm"
    where "rsm"."c_code" = "rsd"."c_stage_code"
    and "rsm"."c_br_code" = "rsd"."c_br_code"
    and "rsm"."c_br_code" = "ib"."c_br_code"
    and "rsd"."c_rack_grp_code" = "r"."c_rack_grp_code"
    and "r"."c_code" = "ib"."c_rack" and "i"."c_code" = "ib"."c_code" and "ib"."c_br_code" = '503'
    and "i"."c_code" = @Item_code
    and "ib"."c_br_code" = @gsBr;
  if @stg_grp_code is null then
    set @stg_grp_code = '-'
  end if;
  -- carton_print count update after line item entry 
  if(select "n_carton_print" from "item_receipt_entry" where "c_item_code" = @Item_code and "c_batch_no" = @batch_no
      and "c_pur_br_code" = "left"((@doc_no),"charindex"('/',(@doc_no))-1)
      and "c_pur_year" = "left"("substring"("left"(@doc_no,("length"(@doc_no)-("charindex"('/',"reverse"(@doc_no))-1))),"charindex"('/',"left"(@doc_no,("length"(@doc_no)-("charindex"('/',"reverse"(@doc_no))-1))))+1),"charindex"('/',"substring"("left"(@doc_no,("length"(@doc_no)-("charindex"('/',"reverse"(@doc_no))-1))),"charindex"('/',"left"(@doc_no,("length"(@doc_no)-("charindex"('/',"reverse"(@doc_no))-1))))+1))-1)
      and "c_pur_prefix" = "left"("substr"("substring"("left"(@doc_no,("length"(@doc_no)-("charindex"('/',"reverse"(@doc_no))-1))),"charindex"('/',"left"(@doc_no,("length"(@doc_no)-("charindex"('/',"reverse"(@doc_no))-1))))+1),"charindex"('/',"substring"("left"(@doc_no,("length"(@doc_no)-("charindex"('/',"reverse"(@doc_no))-1))),"charindex"('/',"left"(@doc_no,("length"(@doc_no)-("charindex"('/',"reverse"(@doc_no))-1))))+1))+1),"charindex"('/',"substr"("substring"("left"(@doc_no,("length"(@doc_no)-("charindex"('/',"reverse"(@doc_no))-1))),"charindex"('/',"left"(@doc_no,("length"(@doc_no)-("charindex"('/',"reverse"(@doc_no))-1))))+1),"charindex"('/',"substring"("left"(@doc_no,("length"(@doc_no)-("charindex"('/',"reverse"(@doc_no))-1))),"charindex"('/',"left"(@doc_no,("length"(@doc_no)-("charindex"('/',"reverse"(@doc_no))-1))))+1))+1))-1)
      and "n_pur_srno" = "reverse"("left"("reverse"(@doc_no),"charindex"('/',("reverse"(@doc_no)))-1))
      and("c_tray_code" = @tray or "n_carton_no" = @tray)) = 0 then
    update "item_receipt_entry" set "n_carton_print" = @carton where "c_item_code" = @Item_code and "c_batch_no" = @batch_no
      and "c_pur_br_code" = "left"((@doc_no),"charindex"('/',(@doc_no))-1)
      and "c_pur_year" = "left"("substring"("left"(@doc_no,("length"(@doc_no)-("charindex"('/',"reverse"(@doc_no))-1))),"charindex"('/',"left"(@doc_no,("length"(@doc_no)-("charindex"('/',"reverse"(@doc_no))-1))))+1),"charindex"('/',"substring"("left"(@doc_no,("length"(@doc_no)-("charindex"('/',"reverse"(@doc_no))-1))),"charindex"('/',"left"(@doc_no,("length"(@doc_no)-("charindex"('/',"reverse"(@doc_no))-1))))+1))-1)
      and "c_pur_prefix" = "left"("substr"("substring"("left"(@doc_no,("length"(@doc_no)-("charindex"('/',"reverse"(@doc_no))-1))),"charindex"('/',"left"(@doc_no,("length"(@doc_no)-("charindex"('/',"reverse"(@doc_no))-1))))+1),"charindex"('/',"substring"("left"(@doc_no,("length"(@doc_no)-("charindex"('/',"reverse"(@doc_no))-1))),"charindex"('/',"left"(@doc_no,("length"(@doc_no)-("charindex"('/',"reverse"(@doc_no))-1))))+1))+1),"charindex"('/',"substr"("substring"("left"(@doc_no,("length"(@doc_no)-("charindex"('/',"reverse"(@doc_no))-1))),"charindex"('/',"left"(@doc_no,("length"(@doc_no)-("charindex"('/',"reverse"(@doc_no))-1))))+1),"charindex"('/',"substring"("left"(@doc_no,("length"(@doc_no)-("charindex"('/',"reverse"(@doc_no))-1))),"charindex"('/',"left"(@doc_no,("length"(@doc_no)-("charindex"('/',"reverse"(@doc_no))-1))))+1))+1))-1)
      and "n_pur_srno" = "reverse"("left"("reverse"(@doc_no),"charindex"('/',("reverse"(@doc_no)))-1))
      and("c_tray_code" = @tray or "n_carton_no" = @tray)
  end if;
  --set @qtyflag = http_variable('qty_print_flag');
  set @qtyflag = '0'; -- uncomment above line after releasing apk version with fixed qtyflag
  set @godwoncode = "http_variable"('GodownCode');
  select "left"("db_property"('file'),"length"("db_property"('file'))-("length"("db_name"())*2+4))+'ecogreen.exe' into "s_app_path";
  set "s_app_path" = "s_app_path"+' '+"s_app_path"+'#'+"db_name"()+'#'+'trayprint@'+@Item_code+'@'+@batch_no+'@'+@Rack+'@'
    +@rack_group+'@'+@doc_no+'@'+@tray+'@'+@carton+'@'+@godwoncode+'@'+@qtyflag+'@'+@stg_grp_code+'@###';
  call "xp_cmdshell"("s_app_path",'no_output');
  --call xp_cmdshell(s_app_path);
  select 'Printing Tray Barcode...'
end;