CREATE PROCEDURE "DBA"."usp_st_store_in_assignment_traywise"()
result( "is_xml_string" xml ) 
begin
  /*
Author 		: Saneesh C G
Procedure	: usp_st_store_in_assignment_traywise
SERVICE		: ws_st_store_in_assignment_traywise
Date 		: 
Modified By : Saneesh C G 
Ldate 		: 19-12-2016
Purpose		: 
Input		: 32767
Note		:
*/
  declare @cIndex char(100);
  declare @TrayCode char(6);
  declare @old_TrayCode char(6);
  declare "i" bigint;
  declare @lDate char(30);
  declare @lTime char(30);
  declare @RackGrpCode char(6);
  declare @RackCode char(6);
  declare @stagecode char(6);
  declare @HdrData char(32767);
  declare @DetData char(32767);
  declare @picked_qty numeric(11,3);
  declare @tot_qty numeric(11,3);
  --tray_full>>
  declare @gsBr char(6);
  declare @UserId char(20);
  declare @IpAdd char(40);
  declare @devName char(200);
  --tray_full<<
  --assign_tray>>
  declare @ColSep char(6);
  declare @RowSep char(6);
  declare @GodownCode char(6);
  declare @s_exp_godown_code char(6);
  declare @Pos integer;
  declare @ColPos integer;
  declare @RowPos integer;
  declare @ColMaxLen numeric(4);
  declare @RowMaxLen numeric(4);
  --common <<
  --change_tray>>
  --Validate_tray>>
  declare @li_ext_tray_cnt numeric(6);
  declare @li_temp_tray_cnt numeric(6);
  declare @ls_doc_no char(25);
  declare @s_docno char(25);
  declare @li_seq numeric(9);
  declare @Traytype numeric(6);
  declare @Validate_Tray_With_Color numeric(6);
  declare @BrCode char(6);
  declare @n_gate_pass_no numeric(9);
  declare @n_tray_count_in_tray_move numeric(9);
  declare @c_doc_no_in_tray_move char(50);
  --Validate_tray<<
  declare @qpb integer;
  set @lDate = "uf_default_date"();
  set @lTime = "now"();
  set @cIndex = "HTTP_VARIABLE"('cIndex');
  set @TrayCode = "HTTP_VARIABLE"('TrayCode');
  set @gsBr = "HTTP_VARIABLE"('gsBr');
  set @UserId = "HTTP_VARIABLE"('UserId');
  set @IpAdd = "HTTP_VARIABLE"('IpAdd');
  set @devName = "HTTP_VARIABLE"('devName');
  set @RackGrpCode = "HTTP_VARIABLE"('RackGrpCode');
  set @HdrData = "HTTP_VARIABLE"('HdrData');
  set @DetData = "HTTP_VARIABLE"('DetData');
  --print @RackGrpCode ;
  set @BrCode = "uf_get_br_code"(@gsBr);
  set @GodownCode = "HTTP_VARIABLE"('GodownCode');
  select "max"("c_godown_code") into @s_exp_godown_code from "storein_setup" where "c_br_code" = @BrCode;
  select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
  select "c_delim" into @RowSep from "ps_tab_delimiter" where "n_seq" = 1;
  set @ColMaxLen = "Length"(@ColSep);
  set @RowMaxLen = "Length"(@RowSep);
  case @cIndex
  when 'Get_Item' then
    --HdrData-->Barcode 
    if @HdrData is null or "ltrim"("rtrim"(@HdrData)) = '' then
      select 'Warning!! ,Barcode Can not be null or Empty !' as "c_message" for xml raw,elements;
      return
    end if;
    select "st_track_in"."c_item_code",
      "item_mst"."c_name"+"uf_st_get_pack_name"("pack_mst"."c_name") as "c_item_name",
      "item_mst"."n_qty_per_box" as "n_qty_per_box",
      "st_track_in"."c_batch_no",
      "st_track_in"."c_doc_no",
      "st_track_in"."n_seq",
      cast(("st_track_in"."n_qty"-"isnull"("st_track_in"."n_send_qty",0)) as numeric(11)) as "n_qty",
      "st_track_in"."c_tray_code",
      "st_track_in"."n_complete",
      "st_track_in"."c_godown_code",
      "st_track_in"."c_user",
      (if "isnull"("st_track_in"."c_godown_code",'-') = '-' then "item_mst_br_info"."c_rack" else "item_mst_br_info_godown"."c_rack" endif) as "c_rk_code",
      "rack_group_mst"."c_code" as "c_rack_grp_code",
      (select "max"("c_stage_code") from "st_store_stage_det" where "c_rack_grp_code" = "st_track_in"."c_rack_grp_code") as "stage_code",
      "stock_mst"."d_exp_dt",
      "stock_mst"."n_mrp",
      "st_track_tray_move"."c_tray_code"
      from "st_track_in" join "barcode_det" on "st_track_in"."c_item_code" = "barcode_det"."c_item_code"
        and "st_track_in"."c_batch_no" = "barcode_det"."c_batch_no"
        left outer join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = ("left"("st_track_in"."c_doc_no","locate"("st_track_in"."c_doc_no",'/')-1))
        and "item_mst_br_info"."c_code" = "st_track_in"."c_item_code"
        left outer join "item_mst_br_info_godown" on "item_mst_br_info_godown"."c_br_code" = ("left"("st_track_in"."c_doc_no","locate"("st_track_in"."c_doc_no",'/')-1))
        and "item_mst_br_info_godown"."c_code" = "st_track_in"."c_item_code"
        and "item_mst_br_info_godown"."c_godown_code" = "isnull"("st_track_in"."c_godown_code",'-')
        left outer join "rack_mst" on "rack_mst"."c_br_code" = "left"("st_track_in"."c_doc_no",3)
        and "rack_mst"."c_code" = "c_rk_code"
        left outer join "rack_group_mst" on "rack_mst"."c_br_code" = "rack_group_mst"."c_br_code"
        and "rack_mst"."c_rack_grp_code" = "rack_group_mst"."c_code"
        join "item_mst" on "st_track_in"."c_item_code" = "item_mst"."c_code"
        join "pack_mst" on "pack_mst"."c_code" = "item_mst"."c_pack_code"
        join "stock_mst" on "st_track_in"."c_item_code" = "stock_mst"."c_item_code" and "st_track_in"."c_batch_no" = "stock_mst"."c_batch_no"
        join(select "c_br_code","c_year","c_prefix","n_srno","c_bill_no","n_gate_pass_no" from "pur_mst" where "n_post" = 1 union
        select "c_br_code","c_year","c_prefix","n_srno","string"("n_ref_srno"),0 as "n_gate_pass_no" from "grn_mst" where "n_post" = 1 union
        select "c_br_code","c_year","c_prefix","n_srno","c_ref_no",0 as "n_gate_pass_no" from "crnt_mst" union
        select "c_br_code","c_year","c_prefix","n_srno",'',0 as "n_gate_pass_no" from "godown_tran_mst" where "godown_tran_mst"."n_approved" = 1 union
        select "c_br_code","c_year","c_prefix","n_srno",'' as "c_ref_no",0 as "n_gate_pass_no" from "dbnt_mst" where "dbnt_mst"."n_approved" = 1) as "trans"
        // old condition
        //   on "trans"."c_br_code"+'/'+"trans"."c_year"+'/'+"trans"."c_prefix"+'/'+"string"("trans"."n_srno") = "st_track_in"."c_doc_no"
        // added new condition
        on "trans"."c_br_code" = ("left"(("st_track_in"."c_doc_no"),"charindex"('/',("st_track_in"."c_doc_no"))-1))
        and "trans"."c_year" = ("left"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),
        "charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),
        "charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),
        "charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))-1))
        and "trans"."c_year" = ("left"("substr"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),
        "charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),
        "charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),
        "charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))+1),
        "charindex"('/',"substr"("substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),
        "charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1),
        "charindex"('/',"substring"("left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))),
        "charindex"('/',"left"("st_track_in"."c_doc_no",("length"("st_track_in"."c_doc_no")-("charindex"('/',"reverse"("st_track_in"."c_doc_no"))-1))))+1))+1))-1))
        and "string"("trans"."n_srno") = ("reverse"("left"("reverse"("st_track_in"."c_doc_no"),"charindex"('/',("reverse"("st_track_in"."c_doc_no")))-1)))
        left outer join "st_track_tray_move" on "st_track_tray_move"."c_godown_code" = "st_track_in"."c_godown_code"
        and "st_track_tray_move"."c_rack_grp_code" = "rack_group_mst"."c_code"
        and "st_track_tray_move"."c_stage_code" = "stage_code"
        and "st_track_tray_move"."c_doc_no" = '999999999999'
        and "st_track_tray_move"."n_inout" = 1
      where "barcode_det"."c_key" = @HdrData and "n_complete" <> 9 and "n_qty" > 0 for xml raw,elements
  when 'Validate_Tray' then
    --@DetData -- 1Rack code ~~2Rack grp code ~~3stage_code ~~
    --@HdrData --1Doc no~~2- seq
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @RackCode = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @RackGrpCode = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @stagecode = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @s_docno = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @li_seq = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    if @RackGrpCode is null or "trim"(@RackGrpCode) = '' then
      select 'Warning! : Rack Group Code Can not be null ,Relogin Once !!' as "c_message" for xml raw,elements;
      return
    end if;
    select "COUNT"() into @li_ext_tray_cnt from "st_tray_mst" where "c_code" = @TrayCode;
    if @li_ext_tray_cnt = 0 then
      select 'Warning! : Tray '+@TrayCode+' is not a Valid Tray !.' as "c_message" for xml raw,elements;
      return
    end if;
    set @li_ext_tray_cnt = 0;
    select "COUNT"() into @li_ext_tray_cnt from "st_tray_mst" where "c_code" = @TrayCode and "n_in_out_flag" = 0;
    select "COUNT"() into @li_temp_tray_cnt from "st_tray_mst" where "c_code" = @TrayCode and "n_in_out_flag" = 3;
    if @li_ext_tray_cnt > 0 then
      select 'Warning! : Tray '+@TrayCode+' is an external Tray code.' as "c_message" for xml raw,elements;
      return
    end if;
    set @n_tray_count_in_tray_move = 0;
    select "max"("c_doc_no"),"COUNT"() into @c_doc_no_in_tray_move,@n_tray_count_in_tray_move
      from "st_track_tray_move" where "c_tray_code" = @TrayCode and "c_doc_no" <> '999999999999';
    if @n_tray_count_in_tray_move is null then
      set @n_tray_count_in_tray_move = 0
    end if;
    if @n_tray_count_in_tray_move > 0 then
      select 'Warning! : Tray Code '+@TrayCode+' is already used for Document '+@c_doc_no_in_tray_move+' !!.' as "c_message" for xml raw,elements;
      return
    end if;
    set @n_tray_count_in_tray_move = 0;
    set @c_doc_no_in_tray_move = '';
    select "max"("c_rack_grp_code"),"COUNT"() into @c_doc_no_in_tray_move,@n_tray_count_in_tray_move
      from "st_track_tray_move" where "c_tray_code" = @TrayCode and "c_rack_grp_code" <> @RackGrpCode;
    if @n_tray_count_in_tray_move is null or "trim"(@n_tray_count_in_tray_move) = '' then
      set @n_tray_count_in_tray_move = 0
    end if;
    if @n_tray_count_in_tray_move > 0 then
      select 'Warning! : Tray Code '+@TrayCode+' is already used for another rack group '+@c_doc_no_in_tray_move+' !!' as "c_message" for xml raw,elements;
      return
    end if;
    select top 1 "c_doc_no"
      into @ls_doc_no from "st_track_det" where "c_tray_code" = @TrayCode and "n_complete" not in( 9,8,2 ) ;
    if @ls_doc_no is null or "ltrim"("rtrim"(@ls_doc_no)) = '' then --Store out
    else
      select 'Warning! : Tray '+@TrayCode+' in use for Document  .'+@ls_doc_no+'' as "c_message" for xml raw,elements;
      return
    end if;
    select top 1 "c_tray_code" into @old_TrayCode from "st_track_tray_move"
      where "c_doc_no" = '999999999999'
      and "n_inout" = 1
      and "c_rack_grp_code" = @RackGrpCode
      and "c_stage_code" = @stagecode;
    insert into "DBA"."st_track_tray_move"
      ( "c_doc_no","n_inout","c_tray_code","c_rack_grp_code","c_stage_code","t_time","c_user","n_flag","c_godown_code","c_user_2","n_eb",
      "n_tray_flag" ) on existing update defaults off values
      ( '999999999999',1,@TrayCode,@RackGrpCode,@stagecode,"Now"(),@UserId,0,@GodownCode,null,0,0 ) ;
    if @old_TrayCode is null or "trim"(@old_TrayCode) = '' then
    else
      if @old_TrayCode <> @TrayCode then
        --Call send Tray FOr Old Tray 
        call "uf_st_generate_indoc"(@old_TrayCode,@gsBr,@UserId,@IpAdd,@devName);
        delete from "st_track_tray_move"
          where "c_doc_no" = '999999999999'
          and "n_inout" = 1
          and "c_tray_code" <> @TrayCode
          and "c_rack_grp_code" = @RackGrpCode
          and "c_stage_code" = @stagecode;
        --sani to update login_time
        call "uf_update_login_time"(@BrCode,@devName,@UserId,'-','','-',0)
      end if end if;
    select 'SUCCESS' as "c_message" for xml raw,elements
  when 'Get_Traylist' then
    select distinct "c_tray_code" as "c_tray_code",
      "c_rack_grp_code"
      from "st_track_tray_move"
      where "c_doc_no" = '999999999999' and "c_godown_code" = @GodownCode
      and "st_track_tray_move"."n_inout" = 1 for xml raw,elements;
    return
  when 'Itemdone' then
    --@HdrData --1Doc no~~2- seq	~~3- picked_qty 
    --@TrayCode = traycode
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @s_docno = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @li_seq = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @picked_qty = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    select "n_qty"-"n_send_qty"
      into @tot_qty from "st_track_in"
      where "c_doc_no"+'/'+"string"("n_seq") = @s_docno+'/'+"string"(@li_seq)
      and "c_godown_code" = @GodownCode;
    if @tot_qty < @picked_qty then
      select 'Qty VALIDATION, Qty Should not exceed  '+"string"(@picked_qty)+'Check The Entered qty !! ' as "c_message" for xml raw,elements;
      return
    end if;
    update "st_track_in"
      set "c_tray_code" = @TrayCode,
      "c_user" = @UserId,
      "t_time" = "now"(),
      "n_confirm" = 1,
      "n_send_qty" = "n_send_qty"+@picked_qty
      where "c_doc_no"+'/'+"string"("n_seq") = @s_docno+'/'+"string"(@li_seq)
      and "c_godown_code" = @GodownCode;
    if sqlstate = '00000' then
      commit work;
      select 'SUCCESS' as "c_message" for xml raw,elements;
      return
    else
      rollback work;
      select 'Warning!! ,Error On Tray code Assignment ' as "c_message" for xml raw,elements
    end if else
    select 'YOU HAVE NO BUSINESS HERE' as "c_message" for xml raw,elements
  end case
end;