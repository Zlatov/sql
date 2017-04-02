#!/bin/bash

. "../vendor/zlatov/sql/src/common.sh"

# Если есть локальный конфиг - подключаем, установим пароль для mysql
if [ -f ./config.sh ]
    then
        . "./config.sh"
        export MYSQL_PWD="$DBPASS"
fi

# По первому параметру команды определяем что будем делать (./sql init)
case $1 in
    init)
        init
        ;;
    dumplist)
        dumpList
        ;;
    dump)
        dump $2
        ;;
    push)
        push $2
        ;;
    pull)
        pull $2
        ;;
    migrate)
        migrateToLastVersion
        ;;
    migrations)
        migrationsList
        ;;
    procedures)
        proceduresList
        ;;
    version)
        echoVersion
        ;;
    dbname)
        echoDbName
        ;;
    dbuser)
        echoDbUser
        ;;
    dbconf)
        echoDbConf
        ;;
    reset)
        reset
        ;;
    data)
        data $2
        ;;
    *)
        sqlMan
        ;;
esac
