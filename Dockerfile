# Frappe Bench Dockerfile

FROM debian:9.6-slim
LABEL author=frappé

# Set locale C.UTF-8 for mariadb and general locale data
ENV LANG C.UTF-8

# Install all neccesary packages
RUN apt-get update && apt-get install -y --no-install-suggests --no-install-recommends build-essential cron curl git iputils-ping libffi-dev \
  liblcms2-dev libldap2-dev libmariadbclient-dev libsasl2-dev libssl-dev libtiff5-dev libwebp-dev mariadb-client nginx \
  python-dev python-pip python-setuptools python-tk redis-tools rlwrap software-properties-common sudo supervisor tk8.6-dev \
  vim xfonts-75dpi xfonts-base wget wkhtmltopdf \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && pip install --upgrade setuptools pip --no-cache \
  && curl https://deb.nodesource.com/node_10.x/pool/main/n/nodejs/nodejs_10.10.0-1nodesource1_amd64.deb > node.deb \
  && dpkg -i node.deb \
  && rm node.deb \
  && npm install -g yarn

# Install su-exec (like gosu, but a lot smaller)
RUN curl -L https://github.com/ncopa/su-exec/archive/dddd1567b7c76365e1e0aac561287975020a8fad.tar.gz | tar xvz \ 
  && cd su-exec-* && make \
  && mv su-exec /usr/local/bin \
  && cd .. && rm -rf su-exec-*

# Add frappe user and setup sudo for it
RUN useradd -ms /bin/bash -G sudo frappe \
  && printf '# Sudo rules for frappe\nfrappe ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/frappe \
  && mkdir /home/frappe/frappe-bench

# Install bench
RUN pip install -e git+https://github.com/frappe/bench.git#egg=bench --no-cache

# Add entrypoint
COPY ./docker-entrypoint.sh /bin/entrypoint
RUN chmod 777 /bin/entrypoint

COPY ./frappe-conf.d/nginx.conf /etc/nginx/nginx.conf
COPY ./frappe-conf.d/supervisord.conf /etc/supervisord.conf

EXPOSE 8000 9000 6787

VOLUME [ "/home/frappe/frappe-bench" ]

ENV MYSQL_ROOT_PASSWORD="123"
ENV ADMIN_PASSWORD="admin"
ENV WEBSERVER_PORT="8000"
ENV SITE_NAME="site1.local"

# These are here because you never know, people may want to change them (for some odd reason), so we need to set defaults.
ENV REDIS_CACHE_HOST="redis-cache"
ENV REDIS_QUEUE_HOST="redis-queue"
ENV REDIS_SOCKETIO_HOST="redis-socketio"
ENV MARIADB_HOST="mariadb"
ENV BENCH="/home/frappe/frappe-bench"

HEALTHCHECK --start-period=5m \
  CMD curl -f "http://localhost:80" || exit 1

ENTRYPOINT [ "/bin/entrypoint" ]
