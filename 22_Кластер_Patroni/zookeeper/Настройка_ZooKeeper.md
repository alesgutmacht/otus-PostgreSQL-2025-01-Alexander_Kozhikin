**Установка, настройка и запуск ZooKeeper**  
  
*Загрузка и распоковка архива*  
```
https://dlcdn.apache.org/zookeeper/zookeeper-3.8.4/apache-zookeeper-3.8.4-bin.tar.gz

# useradd -r -c "Zookeeper service" zookeeper
# mkdir /opt/zookeeper /var/log/zookeeper
# chown -R zookeeper:zookeeper /opt/zookeeper /var/log/zookeeper
# su - zookeeper 
$ cd /opt/zookeeper/
$ tar zxvf /tmp/apache-zookeeper-3.8.4-bin.tar.gz
```
  
*Конфигурация*  
```
# vi /opt/zookeeper/conf/zoo.cfg

tickTime = 2000
maxSessionTimeout = 50000
syncLimit = 5
initLimit = 300
autopurge.purgeInterval = 1
autopurge.snapRetainCount = 5
snapCount = 200000
clientPort = 2181
maxClientCnxns = 100
4lw.commands.whitelist=stat
dataDir = /opt/zookeeper/data
dataLogDir = /var/log/zookeeper
dynamicConfigFile=/opt/zookeeper/conf/zoo.cfg.dynamic
```
  
*Дополнительные файлы конфигурации*  
```
На 3 серверах
# vi /opt/zookeeper/conf/zoo.cfg.dynamic

server.1=192.168.122.10:2888:3888
server.2=192.168.122.20:2888:3888
server.3=192.168.122.30:2888:3888

Сервер 1
# vi /opt/zookeeper/data/myid

1

Сервер 2
# vi /opt/zookeeper/data/myid

2

Сервер 3
# vi /opt/zookeeper/data/myid

3
```
  
*Создание конфигурации сервиса*  
```
# vi /etc/systemd/system/zookeeper.service

[Unit]
Description=ZooKeeper Service
Documentation=https://zookeeper.apache.org/
Requires=network.target
After=network.target

[Service]
Type=forking
User=zookeeper
Group=zookeeper
WorkingDirectory=/opt/zookeeper
ExecStart=/opt/zookeeper/bin/zkServer.sh start
ExecStop=/opt/zookeeper/bin/zkServer.sh stop
ExecReload=/opt/zookeeperbin/zkServer.sh restart
TimeoutSec=30
Restart=on-failure

[Install]
WantedBy=default.target

# systemctl daemon-reload

# systemctl enable zookeeper.service --now

# systemctl status zookeeper.service

● zookeeper.service - ZooKeeper Service
     Loaded: loaded (/etc/systemd/system/zookeeper.service; enabled; preset: disabled)
     Active: active (running)
```
  
*Отслеживание состояния ноды в кластере*  
```
Подробно:
$ echo stat | nc localhost 2181
Режим ноды
$ echo stat | nc localhost 2181 | grep Mode

Реплика-Follower:

Zookeeper version: 3.8.4-9316c2a7a97e1666d8f4593f34dd6fc36ecc436c, built on 2024-02-12 22:16 UTC
Clients:
 /192.168.122.20:48734[1](queued=0,recved=15075,sent=15076)
 /[0:0:0:0:0:0:0:1]:42170[0](queued=0,recved=1,sent=0)
 /192.168.122.30:58166[1](queued=0,recved=12683,sent=12683)

Latency min/avg/max: 0/0.2837/20
Received: 27775
Sent: 27775
Connections: 3
Outstanding: 0
Zxid: 0x470000003e
Mode: follower
Node count: 17

Мастер-Leader:

Zookeeper version: 3.8.4-9316c2a7a97e1666d8f4593f34dd6fc36ecc436c, built on 2024-02-12 22:16 UTC
Clients:
 /[0:0:0:0:0:0:0:1]:50026[0](queued=0,recved=1,sent=0)
 /192.168.122.10:43956[1](queued=0,recved=15196,sent=15198)

Latency min/avg/max: 0/0.2874/20
Received: 16668
Sent: 16671
Connections: 2
Outstanding: 0
Zxid: 0x470000003e
Mode: leader
Node count: 17
Proposal sizes last/min/max: 48/36/5173
```
  
*Настройка описана в статье:*  
```
https://www.dmosk.ru/miniinstruktions.php?mini=zookeeper#cluster
```
