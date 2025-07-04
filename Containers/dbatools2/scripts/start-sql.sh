# load up environment variables
export $(xargs < /tmp/sapassword.env)
export $(xargs < /tmp/sqlcmd.env)
export PATH=$PATH:/opt/mssql-tools/bin

# set the configs
cp /tmp/mssql.conf /var/opt/mssql/mssql.conf

wget https://github.com/microsoft/go-sqlcmd/releases/download/v0.2.0/sqlcmd-v0.2.0-linux-arm64.tar.bz2
tar -xvf sqlcmd-v0.2.0-linux-arm64.tar.bz2
mkdir /opt/mssql-tools /opt/mssql-tools/bin
cp sqlcmd /opt/mssql-tools/bin
chmod +x /opt/mssql-tools/bin/sqlcmd

# startup, wait for it to finish starting
# then run the setup script
/opt/mssql/bin/sqlservr & sleep 20 & /tmp/configure.sh