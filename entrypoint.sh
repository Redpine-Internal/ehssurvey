#!/bin/bash
set -e

CONFIG_FILE="/var/www/html/application/config/config.php"

# Only generate config.php if DB env vars are set AND installer is done (INSTALLED=true)
if [ "$INSTALLED" = "true" ] && [ -n "$DB_CONNECTION_NAME" ]; then
    echo "Generating config.php from environment variables..."
    cat > "$CONFIG_FILE" << 'PHPEOF'
<?php if (!defined('BASEPATH')) exit('No direct script access allowed');
return array(
    'components' => array(
        'db' => array(
            'connectionString' => 'mysql:unix_socket=/cloudsql/__DB_CONNECTION_NAME__;dbname=__DB_NAME__;charset=utf8mb4',
            'emulatePrepare' => true,
            'username' => '__DB_USER__',
            'password' => '__DB_PASSWORD__',
            'charset' => 'utf8mb4',
            'tablePrefix' => 'lime_',
        ),
        'urlManager' => array(
            'urlFormat' => 'get',
            'rules' => array(),
            'showScriptName' => true,
        ),
    ),
    'config' => array(
        'debug' => 0,
        'debugsql' => 0,
        'sitename' => 'EHS Survey',
    )
);
PHPEOF

    # Replace placeholders with actual env var values
    sed -i "s|__DB_CONNECTION_NAME__|${DB_CONNECTION_NAME}|g" "$CONFIG_FILE"
    sed -i "s|__DB_NAME__|${DB_NAME}|g" "$CONFIG_FILE"
    sed -i "s|__DB_USER__|${DB_USER}|g" "$CONFIG_FILE"
    sed -i "s|__DB_PASSWORD__|${DB_PASSWORD}|g" "$CONFIG_FILE"

    chown www-data:www-data "$CONFIG_FILE"
    echo "config.php generated successfully."
else
    echo "INSTALLED not set to true — installer mode (no config.php)."
    # Remove config.php if it exists to allow installer
    rm -f "$CONFIG_FILE"
fi

# Force InnoDB engine (Cloud SQL does not support MyISAM)
DEFAULTS_FILE="/var/www/html/application/config/config-defaults.php"
if grep -q '"MyISAM"' "$DEFAULTS_FILE" 2>/dev/null; then
    sed -i 's/\$config\['"'"'mysqlEngine'"'"'\] = "MyISAM"/\$config['"'"'mysqlEngine'"'"'] = "InnoDB"/' "$DEFAULTS_FILE"
    echo "Forced mysqlEngine to InnoDB (Cloud SQL compatibility)."
fi

exec apache2-foreground
