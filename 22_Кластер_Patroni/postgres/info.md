*Установка*  
```
# dnf install postgresql16 postgresql16-server postgresql16-contrib
```
  
*Настройка*  
```
# postgresql-16-setup initdb
Initializing database ... OK

# systemctl start postgresql-16.service

# passwd postgres 
Changing password for user postgres.
New password: 
Retype new password: 
passwd: all authentication tokens updated successfully.

$ vi 16/data/postgresql.conf
$ vi 16/data/pg_hba.conf

postgres=# \password postgres 
Enter new password for user "postgres": 
Enter it again:

postgres=# create user replicator replication login encrypted password '';
NOTICE:  empty string is not a valid password, clearing password
CREATE ROLE
postgres=# \password replicator 
Enter new password for user "replicator": 
Enter it again:

postgres=# create user pgbouncer password '';
NOTICE:  empty string is not a valid password, clearing password
CREATE ROLE
postgres=# \password pgbouncer 
Enter new password for user "pgbouncer": 
Enter it again:

postgres=# create extension pg_stat_statements;
CREATE EXTENSION
postgres=# load 'auto_explain';
LOAD

# systemctl stop postgresql-16.service
```
*После настройки и герерации конфигурации для Patroni сервис останавливается.*  
*Дальнейшее управление сервисом Postgres осуществляет сервис Patroni.*  
