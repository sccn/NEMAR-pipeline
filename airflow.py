from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from airflow.operators.bash_operator import BashOperator
from datetime import datetime, timedelta

# Define functions for Python tasks
def preprocess():
    # Your preprocessing logic here
    return "preprocessed_data_path"

def postprocess(**kwargs):
    # Get SLURM job output path from xcom
    slurm_output = kwargs['ti'].xcom_pull(task_ids='submit_slurm_job')
    # Your postprocessing logic here
    print(f"Processing {slurm_output}")

# Define default arguments
default_args = {
    'owner': 'user',
    'depends_on_past': False,
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
}

# Define DAG
with DAG(
    'example_pipeline',
    default_args=default_args,
    description='An example pipeline converted to Airflow',
    schedule_interval=timedelta(days=1),
    start_date=datetime(2024, 1, 1),
    catchup=False,
) as dag:

    preprocess_task = PythonOperator(
        task_id='preprocess',
        python_callable=preprocess,
    )

    submit_slurm_job = BashOperator(
        task_id='submit_slurm_job',
        bash_command='sbatch your_slurm_script.sh',
    )

    postprocess_task = PythonOperator(
        task_id='postprocess',
        python_callable=postprocess,
        provide_context=True,  # Enables access to XCom
    )

    # Set task dependencies
    preprocess_task >> submit_slurm_job >> postprocess_task