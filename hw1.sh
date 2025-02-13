#!/bin/bash

HADOOP_VERSION="3.4.0"
HADOOP_URL="https://dlcdn.apache.org/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz"
HADOOP_HOME="/usr/local/hadoop"
JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"

JOURNALNODE="team-17-jn"
NAMENODE="team-17-nn"
DATANODES=("team-17-dn-0" "team-17-dn-1")
JUMP_NODE="176.109.91.19"

sudo apt-get update -y
sudo apt-get install -y openjdk-11-jdk

sudo adduser --disabled-password --gecos "" hadoop

sudo -u hadoop bash <<EOF
ssh-keygen -q -t ed25519 -N "" -f ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
EOF

for NODE in "${DATANODES[@]}" "$NAMENODE" "$JOURNALNODE"; do
    sshpass -p "" ssh-copy-id -o StrictHostKeyChecking=no hadoop@"$NODE"
done

sudo -u hadoop bash <<EOF
wget -q "$HADOOP_URL" -O hadoop.tar.gz
tar -xf hadoop.tar.gz
mv hadoop-$HADOOP_VERSION "$HADOOP_HOME"
EOF

cat <<EOL | sudo tee -a /home/hadoop/.bashrc
export HADOOP_HOME=$HADOOP_HOME
export JAVA_HOME=$JAVA_HOME
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
EOL

source /home/hadoop/.bashrc

sudo chown -R hadoop:hadoop "$HADOOP_HOME"
cd "$HADOOP_HOME/etc/hadoop"

sudo -u hadoop bash <<EOF
echo 'export JAVA_HOME=$JAVA_HOME' >> hadoop-env.sh

cat <<EOL > core-site.xml
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://$NAMENODE:9000</value>
    </property>
</configuration>
EOL

cat <<EOL > hdfs-site.xml
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>${#DATANODES[@]}</value>
    </property>
</configuration>
EOL

printf "%s\n" "${DATANODES[@]}" > workers
EOF

for NODE in "${DATANODES[@]}"; do
    rsync -av "$HADOOP_HOME" hadoop@"$NODE":/usr/local/
done

sudo -u hadoop hdfs namenode -format
sudo -u hadoop "$HADOOP_HOME/sbin/start-dfs.sh"

sudo apt-get install -y nginx

cat <<EOL | sudo tee /etc/nginx/sites-available/hdfs
server {
    listen 9870 default_server;
    location / {
        proxy_pass http://$NAMENODE:9870;
    }
}
EOL

sudo ln -sf /etc/nginx/sites-available/hdfs /etc/nginx/sites-enabled/
sudo systemctl restart nginx

echo "HDFS доступен по адресу: http://$JUMP_NODE:9870"
