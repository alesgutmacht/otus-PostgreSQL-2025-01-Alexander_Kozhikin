**SQL и реляционные СУБД. Введение в PostgreSQL**  

*Создана виртуальная машина под управлением redOS8.*  
*Подключение к ВМ по SSH:*  
> $ ssh-keygen  
  
*Необходимо поместить rey.pub в .ssh/authorized_keys созданной ВМ.*  
*Далее подключение (Пароль не потребуется):*  
> $ ssh user@IP  
  
  
*Установка PostgreSQL:*  
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
  
*Войти 2мя сессиями*  
> [1]$ sudo -u postgres psql  
> [1]postgres=#  
>  
> [2]$ sudo -u postgres psql  
> [2]postgres=#  
  
*Создается таблица и добавляется 2 строки*  
> [1]postgres=# BEGIN;  
> [1]postgres=*# create table persons(id serial, first_name text, second_name text);  
> [1]postgres=*# insert into persons(first_name, second_name) values('ivan', 'ivanov');  
> [1]postgres=*# insert into persons(first_name, second_name) values('petr', 'petrov');  
> [1]postgres=*# commit;  
> [1]postgres=#  
>  
> [1]postgres=# show transaction isolation level;  
> [1]read committed  
  
*Создаем транзакции в каждой сессии*  
> [1]postgres=# BEGIN;  
> [1]postgres=*#  
>  
> [2]postgres=# BEGIN;  
> [2]postgres=*#  
  
*В 1 сессии добавляем строку, но не сохраняем*  
> [1]postgres=*# insert into persons(first_name, second_name) values('sergey', 'sergeev');  
  
*По этому ао 2 сессии видим только 2 строки*  
> [2]postgres=*# select * from persons;  
> [2](2 rows)
  
*Завершаем транзакцию в 1 сессии*  
> [1]postgres=*# commit;  
  
*Теперь во 2 сессии видим 3 строки*  
> [2]postgres=*# select * from persons;  
> [2](3 rows)
> [2]postgres=*# commit;  

*Создаем repeatable read транзакцию в 1 сессии и добавляем строку*  
> [1]postgres=# BEGIN;  
> [1]postgres=*# set transaction isolation level repeatable read;  
> [1]postgres=*# show transaction isolation level;  
> [1]repeatable read  
> [1]postgres=*# insert into persons(first_name, second_name) values('sveta', 'svetova');  
  
*Создаем repeatable read транзакцию во 2 сессии, но все равно видим 3 строки*  
> [2]postgres=# BEGIN;  
> [2]postgres=*# set transaction isolation level repeatable read;  
> [2]postgres=*# show transaction isolation level;  
> [2]repeatable read  
> [2]postgres=*# select * from persons;  
> [2](3 rows)  
  
*Завершаем транзакцию в 1 сессии*  
> [1]postgres=*# commit;  
  
*Проверяем во 2 сессии, но все равно видим 3 строки*  
> [2]postgres=*# select * from persons;  
> [2](3 rows)
  
*Теперь после сохранения во 2 сессии видим 4 строки (До коммита мы видим данные, которые были на момент открытия тразакции во 2 сессии)*  
> [2]postgres=*# commit;  
> [2]postgres=*# select * from persons;  
> [2](4 rows)
  
