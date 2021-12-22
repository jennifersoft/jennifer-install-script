FROM ubuntu:20.04

RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata
RUN apt-get update && \
    apt-get install -y gcc make build-essential \
    libxml2-dev libcurl4-openssl-dev libpcre3-dev libbz2-dev libjpeg-dev \
    libpng-dev libfreetype6-dev libmcrypt-dev libmhash-dev \
    freetds-dev libmysqlclient-dev unixodbc-dev libxslt1-dev \
    gnupg libpq-dev bison re2c \
    cmake wget pkg-config zip


# PHP sources & patches download
ENV PHP_VERSION='7.4.15'
RUN wget -q -O ./php-${PHP_VERSION}.zip https://github.com/php/php-src/archive/refs/tags/php-${PHP_VERSION}.zip
RUN unzip php-${PHP_VERSION}.zip
RUN mv php-src-php-${PHP_VERSION}/ php-${PHP_VERSION}

# Installing NGINX
RUN apt-get update && apt-get install -y nginx

RUN apt-get update && apt-get install -y libsqlite3-dev sqlite3 libonig-dev

ENV PHP_HOME=/usr/local
ENV PHP_RUN_USER=www-data

# Installing PHP
RUN cd php-${PHP_VERSION} && \
    ./buildconf --force && \
    ./configure \
    --prefix=${PHP_HOME}/php-${PHP_VERSION} \
    --with-fpm-user=$PHP_RUN_USER \
    --with-fpm-group=$PHP_RUN_USER \
    --enable-fpm \
    --includedir=/usr/include \
    --with-config-file-path=$PHP_HOME/php-${PHP_VERSION}/etc/php-fpm \
    --with-config-file-scan-dir=$PHP_HOME/php-${PHP_VERSION}/etc/php-fpm/conf.d \
    --sbindir=/usr/bin \
    --sysconfdir=$PHP_HOME/php-${PHP_VERSION}/etc/php-fpm \
    --enable-sysvsem \
    --enable-sysvshm \
    --enable-sysvmsg \
    --with-mysql \
    --with-mysqli \
    --with-pdo-mysql \
    --with-mssql \
    --with-curl \
    --enable-zts \
    --enable-embed
RUN cd php-${PHP_VERSION} \
    && make -j $(nproc) \
    && make install 

RUN cp /php-${PHP_VERSION}/php.ini-production                                   $PHP_HOME/php-${PHP_VERSION}/etc/php-fpm/php.ini
RUN cp $PHP_HOME/php-${PHP_VERSION}/etc/php-fpm/php-fpm.conf.default            $PHP_HOME/php-${PHP_VERSION}/etc/php-fpm/php-fpm.conf
RUN cp $PHP_HOME/php-${PHP_VERSION}/etc/php-fpm/php-fpm.d/www.conf.default      $PHP_HOME/php-${PHP_VERSION}/etc/php-fpm/php-fpm.d/www.conf

RUN rm -f /etc/nginx/sites-enabled/default

# Setting workdir for docker
RUN printf '<?php phpinfo(); ?>' >> /var/www/html/info.php

WORKDIR /var/www/html

# Exposing Nginx port to host
EXPOSE 80


###### AGENT INSTALL

# TODO: 제니퍼 서버의 정보를 를 넣어야함
ENV JENNIFER_SERVER_HOST=192.168.0.248
ENV JENNIFER_VIEW_PORT=7900
ENV JENNIFER_DATA_PORT=5000
ENV JENNIFER_AGENT_TYPE=php

COPY ./jennifer_install.sh /usr/local
RUN /usr/local/jennifer_install.sh \
    -H ${JENNIFER_SERVER_HOST} \
    --view-port ${JENNIFER_VIEW_PORT} \
    --server-port ${JENNIFER_DATA_PORT} \
    -a ${JENNIFER_AGENT_TYPE} \
    -c $PHP_HOME/php-${PHP_VERSION}/etc/php-fpm/php.ini \
    --php-version ${PHP_VERSION}

COPY ./docker/scripts/run_php.sh /usr/local
CMD ["/usr/local/run_php.sh"]