*Для работы keepalived придется отключить SELinux*  
```
# vi /etc/selinux/config
SELINUX=disabled
# reboot
```
  
*Установка*  
```
# dnf install keepalived
```



# vi /usr/libexec/keepalived/haproxy_check.sh

#!/bin/bash
/bin/kill -0 `cat /var/run/haproxy/haproxy.pid`

# chmod 700 /usr/libexec/keepalived/haproxy_check.sh
# chmod +x /usr/libexec/keepalived/haproxy_check.sh



```
# systemctl enable keepalived.service --now
Created symlink /etc/systemd/system/multi-user.target.wants/keepalived.service → /usr/lib/systemd/system/keepalived.service.

# systemctl status keepalived.service 
● keepalived.service - LVS and VRRP High Availability Monitor
     Loaded: loaded (/usr/lib/systemd/system/keepalived.service; enabled; preset: disabled)
     Active: active (running) since Fri 2025-05-16 16:42:51 MSK; 57s ago
   Main PID: 821 (keepalived)
      Tasks: 2 (limit: 2328)
     Memory: 8.0M
        CPU: 147ms
     CGroup: /system.slice/keepalived.service
             ├─821 /usr/sbin/keepalived --dont-fork -D
             └─844 /usr/sbin/keepalived --dont-fork -D

```


```
[root@red8-haproxy1 ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: enp1s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:22:d4:42 brd ff:ff:ff:ff:ff:ff
    inet 192.168.122.40/24 brd 192.168.122.255 scope global noprefixroute enp1s0
       valid_lft forever preferred_lft forever
    inet 192.168.122.100/24 scope global secondary enp1s0
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:fe22:d442/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
```

```
[root@red8-haproxy2 ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: enp1s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:5a:6a:13 brd ff:ff:ff:ff:ff:ff
    inet 192.168.122.50/24 brd 192.168.122.255 scope global noprefixroute enp1s0
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:fe5a:6a13/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
```

# systemctl stop haproxy.service 

```
[root@red8-haproxy2 ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: enp1s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:5a:6a:13 brd ff:ff:ff:ff:ff:ff
    inet 192.168.122.50/24 brd 192.168.122.255 scope global noprefixroute enp1s0
       valid_lft forever preferred_lft forever
    inet 192.168.122.100/24 scope global secondary enp1s0
       valid_lft forever preferred_lft forever
    inet6 fe80::5054:ff:fe5a:6a13/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
```
  
Для отслеживания проблем к строке запуска добавляем ключ -l:
vi /etc/systemd/system/multi-user.target.wants/keepalived.service
ExecStart=/usr/sbin/keepalived --dont-fork -l $KEEPALIVED_OPTIONS
# systemctl daemon-reload
# systemctl restart keepalived.service






