*Установка*  
```
# dnf install pgbouncer

pgbouncer-1.23.1-1.red80.x86_64
```
  
*Настройка*  
```
# vi /etc/pgbouncer/pgbouncer.ini

[databases]
postgres = host=localhost port=5432 dbname=postgres
* = host=localhost port=5432

[pgbouncer]
logfile = /var/log/pgbouncer/pgbouncer.log
pidfile = /var/run/pgbouncer/pgbouncer.pid
listen_addr = *
listen_port = 6432
unix_socket_dir = /var/run/pgbouncer
auth_type = SCRAM-SHA-256
auth_file = /etc/pgbouncer/userlist.txt
auth_user = postgres
auth_query = SELECT usename, passwd FROM pg_shadow WHERE usename=$1
admin_users = postgres
ignore_startup_parameters = extra_float_digits,geqo,search_path

pool_mode = session
server_reset_query = DISCARD ALL
max_client_conn = 10000
reserve_pool_size = 1
reserve_pool_timeout = 1
max_db_connections = 1000
default_pool_size = 500
pkt_buf = 8192
listen_backlog = 4096
log_connections = 1
log_disconnections = 1

# vi /etc/pgbouncer/userlist.txt
В файле хранятся пароли

chown -R pgbouncer:pgbouncer /etc/pgbouncer/
chown pgbouncer:pgbouncer /var/log/pgbouncer/
chmod 700 /etc/pgbouncer/
chmod 600 /etc/pgbouncer/*

vi /etc/systemd/system/multi-user.target.wants/pgbouncer.service
Добавлен ключ -q для отслеживания всех сопытий в статусе сервиса
ExecStart=/usr/bin/pgbouncer -q ${BOUNCERCONF}
```
  
*Пароли хранятся в файле userlist.txt в зашифрованном виде.*  
*Для получения хэша паролей пользователей БД используется следующий запрос:*  
```
postgres=# select rolname,rolpassword from pg_authid where rolname = 'postgres' or rolname = 'pgbouncer';

rolname  |rolpassword                                                                                                                          |
---------+-------------------------------------------------------------------------------------------------------------------------------------+
pgbouncer|SCRAM-SHA-256$4096:fLln7UE1i+pd0SOUDzdH6Q==$lhVEgGFNcQKYLK6znBTp1oN7jUQku0mV00xY2LW15Uk=:iwAZ5/AkAjhzWdJOLh7CWk0+O/S7QUAIbZygl1KSqRc=|
postgres |SCRAM-SHA-256$4096:TQQiXEvpgxtf9zyfjlxuNg==$B2RLAX5/twm87OqAmDQE4UVnL8PwE6mcU/14j2pAW+0=:yEEDNSBEIGhK7j01nxOyDBQ6gGmNRAGgHkd3e7tVzmU=|
```
  
*Файл userlist.txt заполняется данными пользователей и паролей:*  
```
"postgres" "SCRAM-SHA-256$4096:TQQiXEvpgxtf9zyfjlxuNg==$B2RLAX5/twm87OqAmDQE4UVnL8PwE6mcU/14j2pAW+0=:yEEDNSBEIGhK7j01nxOyDBQ6gGmNRAGgHkd3e7tVzmU="
"pgbouncer" "SCRAM-SHA-256$4096:fLln7UE1i+pd0SOUDzdH6Q==$lhVEgGFNcQKYLK6znBTp1oN7jUQku0mV00xY2LW15Uk=:iwAZ5/AkAjhzWdJOLh7CWk0+O/S7QUAIbZygl1KSqRc="
```
  
*Запуск сервиса*  
```
# systemctl enable pgbouncer.service --now
# systemctl status pgbouncer.service 
● pgbouncer.service - A lightweight connection pooler for PostgreSQL
     Loaded: loaded (/usr/lib/systemd/system/pgbouncer.service; enabled; preset: disabled)
     Active: active (running)
```
