# Use a imagem base oficial do PHP com Apache e PHP 8.1
FROM php:8.1-apache

# Define os argumentos para a versão do Moodle e a URL de download
ARG MOODLE_VERSION=4.1.9
ARG MOODLE_DOWNLOAD_URL=https://download.moodle.org/download.php/direct/moodle-${MOODLE_VERSION}.zip

# Atualiza os pacotes e instala as dependências do sistema e extensões PHP necessárias para Moodle e PostgreSQL
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    wget \
    libpq-dev \
    libicu-dev \
    libxml2-dev \
    libzip-dev \
    libonig-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Instala as extensões PHP para Moodle e PostgreSQL
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-png && \
    docker-php-ext-install -j$(nproc) gd \
    intl \
    mbstring \
    pdo_pgsql \
    pgsql \
    soap \
    xml \
    zip \
    curl

# Configura o Apache: ativa os módulos rewrite e ssl
RUN a2enmod rewrite \
    && a2enmod ssl \
    && a2ensite default-ssl

# Baixa e extrai o Moodle
RUN wget -q ${MOODLE_DOWNLOAD_URL} -O /tmp/moodle.zip && \
    unzip -q /tmp/moodle.zip -d /var/www/html && \
    rm /tmp/moodle.zip

# Define permissões para o diretório do Moodle e cria o diretório moodledata
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html && \
    mkdir -p /var/www/moodledata && \
    chown -R www-data:www-data /var/www/moodledata && \
    chmod -R 777 /var/www/moodledata

# Configuração básica do Apache para Moodle (opcional, Moodle geralmente configura via web installer)
# Este VHost padrão garante que o Moodle seja servido.
COPY 000-default.conf /etc/apache2/sites-available/000-default.conf
COPY default-ssl.conf /etc/apache2/sites-available/default-ssl.conf
COPY php.ini /usr/local/etc/php/conf.d/moodle.ini

# Expõe as portas 80 (HTTP) e 443 (HTTPS)
EXPOSE 80 443

# Comando padrão para iniciar o Apache
CMD ["apache2-foreground"]
RUN touch /var/log/moodle_cron.log

RUN sed -i 's/^exec /service cron start\n\nexec /' /usr/local/bin/apache2-foreground
