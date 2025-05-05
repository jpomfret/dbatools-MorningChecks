# loop until sql server is up and ready
for i in {1..50};
do
    /opt/mssql-tools18/bin/sqlcmd -S localhost -d master -Q "SELECT @@VERSION" -No
    if [ $? -ne 0 ];then
        sleep 2
    fi
done


# create sqladmin with dbatools.IO password and disable sa
/opt/mssql-tools18/bin/sqlcmd -S localhost -d master -i /tmp/create-admin.sql -No

# change the default login to sqladmin instead of sa
export SQLCMDUSER=sqladmin

# create QALogin and database for refresh demo
/opt/mssql-tools18/bin/sqlcmd -S localhost -d master -i /tmp/create-dbtorefresh.sql -No

# rename the server 
/opt/mssql-tools18/bin/sqlcmd -d master -Q "EXEC sp_dropserver @@SERVERNAME" -No
/opt/mssql-tools18/bin/sqlcmd -S localhost -d master -Q "EXEC sp_addserver 'dbatools2', local" -No

# import the certificate and creates endpoint 
/opt/mssql-tools18/bin/sqlcmd -S localhost -d master -i /tmp/create-endpoint.sql -No