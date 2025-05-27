*Создание конфигурационного файла Patroni*  
```
Выполняется от имени пользователя postgres
$ patroni --generate-config > patroni.yml
После ввода пароля конфигурационный файл создается в каталоге /var/lib/pgsql.
Настройки в файле будут соответствовать настройкам дейсвующего кластера Postgres.
Файл необходимо переместить в каталог Patroni /etc/patroni и назначить владельца.

# mv /var/lib/pgsql/patroni.yml /etc/patroni
# chown root:root /etc/patroni/patroni.yml

```
*Проверка конфигурационного файла Patroni*  
```
$ patroni --validate-config /etc/patroni/patroni.yml
Если файл корректный, то вывод ничего не вернет
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
