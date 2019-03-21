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
function output () {
    TITLE=$2 NAME=$3 awk 'BEGIN{print "\033[1;36m" ENVIRON["TITLE"] ":\033[0m"} {print "\033[1;31m" ENVIRON["NAME"] " | \033[0m" $0} END{print ""}' $1
}

echo -e "\n${BCYAN}Configuration:"
output ${BENCH}/Procfile "Bench Procfile" "Procfile"
output ${BENCH}/sites/common_site_config.json "Bench Common Site Config" "common_site_config.json"
output /etc/nginx/nginx.conf "Nginx config" "/etc/nginx/nginx.conf"
output /etc/nginx/conf.d/frappe.conf "Nginx frappe conf" "/etc/nginx/conf.d/frappe.conf"
output /etc/supervisor/supervisord.conf "Supervisord config" "/etc/supervisor/supervisord.conf"
output /etc/supervisor/conf.d/frappe.conf "Supervisord frappe conf" "/etc/supervisor/conf.d/frappe.conf"

# Start all services
supervisord
nginx  

su-exec frappe tail -f /dev/null