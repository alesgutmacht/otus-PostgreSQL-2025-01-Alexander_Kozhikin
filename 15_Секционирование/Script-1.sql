drop table demo.bookings.bookings_copy;
drop table demo.bookings.bookings_copy_parts;

select min(demo.bookings.bookings.book_date), max(demo.bookings.bookings.book_date) from demo.bookings.bookings;
min								
2016-07-20 21:16:00.000 +0300	2017-08-15 18:00:00.000 +0300

CREATE TABLE demo.bookings.bookings_copy
(
	book_ref		bpchar(6) not null,
	book_date		timestamptz not null,
	total_amount	numeric(10, 2) not null,
	primary key (book_ref, book_date)
);

comment on column demo.bookings.bookings_copy.book_ref is 'Booking number';
comment on column demo.bookings.bookings_copy.book_date is 'Booking date';
comment on column demo.bookings.bookings_copy.total_amount is 'Total booking cost';

CREATE TABLE demo.bookings.bookings_copy_parts
(
	book_ref		bpchar(6) not null,
	book_date		timestamptz not null,
	total_amount	numeric(10, 2) not null,
	primary key (book_ref, book_date)
)partition by range (book_date);

comment on column demo.bookings.bookings_copy_parts.book_ref is 'Booking number';
comment on column demo.bookings.bookings_copy_parts.book_date is 'Booking date';
comment on column demo.bookings.bookings_copy_parts.total_amount is 'Total booking cost';

insert into demo.bookings.bookings_copy
overriding system value
select * from bookings;

insert into demo.bookings.bookings_copy_parts
overriding system value
select * from bookings;

vacuum analyze demo.bookings.bookings_copy;
vacuum analyze demo.bookings.bookings_copy_parts;

explain analyze
select min(demo.bookings.bookings_copy.book_date), max(demo.bookings.bookings_copy.book_date) from demo.bookings.bookings_copy;
explain analyze
select min(demo.bookings.bookings_copy_parts.book_date), max(demo.bookings.bookings_copy_parts.book_date) from demo.bookings.bookings_copy_parts;

create table bookings_copy_parts_2016_01 partition of demo.bookings.bookings_copy_parts for values from ('2016-01-01') to ('2016-04-01');
create table bookings_copy_parts_2016_02 partition of demo.bookings.bookings_copy_parts for values from ('2016-04-01') to ('2016-07-01');
create table bookings_copy_parts_2016_03 partition of demo.bookings.bookings_copy_parts for values from ('2016-07-01') to ('2016-10-01');
create table bookings_copy_parts_2016_04 partition of demo.bookings.bookings_copy_parts for values from ('2016-10-01') to ('2017-01-01');

create table bookings_copy_parts_2017_01 partition of demo.bookings.bookings_copy_parts for values from ('2017-01-01') to ('2017-04-01');
create table bookings_copy_parts_2017_02 partition of demo.bookings.bookings_copy_parts for values from ('2017-04-01') to ('2017-07-01');
create table bookings_copy_parts_2017_03 partition of demo.bookings.bookings_copy_parts for values from ('2017-07-01') to ('2017-10-01');
create table bookings_copy_parts_2017_04 partition of demo.bookings.bookings_copy_parts for values from ('2017-10-01') to ('2018-01-01');

explain analyze
select * from bookings_copy where book_date >= date'2016-12-31' and book_date <= date'2017-01-01';

Gather  (cost=1000.00..28226.74 rows=5853 width=21) (actual time=0.503..149.905 rows=5405 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  ->  Parallel Seq Scan on bookings_copy  (cost=0.00..26641.44 rows=2439 width=21) (actual time=0.165..136.616 rows=1802 loops=3)
        Filter: ((book_date >= '2016-12-31'::date) AND (book_date <= '2017-01-01'::date))
        Rows Removed by Filter: 701902
Planning Time: 0.146 ms
Execution Time: 150.147 ms

explain analyze
select * from bookings_copy_parts where book_date >= date'2016-12-31' and book_date <= date'2017-01-01';

Gather  (cost=1000.00..29693.29 rows=4823 width=21) (actual time=63.306..90.890 rows=5405 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  ->  Parallel Append  (cost=0.00..28210.99 rows=2013 width=21) (actual time=24.240..66.382 rows=1802 loops=3)
        Subplans Removed: 6
        ->  Parallel Seq Scan on bookings_copy_parts_2016_04 bookings_copy_parts_1  (cost=0.00..6406.55 rows=1750 width=21) (actual time=0.013..30.268 rows=1801 loops=3)
              Filter: ((book_date >= '2016-12-31'::date) AND (book_date <= '2017-01-01'::date))
              Rows Removed by Filter: 167402
        ->  Parallel Seq Scan on bookings_copy_parts_2017_01 bookings_copy_parts_2  (cost=0.00..6273.84 rows=257 width=21) (actual time=36.341..53.177 rows=2 loops=2)
              Filter: ((book_date >= '2016-12-31'::date) AND (book_date <= '2017-01-01'::date))
              Rows Removed by Filter: 248546
Planning Time: 0.452 ms
Execution Time: 91.109 ms

select max(bookings_copy.book_date) from bookings_copy;

explain analyze
select * from bookings_copy where bookings_copy.book_date = '2017-08-15 18:00:00.000 +0300';

Gather  (cost=1000.00..25442.86 rows=5 width=21) (actual time=36.940..106.337 rows=7 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  ->  Parallel Seq Scan on bookings_copy  (cost=0.00..24442.36 rows=2 width=21) (actual time=25.367..96.911 rows=2 loops=3)
        Filter: (book_date = '2017-08-15 18:00:00+03'::timestamp with time zone)
        Rows Removed by Filter: 703701
Planning Time: 0.093 ms
Execution Time: 106.365 ms

explain analyze
select * from bookings_copy_parts where bookings_copy_parts.book_date = '2017-08-15 18:00:00.000 +0300';

Gather  (cost=1000.00..4571.61 rows=5 width=21) (actual time=4.436..32.501 rows=7 loops=1)
  Workers Planned: 1
  Workers Launched: 1
  ->  Parallel Seq Scan on bookings_copy_parts_2017_03 bookings_copy_parts  (cost=0.00..3571.11 rows=3 width=21) (actual time=2.559..23.264 rows=4 loops=2)
        Filter: (book_date = '2017-08-15 18:00:00+03'::timestamp with time zone)
        Rows Removed by Filter: 130088
Planning Time: 0.139 ms
Execution Time: 32.536 ms