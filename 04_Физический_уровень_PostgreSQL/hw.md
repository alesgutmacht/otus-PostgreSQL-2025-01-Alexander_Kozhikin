**Физический уровень PostgreSQL**  
  
*Создана виртуальная машина под управлением redOS8.*  
*Подключение к ВМ по SSH:*  
> $ ssh-keygen  
  
*Необходимо поместить key.pub в .ssh/authorized_keys созданной ВМ.*  
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
>     Active: active (running)  
>  
  
*Вход пользователем postgres*  
> $ sudo -u postgres psql  
> postgres=\#  
  
*Создается таблица и добавляется 1 строка*  
> postgres=\# create table test(c1 text);  
> CREATE TABLE  
> postgres=\# insert into test values('1');  
> INSERT 0 1  
> postgres=\# \q  
  
*Останавливаем PostgreSQL:*  
> \# systemctl stop postgresql-16.service  
  
*Создаем новый диск и подключаем к ВМ:*  
> $ sudo -u qemu qemu-img create -f qcow2 -o preallocation=full abs_path/pgsql_data.qcow2 5G  
> $ sudo virsh attach-disk --domain red8_pg16 abs_path/pgsql_data.qcow2 --target vdb --live --config  
  
*Видим новый подключенный диск vdb*  
> \# lsblk  
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
> \# fdisk /dev/vdb \# Создаем раздел  
> \# lsblk \# Информация о дисках  
> vdb                     252:16   0    5G  0 disk   
> └─vdb1                  252:17   0    5G  0 part   
> \# pvcreate /dev/vdb1  
> \# vgextend ro_red8-pg16 /dev/vdb1  
> \# lvcreate ro_red8-pg16 -l 100%FREE -n pgsql_data  
> \# mkfs.ext4 /dev/mapper/ro_red8--pg16-pgsql_data  
>  
> \# lsblk \# Информация о дисках (видим новый диск в группе lvm)  
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
> \# mkdir /pgsql_data  
> \# vi /etc/fstab \# Добавляем запись для автоматического монтирования /dev/mapper/ro_red8--pg16-pgsql_data  
> \# reboot now  
  
*Новый диск добавлен и примонтирован к системе*  
> $ df -h /pgsql_data/  
> Filesystem                            Size  Used Avail Use% Mounted on  
> /dev/mapper/ro_red8--pg16-pgsql_data  4.9G   24K  4.6G   1% /pgsql_data  
  
*Останавливаем PostgreSQL*  
> \# systemctl stop postgresql-16.service   
> \# systemctl status postgresql-16.service   
> ○ postgresql-16.service - PostgreSQL 16 database server  
>      Loaded: loaded (/usr/lib/systemd/system/postgresql-16.service; enabled; preset: disabled)  
>     Drop-In: /etc/systemd/system/postgresql-16.service.d  
>              └─override.conf  
>      Active: inactive (dead)  
  
*Назначаем владельца каталога и переносим данные*  
> \# chown -R postgres:postgres /pgsql_data/  
> \# mv /var/lib/pgsql/16/ /pgsql_data/  
  
*Попытка запустить кластер*  
> \# systemctl start postgresql-16.service   
> Job for postgresql-16.service failed because the control process exited with error code.  
> \# Ошибка из-за того что данных нет в дефолтном $PGDATA  
  
*Создаем (если нет) директорию и файл содержащий настройки PostgeSQL,*  
*Перезапускаем службу и убеждаемся что данные на новом месте*  
> \# mkdir /etc/systemd/system/postgresql-16.service.d  
> \# vi /etc/systemd/system/postgresql-16.service.d/postgresql-16.conf  
> \# systemctl daemon-reload  
> \# systemctl start postgresql-16.service  
> \# systemctl status postgresql-16.service  
> ● postgresql-16.service - PostgreSQL 16 database server  
>      Loaded: loaded (/usr/lib/systemd/system/postgresql-16.service; enabled; preset: disabled)  
>     Drop-In: /etc/systemd/system/postgresql-16.service.d  
>              └─override.conf  
>      Active: active (running)  
>   
> \# sudo -u postgres psql -c \"show data_directory;\"  
>    data_directory    
> ---------------------  
>  /pgsql_data/16/data  
  
*Проверяем созданную таблицу (Видим ранее созданную таблицу с 1 столбцом c1 и значенией "1")*  
> \# sudo -u postgres psql -c "select * from test;"  
>  c1   
> ----  
>  1  
> (1 row)  
  
*Теперь надо переподключить диск к другой ВМ*  
*Создана новая виртуальная машина под управлением redOS8 и установлен PostgreSQL16*  
  
*На старой ВМ:*  
*Останавливаем службу PostgeSQL*  
> \# systemctl stop postgresql-16.service   
> \# systemctl status postgresql-16.service   
> ○ postgresql-16.service - PostgreSQL 16 database server  
>      Loaded: loaded (/usr/lib/systemd/system/postgresql-16.service; enabled; preset: disabled)  
>     Drop-In: /etc/systemd/system/postgresql-16.service.d  
>              └─override.conf  
>      Active: inactive (dead)  
  
*Отключаем переопределение расположения кластера в файловой системе,*  
*переименовав директорию службы (начнут работать первоначальные настройки)*  
> \# mv /etc/systemd/system/postgresql-16.service.d /etc/systemd/system/postgresql-16.service.d_   
  
*Копируем БД в первоначальное расположение и запускаем ее на старом месте*  
> \# cp -a /pgsql_data/16/ /var/lib/pgsql/  
  
Запускаем PostgreSQL  
> \# systemctl daemon-reload  
> \# systemctl start postgresql-16.service  
> \# systemctl status postgresql-16.service  
> ● postgresql-16.service - PostgreSQL 16 database server  
>      Loaded: loaded (/usr/lib/systemd/system/postgresql-16.service; enabled; preset: disabled)  
>     Drop-In: /etc/systemd/system/postgresql-16.service.d  
>              └─override.conf  
>      Active: active (running)  
> \# sudo -u postgres psql -c "show data_directory;"  
>      data_directory     
> ------------------------  
>  /var/lib/pgsql/16/data  
  
*На подключенном диске хранится копия БД и надо этот диск перенести в другую систему.*  
*Работа с lvm:*  
*Отключаем автоматическое монтирование*  
> \# vi /etc/fstab  
*Отмонтировать раздел*  
> \# umount /pgsql_data  
*Деактивировать раздел*  
> \# lvchange -a n /dev/ro_red8-pg16/pgsql_data  
*Отделить раздел в отдельную группу*  
> \# vgsplit -n /dev/ro_red8-pg16/pgsql_data ro_red8-pg16 export_group  
>   New volume group "export_group" successfully split from "ro_red8-pg16"  
*Деактивировать группу*  
> \# vgchange -a n export_group   
>   0 logical volume(s) in volume group "export_group" now active  
*Экспортировать группу*  
> \# vgexport export_group   
>   Volume group "export_group" successfully exported  
*Отключить диск от ВМ*  
> $ sudo virsh detach-disk --domain red8_pg16-install --persistent --live --target vdb  
> Disk detached successfully  
  
*На новой ВМ:*  
*Подключить диск к другой ВМ*  
> $ sudo virsh attach-disk --domain red8_pg16-clone abs_path/pgsql_data.qcow2 --target vdb --live --config  
> Disk attached successfully  
  
*Видим группу*  
> \# pvs  
>   PV         VG           Fmt  Attr PSize   PFree  
>   /dev/vda3  ro_red8-pg16 lvm2 a--  <29.00g    0   
>   /dev/vdb1  export_group lvm2 ax-   <5.00g    0  
  
*Импортировать группу lvm*  
> \# vgimport export_group   
>   Volume group "export_group" successfully imported  
  
*Видим группу*  
> \# vgs  
>   VG           \#PV \#LV \#SN Attr   VSize   VFree  
>   export_group   1   1   0 wz--n-  <5.00g    0   
>   ro_red8-pg16   1   3   0 wz--n- <29.00g    0   
  
*Активируем группу*  
> \# vgchange -a y export_group  
>   1 logical volume(s) in volume group "export_group" now active  
  
*Видим раздел на диске, можно его монтировать*  
> \# lsblk  
> NAME                        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS  
> vda                         252:0    0   30G  0 disk   
> ├─vda1                      252:1    0    1M  0 part  
> ├─vda2                      252:2    0    1G  0 part /boot  
> └─vda3                      252:3    0   29G  0 part  
>   ├─ro_red8--pg16-root      253:0    0   16G  0 lvm  /  
>   ├─ro_red8--pg16-swap      253:1    0    2G  0 lvm  [SWAP]  
>   └─ro_red8--pg16-pgsql     253:2    0   11G  0 lvm  /var/lib/pgsql  
> vdb                         252:16   0    5G  0 disk   
> └─vdb1                      252:17   0    5G  0 part   
>   └─export_group-pgsql_data 253:3    0    5G  0 lvm  
  
*Монтируем*  
> \# mkdir /pgsql_data  
> \# vi /etc/fstab \# Добавляем запись для автоматического монтирования /dev/mapper/export_group-pgsql_data  
> \# reboot now  
  
*Редактируем расположение данных кластера*  
> \# vi /etc/systemd/system/postgresql-16.service.d/postgresql-16.conf  
  
*Запускаем PostgreSQL*  
> \# systemctl daemon-reload  
> \# systemctl start postgresql-16.service  
> \# systemctl status postgresql-16.service  
> ● postgresql-16.service - PostgreSQL 16 database server  
>      Loaded: loaded (/usr/lib/systemd/system/postgresql-16.service; disabled; preset: disabled)  
>     Drop-In: /etc/systemd/system/postgresql-16.service.d  
>              └─postgresql-16.conf  
>      Active: active (running)  
> \# sudo -u postgres psql -c "show data_directory;"  
>    data_directory    
> ---------------------  
>  /pgsql_data/16/data  
  
*Проверяем созданную таблицу (Видим ранее созданную таблицу с 1 столбцом c1 и значенией "1")*  
> \# sudo -u postgres psql -c "select * from test;"  
>  c1   
> ----  
>  1  
> (1 row)  
  
*Вывод:*  
*Научились перемещать данные кластера на физическом уровне,*  
*как внутри 1 файловой системы,*  
*так и в файловую систему другой виртуальной машины.*  
  
*Перенастройка директории (data_directory) для Red Hat в этой статье:*  
*https://gist.github.com/saichander17/41e1ce4a884b733dc78c89f5266ceb36*  
  
