# Use the official PHP image with Apache
FROM php:8.2-apache

WORKDIR /var/www/html

# Copy your PHP application files into the container's web root directory
COPY /website /var/www/html/

# Expose port 80 for the web server
EXPOSE 80
