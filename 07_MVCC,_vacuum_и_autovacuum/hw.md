**MVCC, vacuum и autovacuum** =  
  
*Инициализация кластера*  
> # postgresql-16-setup initdb  
> Initializing database ... OK  
  
*Назначаем пароль пользователю postgres в linux*  
> # passwd postgres  
> Changing password for user postgres.  
  
*Запускаем кластер и проверяем его работу*  
> # systemctl start postgresql-16.service  
> # systemctl status postgresql-16.service  
> ● postgresql-16.service - PostgreSQL 16 database server  
> Loaded: loaded (/usr/lib/systemd/system/postgresql-16.service; disabled; preset: disable>  
> Active: active (running)  
  
*Входим в Postgres и назначаем пароль для postgres в БД*  
> # su - postgres  
> $ psql -c "password postgres"  
> Enter new password for user "postgres":  
  
*Инициализируем pgbench и тестируем кластер*  
> $ /usr/pgsql-16/bin/pgbench -i postgres  
> $ /usr/pgsql-16/bin/pgbench -c 8 -P 6 -T 60 -U postgres postgres  
> pgbench (16.6)  
> starting vacuum...end.  
> progress: 6.0 s, 533.5 tps, lat 14.886 ms stddev 10.591, 0 failed  
> progress: 12.0 s, 568.7 tps, lat 14.057 ms stddev 9.904, 0 failed  
> progress: 18.0 s, 602.3 tps, lat 13.285 ms stddev 9.115, 0 failed  
> progress: 24.0 s, 550.2 tps, lat 14.535 ms stddev 9.817, 0 failed  
> progress: 30.0 s, 583.8 tps, lat 13.693 ms stddev 9.411, 0 failed  
> progress: 36.0 s, 579.6 tps, lat 13.793 ms stddev 9.085, 0 failed  
> progress: 42.0 s, 558.7 tps, lat 14.317 ms stddev 9.648, 0 failed  
> progress: 48.0 s, 571.2 tps, lat 14.000 ms stddev 9.856, 0 failed  
> progress: 54.0 s, 566.7 tps, lat 14.107 ms stddev 9.230, 0 failed  
> progress: 60.0 s, 554.2 tps, lat 14.434 ms stddev 10.593, 0 failed  
> transaction type: <builtin: TPC-B (sort of)>  
> scaling factor: 1  
> query mode: simple  
> number of clients: 8  
> number of threads: 1  
> maximum number of tries: 1  
> duration: 60 s  
> number of transactions actually processed: 34021  
> number of failed transactions: 0 (0.000%)  
> latency average = 14.097 ms  
> latency stddev = 9.734 ms  
> initial connection time = 28.693 ms  
> tps = 567.107461 (without initial connection time)  
  
*Сохраняем команды для изменения параметров в сценарий set_conf.sql*  
> $ vi set_conf.sql  
> ALTER SYSTEM SET max_connections = 40;  
> ALTER SYSTEM SET shared_buffers = '1GB';  
> ALTER SYSTEM SET effective_cache_size = '3GB';  
> ALTER SYSTEM SET maintenance_work_mem = '512MB';  
> ALTER SYSTEM SET checkpoint_completion_target = 0.9;  
> ALTER SYSTEM SET wal_buffers = '16MB';  
> ALTER SYSTEM SET default_statistics_target = 500;  
> ALTER SYSTEM SET random_page_cost = 4;  
> ALTER SYSTEM SET effective_io_concurrency = 2;  
> ALTER SYSTEM SET work_mem = '6553kB';  
> ALTER SYSTEM SET min_wal_size = '4GB';  
> ALTER SYSTEM SET max_wal_size = '16GB';  
> q  
  
*Перед выполнением сценария сохраняем параметры системы*  
> max_connections = 100  
> shared_buffers = 128MB  
> effective_cache_size = 4GB  
> maintenance_work_mem = 64MB  
> checkpoint_completion_target = 0.9  
> wal_buffers = 4MB  
> default_statistics_target = 100  
> random_page_cost = 4  
> effective_io_concurrency = 1  
> work_mem = 4MB  
> min_wal_size = 80MB  
> max_wal_size = 1GB  
  
*Выполняем сценарий и применяем настройки*  
> $ psql < set_conf.sql  
> ALTER SYSTEM  
> $ exit  
> # systemctl restart postgresql-16.service  
  
*Заново тестируем*  
> # su - postgres  
> $ /usr/pgsql-16/bin/pgbench -c 8 -P 6 -T 60 -U postgres postgres  
> pgbench (16.6)  
> starting vacuum...end.  
> progress: 6.0 s, 646.2 tps, lat 12.271 ms stddev 8.556, 0 failed  
> progress: 12.0 s, 578.5 tps, lat 13.822 ms stddev 9.180, 0 failed  
> progress: 18.0 s, 567.7 tps, lat 14.079 ms stddev 9.687, 0 failed  
> progress: 24.0 s, 538.8 tps, lat 14.841 ms stddev 9.749, 0 failed  
> progress: 30.0 s, 572.7 tps, lat 13.947 ms stddev 9.403, 0 failed  
> progress: 36.0 s, 606.8 tps, lat 13.200 ms stddev 9.028, 0 failed  
> progress: 42.0 s, 515.0 tps, lat 15.516 ms stddev 10.500, 0 failed  
> progress: 48.0 s, 544.0 tps, lat 14.686 ms stddev 10.297, 0 failed  
> progress: 54.0 s, 580.0 tps, lat 13.804 ms stddev 9.695, 0 failed  
> progress: 60.0 s, 571.3 tps, lat 13.994 ms stddev 9.412, 0 failed  
> transaction type: <builtin: TPC-B (sort of)>  
> scaling factor: 1  
> query mode: simple  
> number of clients: 8  
> number of threads: 1  
> maximum number of tries: 1  
> duration: 60 s  
> number of transactions actually processed: 34334  
> number of failed transactions: 0 (0.000%)  
> latency average = 13.967 ms  
> latency stddev = 9.575 ms  
> initial connection time = 39.478 ms  
> tps = 572.366132 (without initial connection time)  
  
*Отличающиеся результаты:*  
*Слева значания нового тестирования, справа значения первоначального тестирования*  
> number of transactions actually processed: 34334 > 34021  
> latency average = 13.967 ms < 14.097 ms  
> latency stddev = 9.575 ms < 9.734 ms  
> initial connection time = 39.478 ms > 28.693 ms  
> tps = 572.366132 (without initial connection time) > 567.107461 (without initial connection time)  
> *Анализ:*  
> shared_buffers увеличен до четверти ОП сервера (Рекомендованное максимальное значение).  
> Увеличение параметра maintenance_work_mem ускорило выполнение операции vacuum.  
> Увеличение параметра work_mem позволило выполнение некоторых операций без обращения к диску.  
  
*Создаем таблицу и наполняем ее данными*  
> $ psql -c "create table table1(i int);"  
> $ psql -c "insert into table1(i) SELECT hw.md out.md FROM generate_series(1,1000000);"  
> *Размер на диске*  
> $ psql -c "select pg_relation_filepath('table1');"  
> pg_relation_filepath  
> ----------------------  
> base/5/24607  
  
*Обновляем данные в таблице*  
> $ psql -c "update table1 set i = 999 where i > 0 and i <= 1000000;"  
> $ psql -c "update table1 set i = 111 where i = 999;"  
> $ psql -c "update table1 set i = 222 where i = 111;"  
> $ psql -c "update table1 set i = 333 where i = 222;"  
> $ psql -c "update table1 set i = 444 where i = 333;"  
  
*Проверяем мертвые записи*  
> postgres=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_TABLEs WHERE relname = 'table1';  
> relname | n_live_tup | n_dead_tup | ratio% | last_autovacuum  
---------+------------+------------+--------+-------------------------------  
table1 | 1000000 | 0 | 0 | 2025-02-26 16:29:19.304765+03  
*Мертвых строчек в таблице нет, т.к. был автовакуум*  
  
*Обновляем данные в таблице*  
> update table1 set i = 9999 where i > 0 and i <= 9999;  
> update table1 set i = 1119 where i > 0 and i <= 9999;  
> update table1 set i = 2229 where i > 0 and i <= 9999;  
> update table1 set i = 3339 where i > 0 and i <= 9999;  
> update table1 set i = 4449 where i > 0 and i <= 9999;  
  
*Размер на диске*  
> $ psql -c "select pg_relation_filepath('table1');"  
> pg_relation_filepath  
> ----------------------  
> base/5/24607  
> *Ничего не изменилось  
  
*Отключаем Автовакуум и применяем изменения*  
> postgres=# ALTER TABLE table1 SET (autovacuum_enabled = off);  
> ALTER TABLE  
> postgres=# SELECT pg_reload_conf();  
> pg_reload_conf  
> ----------------  
> t  
  
*Обновляем данные в таблице*  
> update table1 set i = 8999 where i > 0 and i <= 9999;  
> update table1 set i = 9119 where i > 0 and i <= 9999;  
> update table1 set i = 9229 where i > 0 and i <= 9999;  
> update table1 set i = 9339 where i > 0 and i <= 9999;  
> update table1 set i = 9449 where i > 0 and i <= 9999;  
> update table1 set i = 8999 where i > 0 and i <= 9999;  
> update table1 set i = 9119 where i > 0 and i <= 9999;  
> update table1 set i = 9229 where i > 0 and i <= 9999;  
> update table1 set i = 9339 where i > 0 and i <= 9999;  
> update table1 set i = 9449 where i > 0 and i <= 9999;  
> UPDATE 1000000 x10  
  
*Обновляем данные в таблице*  
> postgres=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_TABLEs WHERE relname = 'table1';  
> relname | n_live_tup | n_dead_tup | ratio% | last_autovacuum  
> ---------+------------+------------+-----------+-----------------  
> table1 | 0 | 9998993 | 999899300 |  
> *Теперь после отключения автовакуума можем увидеть мертвые строки*  
  
*Размер на диске*  
> postgres=# select pg_relation_filepath('table1');  
> pg_relation_filepath  
> ----------------------  
> base/5/24607  
>  
> postgres=# SELECT pg_size_pretty(pg_total_relation_size('table1'));  
> pg_size_pretty  
> ----------------  
> 380 MB  
  
*Применяем самостоятельно вакуум проверяем мертвые строки и размер*  
> postgres=# vacuum table1;  
> VACUUM  
>  
> postgres=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_TABLEs WHERE relname = 'table1';  
> relname | n_live_tup | n_dead_tup | ratio% | last_autovacuum  
> ---------+------------+------------+--------+-----------------  
> table1 | 1000000 | 0 | 0 |  
>  
> postgres=# select pg_relation_filepath('table1');  
> pg_relation_filepath  
> ----------------------  
> base/5/24607  
> *Видим что мертвые строки исчезли, но размер на диске остался прежним*  
  
*Делаем Вакуум с параметром full*  
> postgres=# vacuum full table1;  
> VACUUM  
>  
> postgres=# select pg_relation_filepath('table1');  
> pg_relation_filepath  
> ----------------------  
> base/5/40991  
>  
> postgres=# SELECT pg_size_pretty(pg_total_relation_size('table1'));  
> pg_size_pretty  
> ----------------  
> 35 MB  
> *Теперь место на диске освободилось*  
  
*Обратно включаем Автовакуум*  
> postgres=# ALTER TABLE table1 SET (autovacuum_enabled = on);  
> ALTER TABLE  
> postgres=# SELECT pg_reload_conf();  
> pg_reload_conf  
> ----------------  
> t  
  
*Вывод:*  
*Автовакуум чистит мертвые строки в таблице, Вакуум делает это вручную*  
*Но для очистки данных с диска надо использовать Вакуум с параметром full.*  
