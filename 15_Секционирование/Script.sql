create table bookings_copy (like bookings including all)
inherits (bookings)
;

CREATE TABLE table2part
(
	id			bigint primary KEY,
	name		text,
	create_date	date,
	some_sum	numeric
)
/home/kaw/.local/share/DBeaverData/workspace6/General/Scripts/Script.sql
explain analyze
select * from table2part where id > 0 and id < 10;

create table table0_2020_01 (like table2part including all) inherits (table2part);
alter table table0_2020_01 add check (create_date between date'2020-01-01' and date'2020-02-01' - 1);

create table table0_2020_02 (like table2part including all) inherits (table2part);
alter table table0_2020_02 add check (create_date between date'2020-02-01' and date'2020-03-01' - 1);

create table table0_2020_03 (like table2part including all) inherits (table2part);
alter table table0_2020_03 add check (create_date between date'2020-03-01' and date'2020-04-01' - 1);

create table table0_2020_04 (like table2part including all) inherits (table2part);
alter table table0_2020_04 add check (create_date between date'2020-04-01' and date'2020-05-01' - 1);

select * from table0_2020_01;

create or replace function fn_table0_select_part()
RETURNS trigger
AS $$
BEGIN
	if new.create_date between date'2020-01-01' and date'2020-02-01' - 1
	then
		insert into table0_2020_01 values (new.*);
	elseif new.create_date between date'2020-02-01' and date'2020-03-01' - 1
	then
		insert into table0_2020_02 values (new.*);
	elseif new.create_date between date'2020-03-01' and date'2020-04-01' - 1
	then
		insert into table0_2020_03 values (new.*);
	elseif new.create_date between date'2020-04-01' and date'2020-05-01' - 1
	then
		insert into table0_2020_04 values (new.*);
	else
		raise exception 'this date is not your partitions. add partition';
	end if;
	return null;
END;
$$	language plpgsql
	security definer
	;


create trigger tr_table0_select_part
before insert
on table2part
for each row
execute function fn_table0_select_part();

insert into table2part (id, name, create_date, some_sum) values(6, 'some_text', date'2020-02-03', 100.0);
insert into table2part (id, name, create_date, some_sum) values(3, 'some_text', date'2020-04-03', 100.0);
insert into table2part (id, name, create_date, some_sum) values(4, 'some_text', date'2020-03-03', 100.0);
insert into table2part (id, name, create_date, some_sum) values(5, 'some_text', date'2020-01-03', 100.0);


