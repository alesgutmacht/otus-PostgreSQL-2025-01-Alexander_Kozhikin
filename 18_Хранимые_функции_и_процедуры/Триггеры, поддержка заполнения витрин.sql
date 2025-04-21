-- Создание схемы:
DROP SCHEMA IF EXISTS pract_functions CASCADE;
CREATE SCHEMA pract_functions;

SET search_path TO postgres, pract_functions;
SHOW search_path;

-- Создание таблицы Товары:
CREATE TABLE goods
(
    goods_id    integer PRIMARY KEY,
    good_name   varchar(63) NOT NULL,
    good_price  numeric(12, 2) NOT NULL CHECK (good_price > 0.0)
);
INSERT INTO goods (goods_id, good_name, good_price)
VALUES 	(1, 'Спички хозайственные', .50),
		(2, 'Автомобиль Ferrari FXX K', 185000000.01);

--Для удобства добавления новых товаров создана функция
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
select add_new_good('Спички', 3.95);

select * from pract_functions.goods;


-- Таблица с данными о продаже товаров
CREATE TABLE sales
(
    sales_id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    good_id     integer REFERENCES goods (goods_id),
    sales_time  timestamp with time zone DEFAULT now(),
    sales_qty   integer CHECK (sales_qty > 0)
);

--Продажа осуществляется добавлением строки в таблицу
INSERT INTO sales (good_id, sales_qty) VALUES (1, 10), (1, 1), (1, 120), (2, 1);
INSERT INTO sales (good_id, sales_qty) VALUES (1, 1);

select * from pract_functions.sales;

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

SELECT * from pract_functions.good_sum_mart;

drop function update_good_sum_mart();
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
			--RAISE INFO 'EXIST';
		WHEN NOT MATCHED
		then
			--insert Если товар продается впервые
			insert (good_name, sum_sale) values (product_name, price * new.sales_qty);
			--RAISE INFO 'NOT EXIST';
	else
		--Продается некорректный товар
		RAISE INFO 'NO GOODS NAME';
	end if;
	return null;
END;
$$ LANGUAGE plpgsql;

drop trigger tr_good_sum_update on pract_functions.sales;
create trigger tr_good_sum_update
after insert
on pract_functions.sales
for each row
execute function update_good_sum_mart();

