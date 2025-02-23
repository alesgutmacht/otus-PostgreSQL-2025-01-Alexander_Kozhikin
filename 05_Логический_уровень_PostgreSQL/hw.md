**Логический уровень PostgreSQL**  
  
*Входим пользователем postgres и создаем БД testdb*  
> $ su - postgres  
> $ psql  
> postgres=\# create database testdb;  
> CREATE DATABASE  
  
*Проверяем соединение*  
> postgres=\# \conninfo   
> You are connected to database "postgres" as user "postgres" via socket in "/var/run/postgresql" at port "5432".  
  
*Подключаемся к новой базе*  
> postgres=\# \connect testdb;  
> You are now connected to database "testdb" as user "postgres".  
> testdb=\# create schema testnm;  
> CREATE SCHEMA  
  
*Создаем таблицу, добавляем строку и проверяем содержимое таблицы*  
> testdb=\# create table t1(c1 integer);  
> CREATE TABLE  
> testdb=\# insert into t1 values (1);  
> INSERT 0 1  
> testdb=\# select * from t1;  
>  c1   
> ----  
>   1  
> (1 row)  
  
*Создаем роль и пользователя для чтения таблиц и даем необходимые привилегии пользователю*  
> testdb=\# create role readonly;  
> CREATE ROLE  
> testdb=\# GRANT CONNECT ON DATABASE testdb TO readonly;  
> GRANT  
> testdb=\# GRANT USAGE ON SCHEMA testnm TO readonly;  
> GRANT  
> testdb=\# GRANT SELECT ON ALL TABLES IN SCHEMA testnm TO readonly;  
> GRANT  
> testdb=\# CREATE USER testread WITH PASSWORD 'test123';  
> CREATE ROLE  
> testdb=\# GRANT readonly TO testread;  
> GRANT ROLE  
  
*Подключаемся новым пользователем*  
> testdb=\# \connect testdb testread;  
> connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  Peer authentication failed for user "testread"  
> Previous connection kept  
> testdb=\# \q  
  
*Из-за ошибки выше подключаемся с явным указанием хоста*  
> $ psql -U testread -h localhost -d testdb -W  
  
*Читаем данные из созданной таблицы*  
> testdb=> SELECT * From t1;  
> ERROR:  permission denied for table t1  
*Не можем посмотреть, т.к. таблица была создана для схемы public, а права на просмотр выдавались для схемы testnm.*  
  
*Подключаемся пользователем postgresи удаляем таблицу*  
> testdb=> \connect testdb postgres  
> You are now connected to database "testdb" as user "postgres".  
> testdb=\# DROP TABLE t1;  
> DROP TABLE  
  
*Теперь создаем таблицу для схемы testnm и добавляем в нее строку*  
> testdb=\# CREATE TABLE testnm.t1(c1 integer);  
> CREATE TABLE  
> testdb=\# INSERT INTO testnm.t1 VALUES (1);  
> INSERT 0 1  
  
*Подключаемся пользователем testread и смотрим в таблицу*  
> $ psql -U testread -h localhost -d testdb -W  
> testdb=> SELECT * From testnm.t1;  
> ERROR:  permission denied for table t1  
> testdb=> \dt  
> Did not find any relations.  
*Все равно не имеем доступ к таблице, т.к. права выданы на таблицы имеющиеся на тот момент.*  
  
*Подключаемся пользователем postgres и изменяем привилегии по умолчанию,*  
*это позволит с этого момента просматривать все созданные таблицы в схеме testnm.*  
*Но для просмотра уже созданной таблицы t1 надо обновить гранты.*  
> $ psql -U postgres -h localhost -d testdb  
> testdb=\# ALTER DEFAULT PRIVILEGES IN SCHEMA testnm GRANT SELECT ON TABLES TO readonly;  
> ALTER DEFAULT PRIVILEGES  
> testdb=\# GRANT SELECT ON testnm.t1 TO readonly;  
> GRANT  
  
*Подключаемся пользователем testread и смотрим в таблицу (видим содержимое)*  
> $ psql -U testread -h localhost -d testdb -W  
> testdb=> SELECT * From testnm.t1;  
>  c1   
> ----  
>   1  
> (1 row)  
  
  
*Далее не совсем совпадает с тем что указано в задании.*  
*Таблицу я создать не смог (Версия postgres 16 и по всей видимости нет необходимости делать REVOKE).*  
> testdb=> CREATE TABLE t2(c1 integer);  
> ERROR:  permission denied for schema public  
> LINE 1: CREATE TABLE t2(c1 integer);  
>                      ^  
> testdb=> show search_path;  
>    search_path     
> -----------------  
>  "$user", public  
> (1 row)  
  
  
*Создаем новую роль для создания таблиц и даем ее пользователю testrw*  
> $ psql -U postgres -h localhost -d testdb  
> testdb=\# CREATE ROLE rw;  
> CREATE ROLE  
> testdb=\# GRANT CONNECT ON DATABASE testdb TO rw;  
> GRANT  
> testdb=\# GRANT USAGE ON SCHEMA testnm TO rw;  
> GRANT  
> testdb=\# GRANT CREATE ON SCHEMA testnm TO rw;  
> GRANT  
> testdb=\# ALTER DEFAULT PRIVILEGES IN SCHEMA testnm GRANT ALL ON TABLES TO rw;  
> ALTER DEFAULT PRIVILEGES  
> testdb=\# CREATE USER testrw WITH PASSWORD 'test123';  
> CREATE ROLE  
> testdb=\# GRANT rw TO testrw;  
> GRANT ROLE  
  
*Подключаемся пользователем testrw, создаем и наполняем таблицу.*  
*С этой ролью можно и создавать и просматривать таблицы.*  
> $ psql -U testrw -h localhost -d testdb -W  
> testdb=> CREATE TABLE testnm.t2(c1 integer);  
> CREATE TABLE  
> testdb=> INSERT INTO testnm.t2 VALUES (1);  
> INSERT 0 1  
> testdb=> SELECT * From testnm.t2;  
>  c1   
> ----  
>   1  
> (1 row)  
  
