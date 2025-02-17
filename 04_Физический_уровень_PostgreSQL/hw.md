**Физический уровень PostgreSQL**  
  
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
>     Active: active (running) since Mon 2025-02-17 17:26:22 MSK; 6min ago  
>       Docs: https://www.postgresql.org/docs/16/static/  
>    Process: 1837 ExecStartPre=/usr/pgsql-16/bin/postgresql-16-check-db-dir ${PGDATA} (code=exited, status=0/SUCCESS)  
>  
  
*Вход пользователем postgres*  
> $ sudo -u postgres psql  
> postgres=#  
  
*Создается таблица и добавляется 2 строки*  
> postgres=# create table test(c1 text);  
> CREATE TABLE  
> postgres=# insert into test values('1');  
> INSERT 0 1  
> postgres=# \q  
  
*Останавливаем PostgreSQL:*  
> \# systemctl stop postgresql-16.service  
  
*Создаем новый диск и подключаем к ВМ:*  
> $ sudo -u qemu qemu-img create -f qcow2 -o preallocation=full abs_path/pgsql_data.qcow2 5G
> $ virsh attach-disk --domain red8_pg16 abs_path/pgsql_data.qcow2 --target vdb --live --config
  
*Видим новый подключенный диск vdb*  
> # lsblk  
> NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS  
> vda                     252:0    0   30G  0 disk   
> ├─vda1                  252:1    0    1M  0 part   
> ├─vda2                  252:2    0    1G  0 part /boot  
> └─vda3                  252:3    0   29G  0 part   
>   ├─ro_red8--pg16-root  253:0    0   16G  0 lvm  /  
>   ├─ro_red8--pg16-swap  253:1    0    2G  0 lvm  [SWAP]  
>   └─ro_red8--pg16-pgsql 253:2    0   11G  0 lvm  /var/lib/pgsql  
> vdb                     252:16   0    5G  0 disk   
  
*Подключаем новый диск к группе lvm*  
> # fdisk /dev/vdb # Создаем раздел  
> # lsblk # Информация о дисках  
> vdb                     252:16   0    5G  0 disk   
> └─vdb1                  252:17   0    5G  0 part   
> # pvcreate /dev/vdb1  
> # vgextend ro_red8-pg16 /dev/vdb1  
> # lvcreate ro_red8-pg16 -l 100%FREE -n pgsql_data  
> # mkfs.ext4 /dev/mapper/ro_red8--pg16-pgsql_data  
>  
> # lsblk # Информация о дисках (видим новый диск в группе lvm)  
> NAME                         MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS  
> vda                          252:0    0   30G  0 disk   
> ├─vda1                       252:1    0    1M  0 part   
> ├─vda2                       252:2    0    1G  0 part /boot  
> └─vda3                       252:3    0   29G  0 part   
>   ├─ro_red8--pg16-root       253:0    0   16G  0 lvm  /  
>   ├─ro_red8--pg16-swap       253:1    0    2G  0 lvm  [SWAP]  
>   └─ro_red8--pg16-pgsql      253:2    0   11G  0 lvm  /var/lib/pgsql  
> vdb                          252:16   0    5G  0 disk   
> └─vdb1                       252:17   0    5G  0 part   
>   └─ro_red8--pg16-pgsql_data 253:3    0    5G  0 lvm  
> 
> 
> 
> 
> 
























