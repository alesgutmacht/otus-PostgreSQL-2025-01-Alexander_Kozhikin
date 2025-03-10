**Журналы**  
  
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
  
*Настраиваем выполнение контрольной точки раз в 30 секунд*  
> $ psql -c "SHOW checkpoint_timeout;"  
> checkpoint_timeout  
> --------------------  
> 5min  
>  
> $ psql -c "ALTER SYSTEM SET checkpoint_timeout = '30s';"  
> ALTER SYSTEM  
>  
> $ psql -c "select pg_reload_conf();"  
> pg_reload_conf  
> ----------------  
> t  
>  
> $ psql -c "SHOW checkpoint_timeout;"  
> checkpoint_timeout  
> --------------------  
> 30s  
  
*Инициализируем PGBENCH*  
> $ /usr/pgsql-16/bin/pgbench -i postgres  
> dropping old tables...  
> creating tables...  
> generating data (client-side)...  
> 100000 of 100000 tuples (100%) done (elapsed 0.08 s, remaining 0.00 s)  
> vacuuming...  
> creating primary keys...  
> done in 0.27 s (drop tables 0.03 s, create tables 0.01 s, client-side generate 0.11 s, vacuum 0.05 s, primary keys 0.07 s).  
  
*Запускаем тестирование*  
> $ /usr/pgsql-16/bin/pgbench -P 1 -T 600 postgres  
> pgbench (16.6)  
> starting vacuum...end.  
> progress: 1.0 s, 254.9 tps, lat 3.880 ms stddev 0.838, 0 failed  
> progress: 2.0 s, 439.1 tps, lat 2.277 ms stddev 0.735, 0 failed  
> progress: 3.0 s, 285.0 tps, lat 3.514 ms stddev 0.779, 0 failed  
> ...  
> transaction type: <builtin: TPC-B (sort of)>  
> scaling factor: 1  
> query mode: simple  
> number of clients: 1  
> number of threads: 1  
> maximum number of tries: 1  
> duration: 600 s  
> number of transactions actually processed: 215481  
> number of failed transactions: 0 (0.000%)  
> latency average = 2.783 ms  
> latency stddev = 0.841 ms  
> initial connection time = 7.376 ms  
> tps = 359.137379 (without initial connection time)  
> Получаем результат в синхронном режиме  
  
*Настраиваем асинхронный режим*  
> $ psql -c "SHOW synchronous_commit;"  
> synchronous_commit  
> --------------------  
> on  
>  
> $ psql -c "ALTER SYSTEM SET synchronous_commit = off;"  
> ALTER SYSTEM  
>  
> $ psql -c "select pg_reload_conf();"  
> pg_reload_conf  
> ----------------  
> t  
>  
> $ psql -c "SHOW synchronous_commit;"  
> synchronous_commit  
> --------------------  
> off  
  
*Новое тестирование*  
> $ /usr/pgsql-16/bin/pgbench -P 1 -T 600 postgres  
> pgbench (16.6)  
> starting vacuum...end.  
> ...  
> progress: 598.0 s, 1292.0 tps, lat 0.773 ms stddev 0.936, 0 failed  
> progress: 599.0 s, 1333.0 tps, lat 0.749 ms stddev 0.921, 0 failed  
> progress: 600.0 s, 1178.0 tps, lat 0.848 ms stddev 0.883, 0 failed  
> transaction type: <builtin: TPC-B (sort of)>  
> scaling factor: 1  
> query mode: simple  
> number of clients: 1  
> number of threads: 1  
> maximum number of tries: 1  
> duration: 600 s  
> number of transactions actually processed: 828897  
> number of failed transactions: 0 (0.000%)  
> latency average = 0.723 ms  
> latency stddev = 0.841 ms  
> initial connection time = 6.168 ms  
> tps = 1381.506869 (without initial connection time)  
> В асинхронном режиме транзакций в секунду почти в 4 раза больше  
  
*Последняя запись в журнале*  
> postgres=# SELECT pg_current_wal_insert_lsn();  
> pg_current_wal_insert_lsn  
> ---------------------------  
> 0/D7000028  
  
*Новое тестирование*  
> $ /usr/pgsql-16/bin/pgbench -P 1 -T 600 postgres  
> pgbench (16.6)  
> starting vacuum...end.  
> ...  
  
*Последняя запись обновилась*  
> postgres=# SELECT pg_current_wal_insert_lsn();  
> pg_current_wal_insert_lsn  
> ---------------------------  
> 0/FD1D6F20  
  
*Объем данных между записями*  
> postgres=# select '0/FD1D6F20'::pg_lsn - '0/D7000028'::pg_lsn as bytes;  
> bytes  
> -----------  
> 639463160  
>  
> 639463160 / 20 = 31973158 байт приходится в среднем на одну контрольную точку  
  
*Диагностика кластера*  
> $ /usr/pgsql-16/bin/pg_controldata  
> pg_control version number: 1300  
> Catalog version number: 202307071  
> Database system identifier: 7472084954727532283  
> Database cluster state: in production  
> pg_control last modified: Mon 10 Mar 2025 03:04:22 PM MSK  
> Latest checkpoint location: 0/FD1D6F58  
> Latest checkpoint's REDO location: 0/FC8FE528  
> Latest checkpoint's REDO WAL file: 0000000100000000000000FC  
> Latest checkpoint's TimeLineID: 1  
> Latest checkpoint's PrevTimeLineID: 1  
> Latest checkpoint's full_page_writes: on  
> Latest checkpoint's NextXID: 0:2003421  
> Latest checkpoint's NextOID: 57439  
> Latest checkpoint's NextMultiXactId: 1  
> Latest checkpoint's NextMultiOffset: 0  
> Latest checkpoint's oldestXID: 723  
> Latest checkpoint's oldestXID's DB: 5  
> Latest checkpoint's oldestActiveXID: 2003421  
> Latest checkpoint's oldestMultiXid: 1  
> Latest checkpoint's oldestMulti's DB: 24591  
> Latest checkpoint's oldestCommitTsXid:0  
> Latest checkpoint's newestCommitTsXid:0  
> Time of latest checkpoint: Mon 10 Mar 2025 03:03:55 PM MSK  
> Fake LSN counter for unlogged rels: 0/3E8  
> Minimum recovery ending location: 0/0  
> Min recovery ending loc's timeline: 0  
> Backup start location: 0/0  
> Backup end location: 0/0  
> End-of-backup record required: no  
> wal_level setting: replica  
> wal_log_hints setting: on  
> max_connections setting: 1000  
> max_worker_processes setting: 8  
> max_wal_senders setting: 10  
> max_prepared_xacts setting: 0  
> max_locks_per_xact setting: 64  
> track_commit_timestamp setting: off  
> Maximum data alignment: 8  
> Database block size: 8192  
> Blocks per segment of large relation: 131072  
> WAL block size: 8192  
> Bytes per WAL segment: 16777216  
> Maximum length of identifiers: 64  
> Maximum columns in an index: 32  
> Maximum size of a TOAST chunk: 1996  
> Size of a large-object chunk: 2048  
> Date/time type storage: 64-bit integers  
> Float8 argument passing: by value  
> Data page checksum version: 0  
> Mock authentication nonce: 158cb2d7552bd52d24f296e5b2d28b0b8515c5cbae26332c2721c78abd874ea1  
  
