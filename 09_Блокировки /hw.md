**Блокировки**  
  
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
> $ psql -c "password postgres"  
> Enter new password for user "postgres":  
  
postgres=# SHOW log_lock_waits ;
 log_lock_waits 
----------------
 off

postgres=# SHOW deadlock_timeout ;
 deadlock_timeout 
------------------
 1s

postgres=# SHOW  log_min_duration_statement;
 log_min_duration_statement 
----------------------------
 -1

postgres=# ALTER SYSTEM SET log_lock_waits = on;
ALTER SYSTEM

postgres=# ALTER SYSTEM SET deadlock_timeout = '200ms';
ALTER SYSTEM

postgres=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t

postgres=# SHOW log_lock_waits ;
 log_lock_waits 
----------------
 on

postgres=# SHOW deadlock_timeout;
 deadlock_timeout 
------------------
 200ms
 
