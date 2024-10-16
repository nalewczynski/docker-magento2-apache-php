#!/bin/bash
magento_path="/var/www/html/magento2"

if [ ! -d /var/www/html/magento2 ]; then
  echo "Magento not found, installing with composer.."
  composer config --global $MAGENTO_REPO $API_KEY $API_SECRET
  composer create-project --repository-url=https://repo.magento.com/ $MAGENTO_VERSION $magento_path

  #official Adobe instructions
  cd $magento_path
  find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
  find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
  chown -R :www-data . # Ubuntu
  chmod u+x bin/magento

  php $magento_path/bin/magento setup:install \
    --db-host docker-magento2_db_1 --db-name magento2 --db-user magento2 --db-password magento2 --admin-user admin --timezone $TIMEZONE --currency $CURRENCY --use-rewrites 1 --cleanup-database \
    --backend-frontname admin --admin-firstname AdminFirstName --admin-lastname AdminLastName --admin-email $ADMIN_EMAIL --admin-password $ADMIN_PASSWORD --base-url 'https://magento2.docker/' --language en_US \
    --session-save=redis --session-save-redis-host=sessions --session-save-redis-port=6379 --session-save-redis-db=0 --session-save-redis-password='' \
    --cache-backend=redis --cache-backend-redis-server=cache --cache-backend-redis-port=6379 --cache-backend-redis-db=0 \
    --page-cache=redis --page-cache-redis-server=cache --page-cache-redis-port=6379 --page-cache-redis-db=1 \
    --search-engine=elasticsearch7 --elasticsearch-host=elasticsearch

  #disable 2factor auth
  php bin/magento module:disable Magento_AdminAdobeImsTwoFactorAuth
  php bin/magento module:disable Magento_TwoFactorAuth
  php bin/magento cache:clean

  #deploy static files for first time
  php bin/magento dev:source-theme:deploy
  php bin/magento setup:static-content:deploy -f

else
  echo "Magento already installed, skipping installation.."
fi


