#!/bin/bash

TEXT_BOLD='\033[1m'
COLOR_RED='\033[31m'
COLOR_GREEN='\033[32m'
STYLE_DEFAULT='\033[0m'

if [[ $SQL_DEBUG -eq 1 ]]
	then
		echo -en $COLOR_GREEN
		echo -e "Включён общий конфигурационный файл $STYLE_DEFAULT$BASH_ARGV."
		echo -en $STYLE_DEFAULT
fi

. ../vendor/zlatov/sql/src/fun.sh
