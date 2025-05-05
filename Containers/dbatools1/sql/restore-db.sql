USE [master]
RESTORE DATABASE [Northwind] FROM  DISK = N'/tmp/northwind.bak' WITH  FILE = 1,  MOVE N'Northwind' TO N'/var/opt/mssql/data/northwnd.mdf',  MOVE N'Northwind_log' TO N'/var/opt/mssql/data/northwnd.ldf',  NOUNLOAD,  STATS = 5

GO

USE [master]
RESTORE DATABASE [pubs] FROM  DISK = N'/tmp/pubs.bak' WITH  FILE = 1,  MOVE N'pubs' TO N'/var/opt/mssql/data/pubs.mdf',  MOVE N'pubs_log' TO N'/var/opt/mssql/data/pubs_log.ldf',  NOUNLOAD,  STATS = 5

GO

USE [master]
RESTORE DATABASE [AdventureWorks2022] FROM DISK = '/tmp/AdventureWorks2022.bak' 
WITH MOVE 'AdventureWorks2022' TO '/var/opt/mssql/data/AdventureWorks2022_Data.mdf', 
    MOVE 'AdventureWorks2022_log' TO '/var/opt/mssql/data/AdventureWorks2022_log.ldf',
    FILE = 1,
    NOUNLOAD,
    STATS = 5;
GO

USE [master]
ALTER AUTHORIZATION ON DATABASE::[Northwind] TO [sqladmin]
ALTER AUTHORIZATION ON DATABASE::[pubs] TO [sqladmin]
ALTER AUTHORIZATION ON DATABASE::[AdventureWorks2022] TO [sqladmin]

GO

CREATE DATABASE DatabaseAdmin
GO
