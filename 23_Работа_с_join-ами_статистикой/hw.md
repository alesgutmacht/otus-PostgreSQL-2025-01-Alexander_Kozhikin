**Работа с join'ами, статистикой**  
  
*Создание новой БД:*  
```
postgres=# CREATE DATABASE joins_db;
CREATE DATABASE
postgres=# \c joins_db 
You are now connected to database "joins_db" as user "postgres".
```
  
*Созданы таблицы bikes, aircrafts, cars, citys*  
```
select * from bikes;

id|bike_name|from_city|city_id|
--+---------+---------+-------+
 1|ИЖ       |Ижевск   |      4|
 2|ММВЗ     |Минск    |      5|
 3|ТМЗ      |Тула     |      6|
 4|ММЗ      |Москва   |      1|

select * from aircrafts;

id|air_name|from_city|city_id|
--+--------+---------+-------+
 2|Туполев |Москва   |      1|
 3|Антонов |Москва   |      1|
 1|Сухой   |Москва   |      1|

select * from cars;

id|car_name|from_city      |city_id|
--+--------+---------------+-------+
 1|ЗИЛ     |Москва         |      1|
 2|ВАЗ     |Тольятти       |      2|
 3|ГАЗ     |Нижний Новгород|      3|

select * from citys;
id|city_name      |
--+---------------+
 1|Москва         |
 2|Тольятти       |
 3|Нижний Новгород|
 4|Ижевск         |
 5|Минск          |
 6|Тула           |
```

*Прямой join выводит заводы совпадающие названием города во всех таблицах*  
```
select city_name,bike_name,air_name,car_name from
	citys ci
	inner join bikes b on ci.id = b.city_id
	inner join aircrafts a on ci.id = a.city_id
	inner join cars ca on ci.id = ca.city_id;

city_name|bike_name|air_name|car_name|
---------+---------+--------+--------+
Москва   |ММЗ      |Туполев |ЗИЛ     |
Москва   |ММЗ      |Антонов |ЗИЛ     |
Москва   |ММЗ      |Сухой   |ЗИЛ     |
```
  
*Правый join выводит заводы совпадающие названием города с правой таблицей,*  
*остальные поля пустые*  
```
select city_name,bike_name,air_name,car_name from
	citys ci
	right join bikes b on ci.id = b.city_id
	right join aircrafts a on ci.id = a.city_id
	right join cars ca on ci.id = ca.city_id;

city_name|bike_name|air_name|car_name|
---------+---------+--------+--------+
Москва   |ММЗ      |Туполев |ЗИЛ     |
Москва   |ММЗ      |Антонов |ЗИЛ     |
Москва   |ММЗ      |Сухой   |ЗИЛ     |
         |         |        |ВАЗ     |
         |         |        |ГАЗ     |
```
  
*Перекрестный join выводит заводы объединяя каждую строку всех таблиц*  
*Из 4 таблиц вывод слишком большой, по этому только 2 таблицы*  
```
select city_name,air_name from
	citys
	cross join aircrafts;

city_name      |air_name|
---------------+--------+
Москва         |Туполев |
Москва         |Антонов |
Москва         |Сухой   |
Тольятти       |Туполев |
Тольятти       |Антонов |
Тольятти       |Сухой   |
Нижний Новгород|Туполев |
Нижний Новгород|Антонов |
Нижний Новгород|Сухой   |
Ижевск         |Туполев |
Ижевск         |Антонов |
Ижевск         |Сухой   |
Минск          |Туполев |
Минск          |Антонов |
Минск          |Сухой   |
Тула           |Туполев |
Тула           |Антонов |
Тула           |Сухой   |
```
  
*Полный join выводит все строки из всех таблиц*  
```
select * from
	citys ci
	full join aircrafts a on ci.id = a.city_id
	full join cars ca on ci.id = ca.city_id
	full join bikes b on ci.id = b.city_id;

id|city_name      |id|air_name|from_city|city_id|id|car_name|from_city      |city_id|id|bike_name|from_city|city_id|
--+---------------+--+--------+---------+-------+--+--------+---------------+-------+--+---------+---------+-------+
 1|Москва         | 2|Туполев |Москва   |      1| 1|ЗИЛ     |Москва         |      1| 4|ММЗ      |Москва   |      1|
 1|Москва         | 3|Антонов |Москва   |      1| 1|ЗИЛ     |Москва         |      1| 4|ММЗ      |Москва   |      1|
 1|Москва         | 1|Сухой   |Москва   |      1| 1|ЗИЛ     |Москва         |      1| 4|ММЗ      |Москва   |      1|
 2|Тольятти       |  |        |         |       | 2|ВАЗ     |Тольятти       |      2|  |         |         |       |
 3|Нижний Новгород|  |        |         |       | 3|ГАЗ     |Нижний Новгород|      3|  |         |         |       |
 4|Ижевск         |  |        |         |       |  |        |               |       | 1|ИЖ       |Ижевск   |      4|
 5|Минск          |  |        |         |       |  |        |               |       | 2|ММВЗ     |Минск    |      5|
 6|Тула           |  |        |         |       |  |        |               |       | 3|ТМЗ      |Тула     |      6|
```
  
*Right, Left, Cross join*  
```
select city_name,bike_name,air_name,car_name from
	citys ci
	right join bikes b on ci.id = b.city_id
	left join aircrafts ca on ci.id = ca.city_id
	cross join cars;

city_name|bike_name|air_name|car_name|
---------+---------+--------+--------+
Москва   |ММЗ      |Туполев |ЗИЛ     |
Москва   |ММЗ      |Туполев |ВАЗ     |
Москва   |ММЗ      |Туполев |ГАЗ     |
Москва   |ММЗ      |Антонов |ЗИЛ     |
Москва   |ММЗ      |Антонов |ВАЗ     |
Москва   |ММЗ      |Антонов |ГАЗ     |
Москва   |ММЗ      |Сухой   |ЗИЛ     |
Москва   |ММЗ      |Сухой   |ВАЗ     |
Москва   |ММЗ      |Сухой   |ГАЗ     |
Ижевск   |ИЖ       |        |ЗИЛ     |
Ижевск   |ИЖ       |        |ВАЗ     |
Ижевск   |ИЖ       |        |ГАЗ     |
Минск    |ММВЗ     |        |ЗИЛ     |
Минск    |ММВЗ     |        |ВАЗ     |
Минск    |ММВЗ     |        |ГАЗ     |
Тула     |ТМЗ      |        |ЗИЛ     |
Тула     |ТМЗ      |        |ВАЗ     |
Тула     |ТМЗ      |        |ГАЗ     |

Right - совпадения по таблице bikes
Left - совпадения по таблице citys
Cross - совмещение каждой строки всех таблиц
```
