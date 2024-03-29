ARG PHP_VERSION=8.1

FROM php:$PHP_VERSION-fpm

# Arguments defined in docker-compose.yml
ARG NODE_VERSION=16
ARG PROJECT_DIR
ARG user
ARG uid

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    supervisor \
    curl \
    ca-certificates \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    ffmpeg \
    screen \
    htop

#Install nodejs, npm
#RUN curl -sLS https://deb.nodesource.com/setup_$NODE_VERSION.x | bash -

#install nodejs of latest version
#RUN apt-get install -y npm nodejs

#install node js version from .env config
RUN apt-get update && apt-get install -y \
    software-properties-common \
    npm
RUN npm install npm@latest -g && \
    npm install n -g && \
    n ${NODE_VERSION}

RUN pecl install xdebug
RUN docker-php-ext-enable xdebug

RUN pecl install redis
RUN docker-php-ext-enable redis

#Install Mondodb
#RUN pecl install mongodb
#RUN docker-php-ext-enable mongodb

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip intl

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Set working directory
WORKDIR /var/www

USER $user
