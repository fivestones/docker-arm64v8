FROM arm64v8/php:8.0.5-apache

ENV FR_DB_HOST=db \
    FR_DB_PORT=3306 \
    FR_DB_NAME=filerun \
    FR_DB_USER=filerun \
    FR_DB_PASS=filerun \
    APACHE_RUN_USER=user \
    APACHE_RUN_USER_ID=1000 \
    APACHE_RUN_GROUP=user \
    APACHE_RUN_GROUP_ID=1000

VOLUME ["/var/www/html", "/user-files"]
# set recommended PHP.ini settings
# see http://docs.filerun.com/php_configuration
COPY filerun-optimization.ini /usr/local/etc/php/conf.d/
COPY autoconfig.php entrypoint.sh wait-for-it.sh import-db.sh filerun.setup.sql supervisord.conf /


#freetype patch
#ADD https://git.archlinux.org/svntogit/packages.git/plain/trunk/freetype.patch?h=packages/php /tmp/freetype.patch

# add PHP, extensions and third-party software
RUN apt-get update \
    && apt-get install -y \
        libapache2-mod-xsendfile \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libldap2-dev \
        libxml2-dev \
        libzip-dev \
        libcurl4-gnutls-dev \
        dcraw \
        locales \
        graphicsmagick \
        ffmpeg \
        #default-mysql-client \
        unzip \
        cron \
	libtiff-dev \
	libwebp-dev \
	libosmesa6-dev \
        libgl1 \
        ufraw \
	mariadb-client \
	vim \
        supervisor \
    # patch PHP freetype
    #&& docker-php-source extract; \
    #    cd /usr/src/php; \
    #    patch -p1 -i /tmp/freetype.patch; \
    #    rm /tmp/freetype.patch \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir /var/log/supervisord /var/run/supervisord \
    && sed -i '/disable ghostscript format types/,+6d' /etc/ImageMagick-6/policy.xml \
    && docker-php-ext-configure zip \
    #&& docker-php-ext-configure gd --with-gd --with-freetype-dir \
    && docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ \
    #   && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu \
    && docker-php-ext-configure ldap \
    && docker-php-ext-install -j$(nproc) pdo_mysql exif zip gd opcache ldap \
    && a2enmod rewrite \
# Install ionCube for arm64 (aarch64)
    && echo [Install ionCube] \
    && curl -O -L https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_aarch64.tar.gz \
    && PHP_EXT_DIR=$(php-config --extension-dir) \
    && tar xvfz ioncube_loaders_lin_aarch64.tar.gz ioncube/ioncube_loader_lin_7.4.so -C $PHP_EXT_DIR \
    #&& cp "ioncube/ioncube_loader_lin_7.4.so" $PHP_EXT_DIR \
    && echo "zend_extension=ioncube_loader_lin_7.4.so" >> /usr/local/etc/php/conf.d/00_ioncube_loader_lin_7.4.ini \
    && rm -rf ioncube ioncube_loaders_lin_aarch64.tar.gz \
 # Install STL-THUMB
    && echo [Install STL-THUMB] \
    && curl -O -L https://github.com/unlimitedbacon/stl-thumb/releases/download/v0.4.0/stl-thumb_0.4.0_arm64.deb \
    && dpkg -i stl-thumb-0.4.0_arm64.deb \
    && rm -rf stl-thumb_0.4.0_arm64.deb \
 # Enable Apache XSendfile
    && echo [Enable Apache XSendfile] \
    && echo "XSendFile On\nXSendFilePath /user-files" | tee "/etc/apache2/conf-available/filerun.conf" \
    && a2enconf filerun \

# Enable Apache XSendfile
#RUN { \
#		echo 'XSendFile On'; \
#		echo; \
#		echo 'XSendFilePath /user-files'; \
#	} | tee "/etc/apache2/conf-available/filerun.conf" \
#	&& a2enconf filerun

  # Download FileRun installation package
    && echo [Download FileRun installation package version 2021.03.26 \
    && curl -o /filerun.zip -L 'https://f.afian.se/wl/?id=SkPwYC8dOcMIDWohmyjOqAgdqhRqCZ3X&fmode=download' \
    && chown www-data:www-data /user-files
    && chmod +x /wait-for-it.sh /import-db.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
#CMD ["apache2-foreground"]
CMD ["/usr/bin/supervisord", "-c", "/supervisord.conf"]
