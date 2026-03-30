FROM php:8.1-apache-bookworm

# Install PHP extensions required by ehssurvey
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libzip-dev \
    libldap2-dev \
    libonig-dev \
    libxml2-dev \
    libsodium-dev \
    libicu-dev \
    libc-client-dev \
    libkrb5-dev \
    unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install -j$(nproc) \
        gd \
        pdo_mysql \
        mysqli \
        zip \
        ldap \
        mbstring \
        xml \
        sodium \
        opcache \
        intl \
        imap \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Enable Apache modules
RUN a2enmod rewrite headers

# Configure Apache to listen on PORT (Cloud Run requirement)
RUN sed -i 's/Listen 80/Listen ${PORT}/g' /etc/apache2/ports.conf \
    && sed -i 's/:80/:${PORT}/g' /etc/apache2/sites-available/000-default.conf

# Set document root to /var/www/html
ENV APACHE_DOCUMENT_ROOT=/var/www/html

# Configure Apache VirtualHost
RUN echo '<Directory /var/www/html>\n\
    Options -Indexes +FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>' > /etc/apache2/conf-available/ehssurvey.conf \
    && a2enconf ehssurvey

# PHP production settings
RUN echo "memory_limit=512M\n\
upload_max_filesize=128M\n\
post_max_size=128M\n\
max_execution_time=120\n\
max_input_time=120\n\
max_input_vars=10000\n\
date.timezone=America/Sao_Paulo\n\
opcache.enable=1\n\
opcache.memory_consumption=128\n\
opcache.interned_strings_buffer=8\n\
opcache.max_accelerated_files=10000\n\
opcache.validate_timestamps=0\n\
session.save_handler=files\n\
session.save_path=/tmp/sessions\n\
" > /usr/local/etc/php/conf.d/ehssurvey.ini

# Copy application code
COPY . /var/www/html/

# Create required directories with proper permissions
RUN mkdir -p /var/www/html/tmp/assets \
    && mkdir -p /var/www/html/tmp/runtime \
    && mkdir -p /var/www/html/tmp/upload \
    && mkdir -p /var/www/html/upload/surveys \
    && mkdir -p /var/www/html/upload/global \
    && mkdir -p /var/www/html/upload/labels \
    && mkdir -p /var/www/html/upload/themes/survey \
    && mkdir -p /var/www/html/upload/themes/question \
    && mkdir -p /tmp/sessions \
    && chown -R www-data:www-data /var/www/html/tmp \
    && chown -R www-data:www-data /var/www/html/upload \
    && chown -R www-data:www-data /var/www/html/application/config \
    && chown -R www-data:www-data /tmp/sessions \
    && chmod -R 775 /var/www/html/tmp \
    && chmod -R 775 /var/www/html/upload \
    && chmod -R 775 /var/www/html/application/config

# Remove config.php from image (allows installer to run on first boot)
RUN rm -f /var/www/html/application/config/config.php

# Create entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Default PORT for Cloud Run
ENV PORT=8080

EXPOSE ${PORT}

CMD ["/entrypoint.sh"]
