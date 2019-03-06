# Frappe Bench Dockerfile

FROM debian:9.6-slim
LABEL author=frappé

# Set locale C.UTF-8 for mariadb and general locale data
ENV LANG C.UTF-8

# Install all neccesary packages
RUN apt-get update && apt-get install -y --no-install-recommends git=1:2.11.0-3+deb9u4 cron=3.0pl1-128+deb9u1 \
  python-dev=2.7.13-2 python-setuptools=33.1.1-1 wget=1.18-5+deb9u2 libmariadbclient-dev=10.1.37-0+deb9u1 vim=2:8.0.0197-4+deb9u1 \
  curl=7.52.1-5+deb9u9 wkhtmltopdf=0.12.3.2-3 python-pip=9.0.1-2 sudo=1.8.19p1-2.1 mariadb-client=10.1.37-0+deb9u1 \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && curl https://deb.nodesource.com/node_10.x/pool/main/n/nodejs/nodejs_10.10.0-1nodesource1_amd64.deb > node.deb \
  && dpkg -i node.deb \
  && rm node.deb \
  && npm install -g yarn

# Add frappe user and setup sudo
RUN useradd -ms /bin/bash -G sudo frappe \
  && printf '# Sudo rules for frappe\nfrappe ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/frappe

# Install bench
RUN pip install -e git+https://github.com/frappe/bench.git@ae9cef3f547df8eece4ec460e48ddac9851a3979#egg=bench --no-cache-dir
COPY --chown=frappe:frappe ./frappe-bench /home/frappe/frappe-bench
RUN chown -R frappe:frappe /home/frappe

USER frappe
WORKDIR /home/frappe/frappe-bench

EXPOSE 8000
EXPOSE 9000
EXPOSE 6787

VOLUME [ "/home/frappe/frappe-bench" ]