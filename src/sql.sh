#!/bin/bash
if [ -f ../vendor/zlatov/sql/src/config.sh ]
    then
    . "../vendor/zlatov/sql/src/config.sh"
fi

if [ -f ./config.sh ]
    then
    . "./config.sh"
    export MYSQL_PWD="$DBPASS" # вместо --password="$DBPASS"
fi

case $1 in
    init)
        if [ ! -f ./config.sh ]
            then
                echo -en $COLOR_RED
                echo "Конифигурационный файл config.sh не найден."
                echo -en $STYLE_DEFAULT
                echo -en $COLOR_GREEN
                yN "Создать конифигурационный файл? [yes/NO]"
                echo -en $STYLE_DEFAULT
            else
                echo -en $COLOR_RED
                echo "Найден конфигурационный файл"
                echo -en $STYLE_DEFAULT
                yN "Перезаписать конифигурационный файл? [yes/NO]"
        fi
        if [[ $YN -eq 1 ]]
            then
                createConfig
        fi
        createDefaultFolders
        checkGitignore
        if [[ $(checkTableVersionExist) -eq 0 ]]
            then
                echo -en $COLOR_RED
                echo "Таблица версий не найдена."
                echo -en $STYLE_DEFAULT
                yN "Создать таблицу версий? [yes/NO]"
                if [[ $YN -eq 1 ]]; then
                    createTableVersion
                fi
        fi
        ;;
    dumplist)
        dumpList
        ;;
    dump)
        if [[ $2 == '' ]]
            then
                echo "Создаем дамп БД"
            else
                echo "Восстанавливаем БД из дампа $2"
        fi
        ;;
    push)
        if [[ $2 == '' ]]
            then
                echo "Список локальных дампов:"
                ls -la dump
            else
                if [ ! -f ./config.sh ]
                    then
                        echo -en $COLOR_RED
                        echo "Не найден конфигурационный файл."
                        echo -en $STYLE_DEFAULT
                    else
                        if [ ! -f ./dump/$2 ]
                            then
                                echo -en $COLOR_RED
                                echo "Не найден дамп $2."
                                echo -en $STYLE_DEFAULT
                            else
                                echo "Отправляем $2 на сервер $REMOTE_NAME в $REMOTE_PATH"
                        fi
                fi
        fi
        ;;
    pull)
        if [[ $2 == '' ]]
            then
                echo "Список удаленных дампов:"
                ls -la dump
            else
                echo "Отправляем $2 на сервер $REMOTE_NAME в $REMOTE_PATH"
        fi
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
        if [[ $2 == '' ]]
            then
                echoDatas
            else
                toData "$2"
        fi
        ;;
    *)
        sqlMan
        ;;
esac

# cd "$SQLPATH"
#. config.sh
