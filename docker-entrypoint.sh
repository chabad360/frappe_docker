#!/bin/bash

if [[ ${MYSQL_ROOT_PASSWORD} == "123" ]]; then
    echo "MySQL root password not set! Using default: \"123\""
fi

if [[ ${ADMIN_PASSWORD} == "admin" ]]; then
    echo "Admin password not set! Using default: \"admin\""
fi

if [[ ${WEBSERVER_PORT} == "8000" ]]; then
    echo "Webserver port not set! Using default: \"8000\""
fi

if [[ ${SITE_NAME} == "site1.local" ]]; then
    echo "Site name not set! Using default: \"site1.local\""
fi

bench_home=/home/frappe/frappe-bench

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
    }") > ${bench_home}/sites/common_site_config.json

    cat <(echo -e "web: bench serve --port ${WEBSERVER_PORT}\n\
    \n\
    socketio: /usr/bin/node apps/frappe/socketio.js\n\
    watch: bench watch\n\
    schedule: bench schedule\n\
    worker_short: bench worker --queue short\n\
    worker_long: bench worker --queue long\n\
    worker_default: bench worker --queue default\n\
    ") > ${bench_home}/Procfile
}

#### Entrypoint

chown -R frappe:frappe ${bench_home}

echo "127.0.0.1 ${SITE_NAME}" | tee -a /etc/hosts

exec su-exec frappe <<EOF

# Setup bench
if [[ ! -d "${bench_home}/apps/frappe" ]]; then
    cd /home/frappe && bench init frappe-bench --ignore-exist --skip-redis-config-generation 
    cd ${bench_home} || exit 1
    bench set-mariadb-host ${MARIADB_HOST}
fi

setup_config

# Add a site if its not there (useful if you're doing multitenancy)
if [[ ! -d "${bench_home}/sites/${SITE_NAME}" ]]; then
    bench new-site "${SITE_NAME}"
fi

# Start bench inplace of shell
exec frappe bench --site "${SITE_NAME}" serve
EOF