.DEFAULT_GOAL := help

# List from https://github.com/docker/cli/issues/1534
CHECK_COMPOSE_PLUGIN := $(shell \
(test -e $(HOME)/.docker/cli-plugins/docker-compose) || \
(test -e /usr/local/lib/docker/cli-plugins/docker-compose) || \
(test -e /usr/lib/docker/cli-plugins/docker-compose) || \
(test -e /usr/libexec/docker/cli-plugins/docker-compose) 2> /dev/null; echo $$?)
COMPOSE_FILE_OPT = -f ./docker-compose.yml
ifeq ($(CHECK_COMPOSE_PLUGIN), 0)
    DOCKER_COMPOSE_CMD = docker compose $(COMPOSE_FILE_OPT)
else
    DOCKER_COMPOSE_CMD = docker-compose $(COMPOSE_FILE_OPT)
endif

# Load .env files if exists
ifneq ($(wildcard ./.env.airflow.local),)
include ./.env.airflow.local
export $$(grep -v '^#' ./.env.airflow.local | xargs)
else
warning_msg:
$(warning There's no .env file for airflow. Please run make generate-dotenv.)
endif


ifneq ($(wildcard ./.env.dbt.local),)
include ./.env.dbt.local
export $$(grep -v '^#' ./.env.dbt.local | xargs)
else
warning_msg:
$(warning There's no .env file for dbt. Please run make generate-dotenv.)
endif

ifneq ($(wildcard ./.env.postgres.local),)
include ./.env.postgres.local
export $$(grep -v '^#' ./.env.postgres.local | xargs)
else
warning_msg:
$(warning There's no .env file for postgres. Please run make generate-dotenv.)
endif

.EXPORT_ALL_VARIABLES:
	$$(grep -v '^#' ./.env.airflow.local)
	$$(grep -v '^#' ./.env.dbt.local)
	$$(grep -v '^#' ./.env.postgres.local)

_GREEN='\033[0;32m'
_NC='\033[0m'

define log
	@printf "${_GREEN}$(1)${_NC}\n"
endef


# Reference: https://www.padok.fr/en/blog/beautiful-makefile-awk
.PHONY: help
help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


##@ Environment

.PHONY: generate-dotenv
generate-dotenv: ## Generate new .env files (it overrides the existing ones). Usage: make generate-dotenv
	$(call log, Generating .env file...)
	cp ./.env.airflow.local.example ./.env.airflow.local
	cp ./.env.dbt.local.example ./.env.dbt.local
	cp ./.env.postgres.local.example ./.env.postgres.local

.PHONY: install-poetry
install-poetry: ## Install poetry. Usage: make install-poetry
	$(call log, Installing poetry...)
	curl -sSL https://install.python-poetry.org | POETRY_VERSION=1.6.1 python3 - && \
	export "PATH=${HOME}/.local/bin:${PATH}" && \
	poetry config virtualenvs.in-project true && \
	poetry --version

.PHONY: install-project
install-project: ## Install the project dependencies. Usage: make install-project
	$(call log, Installing project dependencies...)
	poetry install --no-interaction --all-extras --with airflow,dev --sync

.PHONY: install-pre-commit
install-pre-commit: ## Install pre-commit and git hooks. Usage: make install-pre-commit
	$(call log, Installing pre-commit and git hooks...)
	poetry run pre-commit install --install-hooks


##@ Linting & Formatting

.PHONY: lint-sql
lint-sql: ## Lint a SQL file folder. Usage: make lint-sql path="./dbt/**/my_file.sql"
	$(call log, Linting $(path)...)
	poetry run sqlfluff lint --config ./.sqlfluff $(path)

.PHONY: fix-sql
fix-sql: ## Apply fixes to a SQL file. Usage: make fix-sql path="./dbt/**/my_file.sql"
	$(call log, Fixing $(path)...)
	poetry run sqlfluff fix --force --config ./.sqlfluff $(path)

.PHONY: format-sql
format-sql: ## Format a SQL file. Usage: make format-sql path="./dbt/**/my_file.sql"
	$(call log, Formatting $(path)...)
	poetry run sqlfluff format --config ./.sqlfluff $(path)


##@ Pre-commit hooks

.PHONY: nox-hooks
nox-hooks: ## Run all the pre-commit hooks in a nox session on all the files. Usage: make nox-hooks
	$(call log, Running all the pre-commit hooks in a nox session...)
	poetry run nox --session hooks

.PHONY: pre-commit-hooks
pre-commit-hooks: ## Run all the pre-commit hooks on all the files. Usage: make pre-commit-hooks
	$(call log, Running all the pre-commit hooks...)
	poetry run pre-commit run --hook-stage manual --show-diff-on-failure --all-files


##@ Docker

.PHONY: build
build: ## Build docker-defined services, can be passed specific service(s) to only build those. Usage: make build services="postgres"
	$(call log, Building images...)
	$(DOCKER_COMPOSE_CMD) build $(services)

.PHONY: up
up: ## Create docker-defined services, can be passed specific service(s) to only start those. Usage: make up services="postgres"
	$(call log, Creating services in detached mode...)
	$(DOCKER_COMPOSE_CMD) up -d $(services)

.PHONY: start
start: ## Start docker-defined services, can be passed specific service(s) to only start those. Usage: make start services="postgres"
	$(call log, Starting services...)
	$(DOCKER_COMPOSE_CMD) start $(services)

.PHONY: stop
stop: ## Stop docker-defined services, can be passed specific service(s) to only stop those. Usage: make stop services="postgres"
	$(call log, Stopping services $(services)...)
	$(DOCKER_COMPOSE_CMD) stop $(services)

.PHONY: down
down: ## Delete docker-defined services, can be passed specific service(s) to only delete those. Usage: make down services="postgres"
	$(call log, Deleting services $(services)...)
	$(DOCKER_COMPOSE_CMD) down $(services)

.PHONY: clean
clean: down ## Delete containers and volumes
	$(call log, Deleting services and volumes...)
	docker volume prune --all --force

.PHONY: prune
prune: ## Delete everything in docker
	$(call log, Deleting everything...)
	docker system prune --all --volumes --force && docker volume prune --all --force


##@ Airflow

.PHONY: airflow-shell
airflow-shell: ## Open a shell inside the Airflow scheduler. Usage: make airflow-shell
	$(call log, Opening Airflow shell in the scheduler...)
	$(DOCKER_COMPOSE_CMD) exec airflow-scheduler /bin/bash

.PHONY: airflow-tasks-test
airflow-tasks-test: ## Tests an Airflow task. Usage: make airflow-tasks-test dag="transformations" task="stg_events_run"
	$(call log, Testing the task $(task) in the DAG $(dag) in Airflow...)
	$(DOCKER_COMPOSE_CMD) exec airflow-scheduler airflow tasks test $(dag) $(task) $(args)

.PHONY: airflow-conn-test
airflow-conn-test: ## Tests an Airflow connection. Usage: make airflow-conn-test id="postgres_warehouse"
	$(call log, Testing the connection $(id) in Airflow...)
	$(DOCKER_COMPOSE_CMD) exec airflow-scheduler airflow connections test $(id)


##@ dbt

.PHONY: dbt-run-model
dbt-run-model: ## Run a dbt model. Usage: make dbt-run-model node="--select +stg_events+"
	$(call log, Running dbt model $(node)...)
	poetry run dbt run $(node) --project-dir dbt --profiles-dir dbt

.PHONY: dbt-test-model
dbt-test-model: ## Execute tests of a dbt model. Usage: make dbt-test-model node="--select stg_events"
	$(call log, Testing dbt model $(node)...)
	poetry run dbt test $(node) --project-dir dbt --profiles-dir dbt

.PHONY: dbt-run-seed
dbt-run-seed: ## Seed a dbt model. Usage: make dbt-run-seed node="--select stg_events"
	$(call log, Seeding dbt model $(node)...)
	poetry run dbt seed $(node) --project-dir dbt --profiles-dir dbt

.PHONY: dbt-run-macro
dbt-run-macro: ## Run a dbt macro. Usage: make dbt-run-macro name="my_macro" args='{"key": "value"}'
	$(call log, Running dbt macro $(name)...)
	poetry run dbt run-operation $(name) --args '$(args)' --project-dir dbt --profiles-dir dbt

.PHONY: dbt-show-model
dbt-show-model: ## Show a dbt model. Usage: make dbt-show-model node="--select stg_events"
	$(call log, Showing dbt model $(node)...)
	poetry run dbt show $(node) --project-dir dbt --profiles-dir dbt

.PHONY: dbt-build
dbt-build: ## Build the dbt project. Usage: make dbt-build
	$(call log, Building the dbt project...)
	poetry run dbt build --project-dir dbt --profiles-dir dbt

.PHONY: dbt-compile
dbt-compile: ## Compile the dbt project. Usage: make dbt-compile
	$(call log, Compiling the dbt project...)
	poetry run dbt compile --project-dir dbt --profiles-dir dbt

.PHONY: dbt-install-pkgs
dbt-install-pkgs: ## Install dbt packages. Usage: make dbt-install-pkgs
	$(call log, Installing packages...)
	poetry run dbt deps --project-dir dbt --profiles-dir dbt

.PHONY: dbt-debug
dbt-debug: ## Debug the dbt project. Usage: make dbt-debug
	$(call log, Debugging the dbt project...)
	poetry run dbt debug --project-dir dbt --profiles-dir dbt

.PHONY: dbt-docs-generate
dbt-docs-generate: ## Generate documentation of the dbt project. Usage: make dbt-docs-generate
	$(call log, Generating the documentation website for the dbt project...)
	# dbt related issue: https://github.com/dbt-labs/dbt-core/issues/9308
	cd dbt && \
	poetry run dbt docs generate --compile && \
	cd ..

.PHONY: dbt-docs-serve
dbt-docs-serve: ## Serve the documentation website for the dbt project. Usage: make dbt-docs-serve port="8888"
	$(call log, Serving the documentation website for the dbt project...)
	poetry run dbt docs serve --project-dir dbt --profiles-dir dbt --browser --port $(port)

.PHONY: dbt-gen-source-yaml
dbt-gen-source-yaml: ## Generate lightweight YAML for sources. Usage: make dbt-gen-source-yaml db="clara" schema="raw"
	$(call log, Generating sources for $(db).$(schema)...)
	poetry run dbt run-operation generate_source --target prod --project-dir dbt --profiles-dir dbt --args \
		'{ \
			"database_name": "$(db)", \
			"schema_name": "$(schema)", \
			"generate_columns": true, \
			"include_schema": true, \
			"include_database": true, \
			"include_descriptions": true \
		}'

.PHONY: dbt-gen-model-yaml
dbt-gen-model-yaml: ## Generate YAML for models. Usage: make dbt-gen-model-yaml model='["stg_events", "int_events"]'
	$(call log, Generating models for $(model)...)
	poetry run dbt run-operation generate_model_yaml --target prod --project-dir dbt --profiles-dir dbt --args \
		'{ \
			"model_names": $(model), \
			"upstream_descriptions": true, \
			"include_data_types": true \
		}'


##@ Challenge-related

.PHONY: execute-sql
execute-sql: ## Execute a SQL command inside the PostgreSQL service. Usage: make execute-sql
	$(call log, Spawning a psql shell...)
	docker exec -it postgres psql --username ${POSTGRES_USER} --dbname ${POSTGRES_DB}
