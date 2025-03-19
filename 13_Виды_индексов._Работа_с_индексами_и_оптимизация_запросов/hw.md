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
  
*Создаем индекс product_id и сбрасываем кеш планировщика*  
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
  
*План запроса с условиями по двум полям (с 1 индексом)*  
```
index_db=# EXPLAIN SELECT * FROM products WHERE product_id <= 100 AND brand = 'a';
                                       QUERY PLAN                                        
-----------------------------------------------------------------------------------------
 Bitmap Heap Scan on products  (cost=5.07..278.81 rows=1 width=14)
   Recheck Cond: (product_id <= 100)
   Filter: (brand = 'a'::bpchar)
   ->  Bitmap Index Scan on indx_products_product_id  (cost=0.00..5.07 rows=103 width=0)
         Index Cond: (product_id <= 100)
(5 rows)
```
> *Bitmap Index Scan строится битовая карта для последовательного чтения дисковых страниц*  
> *Filter добавляется фильтр по brand*  
> *Bitmap Heap Scan из таблицы выбираются нужные строки с результатом запроса, используя битовую карту*  
  
*Создаем индекс brand и сбрасываем кеш планировщика*  
```
index_db=# CREATE INDEX indx_products_brand ON products (brand );
CREATE INDEX
index_db=# ANALYZE products ;
ANALYZE
```
  
*План запроса с условиями по двум полям (с 2 индексами)*  
```
index_db=# EXPLAIN SELECT * FROM products WHERE product_id <= 100 AND brand = 'a';
                                          QUERY PLAN                                          
----------------------------------------------------------------------------------------------
 Bitmap Heap Scan on products  (cost=16.55..20.56 rows=1 width=14)
   Recheck Cond: ((product_id <= 100) AND (brand = 'a'::bpchar))
   ->  BitmapAnd  (cost=16.55..16.55 rows=1 width=0)
         ->  Bitmap Index Scan on indx_products_product_id  (cost=0.00..5.01 rows=95 width=0)
               Index Cond: (product_id <= 100)
         ->  Bitmap Index Scan on indx_products_brand  (cost=0.00..11.29 rows=933 width=0)
               Index Cond: (brand = 'a'::bpchar)
(7 rows)
```
> *Bitmap Index Scan строится битовая карта для brand*  
> *Bitmap Index Scan строится битовая карта для product_id*  
> *BitmapAnd битовые карты объединяются по указанному условию AND*  
> *Bitmap Heap Scan из таблицы выбираются нужные строки с результатом запроса, используя объединенную битовую карту*  
  
*Запрос для проверки уникальности зачений в столбце*  
```
index_db=# SELECT s.n_distinct FROM pg_stats s WHERE s.tablename = 'products' AND s.attname = 'brand';
 n_distinct 
------------
         95
(1 row)
```
> *В данном столбце таблицы 95 уникальных значений*  
```
index_db=# SELECT s.n_distinct FROM pg_stats s WHERE s.tablename = 'products' AND s.attname = 'product_id';
 n_distinct 
------------
         -1
(1 row)
```
> *-1 означает что в данном столбце все значения уникальны*  
  
*Составные индексы*  
  
*Создаем составной индекса по product_id,brand и сбрасываем кеш планировщика*  
```
index_db=#  CREATE INDEX indx_products_product_id_brand ON products (product_id, brand);
CREATE INDEX
index_db=# ANALYZE products ;
ANALYZE
```
  
*План запроса с условиями по двум полям (с составным индексом)*  
```
index_db=# EXPLAIN SELECT * FROM products WHERE product_id <= 100 AND brand = 'a';
                                           QUERY PLAN                                           
------------------------------------------------------------------------------------------------
 Index Scan using indx_products_product_id_brand on products  (cost=0.29..9.38 rows=1 width=14)
   Index Cond: ((product_id <= 100) AND (brand = 'a'::bpchar))
(2 rows)

index_db=# EXPLAIN SELECT * FROM products WHERE product_id = 100 AND brand <= 'a';
                                           QUERY PLAN                                           
------------------------------------------------------------------------------------------------
 Index Scan using indx_products_product_id_brand on products  (cost=0.29..8.31 rows=1 width=14)
   Index Cond: ((product_id = 100) AND (brand <= 'a'::bpchar))
(2 rows)
```
> *Index Scan поиск с использованием составного индекса для 2 условий*  

*Создаем составной индекса по brand,product_id и сбрасываем кеш планировщика*  
```
index_db=# CREATE INDEX indx_products_brand_product_id ON products (brand, product_id);
CREATE INDEX
index_db=# ANALYZE products ;
ANALYZE
```
  
*План запроса с условиями по двум полям (используются 2 составных индекса)*  
```
index_db=# EXPLAIN SELECT * FROM products WHERE product_id <= 100 AND brand = 'a';
                                           QUERY PLAN                                           
------------------------------------------------------------------------------------------------
 Index Scan using indx_products_brand_product_id on products  (cost=0.29..8.31 rows=1 width=14)
   Index Cond: ((brand = 'a'::bpchar) AND (product_id <= 100))
(2 rows)

index_db=# EXPLAIN SELECT * FROM products WHERE product_id = 100 AND brand <= 'a';
                                           QUERY PLAN                                           
------------------------------------------------------------------------------------------------
 Index Scan using indx_products_product_id_brand on products  (cost=0.29..8.31 rows=1 width=14)
   Index Cond: ((product_id = 100) AND (brand <= 'a'::bpchar))
(2 rows)
```
> *Index Scan запрос выполняется с использованием оптимального индекса, в зависимости от запрошенных условий*  
  
*Частичные индексы*  
  
*Создаем частичный индекс по is_available и сбрасываем кеш планировщика*  
```
index_db=# CREATE INDEX indx_products_is_available_true ON products(is_available) WHERE is_available = true;
CREATE INDEX
index_db=# ANALYZE products ;
ANALYZE
```
  
*План запроса с использованием частичного индекса*  
```
index_db=# EXPLAIN SELECT * FROM products WHERE is_available = true;
                                              QUERY PLAN                                              
------------------------------------------------------------------------------------------------------
 Index Scan using indx_products_is_available_true on products  (cost=0.15..124.84 rows=1033 width=14)
(1 row)

index_db=# EXPLAIN SELECT * FROM products WHERE is_available = false;
                           QUERY PLAN                           
----------------------------------------------------------------
 Seq Scan on products  (cost=0.00..1637.00 rows=98967 width=14)
   Filter: (NOT is_available)
(2 rows)

index_db=# EXPLAIN SELECT * FROM products WHERE is_available != true;
                           QUERY PLAN                           
----------------------------------------------------------------
 Seq Scan on products  (cost=0.00..1637.00 rows=98967 width=14)
   Filter: (NOT is_available)
(2 rows)
```
> *В 1 случае используется частичный индекс Index Scan*  
> *В 2 других последовательный поиск Seq Scan*  
  
*GIN-индексы*  
  
*Создаем таблицу documents и наполняем ее данными*  
```
index_db=# CREATE TABLE documents (
    title    varchar(64),
    metadata jsonb,
    contents text
);
CREATE TABLE
index_db=# INSERT INTO documents
    (title, metadata, contents)
VALUES
    ( 'Document 1',
      '{"author": "John",  "tags": ["legal", "real estate"]}',
      'This is a legal document about real estate.' ),
    ( 'Document 2',
      '{"author": "Jane",  "tags": ["finance", "legal"]}',
      'Financial statements should be verified.' ),
    ( 'Document 3',
      '{"author": "Paul",  "tags": ["health", "nutrition"]}',
      'Regular exercise promotes better health.' ),
    ( 'Document 4',
      '{"author": "Alice", "tags": ["travel", "adventure"]}',
      'Mountaineering requires careful preparation.' ),
    ( 'Document 5',
      '{"author": "Bob",   "tags": ["legal", "contracts"]}',
      'Contracts are binding legal documents.' ),
    ( 'Document 6',
       '{"author": "Eve",  "tags": ["legal", "family law"]}',
       'Family law addresses diverse issues.' ),
    ( 'Document 7',
      '{"author": "John",  "tags": ["technology", "innovation"]}',
      'Tech innovations are changing the world.' );
INSERT 0 7
index_db=# SELECT * FROM documents;
   title    |                         metadata                         |                   contents                   
------------+----------------------------------------------------------+----------------------------------------------
 Document 1 | {"tags": ["legal", "real estate"], "author": "John"}     | This is a legal document about real estate.
 Document 2 | {"tags": ["finance", "legal"], "author": "Jane"}         | Financial statements should be verified.
 Document 3 | {"tags": ["health", "nutrition"], "author": "Paul"}      | Regular exercise promotes better health.
 Document 4 | {"tags": ["travel", "adventure"], "author": "Alice"}     | Mountaineering requires careful preparation.
 Document 5 | {"tags": ["legal", "contracts"], "author": "Bob"}        | Contracts are binding legal documents.
 Document 6 | {"tags": ["legal", "family law"], "author": "Eve"}       | Family law addresses diverse issues.
 Document 7 | {"tags": ["technology", "innovation"], "author": "John"} | Tech innovations are changing the world.
(7 rows)
```
  
*Пробуем наивный полнотекстовый поиск*  
```
index_db=# SELECT * FROM documents WHERE contents like '%document%';
   title    |                       metadata                       |                  contents                   
------------+------------------------------------------------------+---------------------------------------------
 Document 1 | {"tags": ["legal", "real estate"], "author": "John"} | This is a legal document about real estate.
 Document 5 | {"tags": ["legal", "contracts"], "author": "Bob"}    | Contracts are binding legal documents.
(2 rows)

index_db=# EXPLAIN SELECT * FROM documents WHERE contents like '%document%';
                         QUERY PLAN                         
------------------------------------------------------------
 Seq Scan on documents  (cost=0.00..14.25 rows=1 width=210)
   Filter: (contents ~~ '%document%'::text)
(2 rows)
```
> *Seq Scan последовательное сканирование таблицы*  
  
*Создаем GIN-индекс на текст документа и сбрасываем кеш планировщика*  
```
index_db=# CREATE INDEX indx_documents_contents ON documents USING GIN(to_tsvector('english', contents));
CREATE INDEX
index_db=# ANALYZE documents ;
ANALYZE
```
  
*Отключаем последовательное сканирование*
```
index_db=# SET enable_seqscan = OFF;
SET
```
  
*Пробуем полнотекстовый поиск с использованием созданного интекса по тексту*  
```
index_db=# SELECT * FROM documents WHERE to_tsvector('english', contents) @@ 'document';
   title    |                       metadata                       |                  contents                   
------------+------------------------------------------------------+---------------------------------------------
 Document 1 | {"tags": ["legal", "real estate"], "author": "John"} | This is a legal document about real estate.
 Document 5 | {"tags": ["legal", "contracts"], "author": "Bob"}    | Contracts are binding legal documents.
(2 rows)

index_db=# EXPLAIN SELECT * FROM documents WHERE to_tsvector('english', contents) @@ 'document';
                                          QUERY PLAN                                          
----------------------------------------------------------------------------------------------
 Bitmap Heap Scan on documents  (cost=8.54..13.06 rows=2 width=116)
   Recheck Cond: (to_tsvector('english'::regconfig, contents) @@ '''document'''::tsquery)
   ->  Bitmap Index Scan on indx_documents_contents  (cost=0.00..8.54 rows=2 width=0)
         Index Cond: (to_tsvector('english'::regconfig, contents) @@ '''document'''::tsquery)
(4 rows)
```
> *Bitmap Index Scan строится битовая карта для последовательного чтения дисковых страниц*  
> *Bitmap Heap Scan из таблицы выбираются нужные строки с результатом запроса, используя битовую карту*  
