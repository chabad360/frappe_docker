# Frappe Bench Dockerfile

FROM ubuntu:16.04
LABEL author=frappé

# Generate locale C.UTF-8 for mariadb and general locale data
ENV LANG C.UTF-8

# Install all neccesary packages
RUN apt-get update && apt-get install -y --no-install-recommends iputils-ping git build-essential python-setuptools python-dev libffi-dev libssl-dev \
  libjpeg8-dev redis-tools redis-server software-properties-common libxrender1 libxext6 xfonts-75dpi xfonts-base zlib1g-dev \
  libfreetype6-dev liblcms2-dev libwebp-dev python-tk apt-transport-https libsasl2-dev libldap2-dev libtiff5-dev tcl8.6-dev \
  tk8.6-dev wget libmysqlclient-dev mariadb-client mariadb-common curl rlwrap wkhtmltopdf python-pip sudo \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Setup pip
RUN pip install --upgrade setuptools pip && rm -rf ~/.cache/pip

# Install Node.js
RUN curl https://deb.nodesource.com/node_10.x/pool/main/n/nodejs/nodejs_10.10.0-1nodesource1_amd64.deb > node.deb \
 && dpkg -i node.deb \
 && rm node.deb

# Setup user
RUN useradd -ms /bin/bash -G sudo frappe && printf '# Sudo rules for frappe\nfrappe ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/frappe
USER frappe
WORKDIR /home/frappe
# Add some bench files
COPY ./frappe-bench /home/frappe/frappe-bench
# Download the bench utility
RUN chown -R frappe:frappe /home/frappe \
  && git clone -b master https://github.com/frappe/bench.git bench-repo

USER root
# Install bench and yarn
RUN pip install -e bench-repo && rm -rf ~/.cache/pip \
  && npm install -g yarn

USER frappe
WORKDIR /home/frappe/frappe-bench
