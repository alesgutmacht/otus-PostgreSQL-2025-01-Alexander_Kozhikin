**Секционирование**  
  
*Инициализация кластера*  
```
# postgresql-16-setup initdb  
Initializing database ... OK  
```
  
*Назначаем пароль пользователю postgres в linux*  
```
# passwd postgres  
Changing password for user postgres.  
```
  
*Запускаем кластер и проверяем его работу*  
```
# systemctl start postgresql-16.service  
# systemctl status postgresql-16.service  
● postgresql-16.service - PostgreSQL 16 database server  
Loaded: loaded (/usr/lib/systemd/system/postgresql-16.service; disabled; preset: disable 
Active: active (running)  
```
  
*Входим в Postgres и назначаем пароль для postgres в БД*  
```
# su - postgres  
$ psql -c "\password postgres"  
Enter new password for user "postgres":  
```
  
*Распаковываем и устанавливаем БД с сайта https://postgrespro.ru/education/demodb*  
```
$ unzip demo-big.zip 
$ psql -f /tmp/demo-big-20170815.sql
```
  
*Подключаемся к новой БД*  
  ```
$ psql 
psql (16.8)
Type "help" for help.

postgres=# \connect demo 
You are now connected to database "demo" as user "postgres".
demo=# 
```
  
*В БД есть таблица bookings в которой присутствуют даты бронирования, эту таблицу можно секционировать поквартально*  
*Для создания копий таблицы выведем ее параметры и диапазон дат*  
```
demo=# \d bookings
                        Table "bookings.bookings"
    Column    |           Type           | Collation | Nullable | Default 
--------------+--------------------------+-----------+----------+---------
 book_ref     | character(6)             |           | not null | 
 book_date    | timestamp with time zone |           | not null | 
 total_amount | numeric(10,2)            |           | not null | 
Indexes:
    "bookings_pkey" PRIMARY KEY, btree (book_ref)
Referenced by:
    TABLE "tickets" CONSTRAINT "tickets_book_ref_fkey" FOREIGN KEY (book_ref) REFERENCES bookings(book_ref)

demo=# select min(demo.bookings.bookings.book_date), max(demo.bookings.bookings.book_date) from demo.bookings.bookings;
          min           |          max           
------------------------+------------------------
 2016-07-20 21:16:00+03 | 2017-08-15 18:00:00+03
(1 row)
```
  
*Создаем 2 таблицы и наполняем их данными из базы demo*  
*1 - Обычная копия для проверки результатов без секционирования*  
*2 - Копия для реализации секционирования*  
```
CREATE TABLE demo.bookings.bookings_copy
(
	book_ref		character(6) not null,
	book_date		timestamptz not null,
	total_amount	numeric(10, 2) not null,
	primary key (book_ref, book_date)
);

CREATE TABLE demo.bookings.bookings_copy_parts
(
	book_ref		character(6) not null,
	book_date		timestamptz not null,
	total_amount	numeric(10, 2) not null,
	primary key (book_ref, book_date)
)partition by range (book_date);
```
  
*Создаем партиции для хранения диапазонов дат таблицы bookings_copy_parts*  
```
create table bookings_copy_parts_2016_01 partition of demo.bookings.bookings_copy_parts for values from ('2016-01-01') to ('2016-04-01');
create table bookings_copy_parts_2016_02 partition of demo.bookings.bookings_copy_parts for values from ('2016-04-01') to ('2016-07-01');
create table bookings_copy_parts_2016_03 partition of demo.bookings.bookings_copy_parts for values from ('2016-07-01') to ('2016-10-01');
create table bookings_copy_parts_2016_04 partition of demo.bookings.bookings_copy_parts for values from ('2016-10-01') to ('2017-01-01');

create table bookings_copy_parts_2017_01 partition of demo.bookings.bookings_copy_parts for values from ('2017-01-01') to ('2017-04-01');
create table bookings_copy_parts_2017_02 partition of demo.bookings.bookings_copy_parts for values from ('2017-04-01') to ('2017-07-01');
create table bookings_copy_parts_2017_03 partition of demo.bookings.bookings_copy_parts for values from ('2017-07-01') to ('2017-10-01');
create table bookings_copy_parts_2017_04 partition of demo.bookings.bookings_copy_parts for values from ('2017-10-01') to ('2018-01-01');
```
  
*Наполняем таблицы данными бронирования*  
```
insert into demo.bookings.bookings_copy
overriding system value
select * from demo.bookings.bookings;

insert into demo.bookings.bookings_copy_parts
overriding system value
select * from demo.bookings.bookings;
```
  
*Проверяем что записи распределились по секциям корректно на примере 3 и 4 кварталов 2016 года*  
```
demo=# SELECT min(bookings_copy_parts_2016_03.book_date), max(bookings_copy_parts_2016_03.book_date) FROM bookings_copy_parts_2016_03;
          min           |          max           
------------------------+------------------------
 2016-07-20 21:16:00+03 | 2016-09-30 23:59:00+03
(1 row)

demo=# SELECT min(bookings_copy_parts_2016_04.book_date), max(bookings_copy_parts_2016_04.book_date) FROM bookings_copy_parts_2016_04;
          min           |          max           
------------------------+------------------------
 2016-10-01 00:00:00+03 | 2016-12-31 23:59:00+03
(1 row)
```
  
*Сравниваем результаты вывода запроса бронирований с 31.12.2016 по 01.01.2017*  
```
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
```
  
*Сравниваем результаты вывода запроса бронирований за 15.08.2017*  
```
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
```
*В результате видно, что обращение к секционированной таблице выполняется быстрее*  
