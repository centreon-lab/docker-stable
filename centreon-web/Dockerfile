FROM centos:7

LABEL maintainer="Luiz Costa <me@luizgustavo.pro.br>"

ENV CENTREON_REPO_VERSION centreon-release-19.04-1.el7.centos.noarch.rpm
ENV BRANCH_CENTREON_WEB master
ENV BRANCH_CENTREON_BROKER master
ENV BRANCH_CENTREON_ENGINE master
ENV TIMEZONE "Europe/Paris"

RUN yum install -y \
    centos-release-scl \
    wget \
    sudo \
    openssh-clients \
    postfix \
    rsyslog \
    python-devel \
    git \
    unzip \
    cronie \
  && wget http://yum.centreon.com/standard/19.04/el7/stable/noarch/RPMS/${CENTREON_REPO_VERSION} -O /tmp/${CENTREON_REPO_VERSION} \
  && yum install --nogpgcheck -y /tmp/${CENTREON_REPO_VERSION} \
  && yum-config-manager -q --enable centreon-canary \
  && yum-config-manager -q --enable centreon-canary-noarch \
  && yum install -y \
    centreon-clib-devel \
    gcc \
    gcc-c++ \
    make \
    cmake

RUN echo "Compiling and installing Centreon-Broker..." \
  && yum install -y \
    lua-devel \
    rrdtool-devel \
    qt4-devel \
    qt4-mysql \
    gnutls-devel \
  && export PATH="$PATH:/usr/lib64/qt4/bin" \
  && groupadd centreon-broker \
  && useradd -g centreon-broker -m -r -d /var/lib/centreon-broker centreon-broker \
  && cd /tmp \
  && wget -O centreon-broker-${BRANCH_CENTREON_BROKER}.zip https://github.com/centreon/centreon-broker/archive/${BRANCH_CENTREON_BROKER}.zip \
  && unzip centreon-broker-${BRANCH_CENTREON_BROKER}.zip \
  && cd centreon-broker-${BRANCH_CENTREON_BROKER}/build \
  && cmake \
    -DWITH_DAEMONS='central-broker;central-rrd' \
    -DWITH_GROUP=centreon-broker \
    -DWITH_PREFIX=/usr \
    -DWITH_PREFIX_BIN=/usr/sbin \
    -DWITH_PREFIX_CONF=/etc/centreon-broker \
    -DWITH_PREFIX_INC=/usr/include/centreon-broker \
    -DWITH_PREFIX_LIB=/usr/lib/nagios \
    -DWITH_PREFIX_MODULES=/usr/share/centreon/lib/centreon-broker \
    -DWITH_PREFIX_VAR=/var/lib/centreon-broker \
    -DWITH_TESTING=0 \
    -DWITH_USER=centreon-broker . \
  && make \
  && make install \
  && mkdir -p /var/log/centreon-broker \
  && chown centreon-broker:centreon-broker /var/log/centreon-broker

RUN echo "Compiling and installing Centreon-Engine..." \
  && groupadd centreon-engine \
  && useradd -g centreon-engine -m -r -d /var/lib/centreon-engine centreon-engine \
  && cd /tmp \
  && wget -O centreon-engine-${BRANCH_CENTREON_ENGINE}.zip https://github.com/centreon/centreon-engine/archive/${BRANCH_CENTREON_ENGINE}.zip \
  && unzip centreon-engine-${BRANCH_CENTREON_ENGINE}.zip \
  && cd centreon-engine-${BRANCH_CENTREON_ENGINE}/build \
  && cmake \
   -DWITH_PREFIX=/usr \
   -DWITH_PREFIX_BIN=/usr/sbin \
   -DWITH_PREFIX_CONF=/etc/centreon-engine \
   -DWITH_PREFIX_LIB=/usr/lib/centreon-engine \
   -DWITH_USER=centreon-engine \
   -DWITH_GROUP=centreon-engine \
   -DWITH_VAR_DIR=/var/log/centreon-engine \
   -DWITH_RW_DIR=/var/lib/centreon-engine/rw \
   -DWITH_PKGCONFIG_DIR=/usr/lib/pkgconfig \
   -DWITH_TESTING=0 \
  && make \
  && make install \
  && mkdir -p /usr/share/centreon-engine

RUN echo "Compiling and installing Centreon-Web..." \
  && groupadd centreon \
  && useradd -g centreon -m -r -d /var/lib/centreon centreon \
  && yum install -y \
    rh-php71-php-zip \
    rh-php71-php-xml \
    rh-php71-php-fpm \
    rh-php71-php-process \
    rh-php71-php-pecl-gnupg \
    rh-php71-php-common \
    rh-php71-php-pdo \
    rh-php71-php-intl \
    rh-php71-php-pear \
    rh-php71-php-json \
    rh-php71-php-mysqlnd \
    rh-php71-php-ldap \
    rh-php71-php-gd \
    rh-php71-php-cli \
    rh-php71-php-mbstring \
    rh-php71-php-snmp \
    rh-php71-ioncube-loader \
    perl-DBD-MySQL \
    perl-Sys-Syslog \
    centreon-plugins-base \
    httpd \
    centreon-plugin-Operatingsystems-Linux-Local \
    centreon-plugin-Operatingsystems-Linux-Snmp \
  && export PATH=$PATH:/opt/rh/rh-php71/root/usr/bin \
  && /opt/rh/rh-php71/root/bin/php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');" \
  && /opt/rh/rh-php71/root/bin/php /tmp/composer-setup.php --install-dir=/usr/sbin --filename=composer \
  && cd /tmp \
  && wget -O centreon-web-${BRANCH_CENTREON_WEB}.zip https://github.com/centreon/centreon/archive/${BRANCH_CENTREON_WEB}.zip \
  && unzip centreon-web-${BRANCH_CENTREON_WEB}.zip \
  && cd centreon-${BRANCH_CENTREON_WEB} \
  && mkdir -vp /usr/share/centreon/config \
  && mkdir -vp /etc/centreon \
  && mkdir -vp /var/log/centreon \
  && cp -vRf lib/perl/centreon /usr/share/perl5/vendor_perl/ \
  && cp -vRf bin /usr/share/centreon \
  && cp -vRf GPL_LIB /usr/share/centreon \
  && cp -vRf cron /usr/share/centreon \
  && cp -vrf config /usr/share/centreon/ \
  && cp -vf config/centreon.config.php.template /usr/share/centreon/config/centreon.config.php \
  && sed -i \
    -e 's:@CENTREON_ETC@:/etc/centreon:g' \
    /usr/share/centreon/config/centreon.config.php \
  && cp -vf bootstrap.php /usr/share/centreon \
  && cp -vf composer.json /usr/share/centreon \
  && cp -vRf src /usr/share/centreon \
  && cd /tmp/centreon-${BRANCH_CENTREON_WEB} \
  && composer install --no-dev \
  && curl -sL https://rpm.nodesource.com/setup_10.x | bash - \
  && yum install -y nodejs \
  && npm install \
  && npm run build \
  && npm prune --production \
  && cp -vrf www /usr/share/centreon/ \
  && cp -vrf vendor /usr/share/centreon/ \
  && cp -vra lang/fr_FR.UTF-8 lang/en_US.UTF-8 \
  && for LANG in en_US.UTF-8 es_ES.UTF-8 fr_FR.UTF-8 pt_BR.UTF-8 pt_PT.UTF-8; do \
    cd /tmp/centreon-${BRANCH_CENTREON_WEB}/lang/${LANG}/LC_MESSAGES \
    && msgfmt -v messages.po -o messages.mo \
    && msgfmt -v help.po -o help.mo \
    && mkdir -vp /usr/share/centreon/www/locale/${LANG}/LC_MESSAGES \
    && mv -v messages.mo help.mo /usr/share/centreon/www/locale/${LANG}/LC_MESSAGES/ \
    && /opt/rh/rh-php71/root/bin/php /tmp/centreon-${BRANCH_CENTREON_WEB}/bin/centreon-translations.php \
      $(echo $LANG | cut -f1 -d_) messages.po \
      /usr/share/centreon/www/locale/${LANG}/LC_MESSAGES/messages.ser \
    && /opt/rh/rh-php71/root/bin/php /tmp/centreon-${BRANCH_CENTREON_WEB}/bin/centreon-translations.php \
      $(echo $LANG | cut -f1 -d_) help.po \
      /usr/share/centreon/www/locale/${LANG}/LC_MESSAGES/help.ser; \
  done \
  && cp -vp /usr/share/centreon/www/install/install.conf.dist.php /usr/share/centreon/www/install/install.conf.php \
  && mkdir -vp /usr/share/centreon/installDir \
  && mkdir -vp /usr/share/centreon/filesGeneration \
  && mkdir -vp /usr/share/centreon/filesUpload \
  && chown -v apache:centreon /usr/share/centreon/installDir \
  && chown -v apache:centreon /usr/share/centreon/filesGeneration \
  && chown -v apache:centreon /usr/share/centreon/filesUpload \
  && chown -vR apache:centreon /usr/share/centreon/www \
  && chown -vR apache:centreon /usr/share/centreon/vendor \
  && chown -vR apache:centreon /usr/share/centreon/GPL_LIB/SmartyCache \
  && chown -vR apache:centreon /etc/centreon \
  && wget -O - https://bootstrap.pypa.io/get-pip.py | python - \
  && pip install supervisor requests \
  && echo_supervisord_conf > /etc/supervisord.conf \
  && mkdir /etc/supervisor.d \
  && echo '[include]' >> /etc/supervisord.conf \
  && echo 'files = /etc/supervisor.d/*.ini' >> /etc/supervisord.conf \
  && echo "date.timezone = ${TIMEZONE}" > /etc/opt/rh/rh-php71/php.d/php-timezone.ini \
  && echo "max_execution_time = 300" > /etc/opt/rh/rh-php71/php.d/50-centreon.ini \
  && rm -f /etc/opt/rh/rh-php71/php-fpm.d/www.conf \
  && mkdir -vp /var/opt/rh/rh-php71/lib/php/session \
  && chown apache:centreon /var/opt/rh/rh-php71/lib/php/session \
  && mkdir -vp /var/opt/rh/rh-php71/lib/php/wsdlcache \
  && chown apache:centreon /var/opt/rh/rh-php71/lib/php/wsdlcache \
  && usermod -G centreon,centreon-broker,apache centreon-engine \
  && usermod -G centreon,centreon-engine,apache centreon-broker \
  && usermod -G centreon,centreon-engine,centreon-broker apache \
  && usermod -G centreon-broker,centreon-engine,apache centreon

# Add postfix-wrapper
# From: https://www.snip2code.com/Snippet/309436/postfix-wrapper-sh-for-supervisord-in-do
COPY files/postfix-wrapper.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/postfix-wrapper.sh

# Copy supervisor configuration services
COPY files/supervisord/centreon-broker.ini /etc/supervisor.d/
COPY files/supervisord/centreon-core.ini /etc/supervisor.d/
COPY files/supervisord/centreon-engine.ini /etc/supervisor.d/
COPY files/supervisord/crond.ini /etc/supervisor.d/
COPY files/supervisord/php-fpm.ini /etc/supervisor.d/
COPY files/supervisord/apache-httpd.ini /etc/supervisor.d/
COPY files/supervisord/postfix.ini /etc/supervisor.d/
COPY files/supervisord/rsyslog.ini /etc/supervisor.d/

# Add fake init scripts (used by centreon web)
COPY files/init-fake/centengine /etc/init.d/centengine
COPY files/init-fake/centcore /etc/init.d/centcore
COPY files/init-fake/cbd /etc/init.d/cbd
RUN chmod +x \
  /etc/init.d/centengine \
  /etc/init.d/centcore \
  /etc/init.d/cbd

COPY files/start.sh /start.sh
RUN chmod +x /start.sh

# Centreon config
COPY files/central-broker.xml /etc/centreon-broker/
COPY files/central-rrd.xml /etc/centreon-broker/
COPY files/poller-module.xml /etc/centreon-broker/
COPY files/watchdog.xml /etc/centreon-broker/
RUN chown -R centreon-broker:centreon-broker /etc/centreon-broker
COPY files/conf.pm /tmp/conf.pm
COPY files/centreon.conf.php /tmp/centreon.conf.php
COPY files/centreon-connector/centreon_connector_perl /usr/lib64/centreon-connector/centreon_connector_perl
COPY files/centreon-connector/centreon_connector_ssh /usr/lib64/centreon-connector/centreon_connector_ssh
COPY files/10-centreon.conf /etc/httpd/conf.d/10-centreon.conf
COPY files/php-fpm.conf /etc/opt/rh/rh-php71/php-fpm.d/centreon.conf

CMD /start.sh
