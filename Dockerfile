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
  adduser ca-certificates coreutils cron curl debconf debianutils dh-python dpkg fontconfig \
  fontconfig-config fonts-dejavu-core gcc-8-base git git-man init-system-helpers iso-codes \
  libacl1 libaio1 libattr1 libaudit-common libaudit1 libavahi-client3 libavahi-common-data \
  libavahi-common3 libblkid1 libbrotli1 libbsd0 libbz2-1.0 libc-bin libc-dev-bin libc-l10n \
  libc6 libc6-dev libcap-ng0 libcap2 libcap2-bin libcom-err2 libconfig-inifiles-perl libcups2 \
  libcurl3-gnutls libcurl4 libdb5.3 libdbus-1-3 libdouble-conversion1 libdrm-amdgpu1 libdrm-common \
  libdrm-intel1 libdrm-nouveau2 libdrm-radeon1 libdrm2 libedit2 libegl-mesa0 libegl1 libelf1 \
  liberror-perl libevdev2 libevent-2.1-6 libexpat1 libexpat1-dev libffi6 libfontconfig1 \
  libfreetype6 libgbm1 libgcc1 libgcrypt20 libgdbm-compat4 libgdbm6 libgl1 libgl1-mesa-dri \
  libglapi-mesa libglib2.0-0 libglvnd0 libglx-mesa0 libglx0 libgmp10 libgnutls-dane0 \
  libgnutls-openssl27 libgnutls28-dev libgnutls30 libgnutlsxx28 libgpg-error0 libgpm2 \
  libgraphite2-3 libgssapi-krb5-2 libgstreamer-plugins-base1.0-0 libgstreamer1.0-0 libgudev-1.0-0 \
  libharfbuzz0b libhogweed4 libhyphen0 libice6 libicu63 libidn2-0 libidn2-dev libinput-bin \
  libinput10 libjpeg62-turbo libk5crypto3 libkeyutils1 libkrb5-3 libkrb5support0 libldap-2.4-2 \
  libldap-common libllvm7 liblz4-1 liblzma5 libmariadb-dev libmariadb3 libmariadbclient-dev \
  libmount1 libmpdec2 libmtdev1 libncurses6 libncursesw6 libnettle6 libnghttp2-14 liborc-0.4-0 \
  libp11-kit-dev libp11-kit0 libpam-modules libpam-modules-bin libpam-runtime libpam0g \
  libpciaccess0 libpcre2-16-0 libpcre2-8-0 libpcre3 libperl5.28 libpng16-16 libpsl5 \
  libpython3-dev libpython3-stdlib libpython3.7 libpython3.7-dev libpython3.7-minimal \
  libpython3.7-stdlib libqt5core5a libqt5dbus5 libqt5gui5 libqt5network5 libqt5positioning5 \
  libqt5printsupport5 libqt5qml5 libqt5quick5 libqt5sensors5 libqt5svg5 libqt5webchannel5 \
  libqt5webkit5 libqt5widgets5 libqt5xmlpatterns5 libreadline5 libreadline7 librtmp1 libsasl2-2 \
  libsasl2-modules-db libselinux1 libsemanage-common libsemanage1 libsensors-config libsensors5 \
  libsepol1 libsm6 libsnappy1v5 libsqlite3-0 libssh2-1 libssl1.1 libstdc++6 libsystemd0 libtasn1-6 \
  libtasn1-6-dev libtinfo6 libudev1 libunbound8 libunistring2 libuuid1 libwacom-common libwacom2 \
  libwayland-client0 libwayland-server0 libwebp6 libwoff1 libx11-6 libx11-data libx11-xcb1 libxau6 \
  libxcb-dri2-0 libxcb-dri3-0 libxcb-glx0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 \
  libxcb-present0 libxcb-randr0 libxcb-render-util0 libxcb-render0 libxcb-shape0 libxcb-shm0 \
  libxcb-sync1 libxcb-util0 libxcb-xfixes0 libxcb-xinerama0 libxcb-xkb1 libxcb1 libxdamage1 \
  libxdmcp6 libxext6 libxfixes3 libxi6 libxkbcommon-x11-0 libxkbcommon0 libxml2 libxrender1 \
  libxshmfence1 libxslt1.1 libxxf86vm1 linux-libc-dev locales lsb-base mariadb-client \
  mariadb-client-10.3 mariadb-client-core-10.3 mariadb-common mime-support mysql-common \
  nettle-dev openssl passwd perl perl-base perl-modules-5.28 python-pip-whl python3 python3-dev \
  python3-distutils python3-lib2to3 python3-minimal python3-pip python3-pkg-resources \
  python3-setuptools python3-wheel python3.7 python3.7-dev python3.7-minimal readline-common \
  sensible-utils sudo tar ucf vim vim-common vim-runtime wget wkhtmltopdf x11-common xkb-data xxd \
  zlib1g zlib1g-dev \
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
