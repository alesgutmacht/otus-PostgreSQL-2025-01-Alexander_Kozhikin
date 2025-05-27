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
