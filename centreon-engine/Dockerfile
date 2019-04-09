FROM centos:7

LABEL maintainer="Luiz Costa <me@luizgustavo.pro.br>"

ENV CENTREON_REPO_VERSION centreon-release-19.04-1.el7.centos.noarch.rpm
ENV BRANCH_CENTREON_ENGINE master

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
    openssh-server \
  && wget http://yum.centreon.com/standard/19.04/el7/stable/noarch/RPMS/${CENTREON_REPO_VERSION} -O /tmp/${CENTREON_REPO_VERSION} \
  && yum install --nogpgcheck -y /tmp/${CENTREON_REPO_VERSION} \
  && yum-config-manager -q --enable centreon-canary \
  && yum-config-manager -q --enable centreon-canary-noarch \
  && yum install -y \
    centreon-engine \
  && wget -O - https://bootstrap.pypa.io/get-pip.py | python - \
  && pip install supervisor requests \
  && echo_supervisord_conf > /etc/supervisord.conf \
  && mkdir /etc/supervisor.d \
  && echo '[include]' >> /etc/supervisord.conf \
  && echo 'files = /etc/supervisor.d/*.ini' >> /etc/supervisord.conf \
  && ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''

COPY files/supervisord/sshd.ini /etc/supervisor.d/sshd.ini
COPY files/supervisord/centreon-engine.ini /etc/supervisor.d/centreon-engine.ini
COPY files/supervisord/postfix.ini /etc/supervisor.d/postfix.ini
COPY files/start.sh /start.sh
RUN chmod +x /start.sh

# Add postfix-wrapper
# From: https://www.snip2code.com/Snippet/309436/postfix-wrapper-sh-for-supervisord-in-do
COPY files/supervisord/postfix-wrapper.sh /usr/local/sbin/
RUN chmod +x /usr/local/sbin/postfix-wrapper.sh

CMD /start.sh