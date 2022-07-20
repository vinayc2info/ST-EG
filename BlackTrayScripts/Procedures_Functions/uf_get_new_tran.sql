CREATE OR REPLACE FUNCTION uf_get_new_tran( in as_tran_code char(5), in as_prefix char(6)) 
returns numeric(18)
begin
  declare d_sr_no numeric(18);
  declare d_sr_no_b4 numeric(18);
  declare as_br char(3);
  declare as_year char(2);
  declare @sql_code numeric(20);
  set as_br = uf_get_br_code('000');
  set as_year = RIGHT(db_name(),2);
  select prefix_serial_no.n_sr_number
    into d_sr_no_b4 from prefix_serial_no
    where prefix_serial_no.c_br_code = as_br
    and prefix_serial_no.c_year = as_year
    and prefix_serial_no.c_prefix = as_prefix
    and prefix_serial_no.c_trans = as_tran_code;
  //generate new transaction number
  update prefix_serial_no
    set n_sr_number = n_sr_number+1
    where  prefix_serial_no.c_br_code = as_br
    and prefix_serial_no.c_year = as_year
    and prefix_serial_no.c_prefix = as_prefix
    and prefix_serial_no.c_trans = as_tran_code;
  select prefix_serial_no.n_sr_number
    into d_sr_no from prefix_serial_no
    where  prefix_serial_no.c_br_code = as_br
    and prefix_serial_no.c_year = as_year
    and prefix_serial_no.c_prefix = as_prefix
    and prefix_serial_no.c_trans = as_tran_code;
  if d_sr_no = d_sr_no_b4 then
    set d_sr_no = 0
  end if;
  return d_sr_no
exception
  when others then
    set @sql_code = sqlcode;
    if errormsg(@sql_code) is not null then
      set d_sr_no = 999999999
    end if;
    return d_sr_no
end;
COMMIT WORK;
GO 