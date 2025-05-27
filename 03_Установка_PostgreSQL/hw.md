**Установка PostgreSQL**  
  
*Создана 1 виртуальная машина под управлением redOS8. 192.168.122.10*  
*Подключение к ВМ по SSH:*  
> [1]\$ ssh-keygen  
  
*Необходимо поместить key.pub в .ssh/authorized_keys созданной ВМ.*  
*Далее подключение (Пароль не потребуется):*  
> [1]\$ ssh user@192.168.122.10  
  
*Создана 2 виртуальная машина под управлением redOS8. 192.168.122.11*  
*Подключение к ВМ по SSH:*  
> [2]\$ ssh-keygen  
  
*Необходимо поместить key.pub в .ssh/authorized_keys созданной ВМ.*  
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
> [2]postgres=\# \conninfo  
> You are connected to database "postgres" as user "postgres" on host "192.168.122.10" at port "5432".  
> *Теперь подключение удалось*  
  
*Проверяем наличие таблицы*  
> [2]postgres=\# SELECT \* FROM test;  
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
  
*Docker*  
  
*Устанавливем Docker, запускаем службу и скачиваем образ Postgres*  
> \# dnf install docker-ce docker-compose  
> Installed:  
> container-selinux-2:2.169.0-3.red80.noarch                    containerd-1.7.24-1.red80.x86_64  
> criu-3.17.1-3.red80.x86_64                                    docker-ce-4:27.4.1-2.red80.x86_64  
> docker-ce-cli-4:27.4.1-2.red80.x86_64                         docker-ce-cli-doc-4:27.4.1-2.red80.noarch  
> docker-compose-2.32.1-1.red80.x86_64                          docker-compose-switch-1.0.5-2.red80.x86_64  
> libbsd-0.10.0-9.red80.x86_64                                  libcgroup-3.1.0-2.red80.x86_64  
> libnet-1.2-5.red80.x86_64                                     runc-2:1.1.14-1.red80.x86_64  
>   
> Complete!  
>   
> \# systemctl enable docker.service --now  
> Created symlink /etc/systemd/system/multi-user.target.wants/docker.service → /usr/lib/systemd/system/docker.service.  
>   
> \# docker pull postgres  
> Using default tag: latest  
> latest: Pulling from library/postgres  
> 6e909acdb790: Pull complete  
> fec99121872b: Pull complete  
> 133acbc970df: Pull complete  
> e02d97322fc6: Pull complete  
> db9643c6baf3: Pull complete  
> 9bcedd9434e7: Pull complete  
> fc8982ec96d9: Pull complete  
> 1824bd6b75d7: Pull complete  
> fbad2bf2d5e6: Pull complete  
> 221788d72606: Pull complete  
> e5f43b682bc0: Pull complete  
> e7a2d9e24ab0: Pull complete  
> a96cb29b0d13: Pull complete  
> 140970538145: Pull complete  
> Digest: sha256:c522082e582d6267630d0ac3a857e262f4994012e2f841fc9eb65e7bd0500e20  
> Status: Downloaded newer image for postgres:latest  
> docker.io/library/postgres:latest  
>   
> \# docker images  
> REPOSITORY   TAG       IMAGE ID       CREATED       SIZE  
> postgres     latest    76e3e031d245   2 weeks ago   438MB  
  
*Создаем сеть для контейнеров Docker*  
> \# docker network create pg_net  
> 35168884a76bc8e5442fe92a8c153cfc5679ed59a212c7ddb8ee0dbed67e8e08  
  
*Запускаем контейнер с сервером*  
> \# docker run --name pg_server --network pg_net -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d -v /var/lib/pgsql:/var/lib/postgresql/data postgres  
> 0026c9a4e244462819636002105fbeb9ef712b9f6db363ae63b258743a158e31  
  
*Запускаем контейнер с клиентом*  
> \# docker run --name pg_client --network pg_net -e POSTGRES_PASSWORD=postgres -d postgres  
> d3c52d686e324f55334e005e900c6b7e499322a9df126f362649726dc21bfd2d  
  
*Просматриваем запущенные конетейнеры*  
> \# docker ps -a  
> CONTAINER ID   IMAGE      COMMAND                  CREATED              STATUS              PORTS                                       NAMES  
> d3c52d686e32   postgres   "docker-entrypoint.s…"   19 seconds ago       Up 18 seconds       5432/tcp                                    pg_client  
> 0026c9a4e244   postgres   "docker-entrypoint.s…"   About a minute ago   Up About a minute   0.0.0.0:5432->5432/tcp, :::5432->5432/tcp   pg_server  
  
*С клиентского контейнера подключаемся к БД сервера и создаем там базу, таблицу со строкой данных*  
> \# docker exec -it pg_client bash  
> root@d3c52d686e32:/\# su - postgres  
> postgres@d3c52d686e32:~\$ psql -h pg_server -U postgres  
> Password for user postgres:  
> psql (17.4 (Debian 17.4-1.pgdg120+2))  
> Type "help" for help.  
>   
> postgres=\# CREATE DATABASE my_db;  
> CREATE DATABASE  
> postgres=\# c my_db  
> You are now connected to database "my_db" as user "postgres".  
> my_db=\# CREATE TABLE my_table (column1 integer);  
> CREATE TABLE  
> my_db=\# INSERT INTO my_table VALUES (1847);  
> INSERT 0 1  
> my_db=\# SELECT \* FROM my_table;  
> column1  
> ---------  
> 1847  
> (1 row)  
  
*Удаляем контейнер с сервером*  
> \# docker rm -f 0026c9a4e244  
> 0026c9a4e244  
  
*Видим что сервера нет*  
> \# docker ps -a  
> CONTAINER ID   IMAGE      COMMAND                  CREATED          STATUS          PORTS      NAMES  
> d3c52d686e32   postgres   "docker-entrypoint.s…"   14 minutes ago   Up 14 minutes   5432/tcp   pg_client  
>   
> postgres@d3c52d686e32:~\$ psql -h pg_server -U postgres  
> psql: error: could not translate host name "pg_server" to address: Name or service not known  
> *Подключиться с клиента не удалось, т.к. сервер удален*  
  
*Запускаем новый контейнер с сервером*  
> \# docker run --name pg_server --network pg_net -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d -v /var/lib/pgsql:/var/lib/postgresql/data postgres  
> d6630519cae8c637cdbb626710d8373d556800962743393da21b3d6d694abe87  
  
*Проверяем запущенные конетейнеры*  
> \# docker ps -a  
> CONTAINER ID   IMAGE      COMMAND                  CREATED          STATUS          PORTS                                       NAMES  
> d6630519cae8   postgres   "docker-entrypoint.s…"   18 seconds ago   Up 17 seconds   0.0.0.0:5432->5432/tcp, :::5432->5432/tcp   pg_server  
> d3c52d686e32   postgres   "docker-entrypoint.s…"   16 minutes ago   Up 16 minutes   5432/tcp                                    pg_client  
  
*Подключаемся с клиента и видим что в новом контейнере все данные на месте*  
> \# docker exec -it pg_client bash  
> root@d3c52d686e32:/\# su - postgres  
> postgres@d3c52d686e32:~\$ psql -h pg_server -U postgres  
> Password for user postgres:  
> psql (17.4 (Debian 17.4-1.pgdg120+2))  
> Type "help" for help.  
>   
> postgres=\# c my_db  
> You are now connected to database "my_db" as user "postgres".  
> my_db=\# SELECT \* FROM my_table;  
> column1  
> ---------  
> 1847  
> (1 row)  
  
*Для установки Docker на ВМ с RHEL (redOS) рекомендую статью*  
> https://blog.sedicomm.com/2018/07/18/ustanovka-docker-i-obuchenie-bazovym-manipulyatsiyam-s-kontejnerami-v-centos-i-rhel-7-6-chast-1/  
