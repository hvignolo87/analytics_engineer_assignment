from datetime import datetime

from airflow.decorators import dag
from airflow.operators.empty import EmptyOperator
from airflow.utils.trigger_rule import TriggerRule
from cosmos import (
    DbtTaskGroup,
    ExecutionConfig,
    ExecutionMode,
    LoadMode,
    ProfileConfig,
    ProjectConfig,
    RenderConfig,
    TestBehavior,
)
from settings import (
    DBT_PROFILE_NAME,
    DBT_PROFILES_DIR,
    DBT_PROJECT_DIR,
    DBT_TARGET_NAME,
)

DEFAULT_ARGS = {
    "owner": "clara",
    "retries": 0,
}


@dag(
    dag_id="transformations",
    description="dbt transformations pipeline",
    default_args=DEFAULT_ARGS,
    tags=[
        "PostgreSQL",
        "T",
        "analytics_engineering",
        "cosmos",
        "data_engineering",
        "data_pipeline",
        "dbt",
        "transformations",
        "warehouse",
    ],
    schedule="0 */2 * * *",
    start_date=datetime(2024, 1, 1),
    max_active_runs=1,
    catchup=False,
)
def dbt_pipeline():
    """
    **Transformations DAG**

    This DAG executes the [dbt](https://www.getdbt.com/product/what-is-dbt) project with
    all its transformations using [cosmos](https://astronomer.github.io/astronomer-cosmos/).
    It excludes the seeds, as they are manually loaded from the local environment when
    required, and are treated as models here.

    These are the airflow variables related to `dbt`:
    - `DBT_PROJECT_DIR`: the path to the dbt project directory, default is `../dbt`
    - `DBT_PROFILES_DIR`: the path to `profiles.yml` file, default is `dbt/profiles.yml`
    - `DBT_PROFILE_NAME`: the name of the profile to use, default is `clara`
    - `DBT_TARGET_NAME`: the name of the target to use, default is `dev`
    """

    transformations_starts = EmptyOperator(
        task_id="transformations_starts",
    )

    render_config = RenderConfig(
        dbt_deps=True,
        exclude=["resource_type:seed"],
        load_method=LoadMode.DBT_LS,
        test_behavior=TestBehavior.AFTER_EACH,
    )

    project_config = ProjectConfig(dbt_project_path=DBT_PROJECT_DIR)

    profile_config = ProfileConfig(
        profile_name=DBT_PROFILE_NAME,
        profiles_yml_filepath=DBT_PROFILES_DIR,
        target_name=DBT_TARGET_NAME,
    )

    execution_config = ExecutionConfig(
        execution_mode=ExecutionMode.LOCAL,
    )

    operator_args = {
        "append_env": True,
        "install_deps": True,
        "output_encoding": "utf-8",
        "no_version_check": True,
    }

    transformations_layer = DbtTaskGroup(
        execution_config=execution_config,
        group_id="transformations",
        operator_args=operator_args,
        profile_config=profile_config,
        project_config=project_config,
        render_config=render_config,
    )

    transformations_ends = EmptyOperator(
        task_id="transformations_ends",
        trigger_rule=TriggerRule.ALL_DONE,
    )

    transformations_starts >> transformations_layer >> transformations_ends


dbt_pipeline()
