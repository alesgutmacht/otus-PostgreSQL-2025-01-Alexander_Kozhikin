



# dnf install haproxy

```
# systemctl enable haproxy.service --now
Created symlink /etc/systemd/system/multi-user.target.wants/haproxy.service → /usr/lib/systemd/system/haproxy.service.

# systemctl status haproxy.service
● haproxy.service - HAProxy Load Balancer
     Loaded: loaded (/usr/lib/systemd/system/haproxy.service; enabled; preset: disabled)
     Active: active (running) since Fri 2025-05-16 16:43:06 MSK; 3min 13s ago
    Process: 815 ExecStartPre=/usr/sbin/haproxy -f $CONFIG -f $CFGDIR -c -q $OPTIONS (code=exited, status=0/SUCCESS)
   Main PID: 829 (haproxy)
     Status: "Ready."
      Tasks: 3 (limit: 2328)
     Memory: 22.5M
        CPU: 616ms
     CGroup: /system.slice/haproxy.service
             ├─829 /usr/sbin/haproxy -Ws -f /etc/haproxy/haproxy.cfg -f /etc/haproxy/conf.d -p /run/haproxy.pid
             └─847 /usr/sbin/haproxy -Ws -f /etc/haproxy/haproxy.cfg -f /etc/haproxy/conf.d -p /run/haproxy.pid
```
