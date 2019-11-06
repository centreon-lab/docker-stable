#!/bin/sh

# Test the variables
MYSQL_PORT="${MYSQL_PORT:=3306}"
if [ -z "$MYSQL_HOST" ]; then
    echo "Need define the MYSQL_HOST variable !"
    exit 1;
fi
if [ -z "$CR_MYSQL_USER" ]; then
    echo "Need define the MYSQL_USER variable !"
    exit 1;
fi
if [ -z "$CR_MYSQL_PWD" ]; then
    echo "Need define the MYSQL_PASSWD variable !"
    exit 1;
fi
if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
    echo "Need define the MYSQL_ROOT_PASSWORD variable !"
    exit 1;
fi

testMySQL() {
    TIMEOUT=300
    NOW=$(date +%s)
    TEST_CONNECTION=1
    while [ $TEST_CONNECTION -ne 0 ]; do
        if [ $(expr $(date +%s) - $NOW) -gt $TIMEOUT ]; then
            TEST_CONNECTION=100
            break
        fi
        TEST_CONNECTION=$(/opt/rh/rh-php72/root/usr/bin/php -r 'try { $db = new PDO("mysql:host=".getenv("MYSQL_HOST"), "root", getenv("MYSQL_ROOT_PASSWORD")); echo 0; } catch (Exception $e) { echo 1; }')
        sleep 5
    done
    if [ $TEST_CONNECTION -eq 0 ]; then
        echo $(/opt/rh/rh-php72/root/usr/bin/php -r 'try { $db = new PDO("mysql:dbname=".getenv("CR_DB_CENTREON").";host=".getenv("MYSQL_HOST"), "root", getenv("MYSQL_ROOT_PASSWORD")); echo 0; } catch (Exception $e) { echo 1; }')
    else
        echo 100
    fi
}

function installPlugins() {

    # Install JQ tool (https://stedolan.github.io/jq/)
    # to help manage json output in shell
    curl -o /usr/sbin/jq -q -L -g https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
    chmod +x /usr/sbin/jq

    SLUGS=$(curl -q -L -g 'https://api.imp.centreon.com/api/pluginpack/pluginpack?sort=catalog_level&by=asc&page[number]=1&page[size]=20')

    PLUGINS=(
      base-generic
      applications-databases-mysql
      operatingsystems-linux-snmp
      applications-monitoring-centreon-database
      applications-monitoring-centreon-central
    )

    CENTREON_HOST="http://localhost"
    CURL_CMD="curl "

    for PLUGIN in "${PLUGINS[@]}"; do
        JSON_PLUGIN="{\"slug\": \"${PLUGIN}\", \"version\": $(echo $SLUGS | jq ".data[].attributes | select(.slug | contains(\"${PLUGIN}\")).version"), \"action\": \"install\"}"
        STATUS=0
        while [ $STATUS -eq 0 ]; do
            API_TOKEN=$(curl -q -d "username=admin&password=${CENTREON_ADMIN_PASSWD}" \
                "${CENTREON_HOST}/centreon/api/index.php?action=authenticate" \
                | cut -f2 -d":" | sed -e "s/\"//g" -e "s/}//"
            )
            CURL_OUTPUT=$(${CURL_CMD} -X POST \
                -H "Content-Type: application/json" \
                -H "centreon-auth-token: $(read <<<"$API_TOKEN";echo "$REPLY")" \
                -d "{\"pluginpack\":[${JSON_PLUGIN}]}" \
                "${CENTREON_HOST}/centreon/api/index.php?object=centreon_pp_manager_pluginpack&action=installupdate"
            )
            if ! [ $(echo $CURL_OUTPUT | grep "Forbidden") ]; then
                STATUS=1
            fi
        done
    done
}

function installWidgets() {
    WIDGETS=(
        engine-status
        global-health
        graph-monitoring
        grid-map
        host-monitoring
        hostgroup-monitoring
        httploader
        live-top10-cpu-usage
        live-top10-memory-usage
        service-monitoring
        servicegroup-monitoring
        tactical-overview
    )

    CENTREON_HOST="http://localhost"
    CURL_CMD="curl -o /dev/null"
    API_TOKEN=$(curl -q -d "username=admin&password=${CENTREON_ADMIN_PASSWD}" \
        "${CENTREON_HOST}/centreon/api/index.php?action=authenticate" \
        | cut -f2 -d":" | sed -e "s/\"//g" -e "s/}//"
    )

    for WIDGET in "${WIDGETS[@]}"; do
        # Configure widget in Centreon
        ${CURL_CMD} -X POST \
            -H "Content-Type: application/json" \
            -H "centreon-auth-token: $(read <<<"$API_TOKEN";echo "$REPLY")" \
            "${CENTREON_HOST}/centreon/api/index.php?object=centreon_module&action=install&id=${WIDGET}&type=widget"
    done
}

function initialConfiguration() {

    # Add server and set snmp configuration
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o HG -a add -v "Linux;Linux servers"
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o HOST -a ADD -v "centreon-central;Centreon Central;127.0.0.1;App-Monitoring-Centreon-Central-custom;central;Linux"
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o HOST -a ADD -v "centreon-db;Centreon Central;${MYSQL_HOST};App-Monitoring-Centreon-Database-custom;central;Linux"
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o HOST -a setmacro -v "centreon-db;MYSQLPASSWORD;${CR_MYSQL_PWD}"
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o HOST -a setparam -v "centreon-central;snmp_community;public"
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o HOST -a setparam -v "centreon-central;snmp_version;2c"
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o HOST -a applytpl -v "centreon-central"
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o HOST -a applytpl -v "centreon-db"

    # Disable some services because Docker
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o SERVICE -a setparam -v "centreon-central;proc-ntpd;activate;0"
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o SERVICE -a setparam -v "centreon-central;proc-sshd;activate;0"
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o SERVICE -a setparam -v "centreon-db;Cpu;activate;0"
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o SERVICE -a setparam -v "centreon-db;Load;activate;0"
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o SERVICE -a setparam -v "centreon-db;Memory;activate;0"
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o SERVICE -a setparam -v "centreon-db;Swap;activate;0"

    # add a plugin to monitor each ethernet interface
    ip -o link show | awk -F': ' '{print $2}' | grep -v 'lo' | cut -f1 -d'@' | while read IFNAME; do
        centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o SERVICE -a add -v "centreon-central;Interface-${IFNAME};OS-Linux-Traffic-Generic-Name-SNMP"
        centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -o SERVICE -a setmacro -v "centreon-central;Interface-${IFNAME};INTERFACENAME;${IFNAME}"
    done

    # Generate and move configuration to engine
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -a POLLERGENERATE -v 1
    chown -R apache:apache /var/cache/centreon/config/engine/*
    chown -R apache:apache /var/cache/centreon/config/broker/*
    centreon -u admin -p ${CENTREON_ADMIN_PASSWD} -a CFGMOVE -v 1
    chown -R apache:apache /etc/centreon-engine/*
    chown -R apache:apache /etc/centreon-broker/*
}

InstallDbCentreon() {
    CENTREON_HOST="http://localhost"
    COOKIE_FILE="/tmp/install.cookie"
    CURL_CMD="curl -b ${COOKIE_FILE}"

    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/install.php"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=stepContent"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step3.php" \
        --data 'install_dir_engine=%2Fusr%2Fshare%2Fcentreon-engine&centreon_engine_stats_binary=%2Fusr%2Fsbin%2Fcentenginestats&monitoring_var_lib=%2Fvar%2Flib%2Fcentreon-engine&centreon_engine_connectors=%2Fusr%2Flib64%2Fcentreon-connector&centreon_engine_lib=%2Fusr%2Flib64%2Fcentreon-engine&centreonplugins=%2Fusr%2Flib%2Fcentreon%2Fplugins%2F'
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step4.php" \
        --data 'centreonbroker_etc=%2Fetc%2Fcentreon-broker&centreonbroker_cbmod=%2Fusr%2Flib64%2Fnagios%2Fcbmod.so&centreonbroker_log=%2Fvar%2Flog%2Fcentreon-broker&centreonbroker_varlib=%2Fvar%2Flib%2Fcentreon-broker&centreonbroker_lib=%2Fusr%2Fshare%2Fcentreon%2Flib%2Fcentreon-broker'
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step5.php" \
        --data "admin_password=${CENTREON_ADMIN_PASSWD}&confirm_password=${CENTREON_ADMIN_PASSWD}&firstname=${CENTREON_ADMIN_NAME}&lastname=${CENTREON_ADMIN_NAME}&email=${CENTREON_ADMIN_EMAIL}"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step6.php" \
        --data "address=${MYSQL_HOST}&port=${MYSQL_PORT}&root_user=root&root_password=${MYSQL_ROOT_PASSWORD}&db_configuration=${CR_DB_CENTREON}&db_storage=${CR_DB_STORAGE}&db_user=${CR_MYSQL_USER}&db_password=${CR_MYSQL_PWD}&db_password_confirm=${CR_MYSQL_PWD}"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/configFileSetup.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/installConfigurationDb.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/installStorageDb.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/createDbUser.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/insertBaseConf.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/partitionTables.php" -X POST
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step8.php" \
        --data "modules%5B%5D=centreon-license-manager&modules%5B%5D=centreon-pp-manager&modules%5B%5D=centreon-autodiscovery-server"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/step.php?action=nextStep"
    ${CURL_CMD} "${CENTREON_HOST}/centreon/install/steps/process/process_step9.php" \
        --data "send_statistics=1"

}

addRemote() {
    # Temporarly up all services with supervisor
    /usr/bin/supervisord -n -e debug -c /etc/supervisord.conf &2> /dev/null
    PID_SUPER=$!
    sleep 10

    CENTREON_HOST="http://centreon-web"
    CURL_CMD="curl "
    CONTAINER_HOST="$(host $(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}') | cut -d " " -f 5)"
    CONTAINER_NAME="$(echo $CONTAINER_HOST | cut -d. -f1)"
    API_TOKEN=$(curl -q -d "username=admin&password=${CENTREON_ADMIN_PASSWD}" \
        "${CENTREON_HOST}/centreon/api/index.php?action=authenticate" \
        | cut -f2 -d":" | sed -e "s/\"//g" -e "s/}//"
    )
    CURL_OUTPUT=$(${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: $(read <<<"$API_TOKEN";echo "$REPLY")" \
        -d "{\"centreon_folder\":\"/centreon/\",\"server_name\":\"${CONTAINER_NAME}\",\"server_ip\":\"http://${CONTAINER_HOST}\",\"db_user\":\"${CR_MYSQL_USER}\",\"db_password\":\"${CR_MYSQL_PWD}\",\"centreon_central_ip\":\"centreon-web\",\"no_check_certificate\":true,\"no_proxy\":true,\"server_type\":\"remote\"}" \
        "${CENTREON_HOST}/centreon/api/index.php?object=centreon_configuration_remote&action=linkCentreonRemoteServer"
    )
    echo $CURL_OUTPUT
    CURL_OUTPUT=$(${CURL_CMD} -X POST \
        -H "Content-Type: application/json" \
        -H "centreon-auth-token: $(read <<<"$API_TOKEN";echo "$REPLY")" \
        -d "{ \"action\": \"applycfg\", \"values\": \"${CONTAINER_NAME}\" }" \
        "${CENTREON_HOST}/centreon/api/index.php?action=action&object=centreon_clapi"
    )
    echo $CURL_OUTPUT

    # Sleeping to receivied data from central
    sleep 15
    # Kill supervisor
    kill $PID_SUPER
    sleep 10
}

# Always check and fix permission
find /etc/centreon-tmp -type f -printf "%P\n" | while read CFILE; do
    if [ ! -e /etc/centreon/$CFILE ]; then
        cp -rva /etc/centreon-tmp/$CFILE /etc/centreon/
    fi
done
find /etc/centreon-tmp -type d -printf "%P\n" | sed 1d | while read CDIR; do
    if [ ! -d /etc/centreon/$CDIR ]; then
        cp -rva /etc/centreon-tmp/$CDIR /etc/centreon/
    fi
done
rm -rvf /etc/centreon-tmp
chmod -vR 775 /etc/centreon
chown -vR centreon:centreon /etc/centreon

# Test connection with Mysql
echo "Testing connection with database."
echo "Waiting Mysql server up to testing connection ..."
TEST_MYSQL=$(testMySQL)
if [ $TEST_MYSQL -eq 100 ]; then
    echo "You need a valid connection to your MySQL server !"
    exit 1;
elif [ $TEST_MYSQL -eq 0 ]; then
    echo -n "Connection exist, preparing configuration ..."
    echo "done"
else
    echo "Connection exist, but need create the initial database ..."
    echo "Starting Apache to apply configuration ..."
    /opt/rh/httpd24/root/usr/sbin/httpd-scl-wrapper -DFOREGROUND &2> /dev/null
    PID_HTTPD=$!
    echo "Starting PHP-FPM to apply configuration ..."
    /opt/rh/rh-php72/root/usr/sbin/php-fpm -F &2> /dev/null
    PID_PHPFPM=$!
    sleep 5 # waiting start httpd process
    InstallDbCentreon
    installWidgets
    installPlugins
    #initialConfiguration
    echo "Kill Apache and PHP-FPM ..."
    kill $PID_HTTPD
    kill $PID_PHPFPM
    echo "done"
fi

# SSH Configuration
if [ ! -d /var/spool/centreon/.ssh ]; then
    mkdir -v /var/spool/centreon/.ssh
    chown -v centreon:centreon /var/spool/centreon/.ssh
fi
if [ ! -f /var/spool/centreon/.ssh/known_hosts ]; then
    touch /var/spool/centreon/.ssh/known_hosts
    chown -v centreon:centreon /var/spool/centreon/.ssh/known_hosts
fi
# Remote copy id_rsa.pub to authorized_keys
until [ -f /central-ssh/id_rsa.pub ]; do
    echo "Wait for public ssh key from Centreon Central - sleeping"
    sleep 5
done
cp -v /central-ssh/id_rsa.pub /var/spool/centreon/.ssh/authorized_keys
chown -vR centreon:centreon /var/spool/centreon/.ssh
if [ ! -f /var/spool/centreon/.ssh/config ]; then
    su - centreon -c "cat <<EOF > .ssh/config
Compression yes
Host *
    StrictHostKeyChecking no
EOF"
fi
if [ ! -f /var/spool/centreon/.ssh/id_rsa.pub ]; then
    su - centreon -c "ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa"
fi
su - centreon -c "chmod -v 0700 .ssh && chmod -v 0600 .ssh/*"

if [ -d "/usr/share/centreon/www/install" ]; then
    rm -rf /usr/share/centreon/www/install
fi
touch /var/log/centreon/login.log

# Add this container as a remote server in Central
addRemote

echo "Centreon Web ready !"

su - root -c "/usr/bin/supervisord -n -e debug -c /etc/supervisord.conf"
