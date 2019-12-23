# Frappe Bench Dockerfile

FROM debian:10.1-slim
LABEL author=frappé

# Set locale C.UTF-8 for mariadb and general locale data
ENV PYTHONIOENCODING=utf-8
ENV LANGUAGE=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Using apt-lock to ensure correct versions are installed
ADD https://github.com/TrevorSundberg/apt-lock/releases/download/v1.0.1/apt-lock-linux-x64 /usr/local/bin/apt-lock
RUN chmod +x /usr/local/bin/apt-lock
COPY apt-lock.json .

# Install all neccesary packages
# Will neeed this later: build-essential=12.3
RUN apt-get update && apt-lock apt-get install -y --no-install-recommends \
  cron curl git libmariadbclient-dev locales mariadb-client python3-dev python3-pip \
  python3-setuptools python3-wheel sudo vim wget wkhtmltopdf \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && echo "LC_ALL=en_US.UTF-8" >> /etc/environment \
  && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
  && echo "LANG=en_US.UTF-8" > /etc/locale.conf \
  && locale-gen en_US.UTF-8 \
  && wget https://deb.nodesource.com/node_10.x/pool/main/n/nodejs/nodejs_10.10.0-1nodesource1_amd64.deb -O node.deb \
  && dpkg -i --force-depends node.deb && rm node.deb \
  && npm config set python python3 \
  && npm install -g yarn@1.15.2
#  && wget https://github.com/ncopa/su-exec/archive/dddd1567b7c76365e1e0aac561287975020a8fad.tar.gz -O - | tar xvz \
#  && cd su-exec-* && make \
#  && mv su-exec /usr/local/bin \
#  && cd .. && rm -rf su-exec-*

# Add frappe user and setup sudo
RUN groupadd -g 500 frappe \
  && useradd -ms /bin/bash -u 500 -g 500 -G sudo frappe \
  && printf '# Sudo rules for frappe\nfrappe ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/frappe \
  && chown -R 500:500 /home/frappe

WORKDIR /home/frappe

# Install bench
RUN pip3 install -e git+https://github.com/frappe/bench.git@ae9cef3f547df8eece4ec460e48ddac9851a3979#egg=bench --no-cache-dir \
  && chown -R 500:500 /home/frappe \
  && rm -rf /usr/local/bin/apt-lock

USER frappe

RUN bench init /home/frappe/frappe-bench --verbose --skip-redis-config-generation --frappe-branch=v11.1.36 --python python3

# Add some bench files
COPY --chown=500:500 ./frappe-bench /home/frappe/frappe-bench

WORKDIR /home/frappe/frappe-bench

EXPOSE 8000 9000 6787

VOLUME [ "/home/frappe/frappe-bench/sites" ]
