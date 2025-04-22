**Работа с join'ами, статистикой**  
  
*Создание новой БД:*  
```
postgres=# CREATE DATABASE joins_db;
CREATE DATABASE
postgres=# \c joins_db 
You are now connected to database "joins_db" as user "postgres".
backup_restore_db=# CREATE SCHEMA backup_restore;
CREATE SCHEMA
```

create database joins_db;

create table aircrafts(id integer, air_name text);
alter table aircrafts add from_city text;
insert into aircrafts (id, air_name) values (1, 'Сухой');
insert into aircrafts (id, air_name) values (2, 'Туполев');
insert into aircrafts (id, air_name) values (3, 'Антонов');
update aircrafts a set from_city = 'Москва' where a.id = 1;
update aircrafts a set from_city = 'Москва' where a.id = 2;
update aircrafts a set from_city = 'Москва' where a.id = 3;


create table cars(id integer, car_name text);
alter table cars add from_city text;
insert into cars (id, car_name) values (1, 'Лихачёв');
insert into cars (id, car_name) values (2, 'Волжский');
insert into cars (id, car_name) values (3, 'Горьковский');
update cars a set from_city = 'Москва' where a.id = 1;
update cars a set from_city = 'Тольятти' where a.id = 2;
update cars a set from_city = 'Нижний Новгород' where a.id = 3;

create table bikes(id integer, bike_name text);
alter table bikes add from_city text;
insert into bikes (id, bike_name) values (1, 'Ижевский');
insert into bikes (id, bike_name) values (2, 'Минский');
insert into bikes (id, bike_name) values (3, 'Тульский');
update bikes a set from_city = 'Ижевск' where a.id = 1;
update bikes a set from_city = 'Минск' where a.id = 2;
update bikes a set from_city = 'Тула' where a.id = 3;

select * from aircrafts;
select * from cars;
select * from bikes;

select * from aircrafts, cars, bikes;

select * from aircrafts a left join cars c on a.from_city = c.from_city left join bikes b on a.from_city = b.from_city;


