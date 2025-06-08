**Тестирование отказоустойчивости**  
  
*Фиксируем исходное состояние кластера и убеждаемся в синхронности реплик*  
```
[postgres@red8-pg16-node1 ~]$ patronictl -c /etc/patroni/patroni.yml list
+ Cluster: pg16-cluster (7503063564493600161) -----------+----+-----------+
| Member          | Host           | Role    | State     | TL | Lag in MB |
+-----------------+----------------+---------+-----------+----+-----------+
| red8-pg16-node1 | 192.168.122.10 | Replica | streaming | 53 |         0 |
| red8-pg16-node2 | 192.168.122.20 | Replica | streaming | 53 |         0 |
| red8-pg16-node3 | 192.168.122.30 | Leader  | running   | 53 |           |
+-----------------+----------------+---------+-----------+----+-----------+

[user@red8-pg16-work ~]$ /usr/pgsql-16/bin/psql -h 192.168.122.100 -U postgres -p 5000
Password for user postgres: 
psql (16.8)
Type "help" for help.

postgres=# SELECT pid,usesysid,usename,client_addr,client_hostname,state,sync_state,reply_time FROM pg_stat_replication;
 pid  | usesysid |  usename   |  client_addr   | client_hostname |   state   | sync_state |          reply_time           
------+----------+------------+----------------+-----------------+-----------+------------+-------------------------------
 1029 |    16388 | replicator | 192.168.122.20 | red8-pg16-node2 | streaming | async      | 2025-06-08 10:07:01.754982+03
 1061 |    16388 | replicator | 192.168.122.10 | red8-pg16-node1 | streaming | async      | 2025-06-08 10:07:01.75156+03
(2 rows)
```
  
*Ручная симуляция сбоя сервиса Patroni*  
*Остановка сервиса Patroni на мастере*  
```
[root@red8-pg16-node3 ~]# systemctl stop patroni.service

[postgres@red8-pg16-node1 ~]$ patronictl -c /etc/patroni/patroni.yml list
+ Cluster: pg16-cluster (7503063564493600161) -----------+----+-----------+
| Member          | Host           | Role    | State     | TL | Lag in MB |
+-----------------+----------------+---------+-----------+----+-----------+
| red8-pg16-node1 | 192.168.122.10 | Leader  | running   | 54 |           |
| red8-pg16-node2 | 192.168.122.20 | Replica | streaming | 54 |         0 |
+-----------------+----------------+---------+-----------+----+-----------+

[user@red8-pg16-work ~]$ /usr/pgsql-16/bin/psql -h 192.168.122.100 -U postgres -p 5000
Password for user postgres: 
psql (16.8)
Type "help" for help.

postgres=# SELECT pid,usesysid,usename,client_addr,client_hostname,state,sync_state,reply_time FROM pg_stat_replication;
 pid  | usesysid |  usename   |  client_addr   | client_hostname |   state   | sync_state |          reply_time           
------+----------+------------+----------------+-----------------+-----------+------------+-------------------------------
 8735 |    16388 | replicator | 192.168.122.20 | red8-pg16-node2 | streaming | async      | 2025-06-08 10:17:29.750664+03
(1 row)
```
  
*Лог остановки Postgres на ноде с отказавшим сервисом Patroni*  
```
2025-06-08 10:15:25.036 MSK [957] LOG:  received fast shutdown request
2025-06-08 10:15:25.043 MSK [957] LOG:  aborting any active transactions
2025-06-08 10:15:25.047 MSK [2633] FATAL:  terminating connection due to administrator command
2025-06-08 10:15:25.049 MSK [992] FATAL:  terminating connection due to administrator command
2025-06-08 10:15:25.051 MSK [997] FATAL:  terminating connection due to administrator command
2025-06-08 10:15:25.055 MSK [957] LOG:  background worker "logical replication launcher" (PID 1028) exited with exit code 1
2025-06-08 10:15:25.060 MSK [960] LOG:  shutting down
2025-06-08 10:15:25.076 MSK [960] LOG:  checkpoint starting: shutdown immediate
2025-06-08 10:15:25.118 MSK [960] LOG:  checkpoint complete: wrote 0 buffers (0.0%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.001 s, sync=0.001 s, total=0.048 s; sync files=0, longest=0.000 s, average=0.000 s; distance=0 kB, estimate=0 kB; lsn=0/90258B0, redo lsn=0/90258B0
2025-06-08 10:15:25.142 MSK [957] LOG:  database system is shut down
```
  
*Лог перехода Postgres к готовности для подключения (Стал лидером)*  
```
2025-06-08 10:15:25.127 MSK [1082] LOG:  replication terminated by primary server
2025-06-08 10:15:25.127 MSK [1082] DETAIL:  End of WAL reached on timeline 53 at 0/9025928.
2025-06-08 10:15:25.127 MSK [1082] FATAL:  could not send end-of-streaming message to primary: server closed the connection unexpectedly
		This probably means the server terminated abnormally
		before or while processing the request.
	no COPY in progress
2025-06-08 10:15:25.129 MSK [1009] LOG:  invalid record length at 0/9025928: expected at least 24, got 0
2025-06-08 10:15:25.142 MSK [8703] FATAL:  could not connect to the primary server: connection to server at "192.168.122.30", port 5432 failed: server closed the connection unexpectedly
		This probably means the server terminated abnormally
		before or while processing the request.
2025-06-08 10:15:25.142 MSK [1009] LOG:  waiting for WAL to become available at 0/9025940
2025-06-08 10:15:27.189 MSK [1009] LOG:  received promote request
2025-06-08 10:15:27.189 MSK [1009] LOG:  redo done at 0/90258B0 system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 1060.88 s
2025-06-08 10:15:27.202 MSK [1009] LOG:  selected new timeline ID: 54
2025-06-08 10:15:27.276 MSK [1009] LOG:  archive recovery complete
2025-06-08 10:15:27.289 MSK [1007] LOG:  checkpoint starting: force
2025-06-08 10:15:27.297 MSK [1002] LOG:  database system is ready to accept connections
2025-06-08 10:15:27.318 MSK [1007] LOG:  checkpoint complete: wrote 2 buffers (0.0%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.005 s, sync=0.004 s, total=0.029 s; sync files=2, longest=0.002 s, average=0.002 s; distance=0 kB, estimate=0 kB; lsn=0/9025990, redo lsn=0/9025958

Перевод в режим лидера занял 2 секунды
```
  
*Лог переподключения Postgres к новому лидеру*  
```
2025-06-08 10:15:25.130 MSK [1015] LOG:  replication terminated by primary server
2025-06-08 10:15:25.130 MSK [1015] DETAIL:  End of WAL reached on timeline 53 at 0/9025928.
2025-06-08 10:15:25.131 MSK [1015] FATAL:  could not send end-of-streaming message to primary: server closed the connection unexpectedly
		This probably means the server terminated abnormally
		before or while processing the request.
	no COPY in progress
2025-06-08 10:15:25.137 MSK [1012] LOG:  invalid record length at 0/9025928: expected at least 24, got 0
2025-06-08 10:15:25.157 MSK [8624] FATAL:  could not connect to the primary server: connection to server at "192.168.122.30", port 5432 failed: Connection refused
		Is the server running on that host and accepting TCP/IP connections?
2025-06-08 10:15:25.157 MSK [1012] LOG:  waiting for WAL to become available at 0/9025940
2025-06-08 10:15:27.191 MSK [1003] LOG:  received SIGHUP, reloading configuration files
2025-06-08 10:15:27.193 MSK [1003] LOG:  parameter "primary_conninfo" changed to "dbname=postgres user=replicator passfile=/var/lib/pgsql/pgpass host=192.168.122.10 port=5432 sslmode=prefer application_name=red8-pg16-node2 gssencmode=prefer channel_binding=prefer"
2025-06-08 10:15:27.218 MSK [8652] LOG:  started streaming WAL from primary at 0/9000000 on timeline 53
2025-06-08 10:15:27.289 MSK [8652] LOG:  replication terminated by primary server
2025-06-08 10:15:27.289 MSK [8652] DETAIL:  End of WAL reached on timeline 53 at 0/9025928.
2025-06-08 10:15:27.289 MSK [8652] LOG:  fetching timeline history file for timeline 54 from primary server
2025-06-08 10:15:27.303 MSK [8652] FATAL:  terminating walreceiver process due to administrator command
2025-06-08 10:15:27.305 MSK [1012] LOG:  new target timeline is 54
2025-06-08 10:15:27.327 MSK [8653] LOG:  started streaming WAL from primary at 0/9000000 on timeline 54

Переподключение к новому лидеру заняло 2 секунды.
```
  
*Запуск сервиса Patroni*  
```
[root@red8-pg16-node3 ~]# systemctl start patroni.service

[postgres@red8-pg16-node1 ~]$ patronictl -c /etc/patroni/patroni.yml list
+ Cluster: pg16-cluster (7503063564493600161) -----------+----+-----------+
| Member          | Host           | Role    | State     | TL | Lag in MB |
+-----------------+----------------+---------+-----------+----+-----------+
| red8-pg16-node1 | 192.168.122.10 | Leader  | running   | 54 |           |
| red8-pg16-node2 | 192.168.122.20 | Replica | streaming | 54 |         0 |
| red8-pg16-node3 | 192.168.122.30 | Replica | streaming | 54 |         0 |
+-----------------+----------------+---------+-----------+----+-----------+

[redosvm@red8-pg16-work ~]$ /usr/pgsql-16/bin/psql -h 192.168.122.100 -U postgres -p 5000
Password for user postgres: 
psql (16.8)
Type "help" for help.

postgres=# SELECT pid,usesysid,usename,client_addr,client_hostname,state,sync_state,reply_time FROM pg_stat_replication;
  pid  | usesysid |  usename   |  client_addr   | client_hostname |   state   | sync_state |          reply_time           
-------+----------+------------+----------------+-----------------+-----------+------------+-------------------------------
  8735 |    16388 | replicator | 192.168.122.20 | red8-pg16-node2 | streaming | async      | 2025-06-08 10:30:00.013961+03
 14534 |    16388 | replicator | 192.168.122.30 | red8-pg16-node3 | streaming | async      | 2025-06-08 10:29:58.917318+03
(2 rows)
```
