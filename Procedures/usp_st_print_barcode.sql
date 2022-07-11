CREATE PROCEDURE "DBA"."usp_st_print_barcode"( 
  in @gsBr char(6),
  in @devID char(200),
  in @sKey char(20),
  in @UserId char(20),
  in @PhaseCode char(6),
  in @cIndex char(30),
  in @HdrData char(7000),
  in @DetData char(7000) ) 
result( "is_xml_string" xml ) 
begin
  /*
Author 		: Anup 
Procedure	: usp_st_print_barcode
SERVICE		: ws_st_print_barcode
Date 		: 29-09-2014
Ldate 		: 29-09-2014
Purpose		: Store Track TRANSACTION to TAB/DESKTOP
Input		: devID~sKey~UserId~cIndex~HdrData~DetData
IndexDetails: get_trays, get_trans
Note		:
Service Call (Format): http://192.168.7.12:13000/ws_st_print_barcode?devID=devID&sKey=KEY&UserId=MYBOSS&cIndex=&HdrData=&DetData=

*/
  --common >>
  declare @BrCode char(6);
  declare @t_ltime char(25);
  declare @d_ldate char(20);
  declare @ColSep char(6);
  declare @RowSep char(6);
  declare @Pos integer;
  declare @ColPos integer;
  declare @RowPos integer;
  declare @ColMaxLen numeric(4);
  declare @RowMaxLen numeric(4);
  --common <<
  declare @TranBrCode char(6);
  declare @TranPrefix char(4);
  declare @TranYear char(2);
  declare @TranSrno numeric(6);
  declare @DocNo char(25);
  if @devID = '' or @devID is null then
    set @gsBr = "http_variable"('gsBr'); --1
    set @devID = "http_variable"('devID'); --2
    set @sKey = "http_variable"('sKey'); --3
    set @UserId = "http_variable"('UserId'); --4
    set @PhaseCode = "http_variable"('PhaseCode'); --5		
    set @cIndex = "http_variable"('cIndex'); --6
    set @HdrData = "http_variable"('HdrData'); --7
    set @DetData = "http_variable"('DetData') --8
  end if;
  if @PhaseCode <> 'PH0002' then
    return
  end if;
  select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
  select "c_delim" into @RowSep from "ps_tab_delimiter" where "n_seq" = 1;
  --    set @BrCode = uf_get_br_code();	
  set @ColMaxLen = "Length"(@ColSep);
  set @RowMaxLen = "Length"(@RowSep);
  --devid
  set @BrCode = "uf_get_br_code"(@gsBr);
  set @t_ltime = "left"("now"(),19);
  set @d_ldate = "uf_default_date"();
  if @cIndex = 'get_trays' then
    --http://192.168.7.12:13000/ws_st_print_barcode?devID=devID&sKey=KEY&UserId=MYBOSS&cIndex=get_trays&HdrData=&DetData=
    select distinct "a"."c_tray_code"+'['+"c"."c_name"+']' as "c_doc_no",
      "a"."c_doc_no" as "c_ref_no"
      from "st_track_pick" as "a"
        join "st_track_mst" as "b" on "a"."c_doc_no" = "b"."c_doc_no" and "a"."n_inout" = "b"."n_inout"
        join "st_tray_mst" as "c" on "c"."c_code" = "a"."c_tray_code"
      where "b"."c_phase_code" = 'PH0002' for xml raw,elements
  elseif @cIndex = 'get_trans' then
    --http://192.168.7.12:13000/ws_st_print_barcode?devID=devID&sKey=KEY&UserId=MYBOSS&cIndex=get_trans&HdrData=&DetData=
    select "c_doc_no" as "c_doc_no",
      "c_doc_no" as "c_ref_no"
      from "st_track_mst"
      where "c_phase_code" = 'PH0002' for xml raw,elements
  elseif @cIndex = 'get_items' then
    --http://192.168.7.12:14003/ws_st_print_barcode?&gsBr=003&devID=DEVID&sKEY=KEY&UserId=MYBOSS&PhaseCode=PH0002&RackGrpcode=&StageCode=&cindex=get_items&Hdrdata=003**14**S**1**__&DetData=?
    --accept tray no selection 
    --HdrData
    --1 Tranbrcode~2 TranYear~3 TranPrefix~4 TranSrno
    --1 Tranbrcode
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @Tranbrcode = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --message 'Tranbrcode '+@Tranbrcode type warning to client;
    --2 TranYear
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranYear = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --message 'TranYear '+@TranYear type warning to client;	
    --3 TranPrefix
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranPrefix = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --message 'TranPrefix '+@TranPrefix type warning to client;	
    --4 TranSrno
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @TranSrno = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --message 'TranSrno '+string(@TranSrno ) type warning to client;			
    set @DocNo = @Tranbrcode+'/'+@TranYear+'/'+@TranPrefix+'/'+"string"(@TranSrno);
    --message @DocNo type warning to client;
    select "item_mst"."c_code" as "c_item_code",
      "item_mst"."c_name" as "c_item_name",
      "pack_mst"."c_name" as "c_pack_name",
      "rack_mst"."c_name" as "c_rack_name",
      "stock"."c_batch_no" as "c_batch_no",
      "stock_mst"."d_exp_dt" as "d_exp_dt",
      "st_track_pick"."n_qty" as "n_qty",
      "stock_mst"."n_mrp" as "n_mrp",
      "item_mst"."n_self_barcode_req" as "n_print_barcode" --if this item is barcode-print enabled
      --	,stock_mst.n_sale_rate as n_sale_rate			
      from "st_track_pick"
        join "item_mst" on "st_track_pick"."c_item_code" = "item_mst"."c_code"
        join "rack_mst" on "rack_mst"."c_code" = "st_track_pick"."c_rack"
        join "stock" on "stock"."c_item_code" = "st_track_pick"."c_item_code"
        and "stock"."c_batch_no" = "st_track_pick"."c_batch_no"
        and "stock"."c_br_code" = @BrCode
        ,"stock"
        join "stock_mst" on "stock"."c_item_code" = "stock_mst"."c_item_code"
        and "stock"."c_batch_no" = "stock_mst"."c_batch_no"
        ,"item_mst" join "pack_mst" on "pack_mst"."c_code" = "item_mst"."c_pack_code"
      where "st_track_pick"."c_doc_no" = @DocNo for xml raw,elements
  end if
end;