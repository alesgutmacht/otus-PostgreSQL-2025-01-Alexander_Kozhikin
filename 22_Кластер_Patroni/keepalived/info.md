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
  
*Скрипт проверки работы HAProxy*  
```
# vi /usr/libexec/keepalived/haproxy_check.sh

#!/bin/bash
/bin/kill -0 `cat /var/run/haproxy.pid`

# chmod 700 /usr/libexec/keepalived/haproxy_check.sh
# chmod +x /usr/libexec/keepalived/haproxy_check.sh
```
  
*Запуск сервиса*  
```
# systemctl enable keepalived.service --now
Created symlink /etc/systemd/system/multi-user.target.wants/keepalived.service → /usr/lib/systemd/system/keepalived.service.

# systemctl status keepalived.service 
● keepalived.service - LVS and VRRP High Availability Monitor
     Loaded: loaded (/usr/lib/systemd/system/keepalived.service; enabled; preset: disabled)
     Active: active (running)
```
  
*Изменение настроек сервиса*  
```
Для отслеживания проблем к строке запуска добавляем ключ -l:
vi /etc/systemd/system/multi-user.target.wants/keepalived.service
ExecStart=/usr/sbin/keepalived --dont-fork -l $KEEPALIVED_OPTIONS
# systemctl daemon-reload
# systemctl restart keepalived.service
```
