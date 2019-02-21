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

##### Functions

# Setup bench config files
function setup_config () {
    cat <(echo -e "{\n\"auto_update\": false\n\
    \"background_workers\": 1,\n\
    \"db_host\": \"mariadb\",\n\
    \"file_watcher_port\": 6787,\n\
    \"frappe_user\": \"frappe\",\n\
    \"gunicorn_workers\": 4,\n\
    \"rebase_on_pull\": false,\n\
    \"redis_cache\": \"redis://redis-cache:13000\",\n\
    \"redis_queue\": \"redis://redis-queue:11000\",\n\
    \"redis_socketio\": \"redis://redis-socketio:12000\",\n\
    \"restart_supervisor_on_update\": false,\n\
    \"root_password\": \"${MYSQL_ROOT_PASSWORD}\",\n\
    \"serve_default_site\": true,\n\
    \"shallow_clone\": true,\n\
    \"socketio_port\": 9000,\n\
    \"update_bench_on_update\": true,\n\
    \"webserver_port\": ${WEBSERVER_PORT},\n\
    \"admin_password\": \"${ADMIN_PASSWORD}\"\n\
    }") > /home/frappe/frappe-bench/Procfile

    cat <(echo -e "web: bench serve --port ${WEBSERVER_PORT}\n\
    \n\
    socketio: /usr/bin/node apps/frappe/socketio.js\n\
    watch: bench watch\n\
    schedule: bench schedule\n\
    worker_short: bench worker --queue short\n\
    worker_long: bench worker --queue long\n\
    worker_default: bench worker --queue default\n\
    ") > /home/frappe/frappe-bench/sites/common_site_config.json
}

#### Entrypoint

sudo chown -R frappe:frappe frappe-bench

# Setup bench
if [[ ! -d "frappe-bench/apps/frappe" ]]; then
    cd /home/frappe && bench init frappe-bench --ignore-exist --skip-redis-config-generation 
    cd /home/frappe/frappe-bench || exit 1
    setup_config
    bench set-mariadb-host mariadb
fi

# Add a site if its not there (useful if you're doing multitenancy)
if [[ ! -d /home/frappe/frappe-bench/sites/${SITE_NAME} ]]; then
    bench new-site "${SITE_NAME}"
fi

# Start bench inplace of shell
exec bench --site "${SITE_NAME}" start
