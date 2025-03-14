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
> \$ psql -c "password postgres"  
> Enter new password for user "postgres":  
  
*Просмотр и настройка параметров для отображения блокировок в журнале*  
> postgres=\# SHOW log_lock_waits ;  
> log_lock_waits  
> ----------------  
> off  
> postgres=\# SHOW deadlock_timeout ;  
> deadlock_timeout  
> ------------------  
> 1s  
> postgres=\# SHOW log_min_duration_statement;  
> log_min_duration_statement  
> ----------------------------  
> -1  
> postgres=\# ALTER SYSTEM SET log_lock_waits = on;  
> ALTER SYSTEM  
> postgres=\# ALTER SYSTEM SET deadlock_timeout = '200ms';  
> ALTER SYSTEM  
> postgres=\# SELECT pg_reload_conf();  
> pg_reload_conf  
> ----------------  
> t  
> postgres=\# SHOW log_lock_waits ;  
> log_lock_waits  
> ----------------  
> on  
> postgres=\# SHOW deadlock_timeout;  
> deadlock_timeout  
> ------------------  
> 200ms  
  
*В 1 сессии создаем БД и таблицу, наполняем ее данными*  
> [1]\$ psql  
> psql (16.8)  
> Type "help" for help.  
>  
> [1]postgres=\# create database locks;  
> CREATE DATABASE  
> [1]postgres=\# connect locks  
> You are now connected to database "locks" as user "postgres".  
> [1]locks=\# CREATE TABLE accounts(acc_no int PRIMARY KEY, amount numeric);  
> CREATE TABLE  
> [1]locks=\# INSERT INTO accounts VALUES ( 1,1000.00), (2, 2000.00), (3, 3000.00);  
> INSERT 0 3  
> [1]locks=\# select * from accounts ;  
> acc_no  | amount  
> --------+---------  
>       1 | 1000.00  
>       2 | 2000.00  
>       3 | 3000.00  
> (3 rows)  
  
*Открываем транзакцию 1 и обновляем таблицу*  
> [1]locks=\# BEGIN ;  
> BEGIN  
> [1]locks=*\# UPDATE accounts SET amount = amount - 100.00 WHERE acc_no = 1;  
> UPDATE 1  
  
*Открываем 2 транзакцию и пробуем обновить таблицу*  
> [2]\$ psql  
> psql (16.8)  
> Type "help" for help.  
>  
> [2]postgres=\# connect locks  
> You are now connected to database "locks" as user "postgres".  
> [2]locks=\# BEGIN ;  
> BEGIN  
> [2]locks=*\# UPDATE accounts SET amount = amount + 100.00 WHERE acc_no = 1;  
> *Команда UPDATE ожидает блокировку. Через 200мс информация попадет в журнал.*  
  
*Инф. о блокировках*  
> [3]locks=\# SELECT locktype, relation::REGCLASS, mode, granted, pid, pg_blocking_pids(pid) AS wait_for FROM pg_locks WHERE relation = 'accounts'::regclass;  
> locktype  | relation | mode             | granted | pid  | wait_for  
> ----------+----------+------------------+---------+------+----------  
> relation  | accounts | RowExclusiveLock | t | 2376 | {2370}  
> relation  | accounts | RowExclusiveLock | t | 2370 | {}  
> tuple     | accounts | ExclusiveLock    | t | 2376 | {2370}  
> (3 rows)  
  
*Завершаем первую транзакцию*  
> [1]locks=*\# COMMIT ;  
> COMMIT  
  
*Выполняется UPDATE 2 сессии*  
> UPDATE 1  
  
*Инф. о блокировках*  
> [3]locks=\# SELECT locktype, relation::REGCLASS, mode, granted, pid, pg_blocking_pids(pid) AS wait_for FROM pg_locks WHERE relation = 'accounts'::regclass;  
>  locktype | relation |       mode       | granted | pid  | wait_for  
> ----------+----------+------------------+---------+------+----------  
>  relation | accounts | RowExclusiveLock | t       | 2376 | {}  
> (1 row)  
  
*Завершаем вторую транзакцию*  
> [2]locks=*\# COMMIT ;  
> COMMIT  
  
*Инф. о блокировках*  
> [3]locks=\# SELECT locktype, relation::REGCLASS, mode, granted, pid, pg_blocking_pids(pid) AS wait_for FROM pg_locks WHERE relation = 'accounts'::regclass;  
>  locktype | relation | mode | granted | pid | wait_for  
> ----------+----------+------+---------+-----+----------  
> (0 rows)  
  
*Просмотр журнала*  
> [3]locks=\# ! tail /var/lib/pgsql/16/data/log/postgresql-Fri.log  
> 2025-03-14 11:55:49.917 MSK [1785] LOG: checkpoint complete: wrote 4 buffers (0.0%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.307 s, sync=0.008 s, total=0.330 s; sync files=4, longest=0.006 s, average=0.002 s; distance=9 kB, estimate=3470 kB; lsn=0/1A00708, redo lsn=0/1A006D0  
> 2025-03-14 11:57:08.029 MSK [2376] LOG: process 2376 still waiting for ShareLock on transaction 750 after 200.233 ms  
> 2025-03-14 11:57:08.029 MSK [2376] DETAIL: Process holding the lock: 2370. Wait queue: 2376.  
> 2025-03-14 11:57:08.029 MSK [2376] CONTEXT: while updating tuple (0,7) in relation "accounts"  
> 2025-03-14 11:57:08.029 MSK [2376] STATEMENT: UPDATE accounts SET amount = amount + 100.00 WHERE acc_no = 1;  
> 2025-03-14 11:58:50.017 MSK [2376] LOG: process 2376 acquired ShareLock on transaction 750 after 102188.218 ms  
> 2025-03-14 11:58:50.017 MSK [2376] CONTEXT: while updating tuple (0,7) in relation "accounts"  
> 2025-03-14 11:58:50.017 MSK [2376] STATEMENT: UPDATE accounts SET amount = amount + 100.00 WHERE acc_no = 1;  
> 2025-03-14 12:00:49.939 MSK [1785] LOG: checkpoint starting: time  
> 2025-03-14 12:00:50.062 MSK [1785] LOG: checkpoint complete: wrote 2 buffers (0.0%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.105 s, sync=0.005 s, total=0.124 s; sync files=2, longest=0.004 s, average=0.003 s; distance=1 kB, estimate=3123 kB; lsn=0/1A00B28, redo lsn=0/1A00AF0  
  
*Изменение 1 строки из 3 сессий*  
*Создаем удобную View*  
> [1]locks=\# CREATE VIEW locks_v AS  
> SELECT pid,  
> locktype,  
> CASE locktype  
> WHEN 'relation' THEN relation::regclass::text  
> WHEN 'transactionid' THEN transactionid::text  
> WHEN 'tuple' THEN relation::regclass::text||':'||tuple::text  
> END AS lockid,  
> mode,  
> granted  
> FROM pg_locks  
> WHERE locktype in ('relation','transactionid','tuple')  
> AND (locktype != 'relation' OR relation = 'accounts'::regclass);  
> CREATE VIEW  
  
*В 1 сессии обновляем строку и смотрим блокировки*  
> [1]locks=\# BEGIN;  
> BEGIN  
> [1]locks=*\# SELECT txid_current(), pg_backend_pid();  
> txid_current  | pg_backend_pid  
> --------------+----------------  
> 756           | 2370  
> (1 row)  
> [1]locks=*\# UPDATE accounts SET amount = amount + 100.00 WHERE acc_no = 1;  
> UPDATE 1  
> [1]locks=*\# SELECT * FROM locks_v WHERE pid = 2370;  
> pid   | locktype      | lockid   | mode             | granted  
> ------+---------------+----------+------------------+---------  
> 2370  | relation      | accounts | RowExclusiveLock | t  
> 2370  | transactionid | 756      | ExclusiveLock    | t  
> (2 rows)  
> *Блокировка таблицы и своей транзакции*  
  
*Во 2 сессии обновляем строку и смотрим блокировки*  
> [2]locks=\# BEGIN ;  
> BEGIN  
> [2]locks=*\# SELECT txid_current(), pg_backend_pid();  
> txid_current  | pg_backend_pid  
> --------------+----------------  
> 757           | 2376  
> (1 row)  
>  
> [2]locks=*\# UPDATE accounts SET amount = amount + 100.00 WHERE acc_no = 1;  
> *Запрос завис в ожидании*  
  
*Посмотрим из 1 сессии на блокировки по 2 сессии*  
> [1]locks=*\# SELECT * FROM locks_v WHERE pid = 2376;  
> pid   | locktype      | lockid      | mode             | granted  
> ------+---------------+-------------+------------------+---------  
> 2376  | relation      | accounts    | RowExclusiveLock | t  
> 2376  | transactionid | 757         | ExclusiveLock    | t  
> 2376  | tuple         | accounts:12 | ExclusiveLock    | t  
> 2376  | transactionid | 756         | ShareLock        | f  
> (4 rows)  
> *Видим такие же блокировки как и для 1 сессии и еще видим то что строка заблокирована (granted f) и блокировку tuple по тому, что пытаемся редактировать 1 объект из 2 сессий*  
  
*В 3 сессии обновляем строку и смотрим блокировки*  
> [3]locks=\# BEGIN ;  
> BEGIN  
> [3]locks=*\# SELECT txid_current(), pg_backend_pid();  
> txid_current  | pg_backend_pid  
> --------------+----------------  
>           758 |           2171  
> (1 row)  
>  
> [3]locks=*\# UPDATE accounts SET amount = amount + 100.00 WHERE acc_no = 1;  
> *Запрос завис в ожидании*  
  
*Посмотрим из 1 сессии на блокировки по 3 сессии*  
> [1]locks=!\# SELECT * FROM locks_v WHERE pid = 2171;  
>  pid  |   locktype    |   lockid    |       mode       | granted  
> ------+---------------+-------------+------------------+---------  
>  2171 | relation      | accounts    | RowExclusiveLock | t  
>  2171 | tuple         | accounts:12 | ExclusiveLock    | f  
>  2171 | transactionid | 758         | ExclusiveLock    | t  
> (3 rows)  
> *Видим блокировку tuple, но т.к. такая блокировка уже есть она false*  
  
*В 4 сессии обновляем строку и смотрим блокировки*  
> [4]locks=\# BEGIN ;  
> BEGIN  
> [4]locks=*\# SELECT txid_current(), pg_backend_pid();  
>  txid_current | pg_backend_pid  
> --------------+----------------  
>           760 |           3099  
> (1 row)  
>  
> locks=*\# UPDATE accounts SET amount = amount - 100.00 WHERE acc_no = 1;  
> *Запрос завис в ожидании*  
  
*Посмотрим из 1 сессии на блокировки по 4 сессии*  
> [1]locks=*\# SELECT * FROM locks_v WHERE pid = 3099;  
>  pid  |   locktype    |   lockid    |       mode       | granted  
> ------+---------------+-------------+------------------+---------  
>  3099 | relation      | accounts    | RowExclusiveLock | t  
>  3099 | transactionid | 760         | ExclusiveLock    | t  
>  3099 | tuple         | accounts:12 | ExclusiveLock    | f  
> (3 rows)  
> *Аналогично сессии 3*  
  
*Общую картину можно увидеть в представлении pg_stat_activity, находясь в 1 сессии*  
> [1]locks=*\# SELECT pid, wait_event_type, wait_event, pg_blocking_pids(pid) FROM pg_stat_activity WHERE backend_type = 'client backend' ORDER BY pid;  
>  pid  | wait_event_type |  wait_event   | pg_blocking_pids  
> ------+-----------------+---------------+------------------  
>  2171 | Lock            | tuple         | {2376}  
>  2370 |                 |               | {}  
>  2376 | Lock            | transactionid | {2370}  
>  3099 | Lock            | tuple         | {2376,2171}  
> (4 rows)  
  
*Далее начиная с 1 сессии завершаем транзакции и видим как выполняются обновления таблицы и освобождаются блокировки.*  
  
*COMMIT в 1 сесии и вывод информации о блокировках*  
> [1]locks=*\# COMMIT ;  
> COMMIT  
>  
> [1]locks=\# SELECT * FROM locks_v WHERE pid = 2370;  
>  pid | locktype | lockid | mode | granted  
> -----+----------+--------+------+---------  
> (0 rows)  
>  
> [1]locks=\# SELECT * FROM locks_v WHERE pid = 2376;  
>  pid  |   locktype    |  lockid  |       mode       | granted  
> ------+---------------+----------+------------------+---------  
>  2376 | relation      | accounts | RowExclusiveLock | t  
>  2376 | transactionid | 757      | ExclusiveLock    | t  
> (2 rows)  
>  
> [1]locks=\# SELECT * FROM locks_v WHERE pid = 2171;  
>  pid  |   locktype    |  lockid  |       mode       | granted  
> ------+---------------+----------+------------------+---------  
>  2171 | relation      | accounts | RowExclusiveLock | t  
>  2171 | transactionid | 757      | ShareLock        | f  
>  2171 | transactionid | 758      | ExclusiveLock    | t  
> (3 rows)  
>  
> [1]locks=\# SELECT * FROM locks_v WHERE pid = 3099;  
>  pid  |   locktype    |  lockid  |       mode       | granted  
> ------+---------------+----------+------------------+---------  
>  3099 | relation      | accounts | RowExclusiveLock | t  
>  3099 | transactionid | 760      | ExclusiveLock    | t  
>  3099 | transactionid | 757      | ShareLock        | f  
> (3 rows)  
>  
> [1]locks=\# SELECT pid, wait_event_type, wait_event, pg_blocking_pids(pid) FROM pg_stat_activity WHERE backend_type = 'client backend' ORDER BY pid;  
>  pid  | wait_event_type |  wait_event   | pg_blocking_pids  
> ------+-----------------+---------------+------------------  
>  2171 | Lock            | transactionid | {2376}  
>  2370 |                 |               | {}  
>  2376 | Client          | ClientRead    | {}  
>  3099 | Lock            | transactionid | {2376}  
> (4 rows)  
> *Далее аналогично высвобождаются блокировки и применяются UPDATE*  
  
*Итоговое представление активностей*  
> [1]locks=\# SELECT pid, wait_event_type, wait_event, pg_blocking_pids(pid) FROM pg_stat_activity WHERE backend_type = 'client backend' ORDER BY pid;  
>  pid  | wait_event_type | wait_event | pg_blocking_pids  
> ------+-----------------+------------+------------------  
>  2171 | Client          | ClientRead | {}  
>  2370 |                 |            | {}  
>  2376 | Client          | ClientRead | {}  
>  3099 | Client          | ClientRead | {}  
> (4 rows)  
  
  
*Взаимоблокировка 3 транзакций*  
  
*В 1 сессии заблокируем строку в разделяемом режиме*  
> [1]locks=\# BEGIN ;  
> BEGIN  
> [1]locks=*\# SELECT txid_current(), pg_backend_pid();  
>  txid_current | pg_backend_pid  
> --------------+----------------  
>           765 |           2370  
> (1 row)  
>  
> [1]locks=*\# SELECT * FROM accounts WHERE acc_no = 1 FOR SHARE;  
>  acc_no | amount  
> --------+---------  
>       1 | 1400.00  
> (1 row)  
  
*Во 2 сессии пытаемся обновить строку*  
> [2]locks=\# BEGIN ;  
> BEGIN  
> [2]locks=*\# SELECT txid_current(), pg_backend_pid();  
>  txid_current | pg_backend_pid  
> --------------+----------------  
>           766 |           2376  
> (1 row)  
>  
> [2]locks=*\# UPDATE accounts SET amount = amount + 100.00 WHERE acc_no = 1;  
> *Запрос завис в ожидании т.к. строки уже заблокирована для чтения в 1 сессии*  
  
*Посмотрим из 1 сессии на блокировки по 1 и 2 сессии*  
> [1]locks=*\# SELECT * FROM locks_v WHERE pid = 2370;  
>  pid  |   locktype    |  lockid  |     mode      | granted  
> ------+---------------+----------+---------------+---------  
>  2370 | relation      | accounts | RowShareLock  | t  
>  2370 | transactionid | 765      | ExclusiveLock | t  
> (2 rows)  
>  
> [1]locks=*\# SELECT * FROM locks_v WHERE pid = 2376;  
>  pid  |   locktype    |   lockid    |       mode       | granted  
> ------+---------------+-------------+------------------+---------  
>  2376 | relation      | accounts    | RowExclusiveLock | t  
>  2376 | tuple         | accounts:18 | ExclusiveLock    | t  
>  2376 | transactionid | 765         | ShareLock        | f  
>  2376 | transactionid | 766         | ExclusiveLock    | t  
> (4 rows)  
  
*В 3 сессии просмотрим содержимое таблицы, при этом повторно заблокируем строку*  
> [3]locks=\# BEGIN ;  
> BEGIN  
> [3]locks=*\# SELECT txid_current(), pg_backend_pid();  
>  txid_current | pg_backend_pid  
> --------------+----------------  
>           767 |           2171  
> (1 row)  
>  
> [3]locks=*\# SELECT * FROM accounts WHERE acc_no = 1 FOR SHARE;  
>  acc_no | amount  
> --------+---------  
>       1 | 1400.00  
> (1 row)  
  
*Посмотрим из 1 сессии на блокировки по 3 сессии*  
> [1]locks=*\# SELECT * FROM locks_v WHERE pid = 2171;  
>  pid  |   locktype    |  lockid  |     mode      | granted  
> ------+---------------+----------+---------------+---------  
>  2171 | relation      | accounts | RowShareLock  | t  
>  2171 | transactionid | 767      | ExclusiveLock | t  
> (2 rows)  
> *Как и в 1 сессии*  
  
*Создаем расширение*  
> [1]locks=*\# CREATE EXTENSION pgrowlocks;  
> CREATE EXTENSION  
  
*Видим что 2 транзакции блокируют строку*  
> locks=*\# SELECT * FROM pgrowlocks('accounts') gx  
> -[ RECORD 1 ]-------------  
> locked_row | (0,18)  
> locker     | 2  
> multi      | t  
> xids       | {765,767}  
> modes      | {Share,Share}  
> pids       | {2370,2171}  
  
*После COMMIT в 1 сессии транзакция 2 попытается обновить строку, но из-за наличия блокировки из 3 сессии ничего не получится и сессия будет висеть*  
> [1]locks=*\# COMMIT ;  
> COMMIT  
  
*Посмотрим блокировки из 1 сессии*  
> [1]locks=\# SELECT * FROM locks_v WHERE pid = 2370;  
>  pid | locktype | lockid | mode | granted  
> -----+----------+--------+------+---------  
> (0 rows)  
>  
> [1]locks=\# SELECT * FROM locks_v WHERE pid = 2376;  
>  pid  |   locktype    |   lockid    |       mode       | granted  
> ------+---------------+-------------+------------------+---------  
>  2376 | relation      | accounts    | RowExclusiveLock | t  
>  2376 | transactionid | 767         | ShareLock        | f  
>  2376 | tuple         | accounts:18 | ExclusiveLock    | t  
>  2376 | transactionid | 766         | ExclusiveLock    | t  
> (4 rows)  
>  
> [1]locks=\# SELECT * FROM locks_v WHERE pid = 2171;  
>  pid  |   locktype    |  lockid  |     mode      | granted  
> ------+---------------+----------+---------------+---------  
>  2171 | relation      | accounts | RowShareLock  | t  
>  2171 | transactionid | 767      | ExclusiveLock | t  
> (2 rows)  
  
*COMMIT в 3 сессии позволит обновить таблицу в сессии 2*  
> [3]locks=*\# COMMIT ;  
> COMMIT  
> [2]UPDATE 1  
  
*Посмотрим блокировки из 1 сессии*  
> locks=\# SELECT * FROM pgrowlocks('accounts') gx  
> -[ RECORD 1 ]-----------------  
> locked_row | (0,18)  
> locker     | 766  
> multi      | f  
> xids       | {766}  
> modes      | {"No Key Update"}  
> pids       | {2376}  
> *Осталась только 1 не завершенная транзакция из 2 сессии*  
  
*Научились разбираться с блокировками*  
