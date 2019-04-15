# Frappe Bench Dockerfile

FROM balenalib/generic-armv7ahf-debian:stretch
LABEL author=frappé

RUN [ "cross-build-start" ]

# Set locale C.UTF-8 for mariadb and general locale data
ENV LANG C.UTF-8

# Install all neccesary packages
RUN apt-get update && apt-get install -y --no-install-suggests --no-install-recommends build-essential cron curl git iputils-ping libffi-dev \
  liblcms2-dev libldap2-dev libmariadbclient-dev libsasl2-dev libssl-dev libtiff5-dev libwebp-dev mariadb-client \
  python-dev python-pip python-setuptools python-tk redis-tools rlwrap software-properties-common sudo tk8.6-dev \
  vim xfonts-75dpi xfonts-base wget wkhtmltopdf \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && wget https://deb.nodesource.com/node_10.x/pool/main/n/nodejs/nodejs_10.10.0-1nodesource1_armhf.deb -O ./node.deb \
  && dpkg -i node.deb \
  && rm node.deb \
  && npm install -g yarn \
  && pip install -e git+https://github.com/frappe/bench.git#egg=bench --no-cache \
  && wget https://github.com/ncopa/su-exec/archive/dddd1567b7c76365e1e0aac561287975020a8fad.tar.gz -O - | tar xvz \ 
  && cd su-exec-* && make \
  && mv su-exec /usr/local/bin \
  && cd .. && rm -rf su-exec-* \
  && wget https://github.com/jwilder/dockerize/releases/download/v0.6.1/dockerize-linux-armhf-v0.6.1.tar.gz \
  && tar -C /usr/local/bin -xzvf dockerize-linux-armhf-v0.6.1.tar.gz \
  && rm dockerize-linux-amd64-v0.6.1.tar.gz

# Add entrypoint
COPY ./docker-entrypoint.sh /bin/entrypoint

# Add frappe user and setup sudo for it
RUN useradd -ms /bin/bash -G sudo frappe \
  && printf '# Sudo rules for frappe\nfrappe ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/frappe \
  && mkdir /home/frappe/frappe-bench \
  && chmod 777 /bin/entrypoint
# ^^ Saves a layer

# Add templates
COPY --chown=frappe:frappe ./frappe-templates /home/frappe/templates

EXPOSE 8000 9000 6787

VOLUME [ "/home/frappe/frappe-bench" ]

ENV MYSQL_ROOT_PASSWORD="root"
ENV ADMIN_PASSWORD="admin"
ENV SITE_NAME="site1.local"

# These are here because you never know, people may want to change them (for some odd reason), so we need to set defaults.
ENV REDIS_CACHE_HOST="redis-cache"
ENV REDIS_QUEUE_HOST="redis-queue"
ENV REDIS_SOCKETIO_HOST="redis-socketio"
ENV MARIADB_HOST="mariadb"
ENV WEBSERVER_PORT="8000"
ENV SOCKETIO_PORT="9000"
ENV BENCH="/home/frappe/frappe-bench"

HEALTHCHECK --start-period=5m \
  CMD curl -f http://localhost:${WEBSERVER_PORT} || echo "Curl failure: $?" && exit 1

RUN [ "cross-build-end" ]

ENTRYPOINT [ "/bin/entrypoint" ]
