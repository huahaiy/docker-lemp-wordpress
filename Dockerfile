#
# Run wordpress on LEMP (Linux, nginx, MySQL and PHP) 
# 
#
# Version     0.2
#

FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive

RUN \
  echo "===> install LEMP" && \
  apt-get update && \ 
  apt-get -y upgrade && \
  apt-get install -yq mysql-server mysql-client nginx php5-fpm php5-mysql php5-apcu pwgen python-setuptools curl git unzip && \ 
  apt-get install -y php5-curl php5-gd php5-intl php-pear php5-imagick php5-imap php5-mcrypt php5-memcache php5-ming php5-ps php5-pspell php5-recode php5-sqlite php5-tidy php5-xmlrpc php5-xsl

RUN \
  echo "===> config" && \
  sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf && \
  sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf && \
  sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf && \
  echo "daemon off;" >> /etc/nginx/nginx.conf && \
  sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini && \
  sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php5/fpm/php.ini && \
  sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php5/fpm/php.ini && \
  sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf && \
  sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php5/fpm/pool.d/www.conf && \
  find /etc/php5/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \; 

ADD ./nginx-site.conf /etc/nginx/sites-available/default

RUN \
  /usr/bin/easy_install supervisor && \
  /usr/bin/easy_install supervisor-stdout 

ADD ./supervisord.conf /etc/supervisord.conf

RUN \
  echo "===> clean up" && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 

VOLUME ["/var/lib/mysql", "/usr/share/nginx"]

COPY ./docker-entrypoint.sh /

EXPOSE 3306 

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/usr/local/bin/supervisord", "-n"]
