CREATE PROCEDURE "DBA"."usp_st_stock_audit"( 
  in @gsBr char(6),
  in @devID char(200),
  in @sKey char(20),
  in @UserId char(20),
  in @PhaseCode char(6),
  in @StageCode char(6),
  in @RackGrpCode char(300),
  in @cIndex char(30),
  in @HdrData char(32767),
  in @DetData char(32767),
  in @GodownCode char(6) ) 
result( 
  "is_xml_string" xml ) 
begin
  /*
Author 		: Saneesh
Procedure	: usp_st_stock_audit
SERVICE		: ws_usp_st_stock_audit
Date 		: 
Modified By : Saneesh C G 
Ldate 		: 18-05-2016
Purpose		: 
Input		: 
Note		:
*/
  --common >>
  declare @BrCode char(6);
  declare @t_ltime char(25);
  declare @t_preserve_ltime char(25);
  declare @d_ldate char(20);
  declare @nUserValid integer;
  declare @RackGrpList char(7000);
  declare @ColSep char(6);
  declare @RowSep char(6);
  declare @Pos integer;
  declare @ColPos integer;
  declare @RowPos integer;
  declare @ColMaxLen numeric(4);
  declare @RowMaxLen numeric(4);
  declare @tmp char(6);
  --common <<
  -->>submit_data
  declare @c_item_code char(6);
  declare @c_batch_no char(25);
  declare @c_confirm_user char(25);
  declare @d_exp_date date;
  declare @n_mrp numeric(12,3);
  declare @n_qty numeric(12,3);
  declare @n_adj_qty numeric(12,3);
  declare @n_stock_on_hand numeric(12,3);
  declare @n_stock_on_hand_p numeric(12,3);
  declare @n_stock_on_hand_L numeric(12,3);
  declare @n_qtp numeric(12,3);
  declare @n_l_remainder numeric(12,3);
  declare @n_flag numeric(1);
  --submit_data<<-
  declare @n_item_count numeric(9);
  declare @n_audit_item_count numeric(9);
  declare @n_err numeric(2);
  declare @n_audited numeric(2);
  declare @c_val char(20);
  declare @login_user char(20);
  declare @Para_val_code char(10);
  declare @Para_win_code char(10);
  declare @s_return char(100);
  declare @c_rack char(6);
  declare @Stage_code char(6);
  declare @str "text";
  declare @User_remark char(75);
  declare local temporary table "temp_rack_grp_list"(
    "c_rack_grp_code" char(6) null,) on commit preserve rows;
  --Set values
  if @devID = '' or @devID is null then
    set @gsBr = "http_variable"('gsBr'); --1
    set @devID = "http_variable"('devID'); --2
    set @sKey = "http_variable"('sKey'); --3
    set @UserId = "http_variable"('UserId'); --4
    set @PhaseCode = "http_variable"('PhaseCode'); --5		
    set @RackGrpCode = "http_variable"('RackGrpCode'); --6	
    set @StageCode = "http_variable"('StageCode'); --7
    set @cIndex = "http_variable"('cIndex'); --8
    set @HdrData = "http_variable"('HdrData'); --9
    set @DetData = "http_variable"('DetData'); --10
    set @GodownCode = "http_variable"('GodownCode') --11		
  end if;
  select "c_delim" into @ColSep from "ps_tab_delimiter" where "n_seq" = 0;
  select "c_delim" into @RowSep from "ps_tab_delimiter" where "n_seq" = 1;
  set @ColMaxLen = "Length"(@ColSep);
  set @RowMaxLen = "Length"(@RowSep);
  set @BrCode = "uf_get_br_code"(@gsBr);
  set @t_ltime = "left"("now"(),19);
  set @d_ldate = "uf_default_date"();
  set @n_err = 0;
  case @cIndex
  when 'Get_setup' then
    --http://192.168.7.12:16503/ws_st_stock_audit?&cIndex=Get_setup&UserId=lawrence
    --sani 
    set @Para_val_code = 'P00075';
    set @Para_win_code = 'W00056';
    select "uf_get_para_value"(@BrCode,@UserId,@Para_val_code,@Para_win_code) as "c_val" for xml raw,elements
  when 'Get_rack' then
    --http://192.168.7.12:16503/ws_st_stock_audit?&cIndex=Get_rack&RackGrpCode=P11A^^
    set @RackGrpList = @RackGrpCode;
    while @RackGrpList <> '' loop
      --1 RackGrpList
      select "Locate"(@RackGrpList,@ColSep) into @ColPos;
      set @tmp = "Trim"("Left"(@RackGrpList,@ColPos-1));
      set @RackGrpList = "SubString"(@RackGrpList,@ColPos+@ColMaxLen);
      --message 'RackGrpList '+@tmp type warning to client;			
      if(select "COUNT"("C_CODE") from "RACK_GROUP_MST" where "n_lock" = 0 and "C_CODE" = @tmp) > 0 then --valid rack group selection 				
        insert into "temp_rack_grp_list"( "c_rack_grp_code" ) values( @tmp ) 
      end if
    end loop;
    if @GodownCode = '-' then
      select "rack_mst"."c_code",
        "st_track_stock_audit"."d_ldate" as "last_audit_date",
        "st_track_stock_audit"."c_user" as "last_audited_user",
        "isnull"("count"("item_mst_br_info"."c_code"),0) as "n_item_count",
        "isnull"("st_track_stock_audit"."n_audit_item_count",0) as "n_audit_item_count",
        if "n_item_count" <= "n_audit_item_count" then
          1
        else
          0
        endif as "n_audit"
        from "rack_mst"
          --(select 'G55A'as c_rack_grp_code )
          join "temp_rack_grp_list" on "temp_rack_grp_list"."c_rack_grp_code" = "rack_mst"."c_rack_grp_code"
          left outer join "st_track_stock_audit" on "st_track_stock_audit"."c_rack" = "rack_mst"."c_code"
          and "st_track_stock_audit"."c_br_code" = "rack_mst"."c_br_code"
          left outer join "item_mst_br_info" on "item_mst_br_info"."c_br_code" = "rack_mst"."c_br_code"
          and "item_mst_br_info"."c_br_code" = @BrCode
          and "item_mst_br_info"."c_rack" = "rack_mst"."c_code"
        where "n_lock" = 0
        group by "rack_mst"."c_code","last_audit_date","last_audited_user","n_audit_item_count"
        order by "n_audit" asc,"last_audit_date" asc,"rack_mst"."c_code" asc for xml raw,elements
    else
      select "rack_mst"."c_code",
        "st_track_stock_audit"."d_ldate" as "last_audit_date",
        "st_track_stock_audit"."c_user" as "last_audited_user",
        "isnull"("count"("item_mst_br_info_godown"."c_code"),0) as "n_item_count",
        "isnull"("st_track_stock_audit"."n_audit_item_count",0) as "n_audit_item_count",
        if "n_item_count" <= "n_audit_item_count" then
          1
        else
          0
        endif as "n_audit"
        from "rack_mst"
          --(select 'G55A'as c_rack_grp_code )
          join "temp_rack_grp_list" on "temp_rack_grp_list"."c_rack_grp_code" = "rack_mst"."c_rack_grp_code"
          left outer join "st_track_stock_audit" on "st_track_stock_audit"."c_rack" = "rack_mst"."c_code"
          left outer join "item_mst_br_info_godown" on "item_mst_br_info_godown"."c_br_code" = @BrCode
          and "item_mst_br_info_godown"."c_rack" = "rack_mst"."c_code"
          and "item_mst_br_info_godown"."c_godown_code" = @GodownCode
        where "n_lock" = 0
        group by "rack_mst"."c_code","last_audit_date","last_audited_user","n_audit_item_count"
        order by "n_audit" asc,"last_audit_date" asc,"rack_mst"."c_code" asc for xml raw,elements
    end if when 'Get_item' then
    --http://192.168.7.12:16503/ws_st_stock_audit?&cIndex=Get_item&HdrData=18126&GodownCode=-	
    if @GodownCode = '-' then
      select "item_mst"."c_code",
        "item_mst"."c_name",
        "pack_mst"."c_name" as "pack",
        "mfac_mst"."c_name" as "mfac",
        "isnull"((select "sum"(if "isnull"("isnull"("s"."n_bal_qty",0)-"isnull"("s"."n_hold_qty",0),0)
          -"isnull"((select "sum"("g"."n_qty"-"g"."n_hold_qty") from "stock_godown" as "g"
            where "s"."c_item_code" = "g"."c_item_code" and "s"."c_batch_no" = "g"."c_batch_no"
            and "s"."c_br_code" = "g"."c_br_code"),0) > 0 then 1 else 0 endif)
          from "stock" as "s"
          where "s"."c_item_code" = "item_mst"."c_code"),0) as "stk_cnt",
        (select "count"() from "st_track_stock_audit_temp" where "st_track_stock_audit_temp"."c_item_code" = "item_mst"."c_code" and "st_track_stock_audit_temp"."c_br_code" = @BrCode) as "audit_cnt",
        if "stk_cnt" = 0 then
          2 --no batch 
        else
          if "stk_cnt" <= "audit_cnt" then
            1
          else
            if "audit_cnt" <> 0 then
              3
            else
              0
            endif
          endif
        endif as "n_audited",
        "item_mst"."n_qty_per_box",
        if "item_mst"."n_self_barcode_req" = 2 then
          "item_mst"."c_barcode"
          +"isnull"(
          (select ','+"list"("trim"("item_multi_barcode_det"."c_barcode"))
            from "item_multi_barcode_det"
            where "item_multi_barcode_det"."c_item_code" = "item_mst"."c_code"),
          '')
        else
          ''
        endif as "c_key"
        from "item_mst"
          join "pack_mst" on "pack_mst"."c_code" = "item_mst"."c_pack_code"
          join "mfac_mst" on "mfac_mst"."c_code" = "item_mst"."c_mfac_code"
          left outer join "item_mst_br_info" on "item_mst"."c_code" = "item_mst_br_info"."c_code"
        where "item_mst_br_info"."c_br_code" = @BrCode
        and "item_mst_br_info"."c_rack" = @HdrData
        --and n_audited <> 2 
        order by "n_audited" asc,"item_mst"."c_name" asc for xml raw,elements
    else
      select "item_mst"."c_code",
        "item_mst"."c_name",
        "pack_mst"."c_name" as "pack",
        "mfac_mst"."c_name" as "mfac",
        (select "count"() from "stock_godown" where "stock_godown"."c_item_code" = "item_mst"."c_code" and "stock_godown"."c_br_code" = @BrCode and "n_qty"-"n_hold_qty" > 0 and "c_godown_code" = @GodownCode) as "stk_cnt",
        (select "count"() from "st_track_stock_audit_temp" where "st_track_stock_audit_temp"."c_item_code" = "item_mst"."c_code" and "st_track_stock_audit_temp"."c_br_code" = @BrCode) as "audit_cnt",
        if "stk_cnt" = 0 then
          2 --no batch 
        else
          if "stk_cnt" <= "audit_cnt" then
            1
          else
            if "audit_cnt" <> 0 then
              3
            else
              0
            endif
          endif
        endif as "n_audited",
        "item_mst"."n_qty_per_box",
        if "item_mst"."n_self_barcode_req" = 2 then
          "item_mst"."c_barcode"
          +"isnull"(
          (select ','+"list"("trim"("item_multi_barcode_det"."c_barcode"))
            from "item_multi_barcode_det"
            where "item_multi_barcode_det"."c_item_code" = "item_mst"."c_code"),
          '')
        else
          ''
        endif as "c_key"
        from "item_mst"
          join "pack_mst" on "pack_mst"."c_code" = "item_mst"."c_pack_code"
          join "mfac_mst" on "mfac_mst"."c_code" = "item_mst"."c_mfac_code"
          left outer join "item_mst_br_info_godown" on "item_mst"."c_code" = "item_mst_br_info_godown"."c_code"
        where "item_mst_br_info_godown"."c_br_code" = @BrCode and "item_mst_br_info_godown"."c_godown_code" = @GodownCode
        and "item_mst_br_info_godown"."c_rack" = @HdrData
        and "item_mst_br_info_godown"."c_godown_code" = @GodownCode
        --and n_audited <> 2 
        order by "n_audited" asc,"item_mst"."c_name" asc for xml raw,elements
    end if when 'Get_single_item' then
    --http://192.168.7.12:16503/ws_st_stock_audit?&cIndex=Get_single_item&HdrData=320128&GodownCode=-	
    --HdrData -- itemcode 
    select "item_mst"."c_code",
      "item_mst"."c_name",
      "pack_mst"."c_name" as "pack",
      "mfac_mst"."c_name" as "mfac",
      (select "count"() from "stock" where "stock"."c_item_code" = "item_mst"."c_code" and "stock"."c_br_code" = @BrCode and "n_bal_qty"-"n_dc_inv_qty"-"n_hold_qty" > 0) as "stk_cnt",
      (select "count"() from "st_track_stock_audit_temp" where "st_track_stock_audit_temp"."c_item_code" = "item_mst"."c_code" and "st_track_stock_audit_temp"."c_br_code" = @BrCode) as "audit_cnt",
      if "stk_cnt" = 0 then
        2 --no batch 
      else
        if "stk_cnt" <= "audit_cnt" then
          1
        else
          0
        endif
      endif as "n_audited",
      "item_mst"."n_qty_per_box"
      from "item_mst"
        join "pack_mst" on "pack_mst"."c_code" = "item_mst"."c_pack_code"
        join "mfac_mst" on "mfac_mst"."c_code" = "item_mst"."c_mfac_code"
      where "n_audited" <> 2 and "item_mst"."c_code" = @HdrData
      order by "n_audited" asc,"item_mst"."c_name" asc for xml raw,elements
  when 'Get_batch' then
    --http://192.168.7.12:16503/ws_st_stock_audit?&cIndex=Get_batch&HdrData=320128&GodownCode=-
    if @GodownCode = '-' then
      select "stock"."c_item_code",
        "stock"."c_batch_no",
        cast("isnull"(("stock"."n_bal_qty"-"stock"."n_hold_qty"),0)
        -"isnull"("stock_godown"."n_qty",0) as numeric(11)) as "n_bal_qty",
        "stock_mst"."d_exp_dt",
        cast("stock_mst"."n_mrp"*"item_mst"."n_qty_per_box" as numeric(11,2)) as "n_mrp",
        "isnull"(cast("st_track_stock_audit_temp"."n_stock_on_hand" as numeric(11)),0) as "n_stock_on_hand",
        cast(("n_stock_on_hand"/"item_mst"."n_qty_per_box") as numeric(11)) as "n_stock_on_hand_P",
        cast(("n_stock_on_hand"-("n_stock_on_hand_P"*"item_mst"."n_qty_per_box")) as numeric(11)) as "n_stock_on_hand_L",
        "item_mst"."n_qty_per_box",
        "item_mst_br_info"."c_rack",
        "isnull"("st_track_stock_audit_temp"."n_audited",0) as "n_audited"
        from "stock"
          join "stock_mst" on "stock_mst"."c_item_code" = "stock"."c_item_code" and "stock_mst"."c_batch_no" = "stock"."c_batch_no"
          join "Item_mst" on "item_mst"."c_code" = "stock"."c_item_code"
          left outer join "item_mst_br_info" on "item_mst_br_info"."c_code" = "stock"."c_item_Code"
          and "item_mst_br_info"."c_br_Code" = "stock"."c_br_code"
          left outer join(select "c_item_code","c_batch_no","c_br_Code","sum"("n_qty"-"n_hold_qty") as "n_qty" from "stock_godown" group by "c_item_code","c_batch_no","c_br_Code") as "stock_godown"
          on "stock_godown"."c_br_code" = "stock"."c_br_code"
          and "stock_godown"."c_item_code" = "stock"."c_item_code"
          and "stock_godown"."c_batch_no" = "stock"."c_batch_no"
          --and stock_godown.c_godown_code = @GodownCode 
          left outer join "st_track_stock_audit_temp" on "st_track_stock_audit_temp"."c_br_code" = "stock"."c_br_code"
          and "st_track_stock_audit_temp"."c_item_code" = "stock"."c_item_code"
          and "st_track_stock_audit_temp"."c_batch_no" = "stock"."c_batch_no"
          and "st_track_stock_audit_temp"."c_user" = @UserId
        where "stock"."c_br_code" = @BrCode
        and "stock"."c_item_code" = @HdrData
        and "n_bal_qty" > 0
        and "stock_mst"."n_permanent_lock" = 0 union
      select "st_track_stock_audit_temp"."c_item_code",
        "st_track_stock_audit_temp"."c_batch_no",
        cast("st_track_stock_audit_temp"."n_qty" as numeric(11)) as "n_bal_qty",
        "st_track_stock_audit_temp"."d_exp_date",
        "st_track_stock_audit_temp"."n_mrp",
        "isnull"(cast("st_track_stock_audit_temp"."n_stock_on_hand" as numeric(11)),0) as "n_stock_on_hand",
        cast(("n_stock_on_hand"/"item_mst"."n_qty_per_box") as numeric(11)) as "n_stock_on_hand_P",
        cast(("n_stock_on_hand"-("n_stock_on_hand_P"*"item_mst"."n_qty_per_box")) as numeric(11)) as "n_stock_on_hand_L",
        "item_mst"."n_qty_per_box",
        "item_mst_br_info"."c_rack",
        "isnull"("st_track_stock_audit_temp"."n_audited",0) as "n_audited"
        from "st_track_stock_audit_temp" join "item_mst" on "item_mst"."c_code" = "st_track_stock_audit_temp"."c_item_code"
          left outer join "item_mst_br_info" on "item_mst_br_info"."c_code" = "st_track_stock_audit_temp"."c_item_code"
          and "item_mst_br_info"."c_br_Code" = "st_track_stock_audit_temp"."c_br_code"
        where "st_track_stock_audit_temp"."c_br_code" = @BrCode
        and "st_track_stock_audit_temp"."c_item_code" = @HdrData
        and "n_flag" = 1
        order by "n_bal_qty" desc for xml raw,elements
    else
      select "stock_godown"."c_item_code",
        "stock_godown"."c_batch_no",
        cast("isnull"("stock_godown"."n_qty"-"stock_godown"."n_hold_qty",0) as numeric(11)) as "n_bal_qty",
        "stock_mst"."d_exp_dt",
        cast("stock_mst"."n_mrp"*"item_mst"."n_qty_per_box" as numeric(11,2)) as "n_mrp",
        "isnull"(cast("st_track_stock_audit_temp"."n_stock_on_hand" as numeric(11)),0) as "n_stock_on_hand",
        cast(("n_stock_on_hand"/"item_mst"."n_qty_per_box") as numeric(11)) as "n_stock_on_hand_P",
        cast(("n_stock_on_hand"-("n_stock_on_hand_P"*"item_mst"."n_qty_per_box")) as numeric(11)) as "n_stock_on_hand_L",
        "item_mst"."n_qty_per_box",
        "item_mst_br_info_godown"."c_rack",
        "isnull"("st_track_stock_audit_temp"."n_audited",0) as "n_audited"
        from "stock_godown"
          left outer join "stock" on "stock_godown"."c_br_code" = "stock"."c_br_code"
          and "stock_godown"."c_item_code" = "stock"."c_item_code"
          and "stock_godown"."c_batch_no" = "stock"."c_batch_no"
          left outer join "item_mst_br_info_godown" on "item_mst_br_info_godown"."c_code" = "stock_godown"."c_item_code"
          and "item_mst_br_info_godown"."c_br_Code" = "stock_godown"."c_br_code"
          and "item_mst_br_info_godown"."c_godown_code" = @GodownCode
          join "stock_mst" on "stock_mst"."c_item_code" = "stock_godown"."c_item_code" and "stock_mst"."c_batch_no" = "stock_godown"."c_batch_no"
          join "Item_mst" on "item_mst"."c_code" = "stock_godown"."c_item_code"
          left outer join "st_track_stock_audit_temp" on "st_track_stock_audit_temp"."c_br_code" = "stock_godown"."c_br_code"
          and "st_track_stock_audit_temp"."c_item_code" = "stock_godown"."c_item_code"
          and "st_track_stock_audit_temp"."c_batch_no" = "stock_godown"."c_batch_no"
          and "st_track_stock_audit_temp"."c_user" = @UserId
        where "stock_godown"."c_br_code" = @BrCode and "stock_godown"."c_godown_code" = @GodownCode
        and "stock_godown"."c_item_code" = @HdrData
        and "n_bal_qty" > 0
        and "stock_mst"."n_permanent_lock" = 0 union
      select "st_track_stock_audit_temp"."c_item_code",
        "st_track_stock_audit_temp"."c_batch_no",
        cast("st_track_stock_audit_temp"."n_qty" as numeric(11)) as "n_bal_qty",
        "st_track_stock_audit_temp"."d_exp_date",
        "st_track_stock_audit_temp"."n_mrp",
        "isnull"(cast("st_track_stock_audit_temp"."n_stock_on_hand" as numeric(11)),0) as "n_stock_on_hand",
        cast(("n_stock_on_hand"/"item_mst"."n_qty_per_box") as numeric(11)) as "n_stock_on_hand_P",
        cast(("n_stock_on_hand"-("n_stock_on_hand_P"*"item_mst"."n_qty_per_box")) as numeric(11)) as "n_stock_on_hand_L",
        "item_mst"."n_qty_per_box",
        "item_mst_br_info_godown"."c_rack",
        "isnull"("st_track_stock_audit_temp"."n_audited",0) as "n_audited"
        from "st_track_stock_audit_temp" join "item_mst" on "item_mst"."c_code" = "st_track_stock_audit_temp"."c_item_code"
          left outer join "item_mst_br_info_godown" on "item_mst_br_info_godown"."c_code" = "st_track_stock_audit_temp"."c_item_code"
          and "item_mst_br_info_godown"."c_br_Code" = "st_track_stock_audit_temp"."c_br_code"
        where "st_track_stock_audit_temp"."c_br_code" = @BrCode
        and "st_track_stock_audit_temp"."c_item_code" = @HdrData
        and "n_flag" = 1
        order by "n_bal_qty" desc for xml raw,elements
    end if when 'Get_zero_batch' then
    --http://192.168.7.12:16503/ws_st_stock_audit?&cIndex=Get_zero_batch&HdrData=320128&GodownCode=-
    select "stock_mst"."c_item_code",
      "stock_mst"."c_batch_no",
      cast("isnull"(("stock"."n_bal_qty"),0)-("isnull"("stock_godown"."n_qty",0)) as numeric(11)) as "n_bal_qty",
      "stock_mst"."d_exp_dt",
      cast("stock_mst"."n_mrp" as numeric(11,2)) as "n_mrp",
      "isnull"(cast("st_track_stock_audit_temp"."n_stock_on_hand" as numeric(11)),0) as "n_stock_on_hand",
      cast(("n_stock_on_hand"/"item_mst"."n_qty_per_box") as numeric(11)) as "n_stock_on_hand_P",
      cast(("n_stock_on_hand"-("n_stock_on_hand_P"*"item_mst"."n_qty_per_box")) as numeric(11)) as "n_stock_on_hand_L",
      "item_mst"."n_qty_per_box",
      "item_mst_br_info"."c_rack",
      "isnull"("st_track_stock_audit_temp"."n_audited",0) as "n_audited"
      from "stock_mst"
        left outer join "stock" on "stock_mst"."c_item_code" = "stock"."c_item_code"
        and "stock_mst"."c_batch_no" = "stock"."c_batch_no"
        join "item_mst" on "stock_mst"."c_item_code" = "item_mst"."c_code"
        left outer join "item_mst_br_info" on "item_mst_br_info"."c_code" = "stock"."c_item_code"
        and "item_mst_br_info"."c_br_Code" = "stock"."c_br_code"
        left outer join "st_track_stock_audit_temp" on "st_track_stock_audit_temp"."c_br_code" = "stock"."c_br_code"
        and "st_track_stock_audit_temp"."c_item_code" = "stock"."c_item_code"
        and "st_track_stock_audit_temp"."c_batch_no" = "stock"."c_batch_no"
        and "st_track_stock_audit_temp"."c_user" = @UserId
        left outer join "stock_godown" on "stock_godown"."c_item_code" = "stock_mst"."c_item_code"
        and "stock_godown"."c_batch_no" = "stock_mst"."c_batch_no"
      where "stock_mst"."c_item_code" = @HdrData
      and "n_bal_qty" = 0
      and "stock_mst"."n_permanent_lock" = 0
      order by "stock_mst"."d_exp_dt" desc for xml raw,elements
  when 'submit_data' then
    --@DetData 
    --1 c_item_code 2--c_batch_no,3-- d_exp_date,4--n_mrp,5--n_qty,6--n_stock_on_hand_P,
    --7--n_stock_on_hand_L,8--@c_rack --9 n_flag 10--n_audited sani
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @c_item_code = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --2--c_batch_no
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @c_batch_no = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --3-- d_exp_date
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @d_exp_date = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --4--n_mrp
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @n_mrp = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --5--n_qty
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @n_qty = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --6--n_stock_on_hand_P
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @n_stock_on_hand_P = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --7--n_stock_on_hand_L
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @n_stock_on_hand_L = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --8--@c_rack
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @c_rack = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --9--@n_flag
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @n_flag = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    --10--@n_audited
    select "Locate"(@DetData,@ColSep) into @ColPos;
    set @n_audited = "Trim"("Left"(@DetData,@ColPos-1));
    set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
    select "n_qty_per_box" into @n_qtp from "item_mst" where "c_code" = @c_item_code;
    if @n_qtp = 0 then
      set @n_qtp = 1
    end if;
    set @n_l_remainder = @n_stock_on_hand_L/@n_qtp;
    set @n_stock_on_hand_P = @n_stock_on_hand_P+"isnull"(@n_l_remainder,0);
    set @n_stock_on_hand = (@n_stock_on_hand_P*@n_qtp)+"isnull"("mod"(@n_stock_on_hand_L,@n_qtp),0);
    insert into "st_track_stock_audit_temp"
      ( "c_br_code","c_item_code","c_batch_no","c_rack","d_exp_date",
      "n_mrp","n_qty","n_stock_on_hand","c_user","d_ldate",
      "t_ltime","n_flag",
      "n_audited" ) on existing update defaults off values
      ( @BrCode,@c_item_code,@c_batch_no,@c_rack,@d_exp_date,
      @n_mrp,@n_qty,@n_stock_on_hand,@UserId,@d_ldate,
      @t_ltime,@n_flag,@n_audited ) ;
    if sqlstate = '00000' then
      commit work;
      select 'Success' as "c_message" for xml raw,elements
    else
      rollback work;
      select 'Failure' as "c_message" for xml raw,elements
    end if when 'Validate_Check_ID' then
    --http://192.168.7.12:16503/ws_st_stock_audit?&cIndex=Validate_Check_ID&GodownCode=-&UserId=myboss&HdrData=32014
    --sani
    select "max"("user_mst"."c_user_id")
      into @c_confirm_user from "user_mst","act_mst"
      where "user_mst"."c_code" = "act_mst"."c_code"
      and "act_mst"."n_lock" = 0
      and "string"("user_mst"."n_id") = @HdrData;
    if @c_confirm_user = 'SUPERVISOR' or @HdrData = '0' or @c_confirm_user is null or "trim"(@c_confirm_user) = '' then
      select 'Error!! ,Wrong ID ' as "c_message" for xml raw,elements
    else
      select 'Success'+@ColSep+@c_confirm_user as "c_message" for xml raw,elements
    end if when 'Confirm_audit' then
    --@HdrData -- Rack--c_confirm_user--user_remark
    --http://192.168.7.12:16503/ws_st_stock_audit?&cIndex=Confirm_audit&GodownCode=-&UserId=myboss&HdrData=31111^^myboss^^test remark ^^
    --1--	c_rack
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @c_rack = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --2--	c_confirm_user
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @c_confirm_user = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --3--post User remark
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @User_remark = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    begin
      for "c_code" as "Confirm_audit" dynamic scroll cursor for
        select "c_item_code",
          "c_batch_no",
          "n_stock_on_hand"-"n_qty" as "n_adj_qty",
          "n_stock_on_hand" as "n_rack_qty"
          from "st_track_stock_audit_temp"
          where "st_track_stock_audit_temp"."c_user" = @UserId and "c_rack" = @c_rack and "n_qty"+"n_stock_on_hand" <> 0
      do
        set @str = @str+cast("c_item_code" as char(10))+@ColSep
          +cast("c_batch_no" as char(25))+@ColSep
          +cast("n_adj_qty" as char(25))+@ColSep
          +cast("n_rack_qty" as char(25))+@ColSep
          +@RowSep
      end for
    end;
    set @User_remark = "left"("trim"(@c_rack+' '+@User_remark),75);
    --print '@str:'+@str;
    select "uf_st_stock_audit_stock_adj"(@str,@BrCode,@GodownCode,@UserId,@c_confirm_user,@User_remark) into @s_return;
    if "upper"("trim"(@s_return)) <> 'SUCCESS' then
      select 'Error!!,Error On Stock adjustment ' as "c_message" for xml raw,elements;
      return
    end if;
    -- print 'a';
    if @GodownCode = '-' then
      select "isnull"("count"(),0) into @n_item_count from "item_mst_br_info" where "c_br_code" = @BrCode and "c_rack" = @c_rack;
      select "isnull"("count"(distinct "c_item_code"),0) into @n_audit_item_count from "st_track_stock_audit_temp" where "c_br_code" = @BrCode and "c_user" = @UserId
        and "c_rack" = @c_rack
    else
      select "isnull"("count"(),0) into @n_item_count from "item_mst_br_info_godown" where "c_br_code" = @BrCode and "c_rack" = @c_rack and "c_godown_code" = @GodownCode;
      select "isnull"("count"(distinct "c_item_code"),0) into @n_audit_item_count from "st_track_stock_audit_temp" where "c_br_code" = @BrCode and "c_user" = @UserId
        and "c_rack" = @c_rack
    end if;
    --print 'b';
    insert into "st_track_stock_audit"
      ( "c_br_code","c_rack","d_date","n_item_count","n_audit_item_count",
      "c_user","d_ldate","t_ltime" ) on existing update defaults off values
      ( @BrCode,@c_rack,@d_ldate,@n_item_count,@n_audit_item_count,
      @UserId,@d_ldate,@t_ltime ) ;
    --print 'c';
    delete from "st_track_stock_audit_temp" where "c_user" = @UserId and "c_rack" = @c_rack;
    --print 'd';
    if sqlstate = '00000' then
      commit work;
      select 'Success' as "c_message" for xml raw,elements
    else
      rollback work;
      select 'Failure' as "c_message" for xml raw,elements
    end if when 'Discard_change' then
    --http://192.168.7.12:16503/ws_st_stock_audit?&cIndex=Discard_change&GodownCode=-&UserId=myboss&DetData=216316^^5017^^||
    --&DetData=rack^^item_code^^||
    while @DetData <> '' loop
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @c_rack = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      select "Locate"(@DetData,@ColSep) into @ColPos;
      set @c_item_code = "Trim"("Left"(@DetData,@ColPos-1));
      set @DetData = "SubString"(@DetData,@ColPos+@ColMaxLen);
      select "Locate"(@DetData,@RowSep) into @RowPos;
      set @DetData = "SubString"(@DetData,@RowPos+@RowMaxLen);
      delete from "st_track_stock_audit_temp"
        where "c_br_Code" = @BrCode
        and "c_rack" = @c_rack
        and "c_user" = @UserId;
      --print sqlstate ;
      if sqlstate = '00000' then
        commit work
      else
        rollback work;
        set @n_err = @n_err+1
      end if
    end loop;
    if @n_err = 0 then
      select 'Success' as "c_message" for xml raw,elements
    else
      select 'Failure' as "c_message" for xml raw,elements
    end if when 'Audit_login' then
    --http://192.168.7.12:16503/ws_st_stock_audit?&cIndex=Audit_login&GodownCode=-&UserId=myboss&HdrData=P20^^20212^^ &DetData=P20A^^P20B^^&devID='asccsacsacs'
    --&HdrData=Stage_code^^rack
    --&DetData=Rack Grp^^^
    --1--Stage_code
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @Stage_code = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --1--c_rack
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @c_rack = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    set @RackGrpList = @DetData;
    while @RackGrpList <> '' loop
      --1 RackGrpList
      select "Locate"(@RackGrpList,@ColSep) into @ColPos;
      set @tmp = "Trim"("Left"(@RackGrpList,@ColPos-1));
      set @RackGrpList = "SubString"(@RackGrpList,@ColPos+@ColMaxLen);
      if @tmp <> '' then
        select "c_user_id"
          into @login_user from "st_store_login_det"
          where "c_br_code" = @BrCode
          and "c_rack_grp_code" = @tmp
          and "c_stage_code" = @Stage_code
          and "c_user_2" = @c_rack
          and "c_user_id" <> @UserId
          and "t_login_time" is not null;
        if @login_user is null or "trim"(@login_user) = '' then
        else
          select 'ERROR :User '+@login_user+' Alreday Loged in to Rack '+@c_rack as "c_message" for xml raw,elements;
          return
        end if;
        insert into "st_store_login_det"
          ( "c_br_code","c_user_id","c_stage_code","c_rack_grp_code","c_device_id","t_login_time","d_adate","t_ltime",
          "c_user_2" ) on existing update defaults off values
          ( @BrCode,@UserId,@Stage_code,@tmp,@devID,@t_ltime,@d_ldate,@t_ltime,@c_rack ) 
      /*
if sqlstate = '00000' then
else
set @n_err =@n_err+ 1 ;
end if;
*/
      end if
    end loop;
    if @n_err = 0 then
      commit work;
      select 'Success' as "c_message" for xml raw,elements
    else
      rollback work;
      select 'Login Failure' as "c_message" for xml raw,elements
    end if when 'Audit_logout' then
    --http://192.168.7.12:16503/ws_st_stock_audit?&cIndex=Audit_logout&GodownCode=-&UserId=myboss&HdrData=P20^^20212^^ &DetData=P20A^^P20B^^&devID='asccsacsacs'
    --&HdrData=Stage_code^^rack
    --&DetData=Rack Grp^^^
    --1--Stage_code
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @Stage_code = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    --1--c_rack
    select "Locate"(@HdrData,@ColSep) into @ColPos;
    set @c_rack = "Trim"("Left"(@HdrData,@ColPos-1));
    set @HdrData = "SubString"(@HdrData,@ColPos+@ColMaxLen);
    set @RackGrpList = @DetData;
    while @RackGrpList <> '' loop
      --1 RackGrpList
      select "Locate"(@RackGrpList,@ColSep) into @ColPos;
      set @tmp = "Trim"("Left"(@RackGrpList,@ColPos-1));
      set @RackGrpList = "SubString"(@RackGrpList,@ColPos+@ColMaxLen);
      if @tmp <> '' then
        update "st_store_login_det"
          set "t_login_time" = null
          where "c_br_code" = @BrCode
          and "c_user_id" = @UserId
          and "c_rack_grp_code" = @tmp
          and "c_device_id" = @devID
      /*
if sqlstate = '00000' then
else
set @n_err =@n_err+ 1 ;
end if;
*/
      end if
    end loop;
    if @n_err = 0 then
      commit work;
      select 'Success' as "c_message" for xml raw,elements
    else
      rollback work;
      select 'Login Failure' as "c_message" for xml raw,elements
    end if else
    select 'Invalid Index!!' as "c_message" for xml raw,elements
  end case
end;