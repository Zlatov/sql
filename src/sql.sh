#!/bin/bash

# Если есть локальный конфиг - подключаем, установим пароль для mysql
if [ -f ./config.sh ]
    then
        . "./config.sh"
        export MYSQL_PWD="$DBPASS"
fi

# Если есть глобальный конфиг - подключаем
if [ -f ../vendor/zlatov/sql/src/config.sh ]
    then
        . "../vendor/zlatov/sql/src/config.sh"
fi

# По первому параметру команды определяем что будем делать (./sql init)
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
                dump
            else
                if [ ! -f ./dump/$2 ]
                then
                    echo -en $COLOR_RED
                    echo "Не найден дамп $2."
                    echo -en $STYLE_DEFAULT
                else
                    echo "Восстанавливаем БД $DBNAME из дампа $2"
                    tar -xzOf "$1" | mysql -u"$DBUSER" "$DBNAME"
                    if [[ $? -eq 1 ]]
                        then
                            echo -en $COLOR_RED
                            echo -e "Ошибка при восстановлении."
                            echo -en $STYLE_DEFAULT
                        else
                            echo -en $COLOR_GREEN
                            echo -e "Успешно восстановлена бд $DBNAME."
                            echo -en $STYLE_DEFAULT
                    fi
                fi
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
                                echo "Отправляем $2 на сервер $REMOTE_NAME в ${REMOTE_PATH}/sql/dump/$2"
                                scp "./dump/$2" $REMOTE_NAME:$REMOTE_PATH/sql/dump/
                                if [[ $? -eq 1 ]]
                                    then
                                        echo -en $COLOR_RED
                                        echo -e "Ошибка отправки."
                                        echo -en $STYLE_DEFAULT
                                    else
                                        echo -en $COLOR_GREEN
                                        echo -e "Успешно отправлен дамп на сервер."
                                        echo -en $STYLE_DEFAULT
                                fi
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
