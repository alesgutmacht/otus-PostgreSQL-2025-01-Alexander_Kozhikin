**SQL и реляционные СУБД. Введение в PostgreSQL**  

*Создана виртуальная машина под управлением redOS8.*  
*Подключение к ВМ по SSH:*  
  
> $ ssh-keygen  
  
*Необходимо поместить rey.pub в .ssh/authorized_keys созданной ВМ*  
*Далее подключение (Пароль не потребуется)*  
  
> $ ssh user@IP  
  
  
*Установка PostgreSQL*  
  
> \# dnf install postgresql16 postgresql16-server  
> \# postgresql-16-setup initdb  
> \# systemctl enable postgresql-16.service --now  
> \# systemctl status postgresql-16.service  
>  
> ● postgresql-16.service - PostgreSQL 16 database server  
>     Loaded: loaded (/usr/lib/systemd/system/postgresql-16.service; enabled; preset: disabled)  
>     Active: active (running) since Sun 2025-02-16 21:26:33 MSK; 28s ago  
>       Docs: https://www.postgresql.org/docs/16/static/  
>    Process: 1837 ExecStartPre=/usr/pgsql-16/bin/postgresql-16-check-db-dir ${PGDATA} (code=exited, status=0/SUCCESS)  
>  
  
