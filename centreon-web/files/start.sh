#!/bin/sh

# Test the variables
MYSQL_PORT="${MYSQL_PORT:=3306}"
if [ -z "$MYSQL_HOST" ]; then
    echo "Need define the MYSQL_HOST variable !"
    exit 1;
fi
if [ -z "$MYSQL_USER" ]; then
    echo "Need define the MYSQL_USER variable !"
    exit 1;
fi
if [ -z "$MYSQL_PASSWD" ]; then
    echo "Need define the MYSQL_PASSWD variable !"
    exit 1;
fi
if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
    echo "Need define the MYSQL_ROOT_PASSWORD variable !"
    exit 1;
fi
if ! grep -q "/var/spool/centreon/.ssh/id_rsa" /proc/mounts; then
    echo "Need mount a private key to use with SSH !"
    echo "Use the argument (example): \"--mount type=bind,source=\$(pwd)/ssh/id_rsa,target=/var/spool/centreon/.ssh/id_rsa\""
    exit 1;
fi

MakeConf() {
    mv /tmp/conf.pm /etc/centreon/
    mv /tmp/centreon.conf.php /etc/centreon/
    for SFILE in \
        "/etc/centreon/conf.pm" \
        "/etc/centreon/centreon.conf.php"
    do
        sed -i \
        -e "s/--DBUSER--/${MYSQL_USER}/g" \
        -e "s/--DBPASS--/${MYSQL_PASSWD}/g" \
        -e "s/--ADDRESS--/${MYSQL_HOST}/g" \
        -e "s/--DBPORT--/${MYSQL_PORT}/g" \
        $SFILE
    done
}

testMySQL() {
    sleep 15
    if /opt/rh/rh-php71/root/usr/bin/php -r 'try { $db = new PDO("mysql:host=".getenv("MYSQL_HOST"), "root", getenv("MYSQL_ROOT_PASSWORD")); exit(0); } catch (Exception $e) { exit(1); }'; then
        /opt/rh/rh-php71/root/usr/bin/php -r 'try { $db = new PDO("mysql:dbname=centreon;host=".getenv("MYSQL_HOST"), "root", getenv("MYSQL_ROOT_PASSWORD")); exit(0); } catch (Exception $e) { exit(1); }'
        echo $?
    else
        echo "You need a valid connection to your MySQL server !"
        exit 1;
    fi
}

InstallDbCentreon() {
    echo "Starting Apache to apply configuration ..."
    /usr/sbin/httpd -DFOREGROUND &2> /dev/null
    PID_HTTPD=$!
    echo "Starting PHP-FPM to apply configuration ..."
    /opt/rh/rh-php71/root/usr/sbin/php-fpm -F &2> /dev/null
    PID_PHPFPM=$!

    sleep 5 # waiting start httpd process

    CENTREON_HOST="http://localhost"
    COOKIE_FILE="/tmp/install.cookie"
    CURL_CMD="curl -q -o /dev/null -b ${COOKIE_FILE}"

    curl -q -o /dev/null -c ${COOKIE_FILE} ${CENTREON_HOST}/centreon/install/install.php
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=stepContent"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step3.php" \
        --data "install_dir_engine=%2Fusr%2Fshare%2Fcentreon-engine&centreon_engine_stats_binary=%2Fusr%2Fsbin%2Fcentenginestats&monitoring_var_lib=%2Fvar%2Flib%2Fcentreon-engine&centreon_engine_connectors=%2Fusr%2Flib64%2Fcentreon-connector&centreon_engine_lib=%2Fusr%2Flib%2Fcentreon-engine&centreonplugins=%2Fusr%2Flib%2Fcentreon%2Fplugins%2F"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step4.php" \
        --data "centreonbroker_etc=%2Fetc%2Fcentreon-broker&centreonbroker_cbmod=%2Fusr%2Flib%2Fnagios%2Fcbmod.so&centreonbroker_log=%2Fvar%2Flog%2Fcentreon-broker&centreonbroker_varlib=%2Fvar%2Flib%2Fcentreon-broker&centreonbroker_lib=%2Fusr%2Fshare%2Fcentreon%2Flib%2Fcentreon-broker"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step5.php" \
        --data "admin_password=${CENTREON_ADMIN_PASSWD}&confirm_password=${CENTREON_ADMIN_PASSWD}&firstname=${CENTREON_ADMIN_NAME}&lastname=${CENTREON_ADMIN_NAME}&email=${CENTREON_ADMIN_EMAIL}"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step6.php" \
        --data "address=${MYSQL_HOST}&port=${MYSQL_PORT}&root_password=${MYSQL_ROOT_PASSWORD}&db_configuration=centreon&db_storage=centreon_storage&db_user=${MYSQL_USER}&db_password=${MYSQL_PASSWD}&db_password_confirm=${MYSQL_PASSWD}"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/configFileSetup.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/installConfigurationDb.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/installStorageDb.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/createDbUser.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/insertBaseConf.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/partitionTables.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step8.php" \
        --data "modules%5B%5D=centreon-license-manager&modules%5B%5D=centreon-pp-manager"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step9.php" \
        --data "send_statistics=1"

    echo "Kill Apache and PHP-FPM ..."
    kill $PID_HTTPD
    kill $PID_PHPFPM
}


# Test connection with Mysql
echo "Testing connection with database."
echo "Waiting Mysql server up to testing connection (15 secs) ..."
if [ "$(testMySQL)" -eq 0 ]; then
    if [ ! -d "/etc/centreon" ]; then
        mkdir -p /etc/centreon
    fi
    echo -n "Connection exist, preparing configuration ..."
    MakeConf
    chown -R apache:centreon /etc/centreon
    echo "done"
else
    echo "Connection exist, but need create the initial database ..."
    InstallDbCentreon
    echo "done"
fi

# SSH Configuration
if [ ! -f "/var/spool/centreon/.ssh/known_hosts" ]; then
    touch /var/spool/centreon/.ssh/known_hosts
fi 
chmod -R 700 /var/spool/centreon/.ssh
chown -R centreon:centreon /var/spool/centreon/.ssh
if ! grep "StrictHostKeyChecking no" /etc/ssh/ssh_config; then
    echo "\tStrictHostKeyChecking no" >> /etc/ssh/ssh_config
fi

echo "Centreon Web ready !"

if [ -d "/usr/share/centreon/www/install" ]; then
    rm -rf /usr/share/centreon/www/install
fi
touch /var/log/centreon/login.log

# After Centreon configuration, install modules
#if [ ! "$(rpm -aq | grep centreon-map-release)" ]; then
#    yum install -y http://yum.centreon.com/centreon-map/bfcfef6922ae08bd2b641324188d8a5f/19.04/el7/stable/noarch/RPMS/centreon-map-release-19.04-1.el7.centos.noarch.rpm \
#    && yum-config-manager -y -q --disable centreon-map-stable \
#    && yum-config-manager -y -q --enable centreon-map-canary-noarch \
#    && yum install -y centreon-map-server
#fi
#if [ ! "$(rpm -aq | grep centreon-bam-release)" ]; then
#    yum install -y http://yum.centreon.com/centreon-bam/d4e1d7d3e888f596674453d1f20ff6d3/19.04/el7/stable/noarch/RPMS/centreon-bam-release-19.04-1.el7.centos.noarch.rpm \
#    && yum-config-manager -y -q --disable centreon-bam-stable \
#    && yum-config-manager -y -q --enable centreon-bam-canary-noarch \
#    && yum install -y centreon-bam-server
#fi
#if [ ! "$(rpm -aq | grep centreon-mbi-release)" ]; then
#    yum install -y http://yum.centreon.com/centreon-mbi/5e0524c1c4773a938c44139ea9d8b4d7/19.04/el7/stable/noarch/RPMS/centreon-mbi-release-19.04-1.el7.centos.noarch.rpm \
#    && yum-config-manager -y -q --disable centreon-mbi-stable \
#    && yum-config-manager -y -q --enable centreon-mbi-canary-noarch \
#    && yum install -y centreon-bi-server
#fi

# Fix permissions:
find /etc/centreon* -type d | xargs chmod -v 0775
find /etc/centreon* -type f | xargs chmod -v 0664
chown -v centreon:apache /var/log/centreon
chmod -v 0775 /var/log/centreon
chown -v centreon-engine:centreon-engine /var/log/centreon-engine
chown -v centreon-broker:centreon-broker /var/log/centreon-broker
chown -v centreon:centreon /var/lib/centreon/metrics
chown -v centreon:centreon /var/lib/centreon/status

su - root -c "/usr/bin/supervisord -n -e debug -c /etc/supervisord.conf"
