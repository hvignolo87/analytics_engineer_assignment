#!/bin/bash

psql \
    -v ON_ERROR_STOP=1 \
    --username "postgres" \
    --dbname "${POSTGRES_DB}" <<-EOSQL
    GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};
EOSQL
