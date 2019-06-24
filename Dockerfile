# Frappe Bench Dockerfile

FROM debian:9.6-slim
LABEL author=frappé

# Set locale C.UTF-8 for mariadb and general locale data
ENV PYTHONIOENCODING=utf-8
ENV LANGUAGE=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install all neccesary packages
RUN apt-get update && apt-get install -y --no-install-recommends \
  cron=3.0pl1-128+deb9u1 curl=7.52.1-5+deb9u9 git=1:2.11.0-3+deb9u4 libmariadbclient-dev=10.1.37-0+deb9u1 \
  locales=2.24-11+deb9u1 mariadb-client=10.1.37-0+deb9u1 python-dev=2.7.13-2 python-pip=9.0.1-2 \
  python-setuptools=33.1.1-1 python-wheel=0.29.0-2 sudo=1.8.19p1-2.1 vim=2:8.0.0197-4+deb9u1 wget=1.18-5+deb9u2 wkhtmltopdf=0.12.3.2-3 \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && echo "LC_ALL=en_US.UTF-8" >> /etc/environment \
  && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
  && echo "LANG=en_US.UTF-8" > /etc/locale.conf \
  && locale-gen en_US.UTF-8 \
  && wget https://deb.nodesource.com/node_10.x/pool/main/n/nodejs/nodejs_10.10.0-1nodesource1_amd64.deb -O node.deb \
  && dpkg -i node.deb \
  && rm node.deb \
  && npm install -g yarn@1.15.2\
  && wget https://github.com/ncopa/su-exec/archive/dddd1567b7c76365e1e0aac561287975020a8fad.tar.gz -O - | tar xvz \
  && cd su-exec-* && make \
  && mv su-exec /usr/local/bin \
  && cd .. && rm -rf su-exec-*

# Add frappe user and setup sudo
RUN groupadd -g 500 frappe \
  && useradd -ms /bin/bash -u 500 -g 500 -G sudo frappe \
  && printf '# Sudo rules for frappe\nfrappe ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/frappe \
  && chown -R 500:500 /home/frappe

WORKDIR /home/frappe

# Install bench
RUN pip install -e git+https://github.com/frappe/bench.git@ae9cef3f547df8eece4ec460e48ddac9851a3979#egg=bench --no-cache-dir \
  && chown -R 500:500 /home/frappe

USER frappe

RUN bench init /home/frappe/frappe-bench --verbose --skip-redis-config-generation

# Add some bench files
COPY --chown=500:500 ./frappe-bench /home/frappe/frappe-bench

WORKDIR /home/frappe/frappe-bench

EXPOSE 8000 9000 6787

VOLUME [ "/home/frappe/frappe-bench/sites" ]
