#############################################
# File Added by Centreon
#
$centreon_config = {
       VarLib => "/var/lib/centreon",
       CentreonDir => "/usr/share/centreon/",
       "centreon_db" => "centreon",
       "centstorage_db" => "centreon_storage",   
       "db_host" => "--ADDRESS--:--DBPORT--",
       "db_user" => "--DBUSER--",
       "db_passwd" => '--DBPASS--'
};
# Central or Poller ?
$instance_mode = "central";
# Centreon Centcore Command File
$cmdFile = "/var/lib/centreon/centcore.cmd";
# Deprecated format of Config file.
$mysql_user = "--DBUSER--";
$mysql_passwd = '--DBPASS--';
$mysql_host = "--ADDRESS--:--DBPORT--";
$mysql_database_oreon = "centreon";
$mysql_database_ods = "centreon_storage";
1;
