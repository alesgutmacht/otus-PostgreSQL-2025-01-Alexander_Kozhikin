**Резервное копирование и восстановление**  
  
*Создание схемы:*  
```
postgres=# CREATE SCHEMA backup_restore;
```
  
*Логическое резервное копирование*  
  
*Создание таблиц 1 и 2*  
```
postgres=# create table backup_restore.table1(id integer, name text);
CREATE TABLE
postgres=# select * from backup_restore.table1 ;
 id | name 
----+------
(0 rows)

postgres=# create table backup_restore.table2(id integer, name text);
CREATE TABLE
postgres=# select * from backup_restore.table2 ;
 id | name 
----+------
(0 rows)
```
  
*Наполняем таблицу 1*  
```
insert into backup_restore.table1 (id, name) values (1, 'Августина');
insert into backup_restore.table1 (id, name) values (2, 'Валентина');
insert into backup_restore.table1 (id, name) values (3, 'Даниела');
insert into backup_restore.table1 (id, name) values (4, 'Камила');
insert into backup_restore.table1 (id, name) values (5, 'Каролина');

postgres=# select * from backup_restore.table1 ;
 id |   name    
----+-----------
  1 | Августина
  2 | Валентина
  3 | Даниела
  4 | Камила
  5 | Каролина
(5 rows)
```
  
*Путь для хранения бэкапов:*  
> /var/lib/pgsql/16/backups
  
*Сохраняем бэкаб таблицы 1*  
```
postgres=# COPY backup_restore.table1 TO '/var/lib/pgsql/16/backups/logic_copy.sql';
COPY 5

$ cat /var/lib/pgsql/16/backups/logic_copy.sql 
1	Августина
2	Валентина
3	Даниела
4	Камила
5	Каролина
```
  
*Наполняем таблицу 2 из файла бэкапа*  
```
postgres=# COPY backup_restore.table2 FROM '/var/lib/pgsql/16/backups/logic_copy.sql';
COPY 5

postgres=# select * from backup_restore.table2 ;
 id |   name    
----+-----------
  1 | Августина
  2 | Валентина
  3 | Даниела
  4 | Камила
  5 | Каролина
(5 rows)
```
  
*Резервное копирование через pg_dump*  
  
*Создание новой БД и схемы backup_restore:*  
```
postgres=# CREATE DATABASE backup_restore_db;
postgres=# \c backup_restore_db 
You are now connected to database "backup_restore_db" as user "postgres".
backup_restore_db=# CREATE SCHEMA backup_restore;
CREATE SCHEMA
```
  
*Создаем архивный бэкап*  
```
$ pg_dump -d postgres --create -U postgres -Fc > /var/lib/pgsql/16/backups/arch_backup.gz

$ ls -lh /var/lib/pgsql/16/backups/
total 36K
-rw-r--r--. 1 postgres postgres 29K Apr 21 17:44 arch_backup.gz
-rw-r--r--. 1 postgres postgres  93 Apr 21 17:19 logic_copy.sql
```

*Восстанавливаем данные в новую БД (только таблица 2)*  
```
$ pg_restore -n backup_restore -t table2 -d backup_restore_db < /var/lib/pgsql/16/backups/arch_backup.gz
```
  
*Проверяем наличие данных в новой БД*  
```
$ psql 
psql (16.8)
Type "help" for help.

postgres=# \c backup_restore_db 
You are now connected to database "backup_restore_db" as user "postgres".

backup_restore_db=# select * from backup_restore.table2 ;
 id |   name    
----+-----------
  1 | Августина
  2 | Валентина
  3 | Даниела
  4 | Камила
  5 | Каролина
(5 rows)
```
