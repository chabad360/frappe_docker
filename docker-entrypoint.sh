#!/bin/bash

chown -R frappe "${BENCH}"

# Setup bench
if [[ ! -d "${BENCH}/sites" ]]; then
    su-exec frappe bench init "${BENCH}" --ignore-exist --skip-redis-config-generation --verbose
fi

# Safely add bench config files
if [[ ! -f "${BENCH}/Procfile" ]]; then
    dockerize -template /home/frappe/templates/procfile.tmpl:${BENCH}/Procfile 
fi
if [[ ! -f "${BENCH}/sites/common_site_config.json" ]]; then
    dockerize -template /home/frappe/templates/common_site_config.tmpl:${BENCH}/sites/common_site_config.json
fi

cd "${BENCH}" || exit 1
su-exec frappe bench set-mariadb-host "${MARIADB_HOST}"

# Make sure Redis is up
dockerize -wait "tcp://${REDIS_CACHE_HOST}:13000" -wait "tcp://${REDIS_QUEUE_HOST}:11000" -wait "tcp://${REDIS_SOCKETIO_HOST}:12000"
# Make sure MariaDB is up
dockerize -wait "tcp://${MARIADB_HOST}:3306"

# Add a site if it's not there (useful if you're doing multitenancy)
if [[ ! -d "${BENCH}/sites/${SITE_NAME}" ]]; then
     su-exec frappe bench new-site "${SITE_NAME}" --verbose
fi

echo "127.0.0.1 ${SITE_NAME}" | tee -a /etc/hosts

# Print all configuration
function output () {
    TITLE=$2 NAME=${3:-$(echo "$1" | grep -o '\([^\/\\]\+\.\w\+\)$')} awk 'BEGIN{print "\033[1;36m" ENVIRON["TITLE"] \
    ":\n\033[0;31m" ENVIRON["NAME"] "\t|\033[1;31m ------------------------------------------------------------------------\033[0m"} \
    {print "\033[0;31m" ENVIRON["NAME"] "\t| \033[0m" $0} END{print "\033[0;31m" \
    ENVIRON["NAME"] "\t|\033[1;31m ------------------------------------------------------------------------\033[0m\n"}' $1
};\

echo -e "\n\033[1;36mConfiguration:"
output ./Procfile "Bench Procfile"
output ${BENCH}/sites/common_site_config.json "Bench Common Site Config"


# Start bench inplace of shell
su-exec frappe bench start