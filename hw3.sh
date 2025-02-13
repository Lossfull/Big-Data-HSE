#!/bin/bash

sudo adduser postgres

sudo apt-get update -y
sudo apt-get install -y postgresql

sudo -i -u postgres <<EOF
psql <<SQL
CREATE DATABASE metastore;
CREATE USER hive WITH PASSWORD 'hadoop12';
GRANT ALL PRIVILEGES ON DATABASE metastore TO hive;
ALTER DATABASE metastore OWNER TO hive;
SQL
EOF

sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = 'team-17-nn'/" /etc/postgresql/16/main/postgresql.conf

sudo bash -c 'echo "
host    metastore   hive    192.168.1.70/22    password
host    all         all     127.0.0.1/22      scram-sha-256
" >> /etc/postgresql/16/main/pg_hba.conf'

sudo systemctl restart postgresql
sudo systemctl status postgresql

psql -h team-17-nn -p 5432 -U hive -W -d metastore

sudo apt-get install -y postgresql-client-16
psql -h team-17-nn -p 5432 -U hive -W -d metastore

sudo -i -u hadoop <<EOF
cd /home/hadoop
wget https://dlcdn.apache.org/hive/hive-4.0.1/apache-hive-4.0.1-bin.tar.gz
tar -xvzf apache-hive-4.0.1-bin.tar.gz
cd apache-hive-4.0.1-bin/

wget https://jdbc.postgresql.org/download/postgresql-42.7.4.jar

cat <<EOL > conf/hive-site.xml
<configuration>
    <property>
        <name>hive.server2.authentication</name>
        <value>NONE</value>
    </property>
    <property>
        <name>hive.metastore.warehouse.dir</name>
        <value>/user/hive/warehouse</value>
    </property>
    <property>
        <name>hive.server2.thrift.port</name>
        <value>5433</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:postgresql://team-17-nn:5432/metastore</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>org.postgresql.Driver</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>hive</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionPassword</name>
        <value>hiveMegaPass</value>
    </property>
</configuration>
EOL

cat <<EOL >> ~/.profile
export HIVE_HOME=/home/hadoop/apache-hive-4.0.1-bin
export HIVE_CONF_DIR=\$HIVE_HOME/conf
export HIVE_AUX_JARS_PATH=\$HIVE_HOME/lib/*
export PATH=\$PATH:\$HIVE_HOME/bin
EOL

source ~/.profile
hive --version
EOF

sudo -u hadoop hdfs dfs -mkdir -p /user/hive/warehouse
sudo -u hadoop hdfs dfs -chmod 777 /tmp
sudo -u hadoop hdfs dfs -chmod 777 /user/hive/warehouse

sudo -u hadoop /home/hadoop/apache-hive-4.0.1-bin/bin/schematool -dbType postgres -initSchema

sudo -u hadoop beeline -u jdbc:hive2://team-17-jn:5433 <<EOF
SHOW DATABASES;
CREATE DATABASE test;
EOF

sudo -u hadoop hdfs dfs -put vacancies.csv /input

sudo -u hadoop beeline -u jdbc:hive2://team-17-jn:5433 <<EOF
CREATE TABLE IF NOT EXISTS test.vacancies (
    id INT,
    position_name STRING,
    employer_name STRING,
    area STRING,
    experience STRING,
    schedule STRING,
    employment STRING,
    professional_roles STRING,
    salary STRING,
    description STRING,
    key_skills ARRAY<STRING>
)
PARTITIONED BY (area STRING)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ',';

LOAD DATA INPATH '/input/vacancies.csv' INTO TABLE test.vacancies;

SELECT COUNT(*) FROM test.vacancies;
SELECT * FROM test.vacancies LIMIT 10;
EOF
