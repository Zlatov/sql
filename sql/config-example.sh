#!/bin/bash

VENDORPATH="/vendor"
DBHOST="$DB_HOST"
DBUSER="$DB_USER"
DBPASS="$DB_PASS"
DBNAME="$DB_NAME"

. "..$VENDORPATH/zlatov/sql/src/config.sh"
echo -en $COLOR_GREEN
echo "Конфигурационный файл был включён."
echo "Работа с базой данных: $DBNAME"
echo -en $STYLE_DEFAULT
