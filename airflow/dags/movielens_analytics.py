from __future__ import annotations

from datetime import datetime, timedelta
from pathlib import Path

from airflow import DAG
from airflow.operators.email import EmailOperator
from airflow.operators.empty import EmptyOperator
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.sensors.external_task import ExternalTaskSensor

DEFAULT_ARGS = {
    "owner": "lab",
    "retries": 1,
    "retry_delay": timedelta(minutes=1),
}

with DAG(
    dag_id="movielens_analytics",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    default_args=DEFAULT_ARGS,
    tags=["lab", "analytics"],
) as dag:
    start = EmptyOperator(task_id="start")

    wait_for_etl = ExternalTaskSensor(
        task_id="wait_for_etl",
        external_dag_id="movielens_etl",
        external_task_id="etl_warehouse",
        allowed_states=["success"],
        failed_states=["failed", "skipped"],
        poke_interval=30,
        timeout=15 * 60,
        mode="reschedule",
    )

    run_analytics = SQLExecuteQueryOperator(
        task_id="run_analytics",
        sql=Path("/scripts/03_analytics.hql").read_text(),
        conn_id="hiveserver2_default",
        split_statements=True,
    )

    notify = EmailOperator(
        task_id="notify",
        to=["{{ var.value.get('alert_email', 'you@example.com') }}"],
        subject="Airflow lab: MovieLens analytics finished",
        html_content="<p>The MovieLens analytics task has completed.</p>",
        trigger_rule="all_done",
    )

    end = EmptyOperator(task_id="end")

    start >> wait_for_etl >> run_analytics >> notify >> end
