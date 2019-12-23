# Frappe Bench Dockerfile

FROM debian:buster-20191118-slim
LABEL author=frappé


# Add entrypoint
COPY ./docker-entrypoint.sh /bin/entrypoint

# Install locales
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends locales \
  && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
  && dpkg-reconfigure --frontend=noninteractive locales \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set locale en_us.UTF-8 for mariadb and general locale data
ENV PYTHONIOENCODING=utf-8
ENV LANGUAGE=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Using apt-lock to ensure correct versions are installed
#ADD https://github.com/TrevorSundberg/apt-lock/releases/download/v1.0.1/apt-lock-linux-x64 /usr/local/bin/apt-lock
#RUN chmod +x /usr/local/bin/apt-lock
#COPY apt-lock.json .

# Lock APT repository
RUN printf "deb http://snapshot.debian.org/archive/debian/20191118T000000Z buster main\n\
deb http://snapshot.debian.org/archive/debian-security/20191118T000000Z buster/updates main\n\
deb http://snapshot.debian.org/archive/debian/20191118T000000Z buster-updates main" > /etc/apt/sources.list

# Install all neccesary packages
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-suggests --no-install-recommends \
  build-essential cron curl git iputils-ping libffi-dev liblcms2-dev libldap2-dev libmariadbclient-dev libsasl2-dev \
  libssl-dev libtiff5-dev libwebp-dev mariadb-client nginx python-dev python-pip python-setuptools python-tk redis-tools rlwrap \
  rlwrap software-properties-common sudo supervisor tk8.6-dev vim xfonts-75dpi xfonts-base wget wkhtmltopdf \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && wget https://deb.nodesource.com/node_10.x/pool/main/n/nodejs/nodejs_10.10.0-1nodesource1_amd64.deb -O node.deb \
  && dpkg -i node.deb && rm node.deb \
  && npm install -g yarn \
  && pip install -e git+https://github.com/frappe/bench.git#egg=bench --no-cache \
  && wget https://github.com/ncopa/su-exec/archive/dddd1567b7c76365e1e0aac561287975020a8fad.tar.gz -O - | tar xzv \
  && cd su-exec-* && make \
  && mv su-exec /usr/local/bin \
  && cd .. && rm -rf su-exec-* \
  && wget https://github.com/jwilder/dockerize/releases/download/v0.6.1/dockerize-linux-amd64-v0.6.1.tar.gz -O - | tar xzv -C /usr/local/bin \
  && groupadd -g 500 frappe \
  && useradd -ms /bin/bash -u 500 -g 500 -G sudo frappe \
  && printf '# Sudo rules for frappe\nfrappe ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/frappe \
  && chown -R 500:500 /home/frappe\
  && chmod 777 /bin/entrypoint
# ^^ Saves a layer

# Add templates
COPY --chown=500:500 ./frappe-templates /home/frappe/templates

# These are here because you never know, people may want to change them (for some odd reason), so we need to set defaults.
ENV REDIS_CACHE_HOST="redis-cache"
ENV REDIS_QUEUE_HOST="redis-queue"
ENV REDIS_SOCKETIO_HOST="redis-socketio"
ENV MARIADB_HOST="mariadb"
ENV WEBSERVER_PORT="8000"
ENV SOCKETIO_PORT="9000"
ENV BENCH="/home/frappe/frappe-bench"
ENV DEV_MODE="false"
ENV MYSQL_ROOT_PASSWORD="root"
ENV ADMIN_PASSWORD="admin"
ENV SITE_NAME="localhost"

EXPOSE 80 8000 9000 6787

VOLUME [ "/home/frappe/frappe-bench/sites" ]

HEALTHCHECK --start-period=5m \
  CMD curl -f http://localhost || echo "Curl failure: $?" && exit 1

ENTRYPOINT [ "/bin/entrypoint" ]
