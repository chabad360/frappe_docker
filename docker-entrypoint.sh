#!/bin/bash

if [[ -z ${MYSQL_ROOT_PASSWORD} ]]; then
    echo "MySQL root password not set! Using default: \"123\""
    export MYSQL_ROOT_PASSWORD=123
fi

if [[ -z ${ADMIN_PASSWORD} ]]; then
    echo "Admin password not set! Using default: \"admin\""
    export ADMIN_PASSWORD=admin
fi

if [[ -z ${WEBSERVER_PORT} ]]; then
    echo "Webserver port not set! Using default: \"8000\""
    export WEBSERVER_PORT=8000
fi


function setup_config () {
    cat <(echo "{\n\"auto_update\": false\n\
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
    }") > /home/frappe/frappe-bench/Procfile_docker

    cat <(echo "web: bench serve --port ${WEBSERVER_PORT}\n\
    \n\
    socketio: /usr/bin/node apps/frappe/socketio.js\n\
    watch: bench watch\n\
    schedule: bench schedule\n\
    worker_short: bench worker --queue short\n\
    worker_long: bench worker --queue long\n\
    worker_default: bench worker --queue default\n\
    ") > /home/frappe/frappe-bench/sites/common_site_config_docker.json
}

setup_config

tail -f /dev/null
