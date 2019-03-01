# Frappe Bench Dockerfile

FROM ubuntu:16.04
LABEL author=frappé

# Generate locale C.UTF-8 for mariadb and general locale data
ENV LANG C.UTF-8

# Install all neccesary packages
RUN apt-get update && apt-get install -y --no-install-recommends iputils-ping git build-essential python-setuptools \
  libssl-dev libjpeg8-dev redis-tools software-properties-common libxrender1 libxext6 xfonts-75dpi xfonts-base \
  python-dev libffi-dev libfreetype6-dev liblcms2-dev libwebp-dev python-tk libsasl2-dev libldap2-dev libtiff5-dev \
  tk8.6-dev wget libmysqlclient-dev mariadb-client mariadb-common curl rlwrap wkhtmltopdf python-pip sudo \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Setup pip
RUN pip install --upgrade setuptools pip && rm -rf ~/.cache/pip

# Install Node.js and yarn
RUN curl https://deb.nodesource.com/node_10.x/pool/main/n/nodejs/nodejs_10.10.0-1nodesource1_amd64.deb > node.deb \
  && dpkg -i node.deb \
  && rm node.deb \
  && npm install -g yarn

# Install su-exec (like gosu, but a lot smaller)
RUN curl -L https://github.com/ncopa/su-exec/archive/dddd1567b7c76365e1e0aac561287975020a8fad.tar.gz | tar xvz && \ 
  cd su-exec-* && make && mv su-exec /usr/local/bin && cd .. && rm -rf su-exec-*

# Add frappe user and setup sudo for it
RUN useradd -ms /bin/bash -G sudo frappe \
  && printf '# Sudo rules for frappe\nfrappe ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/frappe \
  && mkdir /home/frappe/frappe-bench

USER root
# Install bench
RUN pip install -e git+https://github.com/frappe/bench.git#egg=bench --no-cache

# Add entrypoint
COPY ./docker-entrypoint.sh /bin/entrypoint
RUN chmod 777 /bin/entrypoint

EXPOSE 8000
EXPOSE 9000
EXPOSE 6787

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

HEALTHCHECK --start-period=5m \
  CMD curl -f http://localhost:${WEBSERVER_PORT} || exit 1

ENTRYPOINT [ "/bin/entrypoint" ]
