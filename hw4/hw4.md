## Шаг 0: Подготовка окружения

1. Перед выполнением убедитесь, что на клатсере запущен HDFS и YARN, а также в HDFS загружены данные.

2. Зайдите на ноду JumpNode

## Шаг 1: Установите Apache Spark и Pyspark

1. Скачайте и разархивируйте клиент Apache Spark
```
wget https://dlcdn.apache.org/spark/spark-3.5.3/spark-3.5.3-bin-hadoop3.tgz
tar xvf spark-3.5.3-bin-hadoop3.tgz
sudo mv spark-3.5.3-bin-hadoop3 /opt/spark
```
2. Установите pyspark и ipython
В консоли выполните команду
```
pip3 install pyspark
pip3 install ipython
```

## Шаг 2: Добавьте их в переменные окружения

1. Откройте .bashrc
```
nano ~/.bashrc
```

2. добавьте в конца файла следующие строки:

```
export PYSPARK_PYTHON=python3
export SPARK_HOME=/opt/spark
export PATH=$PATH:$SPARK_HOME/bin
```

3. Закройте файл и сохраните изменения
```
source ~/.bashrc
```
## Шаг 2.5:

Запустите Spark сессию с помощью pyspark
```
pyspark --master yarn
```


## Шаг 3: Работа с данными

Убедитесь, что HDFS поднят и к нему есть доступ:
```
hdfs dfs -ls /
```

Зайдите в интерактивную среду ipython:
```
ipython
```

Затем в интерактивной среде выполните следующий код для того, чтобы прочитать данные, провести над ними трансформации и сохранить данные, как таблицу.

```
#create spark session

from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("SparkJob") \
    .getOrCreate()
    
# read data form hdfs
df = spark.read.csv("hdfs://team-17-nn:9870/user/hive/data/data.csv", header=True, inferSchema=True)


filtered_df = df.filter(df["age"] > 30)

aggregated_df = df.groupBy("group").avg("age")

from pyspark.sql.functions import col
transformed_df = df.withColumn("date", col("date").cast("date"))

from pyspark.sql.functions import year
transformed_df = df.withColumn("age_in_years", year(col("date")) - col("birth_year"))

sorted_df = df.orderBy("age")

# save transformed data
transformed_df.write.saveAsTable("my_table")

# save partitioned transformed data
transformed_df.write.partitionBy("group").saveAsTable("partitioned_table")
```

## Шаг 4: Работа с Hive

Для того, чтобы проверить возможность прочитать данные с Hive:

Откройте hive 
```
hive
```
Затем выполните запрос
```
SHOW TABLES;
SELECT * FROM my_table LIMIT 10;
```

Чтобы проверить партицированную таблицу, выполните запрос:
```
SHOW PARTITIONS partitioned_table;
```