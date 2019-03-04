# Frappe Bench Dockerfile

FROM debian:9.6-slim
LABEL author=frappé

# Set locale C.UTF-8 for mariadb and general locale data
ENV LANG C.UTF-8

# Install all neccesary packages
RUN apt-get update && apt-get install -y --no-install-recommends iputils-ping=3:20161105-1 git=1:2.11.0-3+deb9u4 build-essential=12.3 python-minimal=2.7.13-2 \
  libffi-dev=3.2.1-6 libssl-dev=1.1.0j-1~deb9u1 libjpeg62-turbo-dev=1:1.5.1-2 redis-tools=3:3.2.6-3+deb9u2 software-properties-common=0.96.20.2-1 libxext6=2:1.3.3-1+b2 xfonts-75dpi=1:1.0.4+nmu1 xfonts-base=1:1.0.4+nmu1 \
  python3-dev=3.5.3-1 libfreetype6-dev=2.6.3-3.2 liblcms2-dev=2.8-4+deb9u1 libwebp-dev=0.5.2-1 python3-tk=3.5.3-1 libsasl2-dev=2.1.27~101-g0780600+dfsg-3 libldap2-dev=2.4.44+dfsg-5+deb9u2 libtiff5-dev=4.0.8-2+deb9u4 \
  python3-setuptools=33.1.1-1 tk8.6-dev=8.6.6-1+b1 wget=1.18-5+deb9u2 libmariadbclient-dev=10.1.37-0+deb9u1 mariadb-client=10.1.37-0+deb9u1 curl=7.52.1-5+deb9u9 rlwrap=0.42-3 wkhtmltopdf=0.12.3.2-3 python3-pip=9.0.1-2 sudo=1.8.19p1-2.1 \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && which pip3 && sudo ln -s /usr/bin/pip3 /usr/bin/pip \
  && pip install --upgrade setuptools pip --no-cache \
  && curl https://deb.nodesource.com/node_10.x/pool/main/n/nodejs/nodejs_10.10.0-1nodesource1_amd64.deb > node.deb \
  && dpkg -i node.deb \
  && rm node.deb \
  && npm install -g yarn

# Add frappe user and setup sudo
RUN useradd -ms /bin/bash -G sudo frappe \
  && printf '# Sudo rules for frappe\nfrappe ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/frappe

USER root
# Install bench
RUN pip install -e git+https://github.com/frappe/bench.git#egg=bench --no-cache
COPY --chown=frappe:frappe ./frappe-bench /home/frappe/frappe-bench


USER frappe
WORKDIR /home/frappe/frappe-bench

EXPOSE 8000
EXPOSE 9000
EXPOSE 6787

VOLUME [ "/home/frappe/frappe-bench" ]