FROM alpine:3.11
LABEL Maintainer="Radoslav Stefanov <radoslav@rstefanov.info>" \
      Description="Lightweight container with Nginx and PHP-FPM 7, based on Alpine Linux."

# Install packages
RUN apk --no-cache add php7 php7-fpm php7-iconv php7-json php7-openssl php7-curl \
    php7-zlib php7-xml php7-phar php7-intl php7-dom php7-xmlreader php7-ctype php7-session \
    php7-mbstring php7-gd nginx supervisor curl

# Configure php
RUN touch /etc/php7/conf.d/uploads.ini \
    && echo "upload_max_filesize = 10240M" >> /etc/php7/conf.d/uploads.ini \
    && echo "post_max_size = 10240M" >> /etc/php7/conf.d/uploads.ini \
    && echo "output_buffering = 0" >> /etc/php7/conf.d/uploads.ini \
    && echo "max_input_time = 7200" >> /etc/php7/conf.d/uploads.ini \
    && echo "max_execution_time = 7200" >> /etc/php7/conf.d/uploads.ini \
    && echo "memory_limit = 1024M" >> /etc/php7/conf.d/uploads.ini

# Configure supervisord
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Add Nginx and php-fpm configuration files
COPY nginx.conf /etc/nginx/nginx.conf
COPY php-fpm.conf /etc/php7/php-fpm.d/www.conf

# Get rid of default Nginx configuration file
RUN rm /etc/nginx/conf.d/default.conf

# Make sure permissions are set
RUN chown -R 82:www-data /run && \
  chown -R 82:www-data /var/lib/nginx && \
  chown -R 82:www-data /var/log/nginx

# Switch to use a non-root user from here on
USER 82:82

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
