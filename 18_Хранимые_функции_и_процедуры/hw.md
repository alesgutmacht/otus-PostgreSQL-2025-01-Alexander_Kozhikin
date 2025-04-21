**Хранимые функции и процедуры**  
  
*Создание схемы:*  
```
DROP SCHEMA IF EXISTS pract_functions CASCADE;
CREATE SCHEMA pract_functions;

SET search_path TO postgres, pract_functions;
SHOW search_path;
```
  
*Создание таблицы Товары*  
```
CREATE TABLE goods
(
    goods_id    integer PRIMARY KEY,
    good_name   varchar(63) NOT NULL,
    good_price  numeric(12, 2) NOT NULL CHECK (good_price > 0.0)
);

-- Для удобства добавления новых товаров создана функция
-- Создание функции для добавления товара в таблицу Товары:
CREATE OR REPLACE FUNCTION add_new_good(name varchar(63), price numeric(12, 2))
RETURNS void
as
$$
declare id_val integer;
BEGIN
	SELECT goods_id + 1 into id_val
	FROM goods
	ORDER BY goods_id DESC
	LIMIT 1;
	INSERT INTO goods(goods_id, good_name, good_price)
	VALUES(id_val, name, price);
END;
$$ LANGUAGE plpgsql;

-- Добавление товара через функцию:
select add_new_good('Хлеб', 43.95);

-- Список всех товаров:
select * from pract_functions.goods;
 goods_id |        good_name         |  good_price  
----------+--------------------------+--------------
        1 | Спички хозайственные     |         0.50
        2 | Автомобиль Ferrari FXX K | 185000000.01
        3 | Хлеб                     |        43.95
        4 | Масло                    |       229.95
        5 | Молоко                   |       120.95
(5 rows)
```
  
*Для отслеживания сумм проданных товаров можно использовать отчет.*  
*Но мы создадим дополнительную таблицу, которая будет обновляться после каждой продажи*  
```
-- Отчет
SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;

--Создана таблица хранящая актуальные суммы проданных товаров
CREATE TABLE good_sum_mart
(
	good_name   varchar(63) NOT NULL,
	sum_sale	numeric(16, 2)NOT NULL
);
```
  
*Создаем функцию и триггер для обновления таблицы good_sum_mart*  
```
-- Создание функции обновления таблицы с продажами:
CREATE OR REPLACE FUNCTION update_good_sum_mart()
RETURNS trigger
as
$$
declare product_name varchar(63); --Имя товара
declare price numeric(16, 2); --Стоимость 1 единицы товара
BEGIN
	SELECT good_name FROM goods WHERE goods_id = new.good_id limit 1 into product_name;
	SELECT good_price FROM goods WHERE goods_id = new.good_id into price;
	if product_name != ''
	then
		MERGE into good_sum_mart su
		USING (SELECT * FROM goods WHERE goods_id = new.good_id limit 1) AS g
		ON g.good_name = su.good_name
		WHEN MATCHED
		then
			--update Если товар уже продавался
			UPDATE SET sum_sale = (sum_sale + (price * new.sales_qty))
		WHEN NOT MATCHED
		then
			--insert Если товар продается впервые
			insert (good_name, sum_sale) values (product_name, price * new.sales_qty);
	else
		--Продается некорректный товар
		RAISE INFO 'NO GOODS NAME';
	end if;
	return null;
END;
$$ LANGUAGE plpgsql;

--Создаем триггер для срабатывания функции update_good_sum_mart
create trigger tr_good_sum_update
after insert
on pract_functions.sales
for each row
execute function update_good_sum_mart();
```
  
*Командами INSERT для таблицы sales мы имитировали несколько продаж*  
```
INSERT INTO sales (good_id, sales_qty) VALUES (1, 1);
INSERT INTO sales (good_id, sales_qty) VALUES (2, 2);
INSERT INTO sales (good_id, sales_qty) VALUES (3, 3);
INSERT INTO sales (good_id, sales_qty) VALUES (4, 4);
INSERT INTO sales (good_id, sales_qty) VALUES (5, 5);
INSERT INTO sales (good_id, sales_qty) VALUES (1, 5);
INSERT INTO sales (good_id, sales_qty) VALUES (2, 4);
INSERT INTO sales (good_id, sales_qty) VALUES (3, 3);
INSERT INTO sales (good_id, sales_qty) VALUES (4, 2);
INSERT INTO sales (good_id, sales_qty) VALUES (5, 1);

--Выведем список продаж
select * from pract_functions.sales;
 sales_id | good_id |          sales_time           | sales_qty 
----------+---------+-------------------------------+-----------
        1 |       1 | 2025-04-20 19:22:52.532945+03 |         1
        2 |       2 | 2025-04-20 19:22:52.532945+03 |         2
        3 |       3 | 2025-04-20 19:22:52.532945+03 |         3
        4 |       4 | 2025-04-20 19:22:52.532945+03 |         4
        5 |       5 | 2025-04-20 19:22:52.532945+03 |         5
        6 |       1 | 2025-04-20 19:22:52.532945+03 |         5
        7 |       2 | 2025-04-20 19:22:52.532945+03 |         4
        8 |       3 | 2025-04-20 19:22:52.532945+03 |         3
        9 |       4 | 2025-04-20 19:22:52.532945+03 |         2
       10 |       5 | 2025-04-20 19:22:52.532945+03 |         1
(10 rows)
```
  
*После каждой команды INSERT наша таблица good_sum_mart обновлялась*  
```
SELECT * from pract_functions.good_sum_mart;
        good_name         |   sum_sale    
--------------------------+---------------
 Спички хозайственные     |          3.00
 Автомобиль Ferrari FXX K | 1110000000.06
 Хлеб                     |        263.70
 Масло                    |       1379.70
 Молоко                   |        725.70
(5 rows)
```
  
*Для сравнения сделаем EXPLAIN отчета и просмотра таблицы*  
```
EXPLAIN
SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;

HashAggregate  (cost=67.96..70.46 rows=200 width=176)
  Group Key: g.good_name
  ->  Hash Join  (cost=19.45..50.96 rows=1700 width=164)
        Hash Cond: (s.good_id = g.goods_id)
        ->  Seq Scan on sales s  (cost=0.00..27.00 rows=1700 width=8)
        ->  Hash  (cost=14.20..14.20 rows=420 width=164)
              ->  Seq Scan on goods g  (cost=0.00..14.20 rows=420 width=164)


EXPLAIN
SELECT * from pract_functions.good_sum_mart;

Seq Scan on good_sum_mart  (cost=0.00..14.20 rows=420 width=162)
```
