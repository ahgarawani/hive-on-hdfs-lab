from __future__ import annotations

from datetime import datetime, timedelta
from pathlib import Path

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.providers.common.sql.sensors.sql import SqlSensor
from airflow.sensors.filesystem import FileSensor

DEFAULT_ARGS = {
    "owner": "lab",
    "retries": 1,
    "retry_delay": timedelta(minutes=1),
}

with DAG(
    dag_id="movielens_etl",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    default_args=DEFAULT_ARGS,
    tags=["lab", "hdfs", "hive"],
) as dag:
    start = EmptyOperator(task_id="start")

    wait_for_dataset = FileSensor(
        task_id="wait_for_dataset",
        filepath="ml-latest-small/movies.csv",
        poke_interval=30,
        timeout=15 * 60,
        mode="reschedule",
    )

    create_staging = SQLExecuteQueryOperator(
        task_id="create_staging",
        sql=Path("/scripts/01_setup_staging.hql").read_text(),
        conn_id="hiveserver2_default",
        split_statements=True,
    )

    etl_warehouse = SQLExecuteQueryOperator(
        task_id="etl_warehouse",
        sql=Path("/scripts/02_etl_warehouse.hql").read_text(),
        conn_id="hiveserver2_default",
        split_statements=True,
    )

    quality_check = SqlSensor(
        task_id="quality_check",
        conn_id="hiveserver2_default",
        sql="SELECT COUNT(*) > 0 FROM movielens.movies_orc",
        poke_interval=30,
        timeout=10 * 60,
        mode="reschedule",
    )

    trigger_analytics = TriggerDagRunOperator(
        task_id="trigger_analytics",
        trigger_dag_id="movielens_analytics",
        wait_for_completion=False,
    )

    end = EmptyOperator(task_id="end")

    (
        start
        >> wait_for_dataset
        >> create_staging
        >> etl_warehouse
        >> quality_check
        >> trigger_analytics
        >> end
    )
