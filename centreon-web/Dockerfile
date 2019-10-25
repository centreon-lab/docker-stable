FROM centos:7

LABEL maintainer="Luiz Costa <me@luizgustavo.pro.br>"

ENV CENTREON_REPO_VERSION centreon-release-19.10-1.el7.centos.noarch.rpm
ENV TIMEZONE "Europe/Paris"

RUN yum install -y \
    centos-release-scl \
    iproute \
    wget \
    sudo \
    openssh-clients \
    postfix \
    rsyslog \
    cronie \
    net-snmp \
    ntp \
  && yum install --nogpgcheck -y http://yum.centreon.com/standard/19.10/el7/stable/noarch/RPMS/${CENTREON_REPO_VERSION} \
  && yum install -y \
    centreon-base-config-centreon-engine \
    centreon-widget-* \
  && yum install -y epel-release \
  && yum install -y supervisor \
  && yum remove -y epel-release \
  && echo "date.timezone = ${TIMEZONE}" > /etc/opt/rh/rh-php72/php.d/php-timezone.ini

# Add postfix-wrapper
# From: https://www.snip2code.com/Snippet/309436/postfix-wrapper-sh-for-supervisord-in-do
COPY files/postfix-wrapper.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/postfix-wrapper.sh

# Copy supervisor configuration services
COPY files/supervisord/centreon-broker.ini /etc/supervisord.d/
COPY files/supervisord/centreon-core.ini /etc/supervisord.d/
COPY files/supervisord/centreon-engine.ini /etc/supervisord.d/
COPY files/supervisord/crond.ini /etc/supervisord.d/
COPY files/supervisord/php-fpm.ini /etc/supervisord.d/
COPY files/supervisord/apache-httpd.ini /etc/supervisord.d/
COPY files/supervisord/postfix.ini /etc/supervisord.d/
COPY files/supervisord/rsyslog.ini /etc/supervisord.d/
COPY files/supervisord/snmpd.ini /etc/supervisord.d/
COPY files/supervisord/ntpd.ini /etc/supervisord.d/

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

CMD /start.sh
