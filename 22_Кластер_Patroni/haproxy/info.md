*Установка*  
```
# dnf install haproxy
```
  
*Запуск службы*  
```
# systemctl enable haproxy.service --now
Created symlink /etc/systemd/system/multi-user.target.wants/haproxy.service → /usr/lib/systemd/system/haproxy.service.

# systemctl status haproxy.service
● haproxy.service - HAProxy Load Balancer
     Loaded: loaded (/usr/lib/systemd/system/haproxy.service; enabled; preset: disabled)
     Active: active (running)
```
