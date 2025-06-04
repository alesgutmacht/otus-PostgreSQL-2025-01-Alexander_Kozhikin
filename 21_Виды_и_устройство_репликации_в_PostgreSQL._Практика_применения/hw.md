**Виды и устройство репликации в PostgreSQL. Практика применения**  
  
**Логическая репликация**  

*Настройка серверов 1 и 2*  
```
postgres=# CREATE ROLE replicator WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT REPLICATION NOBYPASSRLS CONNECTION LIMIT -1 PASSWORD '*';
CREATE ROLE

postgres=# \password replicator 
Enter new password for user "replicator": 
Enter it again: 

$ vi $HOME/.pgpass

*:5432:postgres:replicator:replicator

$ chmod 0600 $HOME/.pgpass

$ vi /var/lib/pgsql/16/data/postgresql.conf

listen_addresses = '*'
wal_level = logical
wal_log_hints = on

$ vi /var/lib/pgsql/16/data/pg_hba.conf

# IPv4 local connections:
host    all             all             0.0.0.0/0            scram-sha-256
# replication privilege.
host    replication     replicator             0.0.0.0/0            scram-sha-256

# systemctl restart postgresql-16.service 
# systemctl status postgresql-16.service 

● postgresql-16.service - PostgreSQL 16 database server
     Loaded: loaded (/usr/lib/systemd/system/postgresql-16.service; enabled; preset: disabled)
     Active: active (running)
```
  
*Создаем таблицы на сервере 1, 2 и 3*  
*Даем права для пользователя replicator на эти таблицы на всех серверах*  
```
1$ psql 
psql (16.8)
Type "help" for help.

1postgres=# create table test (c1 integer, c2 text);
CREATE TABLE
1postgres=# create table test2 (c1 integer, c2 text);
CREATE TABLE

2$ psql 
psql (16.8)
Type "help" for help.

2postgres=# create table test2 (c1 integer, c2 text);
CREATE TABLE
2postgres=# create table test (c1 integer, c2 text);
CREATE TABLE

3$ psql 
psql (16.8)
Type "help" for help.

3postgres=# create table test (c1 integer, c2 text);
CREATE TABLE
3postgres=# create table test2 (c1 integer, c2 text);
CREATE TABLE

postgres=# GRANT ALL ON TABLE public.test TO replicator;
GRANT
postgres=# GRANT ALL ON TABLE public.test2 TO replicator;
GRANT
```
  
*На сервере 1 создаем публикацию таблицы test и подписываемся на публикацию таблицы test2 от сервера 2*  
```
postgres=# CREATE PUBLICATION publication_test FOR TABLE test;
CREATE PUBLICATION

postgres=# CREATE SUBSCRIPTION subscription_test2 CONNECTION 'hostaddr=192.168.122.3 port=5432 dbname=postgres user=replicator connect_timeout=10' PUBLICATION publication_test2;
NOTICE:  created replication slot "subscription_test2" on publisher
CREATE SUBSCRIPTION
```
  
*На сервере 2 создаем публикацию таблицы test2 и подписываемся на публикацию таблицы test от сервера 1*  
```
postgres=# CREATE PUBLICATION publication_test2 FOR TABLE test2;
CREATE PUBLICATION

postgres=# CREATE SUBSCRIPTION subscription_test CONNECTION 'hostaddr=192.168.122.2 port=5432 dbname=postgres user=replicator connect_timeout=10' PUBLICATION publication_test;
NOTICE:  created replication slot "subscription_test" on publisher
CREATE SUBSCRIPTION
```

*На сервере 3 подписываемся на публикацию таблиц test и test2*  
```
postgres=# CREATE SUBSCRIPTION subscription_test_rep CONNECTION 'hostaddr=192.168.122.2 port=5432 dbname=postgres user=replicator connect_timeout=10' PUBLICATION publication_test;
NOTICE:  created replication slot "subscription_test_rep" on publisher
CREATE SUBSCRIPTION

postgres=# CREATE SUBSCRIPTION subscription_test2_rep CONNECTION 'hostaddr=192.168.122.3 port=5432 dbname=postgres user=replicator connect_timeout=10' PUBLICATION publication_test2;
NOTICE:  created replication slot "subscription_test2_rep" on publisher
CREATE SUBSCRIPTION
```
  
*Заполняем таблицы на сервере 1 и 2*  
```
postgres=# insert into public.test values (1, '1Вводим данные на сервере 1');
INSERT 0 1

postgres=# insert into public.test2 values (1, '1Вводим данные на сервере 2');
INSERT 0 1
**  
```
  
*Проверяем репликацию на всех серверах*  
```
1postgres=# select * from public.test2;
 c1 |             c2              
----+-----------------------------
  1 | 1Вводим данные на сервере 2
(1 rows)

2postgres=# SELECT * FROM public.test;
 c1 |             c2              
----+-----------------------------
  1 | 1Вводим данные на сервере 1
(1 rows)

3postgres=# SELECT * from public.test;
 c1 |             c2              
----+-----------------------------
  1 | 1Вводим данные на сервере 1
(1 rows)

3postgres=# SELECT * from public.test2;
 c1 |             c2              
----+-----------------------------
  1 | 1Вводим данные на сервере 2
(1 rows)
```
