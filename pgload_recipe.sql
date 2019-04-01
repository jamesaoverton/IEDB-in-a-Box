-- pgloader (https://github.com/dimitri/pgloader) statements for moving data from the MariaDB
-- instance to the PostgreSQL instance.

LOAD DATABASE
     FROM mysql://root@127.0.0.1/upstream
     INTO postgresql://iedbadmin@127.0.0.1/iedb
-- These parameters are possibly a bit conservative, but with these it requires about 23 minutes
-- to load all of the data on my system, and the memory usage doesn't blow up (which it does with
-- the defaults). It might be worth experimenting with higher sizes, though. For more info, see:
-- https://pgloader.readthedocs.io/en/latest/pgloader.html
-- https://pgloader.readthedocs.io/en/latest/ref/mysql.html
WITH batch rows = 10, prefetch rows = 100, workers = 2,
     concurrency = 1, max parallel create index = 1
SET MySQL PARAMETERS
    net_read_timeout  = '120', net_write_timeout = '120';
