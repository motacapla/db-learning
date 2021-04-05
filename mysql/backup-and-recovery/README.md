# References
https://dev.mysql.com/doc/refman/8.0/en/backup-and-recovery.html
https://qiita.com/Tocyuki/items/f34ca92b8bf6e0014923
http://www.tohoho-web.com/ex/mysql-mysqldump.html

# Physical (Raw) Versus Logical Backups
## Physical backup
### How to backup
- Copy directories and files

### How to restore
- Replace files with backup

### Pros
- Faster than logical backup because they involve only file copying without conversion
- Output is more compact than logical backup
- Can include log or configuration files
- Portable to other machines

### Cons
- Granularity ranges is only table (InnoDB : one table is composed of multiple files, MyISAM : one table is composed of 1 file)
- Backups can be performed while the MySQL server is not running. 
If the server is running, it is necessary to perform appropriate locking so that the server does not change database contents during the backup. 

## Logical backup
### How to backup
- Query to obtain database structure and content information: SELECT ... INTO OUTFILE

### How to restore
- Query: LOAD DATA

### Pros
- Backup and restore granularity is available at the server level (all databases), database level (all tables in a particular database), or table level

### Cons
- Slower than physical backup
- Output is larger than for physical backup, particularly when saved in text format
- Cannot include log or configuration files

# Online Versus Offline Backups
## Online
### Pros
- The backup is less intrusive to other clients, which can connect to the MySQL server during the backup and may be able to access data depending on what operations they need to perform.
### Cons
- Care must be taken to impose appropriate locking so that data modifications do not take place that would compromise backup integrity.

## Offline
### Pros
- Clients can be affected adversely because the server is unavailable during backup. 
For that reason, such backups are often taken from a replica that can be taken offline without harming availability.
### Cons
- The backup procedure is simpler because there is no possibility of interference from client activity

Recovery in online is more harder than backup

# Local Versus Remote Backups
## Local
Backup is performed on the same host where the MySQL server runs

## Remote
Backup is done from a different host

# Snapshot Backups
Some file system implementations enable “snapshots” to be taken. 
These provide logical copies of the file system at a given point in time, without requiring a physical copy of the entire file system. 
(For example, the implementation may use copy-on-write techniques so that only parts of the file system modified after the snapshot time need be copied.) 
MySQL itself does not provide the capability for taking file system snapshots. 
It is available through third-party solutions such as Veritas, LVM, or ZFS.

# Full Versus Incremental Backups
## Full backup
- All data managed by a MySQL server will be backup

## Incremental backup
- Uses server's binary log, which the server uses to record data changes

# Full Versus Point-in-Time (Incremental) Recovery
## Full recovery
- All data will be restored from a full backup

## Point-in-Time(=Incremental) recovery
- Incremental recovery is recovery of changes made during a given time span
- Point-in-time recovery is based on the binary log and typically follows a full recovery from the backup files that restores the server to its state when the backup was made.
Then the data changes written in the binary log files are applied as incremental recovery to redo data modifications and bring the server up to the desired point in time.

# Hands-on
Confirmed with mysqldump

## Result
### Data
mysql> select * from tomoya.pet;
+----+------+
| id | name |
+----+------+
|  1 | fish |
|  2 | cat  |
|  3 | dog  |
+----+------+
3 rows in set (0.00 sec)

### Backup
root@ebc0e3141cd6:/# mysqldump -uroot -pblah --single-transaction --flush-logs --master-data=2 --all-databases > backup.sql

### Drop table
root@ebc0e3141cd6:/# mysql -uroot -pblah
mysql> DROP TABLE tomoya.pet;
Query OK, 0 rows affected (0.03 sec)

### Restore
root@ebc0e3141cd6:/# mysql -uroot -pblah < backup.sql 

### Verify
root@ebc0e3141cd6:/# mysql -uroot -pblah
mysql> use tomoya
Database changed

mysql> show tables;
+------------------+
| Tables_in_tomoya |
+------------------+
| pet              |
+------------------+
1 row in set (0.00 sec)

mysql> select * from pet;
+----+------+
| id | name |
+----+------+
|  1 | fish |
|  2 | cat  |
|  3 | dog  |
+----+------+
3 rows in set (0.00 sec)

