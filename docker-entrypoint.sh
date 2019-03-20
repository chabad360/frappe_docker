#!/bin/bash

set -e

chown -R frappe "${BENCH}"

# Setup bench
if [[ ! -d "${BENCH}/sites" ]]; then
    su-exec frappe bench init "${BENCH}" --ignore-exist --skip-redis-config-generation --verbose
    dockerize -template /home/frappe/templates/procfile.tmpl:${BENCH}/Procfile -template /home/frappe/templates/common_site_config.tmpl:${BENCH}/sites/common_site_config.json
fi

cd "${BENCH}" || exit 1
su-exec frappe bench set-mariadb-host "${MARIADB_HOST}"

# Make sure redis is up
dockerize -wait "tcp://${REDIS_CACHE_HOST}:13000" -wait "tcp://${REDIS_QUEUE_HOST}:11000" -wait "tcp://${REDIS_SOCKETIO_HOST}:12000"
# Make sure MariaDB is up
dockerize -wait "tcp://${MARIADB_HOST}:3306"

dockerize -template /home/frappe/templates/nginx.tmpl:/etc/nginx/conf.d/frappe.conf -template /home/frappe/templates/supervisord.tmpl:/etc/supervisor/conf.d/frappe.conf


# Add a site if its not there (useful if you're doing multitenancy)
if [[ ! -d "${BENCH}/sites/${SITE_NAME}" ]]; then
     su-exec frappe bench new-site "${SITE_NAME}" --verbose
fi

# Avoid hostname resolution issues (has happened before)
echo "127.0.0.1 ${SITE_NAME}" | tee -a /etc/hosts

# Make sure frappe is built
su-exec frappe bench build

# Print all configuration
echo "Configuration:"
echo "Bench Procfile:"
cat ${BENCH}/Procfile 
echo ""
echo "Bench Common Site Config:"
cat ${BENCH}/sites/common_site_config.json
echo ""
echo "Nginx config:"
cat /etc/nginx/nginx.conf <(echo "") /etc/nginx/conf.d/frappe.conf
echo ""
echo "Supervisord config:"
cat /etc/supervisord.conf <(echo "") /etc/supervisor/conf.d/frappe.conf
echo ""

# Start all services
exec nginx & supervisord 
