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
    centreon-base-config-centreon-engine \
  && wget -O - https://bootstrap.pypa.io/get-pip.py | python - \
  && pip install supervisor requests \
  && echo_supervisord_conf > /etc/supervisord.conf \
  && mkdir /etc/supervisor.d \
  && echo '[include]' >> /etc/supervisord.conf \
  && echo 'files = /etc/supervisor.d/*.ini' >> /etc/supervisord.conf \
  && echo "date.timezone = ${TIMEZONE}" > /etc/opt/rh/rh-php71/php.d/php-timezone.ini

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

CMD /start.sh
