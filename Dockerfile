# Frappe Bench Dockerfile

FROM debian:9.6-slim
LABEL author=frappé

# Set locale C.UTF-8 for mariadb and general locale data
ENV PYTHONIOENCODING=utf-8
ENV LANGUAGE=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install all neccesary packages
RUN apt-get update && apt-get install -y --no-install-suggests --no-install-recommends build-essential cron curl git locales \
  libffi-dev liblcms2-dev libldap2-dev libmariadbclient-dev libsasl2-dev libssl-dev libtiff5-dev libwebp-dev mariadb-client \
  iputils-ping python-dev python-pip python-setuptools python-tk redis-tools rlwrap software-properties-common sudo tk8.6-dev \
  vim xfonts-75dpi xfonts-base wget wkhtmltopdf \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && echo "LC_ALL=en_US.UTF-8" >> /etc/environment \
  && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
  && echo "LANG=en_US.UTF-8" > /etc/locale.conf \
  && locale-gen en_US.UTF-8 \
  && wget https://deb.nodesource.com/node_10.x/pool/main/n/nodejs/nodejs_10.10.0-1nodesource1_amd64.deb -O node.deb \
  && dpkg -i node.deb \
  && rm node.deb \
  && npm install -g yarn \
  && wget https://github.com/ncopa/su-exec/archive/dddd1567b7c76365e1e0aac561287975020a8fad.tar.gz -O - | tar xvz \
  && cd su-exec-* && make \
  && mv su-exec /usr/local/bin \
  && cd .. && rm -rf su-exec-*

# Add frappe user and setup sudo
RUN groupadd -g 500 frappe \
  && useradd -ms /bin/bash -u 500 -g 500 -G sudo frappe \
  && printf '# Sudo rules for frappe\nfrappe ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/frappe \
  && chown -R 500:500 /home/frappe

# Install bench
WORKDIR /home/frappe

RUN git clone https://github.com/frappe/bench.git frappe-bench \
  && pip install -e frappe-bench \
  && chown -R frappe:frappe /home/frappe \
  && su-exec frappe bench init /home/frappe/frappe-bench --ignore-exist --skip-redis-config-generation

USER frappe

# Add some bench files
COPY --chown=frappe:frappe ./frappe-bench /home/frappe/frappe-bench

WORKDIR /home/frappe/frappe-bench

EXPOSE 8000 9000 6787

VOLUME [ "/home/frappe/frappe-bench/sites" ]
