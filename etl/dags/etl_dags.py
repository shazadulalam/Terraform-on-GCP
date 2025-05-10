from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from datetime import datetime

default_args = {
    'owner': 'airflow',
    'start_date': datetime(2023, 1, 1),
    'retries': 1
}

with DAG(
    'covid_etl',
    default_args=default_args,
    schedule_interval='@daily',
    catchup=False
) as dag:

    run_etl = BigQueryInsertJobOperator(
        task_id='run_etl',
        configuration={
            "query": {
                "query": "{% include 'sql/covid_etl.sql' %}",
                "useLegacySql": False,
                "destinationTable": {
                    "projectId": "{{ var.value.gcp_project }}",
                    "datasetId": "{{ var.value.bq_dataset }}",
                    "tableId": "daily_covid_summary"
                },
                "writeDisposition": "WRITE_TRUNCATE"
            }
        },
        location='US'
    )