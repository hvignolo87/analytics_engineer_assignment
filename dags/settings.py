from pathlib import Path

from airflow.models import Variable

## dbt related vars
DBT_PROJECT_DIR = Path(__file__).parent.parent / Variable.get("DBT_PROJECT_DIR", "dbt")
DBT_PROFILES_DIR = DBT_PROJECT_DIR / "profiles.yml"
DBT_PROFILE_NAME = Variable.get("DBT_PROFILE_NAME", "clara")
DBT_TARGET_NAME = Variable.get("DBT_TARGET_NAME", "prod")
