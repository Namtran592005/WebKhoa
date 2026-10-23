#!/bin/sh
# Fix permissions and materialize WORDPRESS_* env for LSPHP.
chmod -R 777 /var/www/vhosts/localhost/html 2>/dev/null || true

php_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e "s/'/\\'/g"
}

ENV_PHP=/usr/local/lsws/conf/wp-env.php
ENV_INI_DIR=/usr/local/lsws/lsphp85/etc/php/8.5/litespeed/conf.d
mkdir -p "$ENV_INI_DIR"
{
  echo '<?php'
  echo '// Auto-generated at container start. Do not edit.'
  for v in WORDPRESS_DB_HOST WORDPRESS_DB_NAME WORDPRESS_DB_USER WORDPRESS_DB_PASSWORD WORDPRESS_CONFIG_EXTRA; do
    val=$(printenv "$v")
    printf "putenv('%s=%s');\n" "$v" "$(php_escape "$val")"
  done
} > "$ENV_PHP"
echo "auto_prepend_file=$ENV_PHP" > "$ENV_INI_DIR/98-env.ini"

exec /entrypoint.sh "$@"
