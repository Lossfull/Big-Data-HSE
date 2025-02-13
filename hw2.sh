#!/bin/bash

cat <<EOL > /usr/local/hadoop/etc/hadoop/yarn-site.xml
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.env-whitelist</name>
        <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_HOME,PATH,LANG,TZ,HADOOP_MAPRED_HOME</value>
    </property>
</configuration>
EOL

cat <<EOL > /usr/local/hadoop/etc/hadoop/mapred-site.xml
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>mapreduce.application.classpath</name>
        <value>\$HADOOP_HOME/share/hadoop/mapreduce/*:\$HADOOP_HOME/share/hadoop/mapreduce/lib/*</value>
    </property>
</configuration>
EOL

for NODE in team-17-dn-0 team-17-dn-1; do
    rsync -av /usr/local/hadoop hadoop@"${NODE}":/usr/local/
done

sudo -u hadoop /usr/local/hadoop/sbin/start-yarn.sh

jps | grep -E "ResourceManager|NodeManager|JobHistoryServer"

mapred --daemon start historyserver

sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/yarn

sudo bash -c 'cat <<EOL > /etc/nginx/sites-available/yarn
server {
    listen 8088 default_server;
    location / {
        proxy_pass http://team-17-nn:8088;
    }
}
EOL'

sudo ln -sf /etc/nginx/sites-available/yarn /etc/nginx/sites-enabled/yarn
sudo systemctl restart nginx

sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/dh

sudo bash -c 'cat <<EOL > /etc/nginx/sites-available/dh
server {
    listen 19888 default_server;
    location / {
        proxy_pass http://team-17-nn:19888;
    }
}
EOL'

sudo ln -sf /etc/nginx/sites-available/dh /etc/nginx/sites-enabled/dh
sudo systemctl restart nginx

echo "YARN: http://176.109.91.19:8088"
echo "History Server: http://176.109.91.19:19888"
