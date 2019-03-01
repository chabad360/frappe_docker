# Frappe Bench Dockerfile

FROM ubuntu:16.04
LABEL author=frappé

# Set locale C.UTF-8 for mariadb and general locale data
ENV LANG C.UTF-8

# Install all neccesary packages
RUN apt-get update && apt-get install -y --no-install-recommends iputils-ping git build-essential cron \
  libffi-dev libssl-dev libjpeg8-dev redis-tools software-properties-common libxext6 xfonts-75dpi xfonts-base \
  python-dev libfreetype6-dev liblcms2-dev libwebp-dev python-tk libsasl2-dev libldap2-dev libtiff5-dev vim \
  python-setuptools tk8.6-dev wget libmysqlclient-dev mariadb-client curl rlwrap wkhtmltopdf python-pip sudo \
  && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN pip install --upgrade setuptools pip && rm -rf ~/.cache/pip

# Install Node.js and yarn
RUN curl https://deb.nodesource.com/node_10.x/pool/main/n/nodejs/nodejs_10.10.0-1nodesource1_amd64.deb > node.deb \
  && dpkg -i node.deb \
  && rm node.deb \
  && npm install -g yarn

# Add frappe user and setup sudo
RUN useradd -ms /bin/bash -G sudo frappe \
  && printf '# Sudo rules for frappe\nfrappe ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/frappe

# Install bench
RUN pip install -e git+https://github.com/frappe/bench.git#egg=bench --no-cache

USER frappe
# Add some bench files
COPY --chown=frappe:frappe ./frappe-bench /home/frappe/frappe-bench
RUN sudo chown -R frappe:frappe /home/frappe/

WORKDIR /home/frappe
RUN bench init frappe-bench --ignore-exist --skip-redis-config-generation


EXPOSE 8000
EXPOSE 9000
EXPOSE 6787

VOLUME [ "/home/frappe/frappe-bench" ]
