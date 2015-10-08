#!/bin/bash

set -e

if [ "$1" = '/usr/local/bin/supervisord' ]; then

  if [ ! -f /usr/share/nginx/www/wp-config.php ]; then
    /usr/bin/mysqld_safe &
    sleep 10s

    WORDPRESS_DB="wordpress"
    MYSQL_PASSWORD=`pwgen -c -n -1 12`
    WORDPRESS_PASSWORD=`pwgen -c -n -1 12`

    echo mysql root password: $MYSQL_PASSWORD
    echo wordpress password: $WORDPRESS_PASSWORD
    echo $MYSQL_PASSWORD > /mysql-root-pw.txt
    echo $WORDPRESS_PASSWORD > /wordpress-db-pw.txt

    sed -e "s/database_name_here/$WORDPRESS_DB/
    s/username_here/$WORDPRESS_DB/
    s/password_here/$WORDPRESS_PASSWORD/
    /'AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'SECURE_AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'LOGGED_IN_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'NONCE_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'SECURE_AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'LOGGED_IN_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'NONCE_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/" /usr/share/nginx/www/wp-config-sample.php > /usr/share/nginx/www/wp-config.php

    curl -O `curl -i -s https://wordpress.org/plugins/nginx-helper/ | egrep -o "https://downloads.wordpress.org/plugin/[^']+"`
    unzip -o nginx-helper.*.zip -d /usr/share/nginx/www/wp-content/plugins
    chown -R www-data:www-data /usr/share/nginx/www/wp-content/plugins/nginx-helper

    cat << ENDL >> /usr/share/nginx/www/wp-config.php
\$plugins = get_option( 'active_plugins' );
if ( count( \$plugins ) === 0 ) {
  require_once(ABSPATH .'/wp-admin/includes/plugin.php');
  \$pluginsToActivate = array( 'nginx-helper/nginx-helper.php' );
  foreach ( \$pluginsToActivate as \$plugin ) {
    if ( !in_array( \$plugin, \$plugins ) ) {
      activate_plugin( '/usr/share/nginx/www/wp-content/plugins/' . \$plugin );
    }
  }
}
ENDL

    chown www-data:www-data /usr/share/nginx/www/wp-config.php
    cat /usr/share/nginx/www/wp-config.php

    mysqladmin -u root password $MYSQL_PASSWORD
    mysql -uroot -p$MYSQL_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    mysql -uroot -p$MYSQL_PASSWORD -e "CREATE DATABASE wordpress; GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost' IDENTIFIED BY '$WORDPRESS_PASSWORD'; FLUSH PRIVILEGES;"
    killall mysqld
  fi

  PORT=${PORT:-"8080"}
  sed -ri "s/listen 80/listen $PORT/" /etc/nginx/sites-available/default
  sed -ri "s/80 default/$PORT default/" /etc/nginx/sites-available/default

  exec "$@"

fi

exec "$@"
