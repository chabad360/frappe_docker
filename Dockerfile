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
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && wget https://github.com/ncopa/su-exec/archive/dddd1567b7c76365e1e0aac561287975020a8fad.tar.gz -O - | tar xvz \ 
  && cd su-exec-* && make \
  && mv su-exec /usr/local/bin \
  && cd .. && rm -rf su-exec-*

# Install Node.js and yarn
RUN curl https://deb.nodesource.com/node_10.x/pool/main/n/nodejs/nodejs_10.10.0-1nodesource1_amd64.deb > node.deb \
  && dpkg -i node.deb \
  && rm node.deb \
  && npm install -g yarn

# Add frappe user and setup sudo
RUN useradd -ms /bin/bash -G sudo frappe \
  && printf '# Sudo rules for frappe\nfrappe ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/frappe 

# Install bench
RUN git clone https://github.com/frappe/bench.git /home/frappe/frappe-bench \
  && pip install -e /home/frappe/frappe-bench \
  && chown -R frappe:frappe /home/frappe/

# Add some bench files
COPY --chown=frappe:frappe ./frappe-bench /home/frappe/frappe-bench

RUN su-exec frappe bench init /home/frappe/frappe-bench --ignore-exist --skip-redis-config-generation

USER frappe
WORKDIR /home/frappe/frappe-bench

EXPOSE 8000
EXPOSE 9000
EXPOSE 6787

VOLUME [ "/home/frappe/frappe-bench" ]
