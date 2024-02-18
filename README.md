# Analytics Engineer assignment resolution

[![Apache Airflow](https://img.shields.io/badge/Apache%20Airflow-2.6.3-green.svg?logo=apacheairflow)](https://airflow.apache.org/docs/apache-airflow/2.6.3/index.html) [![Python 3.10.12](https://img.shields.io/badge/python-3.10.12-blue.svg?labelColor=%23FFE873&logo=python)](https://www.python.org/downloads/release/python-31012/) ![dbt-version](https://img.shields.io/badge/dbt-version?style=flat&logo=dbt&label=1.5&link=https%3A%2F%2Fdocs.getdbt.com%2Fdocs%2Fintroduction)<br>
[![Ruff](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/astral-sh/ruff/main/assets/badge/v2.json)](https://docs.astral.sh/ruff/) [![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://black.readthedocs.io/en/stable/) [![Imports: isort](https://img.shields.io/badge/%20imports-isort-%231674b1?style=flat&labelColor=ef8336)](https://pycqa.github.io/isort/)<br>
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196?logo=conventionalcommits&logoColor=white)](https://conventionalcommits.org) [![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://pre-commit.com/)

In this document, you'll find information and instructions about my solution to the analytics engineer assignment.

## Directories structure

This is the structure of the project.

```text
.
├── .dockerignore
├── .env.airflow.local.example
├── .env.dbt.local.example
├── .env.postgres.local.example
├── .gitignore
├── .pre-commit-config.yaml
├── .python-version
├── .sqlfluff
├── .sqlfluffignore
├── .vscode
│   ├── extensions.json
│   └── settings.json
├── Analytics Engineer Assessment.docx
├── Dockerfile.airflow
├── Dockerfile.dbt
├── LICENSE
├── Makefile
├── README.md
├── analytics_engineer_assessment.pdf
├── dags
│   ├── .airflowignore
│   ├── settings.py
│   └── transformations.py
├── dbt
│   ├── analyses
│   │   └── .gitkeep
│   ├── dbt_project.yml
│   ├── macros
│   │   ├── .gitkeep
│   │   ├── generate_raw_data.sql
│   │   ├── generate_schema_name.sql
│   │   └── macros.yml
│   ├── models
│   │   ├── core
│   │   │   ├── core.yml
│   │   │   ├── core_commits.sql
│   │   │   ├── core_events.sql
│   │   │   ├── core_repos.sql
│   │   │   └── core_users.sql
│   │   ├── landing.yml
│   │   ├── marts
│   │   │   ├── marts.yml
│   │   │   └── reporting
│   │   │       ├── dim_commits.sql
│   │   │       ├── dim_repos.sql
│   │   │       ├── dim_users.sql
│   │   │       ├── fct_events.sql
│   │   │       └── reporting.yml
│   │   └── staging
│   │       ├── staging.yml
│   │       ├── stg_actors.sql
│   │       ├── stg_commits.sql
│   │       ├── stg_events.sql
│   │       └── stg_repos.sql
│   ├── packages.yml
│   ├── profiles.yml
│   ├── seeds
│   │   ├── .gitkeep
│   │   ├── raw
│   │   │   ├── actors.csv
│   │   │   ├── commits.csv
│   │   │   ├── events.csv
│   │   │   └── repos.csv
│   │   └── seeds.yml
│   ├── snapshots
│   │   └── .gitkeep
│   └── tests
│       └── .gitkeep
├── docker-compose.yml
├── mypy.ini
├── noxfile.py
├── poetry.lock
├── pyproject.toml
└── scripts
    └── postgres_init.sh
```

## What you'll need

This solution is containerized, so you'll need to [install docker and docker-compose](https://docs.docker.com/get-docker/).

Also, it's recommended to have a desktop SQL client like [DBeaver](https://dbeaver.io/download/).

On a secondary stage, you can install the recommended VS Code extensions.

## Setup

Let's dive into the setup process.

### 1. Generate the environment variables

Open a shell in your machine, and navigate to this directory. Then run:

```bash
make generate-dotenv
```

This will generate three `.env` files with predefined values. Please, go ahead and open it! If you want to modify some values, just take into account that this may break some things.

### 2. Install the project dependencies

Run these commands in this sequence:

```bash
make install-poetry
make install-project
```

Optionally, if you've cloned the repo, you can run:

```bash
make install-pre-commit
```

To install the pre-commit hooks and play around with them.

### 3. Build the images

Run:

```bash
make build services="postgres bootstrap-dbt"
```

This will build all the required images.

### 4. Create the services

Run:

```bash
make up services="postgres bootstrap-dbt"
```

This will create a PostgreSQL database, and all the raw tables, and run a command that populates those tables with the provided data.

### 5. Connect to the DB locally

Open DBeaver, and set up the connection to the database. If you didn't modify the `.env` files, you can use these credentials:

- User: `clara`
- Password: `clara`
- Host: `localhost`
- Port: `5440`
- DB: `clara`

Then, please open the `queries.sql` and `view.sql` files and run queries in DBeaver to verify the results.

If you don't have DBeaver, you can run the queries from PostgreSQL's terminal with [psql](https://www.postgresql.org/docs/14/app-psql.html). To do this, please run:

```bash
make execute-sql
```

Then you can run the queries from the terminal.

## Creating the data model

In this section, we'll materialize the data model with `dbt`.

In your terminal, run:

```bash
make dbt-run-model node="--target prod"
```

And wait until all the models are finished.

## Assignment resolution: SQL queries for reporting

Using the data model created with `dbt`, you can answer the required questions.

Please, run these queries in DBeaver to verify the results.

```sql
-- Top 10 active users sorted by the amount of PRs created and commits pushed
SELECT
    fct_events.user_id AS user_id
    , dim_users.username AS username
    , COUNT(*) AS num_commits_and_prs_events
FROM reporting.fct_events
LEFT JOIN reporting.dim_users
    ON fct_events.user_id = dim_users.id
WHERE fct_events.event_type IN ('PushEvent', 'PullRequestEvent')
    AND NOT username ~* '-bot|\[bot\]|bot$'
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 10
```

```sql
-- Top 10 repositories sorted by the amount of commits pushed
SELECT
    fct_events.repo_id AS repo_id
    , dim_repos.name AS repo_name
    , COUNT(*) AS num_commits_per_repo
FROM reporting.fct_events
LEFT JOIN reporting.dim_repos
    ON fct_events.repo_id = dim_repos.id
WHERE fct_events.commit_sha IS NOT NULL
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 10
```

```sql
-- Top 10 repositories sorted by the amount of watch events
SELECT
    fct_events.repo_id AS repo_id
    , dim_repos.name AS repo_name
    , COUNT(*) AS num_watch_events_per_repo
FROM reporting.fct_events
LEFT JOIN reporting.dim_repos
    ON fct_events.repo_id = dim_repos.id
WHERE fct_events.event_type = 'WatchEvent'
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 10
```

<https://docs.github.com/en/rest/using-the-rest-api/github-event-types?apiVersion=2022-11-28>
