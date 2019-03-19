#!/bin/bash

set -e

chown -R frappe "${BENCH}"

# Setup bench
if [[ ! -d "${BENCH}/sites" ]]; then
    su-exec frappe bench init "${BENCH}" --ignore-exist --skip-redis-config-generation --verbose
    dockerize -template /home/frappe/templates/procfile.tmpl:${BENCH}/Procfile -template /home/frappe/templates/common_site_config.tmpl:${BENCH}/sites/common_site_config.json
fi

cat <(echo "Bench Procfile:") ${BENCH}/Procfile <(echo)
cat <(echo "Bench Common Site Config") ${BENCH}/sites/common_site_config.json <(echo)

cd "${BENCH}" || exit 1
su-exec frappe bench set-mariadb-host "${MARIADB_HOST}"

# Make sure redis is up
dockerize -wait "tcp://${REDIS_CACHE_HOST}:13000" -wait "tcp://${REDIS_QUEUE_HOST}:11000" -wait "tcp://${REDIS_SOCKETIO_HOST}:12000"
# Make sure MariaDB is up
dockerize -wait "tcp://${MARIADB_HOST}:3306"

ls /etc
ls /etc/nginx
ls /etc/nginx/conf.d

dockerize -template /home/frappe/templates/nginx.tmpl:/etc/nginx/conf.d/frappe.conf -template /home/frappe/templates/supervisord.tmpl:/etc/supervisord/conf.d/frappe.conf


# Add a site if its not there (useful if you're doing multitenancy)
if [[ ! -d "${BENCH}/sites/${SITE_NAME}" ]]; then
     su-exec frappe bench new-site "${SITE_NAME}" --verbose
fi

echo "127.0.0.1 ${SITE_NAME}" | tee -a /etc/hosts

# Start all services
su-exec frappe supervisord & nginx

# Wait for exit...
su-exec frappe tail -f /dev/null
