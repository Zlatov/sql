#!/bin/bash
DBHOST="$DB_HOST"
DBUSER="$DB_USER"
DBPASS="$DB_PASS"
DBNAME="$DB_NAME"

echo "База данных: $DB_NAME"
echo "База данных: $DBNAME"

TEXT_BOLD='\033[1m'
COLOR_RED='\033[31m'
COLOR_GREEN='\033[32m'
STYLE_DEFAULT='\033[0m'
echo -en $COLOR_GREEN
echo "Конфигурационный файл был включён."
echo -en $STYLE_DEFAULT
