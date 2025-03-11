**Установка PostgreSQL**  
  
*Создана 1 виртуальная машина под управлением redOS8. 192.168.122.10*  
*Подключение к ВМ по SSH:*  
> [1]\$ ssh-keygen  
  
*Необходимо поместить rey.pub в .ssh/authorized_keys созданной ВМ.*  
*Далее подключение (Пароль не потребуется):*  
> [1]\$ ssh user@192.168.122.10  
  
*Создана 2 виртуальная машина под управлением redOS8. 192.168.122.11*  
*Подключение к ВМ по SSH:*  
> [2]\$ ssh-keygen  
  
*Необходимо поместить rey.pub в .ssh/authorized_keys созданной ВМ.*  
*Далее подключение (Пароль не потребуется):*  
> [2]\$ ssh user@192.168.122.11  
  
*Установка PostgreSQL:*  
*Делается на 2 ВМ*  
> \# dnf install postgresql16 postgresql16-server  
> \# postgresql-16-setup initdb  
> \# systemctl enable postgresql-16.service --now  
> \# systemctl status postgresql-16.service  
>  
> ● postgresql-16.service - PostgreSQL 16 database server  
> Loaded: loaded (/usr/lib/systemd/system/postgresql-16.service; enabled; preset: disabled)  
> Active: active (running)  
>  
  
*Вход пользователем postgres на 1 ВМ*  
> [1]\$ sudo -u postgres psql  
> [1]postgres=\#  
  
*Создается таблица и добавляется 1 строка*  
> [1]postgres=\# create table test(c1 text);  
> CREATE TABLE  
> [1]postgres=\# insert into test values('1');  
> INSERT 0 1  
> [1]postgres=\# q  
  
*Подключение к БД ВМ 1 с ВМ 2*  
> [2]\$ psql -h 192.168.122.10 -U postgres -p 5432  
> psql: error: connection to server at "192.168.122.10", port 5432 failed: Connection refused  
> Is the server running on that host and accepting TCP/IP connections?  
> *Не получается, т.к. не указан адрес слушателя listen_addresses*  
  
*Редактируем конфигурационный файл 1 ВМ и перезапускаем кластер PostgreSQL*  
> [1]\$ vi 16/data/postgresql.conf \# listen_addresses = '192.168.122.10'  
> [1]\# systemctl restart postgresql-16.service  
  
*Пробуем подключиться снова к БД ВМ 1 с ВМ 2*  
> \$ psql -h 192.168.122.10 -U postgres -p 5432  
> psql: error: connection to server at "192.168.122.10", port 5432 failed: FATAL: no pg_hba.conf entry for host "192.168.122.11", user "postgres", database "postgres", no encryption  
> *Теперь не получается, т.к. не настроен файл pg_hba.conf*  
  
*Редактируем конфигурационный файл 1 ВМ и перезапускаем кластер PostgreSQL*  
> [1]\$ vi 16/data/pg_hba.conf  
> \# Добавляем строку host all all 192.168.122.11/24 scram-sha-256  
> [1]\# systemctl restart postgresql-16.service  
  
*Пробуем подключиться снова к БД ВМ 1 с ВМ 2*  
> [2]\$ psql -h 192.168.122.10 -U postgres -p 5432  
> Password for user postgres:  
> psql (16.6)  
> Type "help" for help.  
>  
> [2]postgres=\# conninfo  
> You are connected to database "postgres" as user "postgres" on host "192.168.122.10" at port "5432".  
> *Теперь подключение удалось*  
  
*Проверяем наличие таблицы*  
> [2]postgres=\# SELECT 1.bash 2.bash axioma_files azimuth_doc blender-3.6.11-linux-x64 books Desktop Documents Downloads env err file godot gpb_p12 grub.txt hosts_vm.txt hs_err_pid3032.log installs journalctl_patroni.txt libclang mail_vpn.txt main.py Music openvpn out.txt pdfgrep-2.1.2 Pictures pkgs.txt programming Public Python-3.7.9 scripts start_vpn.sh status_patroni.txt Templates test.md test.md~ tmt.txt version.png Videos vm _Расширенное администрирование FROM test;  
> c1  
> ----  
> 1  
> (1 rows)  
> *Видим таблицу созданную на ВМ 1*  
  
*Удаляем кластер PostgreSQL с 1 ВМ*  
> [1]\# systemctl stop postgresql-16.service  
> [1]\# dnf remove postgresql16*  
> [1]\# rm -fr --dir /var/lib/pgsql/16/  
> [1]\# systemctl status postgresql-16.service  
> Unit postgresql-16.service could not be found.  
  
*Пробуем подключиться снова к БД ВМ 1 с ВМ 2*  
> [2]\$ psql -h 192.168.122.10 -U postgres -p 5432  
> psql: error: connection to server at "192.168.122.10", port 5432 failed: Connection refused  
> Is the server running on that host and accepting TCP/IP connections?  
> *Кластер удален, по указанному адресу и порту не устанавливается соединение*  
  
