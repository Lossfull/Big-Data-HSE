## Шаг 0: Подготовка

предполагается, что все шаги с предыдущих домашних заданий выполнены, в том числе развернутый spark.

## Шаг 1: Установка, запуск и настройка airflow
Установить airflow, инициализировать базу данных и запустить сервер
```
pip install apache-airflow

airflow db init

airflow webserver --port 8080
```

Запуск исполнителя Airflow
```
airflow scheduler
```

## Шаг 2: Создание spark_script.py

Создайте файл spark_script.py с кодом предыдущего задания
```
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("SparkJob") \
    .getOrCreate()
    
# read data form hdfs
df = spark.read.csv("hdfs://team-17-nn:9870/<PATH_TO_DATA>", header=True, inferSchema=True)


filtered_df = df.filter(df["age"] > 30)

aggregated_df = df.groupBy("group").avg("age")

from pyspark.sql.functions import col
transformed_df = df.withColumn("date", col("date").cast("date"))

from pyspark.sql.functions import year
transformed_df = df.withColumn("age_in_years", year(col("date")) - col("birth_year"))

sorted_df = df.orderBy("age")

# save transformed data
transformed_df.write.saveAsTable("my_table")
```

## Шаг 3: Создание airflow DAG

Создайте новый файл DAG в директории "~/airflow/dags"

```
touch ~/airflow/dags/spark_dag.py
```

Скопируйте в spark_dag.py следующий код:
```
from airflow import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from datetime import datetime

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2024, 12, 20),
    'retries': 1,
}

dag = DAG(
    'spark_pipeline',
    default_args=default_args,
    description='something',
    schedule_interval=None,
)

spark_task = SparkSubmitOperator(
    task_id='spark_task',
    conn_id='yarn_spark',
    application='/path/to/your/spark_script.py',
    dag=dag,
)
```

## Шаг 4: Запуск airflow DAG

Перейдите в веб-интерфейс Airflow (http://localhost:8080) и активируйте DAG


