if (select count() from systable where creator = 1 and table_name = 'st_err_track_det') = 0 then 
  CREATE TABLE DBA.st_err_track_det (
    c_doc_no CHAR(25) NOT NULL,
    n_inout NUMERIC(1,0) NOT NULL,
    n_seq NUMERIC(11,0) NOT NULL DEFAULT 0,
    n_org_seq NUMERIC(11,0) NOT NULL DEFAULT 0,
    c_item_code CHAR(6) NOT NULL,
    c_batch_no CHAR(15) NOT NULL,
    n_qty NUMERIC(11,3) NOT NULL,
    c_tray_code CHAR(6) NOT NULL,
    c_rack CHAR(6) NULL,
    c_rack_grp_code CHAR(6) NOT NULL,
    c_stage_code CHAR(6) NULL,
    c_godown_code CHAR(6) NULL DEFAULT '-',
    c_reason_code CHAR(6) NULL,
    c_note CHAR(40) NULL,
    c_black_tray_code CHAR(6) NOT NULL,
    n_err_type NUMERIC(1,0) NULL DEFAULT 0,
    c_err_mark_user CHAR(10) NULL,
    t_err_time TIMESTAMP NULL,
    c_contra_item CHAR(6) NULL,
    c_contra_batch CHAR(15) NULL,
    n_contra_qty NUMERIC(11,3) NULL,
    c_pack_tray_code CHAR(6) NULL,
    n_carton_no NUMERIC(9,0) NULL DEFAULT 0,
    c_counter_table_code CHAR(6) NULL,
    n_ref_srno NUMERIC(18,0) NULL DEFAULT 0,
    c_ref_doc_no CHAR(25) NULL,
    c_supervisor CHAR(10) NULL,
    t_spvr_err_marked_time TIMESTAMP NULL,
    c_new_doc_no CHAR(25) NULL,
    n_new_inout NUMERIC(1,0) NULL,
    n_new_seq NUMERIC(11,0) NULL DEFAULT 0,
    n_complete NUMERIC(1,0) NULL DEFAULT 0,
    n_hold_flag NUMERIC(1,0) NULL DEFAULT 0,
    t_ltime TIMESTAMP NULL,
    c_luser CHAR(10) NULL,
    PRIMARY KEY ( c_doc_no ASC, n_inout ASC, n_seq ASC, c_tray_code ASC, c_rack_grp_code ASC )
  ) IN system;
  COMMENT ON COLUMN DBA.st_err_track_det.n_err_type IS '0 item_short,1 item_excess,2 item_breakage,3 wrong_item,4 batch_mismatch';
end if;
commit work;
go

if (select count() from systable where creator = 1 and table_name = 'black_tray_mst') = 0 then 
  CREATE TABLE black_tray_mst (
  	c_br_code CHAR(6) NOT NULL,
  	c_year CHAR(2) NOT NULL,
  	c_prefix CHAR(4) NOT NULL,
  	n_srno NUMERIC(9,0) NOT NULL,
    n_inout numeric(1,0) not null,
  	d_date DATE NOT NULL,
    c_cust_code CHAR(6) NOT NULL,
    c_supervisor CHAR(15) NULL,
  	n_store_track NUMERIC(1,0) NULL DEFAULT 0,
  	d_ldate DATE NULL,
  	t_ltime TIMESTAMP NULL DEFAULT CURRENT TIMESTAMP,
  	PRIMARY KEY ( c_br_code ASC, c_year ASC, c_prefix ASC, n_srno ASC, n_inout ASC )
  ) IN system;
end if;
commit work;
go

if (select count() from systable where creator = 1 and table_name = 'black_tray_det') = 0 then 
  CREATE TABLE black_tray_det (
  	c_br_code CHAR(6) NOT NULL,
  	c_year CHAR(2) NOT NULL,
  	c_prefix CHAR(4) NOT NULL,
  	n_srno NUMERIC(9,0) NOT NULL,
    n_inout numeric(1,0) not null,
  	n_seq NUMERIC(4,0) NOT NULL,
  	d_date DATE NULL,
  	c_item_code CHAR(6) NOT NULL,
  	c_batch_no CHAR(15) NOT NULL,
  	n_qty NUMERIC(11,3) NOT NULL DEFAULT 0,
  	c_rack CHAR(6) NULL,
    c_rack_grp_code CHAR(6) NULL,
    c_stage_code CHAR(6) NULL,
    c_godown_code CHAR(6) NULL,
  	c_black_tray_code CHAR(6) NOT NULL,	
    n_err_type NUMERIC(1,0) NOT NULL,
  	n_store_track NUMERIC(1,0) NULL DEFAULT 0,
  	d_ldate DATE NULL,
  	t_ltime TIMESTAMP NULL DEFAULT CURRENT TIMESTAMP,
  	PRIMARY KEY ( c_br_code ASC, c_year ASC, c_prefix ASC, n_srno ASC, n_inout ASC, n_seq ASC )
  ) IN system;
  end if;
commit work;
go