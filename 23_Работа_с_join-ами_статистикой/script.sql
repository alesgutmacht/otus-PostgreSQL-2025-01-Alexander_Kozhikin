create database joins_db;

create table aircrafts(id integer, air_name text);
alter table aircrafts add from_city text;
alter table aircrafts add city_id integer;
insert into aircrafts (id, air_name) values (1, 'Сухой');
insert into aircrafts (id, air_name) values (2, 'Туполев');
insert into aircrafts (id, air_name) values (3, 'Антонов');
update aircrafts a set from_city = 'Москва' where a.id = 1;
update aircrafts a set from_city = 'Москва' where a.id = 2;
update aircrafts a set from_city = 'Москва' where a.id = 3;
update aircrafts set city_id = 1 where from_city = 'Москва';

drop table cars;
create table cars(id integer, car_name text);
alter table cars add from_city text;
alter table cars add city_id integer;
insert into cars (id, car_name) values (1, 'ЗИЛ');
insert into cars (id, car_name) values (2, 'ВАЗ');
insert into cars (id, car_name) values (3, 'ГАЗ');
update cars a set from_city = 'Москва' where a.id = 1;
update cars a set from_city = 'Тольятти' where a.id = 2;
update cars a set from_city = 'Нижний Новгород' where a.id = 3;
update cars set city_id = 1 where from_city = 'Москва';
update cars set city_id = 2 where from_city = 'Тольятти';
update cars set city_id = 3 where from_city = 'Нижний Новгород';

drop table bikes;
create table bikes(id integer, bike_name text);
alter table bikes add from_city text;
alter table bikes add city_id integer;
insert into bikes (id, bike_name) values (1, 'ИЖ');
insert into bikes (id, bike_name) values (2, 'ММВЗ');
insert into bikes (id, bike_name) values (3, 'ТМЗ');
insert into bikes (id, bike_name) values (4, 'ММЗ');
update bikes a set from_city = 'Ижевск' where a.id = 1;
update bikes a set from_city = 'Минск' where a.id = 2;
update bikes a set from_city = 'Тула' where a.id = 3;
update bikes a set from_city = 'Москва' where a.id = 4;
update bikes set city_id = 4 where from_city = 'Ижевск';
update bikes set city_id = 5 where from_city = 'Минск';
update bikes set city_id = 6 where from_city = 'Тула';
update bikes set city_id = 1 where from_city = 'Москва';


create table citys(id integer, city_name text);
insert into citys (id, city_name) values (1, 'Москва');
insert into citys (id, city_name) values (2, 'Тольятти');
insert into citys (id, city_name) values (3, 'Нижний Новгород');
insert into citys (id, city_name) values (4, 'Ижевск');
insert into citys (id, city_name) values (5, 'Минск');
insert into citys (id, city_name) values (6, 'Тула');

select * from aircrafts;
select * from cars;
select * from bikes;
select * from citys;

select city_name,bike_name,air_name,car_name from
	citys ci
	inner join bikes b on ci.id = b.city_id
	inner join aircrafts a on ci.id = a.city_id
	inner join cars ca on ci.id = ca.city_id;

select city_name,bike_name,air_name,car_name from
	citys ci
	right join bikes b on ci.id = b.city_id
	right join aircrafts a on ci.id = a.city_id
	right join cars ca on ci.id = ca.city_id;

select city_name,bike_name from
	citys ci
	cross join bikes;

select * from
	citys ci
	full join aircrafts a on ci.id = a.city_id
	full join cars ca on ci.id = ca.city_id
	full join bikes b on ci.id = b.city_id;

select city_name,bike_name,air_name,car_name from
	citys ci
	right join bikes b on ci.id = b.city_id
	left join aircrafts ca on ci.id = ca.city_id
	cross join cars;
