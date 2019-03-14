#!/bin/bash

set -e

##### Functions

# Setup bench config files
function setup_config () {
    cat <(echo -e "{\n\
    \"auto_update\": false,\n\
    \"background_workers\": 1,\n\
    \"db_host\": \"${MARIADB_HOST}\",\n\
    \"file_watcher_port\": 6787,\n\
    \"frappe_user\": \"frappe\",\n\
    \"gunicorn_workers\": 4,\n\
    \"rebase_on_pull\": false,\n\
    \"redis_cache\": \"redis://${REDIS_CACHE_HOST}:13000\",\n\
    \"redis_queue\": \"redis://${REDIS_QUEUE_HOST}:11000\",\n\
    \"redis_socketio\": \"redis://${REDIS_SOCKETIO_HOST}:12000\",\n\
    \"restart_supervisor_on_update\": false,\n\
    \"root_password\": \"${MYSQL_ROOT_PASSWORD}\",\n\
    \"serve_default_site\": true,\n\
    \"shallow_clone\": true,\n\
    \"socketio_port\": 9000,\n\
    \"update_bench_on_update\": true,\n\
    \"webserver_port\": ${WEBSERVER_PORT},\n\
    \"admin_password\": \"${ADMIN_PASSWORD}\"\n\
    }") > ${BENCH}/sites/common_site_config.json

    cat <(echo -e "web: bench serve --port ${WEBSERVER_PORT}\n\
    \n\
    socketio: /usr/bin/node apps/frappe/socketio.js\n\
    watch: bench watch\n\
    schedule: bench schedule\n\
    worker_short: bench worker --queue short\n\
    worker_long: bench worker --queue long\n\
    worker_default: bench worker --queue default\n\
    ") > ${BENCH}/Procfile
}

#### Entrypoint

echo "127.0.0.1 ${SITE_NAME}" | tee -a /etc/hosts
chown -R frappe ${BENCH}

# Setup bench
if [[ ! -d "${BENCH}/sites" ]]; then
    su-exec frappe bench init ${BENCH} --ignore-exist --skip-redis-config-generation --verbose
fi

cd ${BENCH} || exit 1
setup_config
su-exec frappe bench set-mariadb-host "${MARIADB_HOST}"

# Add a site if its not there (useful if you're doing multitenancy)
if [[ ! -d "${BENCH}/sites/${SITE_NAME}" ]]; then
     su-exec frappe bench new-site "${SITE_NAME}" --verbose
fi

# Start bench inplace of shell
su-exec frappe bench start