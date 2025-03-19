**Виды индексов. Работа с индексами и оптимизация запросов**  
  
*Инициализация кластера*  
> \# postgresql-16-setup initdb  
> Initializing database ... OK  
  
*Назначаем пароль пользователю postgres в linux*  
> \# passwd postgres  
> Changing password for user postgres.  
  
*Запускаем кластер и проверяем его работу*  
> \# systemctl start postgresql-16.service  
> \# systemctl status postgresql-16.service  
> ● postgresql-16.service - PostgreSQL 16 database server  
> Loaded: loaded (/usr/lib/systemd/system/postgresql-16.service; disabled; preset: disable>  
> Active: active (running)  
  
*Входим в Postgres и назначаем пароль для postgres в БД*  
> \# su - postgres  
> \$ psql -c "\password postgres"  
> Enter new password for user "postgres":  
  
*Создаем, наполняем и проверяем таблицу в БД*  
```
$ psql 
psql (16.8)
Type "help" for help.

postgres=# CREATE DATABASE index_db;
CREATE DATABASE
postgres=# \c index_db 
You are now connected to database "index_db" as user "postgres".
index_db=# CREATE TABLE products 
(             OF            PARTITION OF  
index_db=# CREATE TABLE products(
    product_id   integer,
    brand        char(1),
    gender       char(1),
    price        integer,
    is_available boolean
);
CREATE TABLE
index_db=# WITH random_data AS (
    SELECT
    num,
    random() AS rand1,
    random() AS rand2,
    random() AS rand3
    FROM generate_series(1, 100000) AS s(num)
)
INSERT INTO products
    (product_id, brand, gender, price, is_available)
SELECT
    random_data.num,
    chr((32 + random_data.rand1 * 94)::integer),
    case when random_data.num % 2 = 0 then 'М' else 'Ж' end,
    (random_data.rand2 * 100)::integer,
    random_data.rand3 < 0.01
    FROM random_data
    ORDER BY random();
INSERT 0 100000
index_db=# SELECT count(*) FROM products;
 count  
--------
 100000
(1 row)
index_db=# SELECT * FROM products WHERE product_id >= 5057 AND product_id <= 5080;
 product_id | brand | gender | price | is_available 
------------+-------+--------+-------+--------------
       5058 | "     | М      |    69 | f
       5071 | Y     | Ж      |    22 | f
       5062 | \     | М      |    31 | f
       5077 | l     | Ж      |    97 | f
       5061 | d     | Ж      |    73 | f
       5059 | U     | Ж      |    96 | f
       5057 | C     | Ж      |    12 | f
       5067 | H     | Ж      |    39 | f
       5074 | >     | М      |    85 | f
       5066 | #     | М      |    97 | f
       5060 | F     | М      |     4 | f
       5065 | B     | Ж      |    39 | f
       5070 | >     | М      |    87 | f
       5073 | 1     | Ж      |    16 | f
       5064 | t     | М      |    88 | f
       5076 | W     | М      |    37 | f
       5078 | _     | М      |    66 | f
       5068 | Q     | М      |    46 | f
       5079 | g     | Ж      |    54 | f
       5069 | 9     | Ж      |    41 | f
       5080 | ,     | М      |    76 | f
       5063 | ?     | Ж      |    15 | f
       5072 | C     | М      |    89 | f
       5075 | P     | Ж      |    48 | f
(24 rows)
```
  
*Простые индексы*  
  
*План запроса для выборки по равенству*  
```
index_db=# EXPLAIN SELECT * FROM products WHERE product_id = 1;
                         QUERY PLAN                         
------------------------------------------------------------
 Seq Scan on products  (cost=0.00..1887.00 rows=1 width=14)
   Filter: (product_id = 1)
(2 rows)
```
> *Seq Scan последовательное сканирование таблицы*  
  
*План запроса для выборки по диапазону*  
```
index_db=# EXPLAIN SELECT * FROM products WHERE product_id < 100;
                         QUERY PLAN                          
-------------------------------------------------------------
 Seq Scan on products  (cost=0.00..1887.00 rows=97 width=14)
   Filter: (product_id < 100)
(2 rows)
```
> *Seq Scan последовательное сканирование таблицы*
  
*Добавляем индекс product_id и сбрасываем кеш планировщика*  
```
index_db=# CREATE INDEX indx_products_product_id ON products (product_id);
CREATE INDEX
index_db=# ANALYZE products ;
ANALYZE
```
  
*План запроса для выборки по равенству (с индексом)*  
```
index_db=# EXPLAIN SELECT * FROM products WHERE product_id = 1;
                                        QUERY PLAN                                        
------------------------------------------------------------------------------------------
 Index Scan using indx_products_product_id on products  (cost=0.29..8.31 rows=1 width=14)
   Index Cond: (product_id = 1)
(2 rows)
```
> *Index Scan поиск с использованием индекса для условия product_id = 1*  
  
*План запроса для выборки по диапазону (с индексом)*  
```
index_db=# EXPLAIN SELECT * FROM products WHERE product_id < 100;
                                       QUERY PLAN                                       
----------------------------------------------------------------------------------------
 Bitmap Heap Scan on products  (cost=5.01..255.36 rows=92 width=14)
   Recheck Cond: (product_id < 100)
   ->  Bitmap Index Scan on indx_products_product_id  (cost=0.00..4.98 rows=92 width=0)
         Index Cond: (product_id < 100)
(4 rows)
```
> *Bitmap Index Scan строится битовая карта для последовательного чтения дисковых страниц*  
> *Bitmap Heap Scan из таблицы выбираются нужные строки с результатом запроса, используя битовую карту*  
  
**  
