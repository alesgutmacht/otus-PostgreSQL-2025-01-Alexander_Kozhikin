*Установка*  
```
# dnf install install patroni patroni-zookeeper

python3-jmespath-1.0.0-5.red80.noarch
python3-prettytable-0.7.2-30.red80.noarch
python3-ydiff-1.2-7.red80.noarch
libpq-17.4-2.red80.x86_64
patroni-4.0.5-3.red80.noarch
python3-boto3-1.34.47-1.red80.noarch
python3-botocore-1.34.47-1.red80.noarch
python3-click-8.1.7-1.red80.noarch
python3-psycopg2-2.9.6-1.red80.x86_64
python3-pysyncobj-0.3.13-3.red80.noarch
python3-s3transfer-0.10.1-1.red80.noarch
python3-kazoo-2.8.0-7.red80.noarch
patroni-zookeeper-4.0.5-3.red80.noarch
```
  
*Создание конфигурационного файла Patroni*  
```
Выполняется от имени пользователя postgres
$ patroni --generate-config > patroni.yml
После ввода пароля конфигурационный файл создается в каталоге /var/lib/pgsql.
Настройки в файле будут соответствовать настройкам дейсвующего кластера Postgres.
Файл необходимо переместить в каталог Patroni /etc/patroni и назначить владельца.

# mv /var/lib/pgsql/patroni.yml /etc/patroni
# chown postgres:postgres /etc/patroni/patroni.yml

```
*Проверка конфигурационного файла Patroni*  
```
$ patroni --validate-config /etc/patroni/patroni.yml
Если файл корректный, то вывод ничего не вернет
```
  
*Настройка*  
```
# chown -R postgres:postgres /etc/patroni/
# chmod 700 /etc/patroni/

Postgres должен быть остановлен перез запуском Patroni.
На репликах данные кластера Postgres должны быть удалены.

# systemctl stop postgresql-16.service
# rm -fr /var/lib/pgsql/16/data/*

# systemctl enable patroni.service --now
# systemctl status patroni.service

● patroni.service - Runners to orchestrate a high-availability PostgreSQL
     Loaded: loaded (/usr/lib/systemd/system/patroni.service; enabled; preset: disabled)
     Active: active (running)
```
  
*Изменение параметров Postgres*  
```
$ patronictl -c /etc/patroni/patroni.yml edit-config pg16-cluster --pg "shared_buffers = 130MB"
--- 
+++ 
@@ -117,7 +117,7 @@
     pg_stat_statements.max: 10000
     pg_stat_statements.save: false
     pg_stat_statements.track: all
-    shared_buffers: 129MB
+    shared_buffers: 130MB
     shared_preload_libraries: pg_stat_statements,auto_explain
     track_commit_timestamp: 'off'
     unix_socket_directories: /var/run/postgresql

Apply these changes? [y/N]: y
Configuration changed

$ patronictl -c /etc/patroni/patroni.yml restart pg16-cluster
+ Cluster: pg16-cluster (7503063564493600161) -----------+----+-----------+-----------------+------------------------------+
| Member          | Host           | Role    | State     | TL | Lag in MB | Pending restart | Pending restart reason       |
+-----------------+----------------+---------+-----------+----+-----------+-----------------+------------------------------+
| red8-pg16-node1 | 192.168.122.10 | Replica | streaming | 48 |         0 | *               | shared_buffers: 129MB->130MB |
| red8-pg16-node2 | 192.168.122.20 | Leader  | running   | 48 |           | *               | shared_buffers: 129MB->130MB |
| red8-pg16-node3 | 192.168.122.30 | Replica | streaming | 48 |         0 | *               | shared_buffers: 129MB->130MB |
+-----------------+----------------+---------+-----------+----+-----------+-----------------+------------------------------+
When should the restart take place (e.g. 2025-05-21T09:59)  [now]: 
Are you sure you want to restart members red8-pg16-node1, red8-pg16-node2, red8-pg16-node3? [y/N]: y
Restart if the PostgreSQL version is less than provided (e.g. 9.5.2)  []: 
Success: restart on member red8-pg16-node1
Success: restart on member red8-pg16-node2
Success: restart on member red8-pg16-node3

$ psql -c "show shared_buffers;"
 shared_buffers 
----------------
 130MB
(1 row)
```
  
*Переключение лидера вручную*  
```
[postgres@red8-pg16-node1 ~]$ patronictl -c /etc/patroni/patroni.yml switchover
Current cluster topology
+ Cluster: pg16-cluster (7503063564493600161) -----------+----+-----------+
| Member          | Host           | Role    | State     | TL | Lag in MB |
+-----------------+----------------+---------+-----------+----+-----------+
| red8-pg16-node1 | 192.168.122.10 | Replica | streaming | 51 |         0 |
| red8-pg16-node2 | 192.168.122.20 | Leader  | running   | 51 |           |
| red8-pg16-node3 | 192.168.122.30 | Replica | streaming | 51 |         0 |
+-----------------+----------------+---------+-----------+----+-----------+
Primary [red8-pg16-node2]: 
Candidate ['red8-pg16-node1', 'red8-pg16-node3'] []: red8-pg16-node3
When should the switchover take place (e.g. 2025-06-07T15:14 )  [now]: 
Are you sure you want to switchover cluster pg16-cluster, demoting current leader red8-pg16-node2? [y/N]: y
2025-06-07 14:14:21.67936 Successfully switched over to "red8-pg16-node3"
+ Cluster: pg16-cluster (7503063564493600161) -----------+----+-----------+
| Member          | Host           | Role    | State     | TL | Lag in MB |
+-----------------+----------------+---------+-----------+----+-----------+
| red8-pg16-node1 | 192.168.122.10 | Replica | streaming | 51 |         0 |
| red8-pg16-node2 | 192.168.122.20 | Replica | stopped   |    |   unknown |
| red8-pg16-node3 | 192.168.122.30 | Leader  | running   | 51 |           |
+-----------------+----------------+---------+-----------+----+-----------+
[postgres@red8-pg16-node1 ~]$ patronictl -c /etc/patroni/patroni.yml list
+ Cluster: pg16-cluster (7503063564493600161) -----------+----+-----------+
| Member          | Host           | Role    | State     | TL | Lag in MB |
+-----------------+----------------+---------+-----------+----+-----------+
| red8-pg16-node1 | 192.168.122.10 | Replica | streaming | 52 |         0 |
| red8-pg16-node2 | 192.168.122.20 | Replica | streaming | 52 |         0 |
| red8-pg16-node3 | 192.168.122.30 | Leader  | running   | 52 |           |
+-----------------+----------------+---------+-----------+----+-----------+
[postgres@red8-pg16-node1 ~]$ 
```
