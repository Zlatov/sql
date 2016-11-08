#!/bin/bash

function sqlMan {
    cat ../vendor/zlatov/sql/src/man.txt
}

function yN {
    read -r -p "${1:-Are you sure? [yes/No]} " response
    case $response in
        [yY][eE][sS]|[yY]|[дД][аА]|[дД]) 
            YN=1
            ;;
        *)
            YN=0
            ;;
    esac
}

function Yn {
    read -r -p "${1:-Are you sure? [Yes/no]} " response
    case $response in
        [nN][oO]|[nN]|[нН][еЕ][тТ]|[нН]) 
            YN=0
            ;;
        *)
            YN=1
            ;;
    esac
}

function createConfig {
    echo -n "Хост (localhost): "
    read DBHOST
    if [[ $DBHOST == '' ]]
        then
        DBHOST="localhost"
    fi

    echo -n "Имя БД: "
    read DBNAME

    echo -n "Имя пользователя БД (root): "
    read DBUSER
    if [[ $DBUSER == '' ]]
        then
        DBUSER="root"
    fi

    echo -n "Пароль: "
    read -s DBPASS
    echo

    echo -n "Адрес удаленного сервера (user@server) или алиас (myserver): "
    read REMOTE_NAME

    echo -n "Абсолютный путь к корню проекта (/home/user/projectname): "
    read REMOTE_PATH

    echo "#!/bin/bash

DBHOST=\"$DBHOST\"
DBNAME=\"$DBNAME\"
DBUSER=\"$DBUSER\"
DBPASS=\"$DBPASS\"

REMOTE_NAME=\"$REMOTE_NAME\"
REMOTE_PATH=\"$REMOTE_PATH\"

#echo -en \$COLOR_GREEN
#echo \"Конфигурационный файл \$BASH_ARGV был включен.\"
#echo \"Работа с базой данных: \$DBNAME\"
#echo -en \$STYLE_DEFAULT

" > config.sh

    if [ ! -f ./config.sh ]
        then
            echo -en $COLOR_RED
            echo "Конфигурационный файл НЕ создан!"
            echo -en $STYLE_DEFAULT
        else
            echo -en $COLOR_GREEN
            echo "Конфигурационный файл успешно создан."
            echo -en $STYLE_DEFAULT
    fi

}

function createDefaultFolders {
    if [ ! -d ./dump ]; then
        # mkdir -p dump
        mkdir dump
        if [ -d ./dump ]; then
            echo -en $COLOR_GREEN
            echo "Создана папка размещения дампов (dump/)"
            echo -en $STYLE_DEFAULT
        fi
    fi
    if [ ! -d ./migration ]; then
        mkdir migration
        if [ -d ./migration ]; then
            echo -en $COLOR_GREEN
            echo "Создана папка хранения миграций (migration/)"
            echo -en $STYLE_DEFAULT
        fi
    fi
    if [ ! -d ./procedures ]; then
        mkdir procedures
        if [ -d ./procedures ]; then
            echo -en $COLOR_GREEN
            echo "Создана папка хранения процедур (procedures/)"
            echo -en $STYLE_DEFAULT
        fi
    fi
    if [ ! -d ./triggers ]; then
        mkdir triggers
        if [ -d ./triggers ]; then
            echo -en $COLOR_GREEN
            echo "Создана папка хранения триггеров (triggers/)"
            echo -en $STYLE_DEFAULT
        fi
    fi
    if [ ! -d ./data ]; then
        mkdir data
        if [ -d ./data ]; then
            echo -en $COLOR_GREEN
            echo "Создана папка хранения тестовых или обязательных данных (data/)"
            echo -en $STYLE_DEFAULT
        fi
    fi
}

function checkGitignore {
    if [ ! -f ./.gitignore ]
        then
            echo "
dump/*.sql
dump/*.tar.gz
config.sh
sql
" > .gitignore
            if [ -f ./.gitignore ]
                then
                    echo -en $COLOR_GREEN
                    echo "Файл .gitignore успешно создан."
                    echo -en $STYLE_DEFAULT
            fi
    fi
}

function dumpList {
    echo "Список локальных дампов"
    ls -la dump
}

function checkTableVersionExist {
    TEMP=`mysql --host=$DBHOST --port=3306 --user="$DBUSER" --database="$DBNAME" --execute="
SELECT TABLE_NAME
FROM information_schema.tables
WHERE table_schema = '$DBNAME'
AND table_name = 'sqlversion';
"`
    if echo $TEMP | grep -q 'sqlversion'
        then
            echo 1
        else
            echo 0
    fi
}

function createTableVersion {
    `mysql --host=$DBHOST --port=3306 --user="$DBUSER" --database="$DBNAME" --execute="
        CREATE TABLE \\\`sqlversion\\\` (
          \\\`name\\\` varchar(45) NOT NULL,
          \\\`value\\\` varchar(45) NOT NULL,
          PRIMARY KEY (\\\`name\\\`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
        INSERT INTO sqlversion VALUES ('version', '0.0.0');
    "`
    if [[ $? -eq 1 ]]
        then
            echo -en $COLOR_RED
            echo -e "Ошибка создания таблицы версий."
            echo -en $STYLE_DEFAULT
        else
            echo -en $COLOR_GREEN
            echo -e "Таблица версий успешно создана."
            echo -en $STYLE_DEFAULT
    fi
}

function echoVersion {
    if [[ `checkTableVersionExist` -eq 0 ]]
        then
            echo -en $COLOR_RED
            echo -e "Таблица версий БД не создана."
            echo -en $STYLE_DEFAULT
            yN "Создать таблицу версий? [yes/NO]"
            if [[ $YN -eq 1 ]]
                then
                    createTableVersion
            fi
    fi
    if [[ `checkTableVersionExist` -eq 1 ]]
        then
            # TEMP=$(mysql --host=$DBHOST --port=3306 --user="$DBUSER" -s --execute="
            #     -- SELECT concat(\`1\`, '.', \`2\`, '.', \`3\`) as version FROM sqlversion LIMIT 1;
            #     SELECT \`value\` as version FROM \`sqlversion\` WHERE name = 'version';
            # ")
            TEMP=$(getDbVersion)
            if [[ $TEMP == '' ]]; then
                TEMP="Нет версии"
            fi
            echo -en $COLOR_GREEN
            echo -e "Версия БД:                 $STYLE_DEFAULT$TEMP"
            echo -en $STYLE_DEFAULT
    fi
    MVERSION=`LANG=C ls migration | grep  '.sql' | sed -r 's/\.sql//' | tail -1`
    if [[ $MVERSION == ''  ]]; then
        echo "Нет миграций"
    fi
    echo -en $COLOR_GREEN
    echo -e "Версия последней миграции: $STYLE_DEFAULT$MVERSION"
    echo -en $STYLE_DEFAULT
}

function getDbVersion {
    echo $(mysql --host=$DBHOST --port=3306 --user="$DBUSER" --database="$DBNAME" -s --execute="
        SELECT \`value\` as version FROM \`sqlversion\` WHERE name = 'version';
    ")
}

function migrateToLastVersion {
    # Текущая версия
    DB_VERSION=$(getDbVersion)
    echo -en $COLOR_GREEN
    echo -e "Версия БД: $STYLE_DEFAULT$DB_VERSION"
    echo -en $STYLE_DEFAULT

    # Версии миграций
    # так:

    # VERSIONS=(`LANG=C ls migration | grep  '.sql' | sed -r 's/\.sql//'`)
    # echo "VERSIONS: "
    # for value in "${VERSIONS[@]}"
    # do
    #     echo $value
    # done

    # или так:

    declare -a VERSIONS
    while read line
    do
        VERSIONS=("${VERSIONS[@]}" "$line")
    done < <(LANG=C ls migration | grep  '.sql' | sed -r 's/\.sql//')

    # Перебор и выполнение необходимых миграций
    dbArray=(${DB_VERSION//./ })
    for mVersion in "${VERSIONS[@]}"
    do
        mArray=(${mVersion//./ })
        if [[ ${mArray[0]} -gt ${dbArray[0]} ]]
            then
                migrate $mVersion
                if [ $MIGRATION_STATUS -eq 1 ]; then break; fi
            else
                if [[ ${mArray[1]} -gt ${dbArray[1]} ]]
                    then
                        migrate $mVersion
                        if [ $MIGRATION_STATUS -eq 1 ]; then break; fi
                    else
                        if [[ ${mArray[2]} -gt ${dbArray[2]} ]]
                            then
                                migrate $mVersion
                                if [ $MIGRATION_STATUS -eq 1 ]; then break; fi
                        fi
                fi
        fi
    done

    declare -a TRIGGERS
    while read line
    do
        TRIGGERS=("${TRIGGERS[@]}" "$line")
    done < <(LANG=C ls triggers | grep  '.sql' | sed -r 's/\.sql//')
    if [[ ${#TRIGGERS[*]} -gt 0 ]]; then
        for trigger in "${TRIGGERS[@]}"
        do
            echo -en $COLOR_GREEN
            echo -e "Применение триггеров в $STYLE_DEFAULT$trigger:"
            echo -en $STYLE_DEFAULT
            (mysql --host=$DBHOST --port=3306 --user="$DBUSER" --database="$DBNAME" -s < "./triggers/$trigger") >/dev/null
            TRIGGER_STATUS=$?
            if [ $TRIGGER_STATUS -eq 0 ]
                then
                    echo -en $COLOR_GREEN
                    echo "Успешно."
                    echo -en $STYLE_DEFAULT
                else
                    echo -en $COLOR_RED
                    echo -e "Ошибка применения триггеров."
                    echo -en $STYLE_DEFAULT
                    break
            fi
        done
    fi

    declare -a PROCEDURES
    while read line
    do
        PROCEDURES=("${PROCEDURES[@]}" "$line")
    done < <(LANG=C ls procedures | grep  '.sql' | sed -r 's/\.sql//')
    if [[ ${#PROCEDURES[*]} -gt 0 ]]; then
        for procedure in "${PROCEDURES[@]}"
        do
            echo -en $COLOR_GREEN
            echo -e "Применение процедур в $STYLE_DEFAULT$procedure:"
            echo -en $STYLE_DEFAULT
            (mysql --host=$DBHOST --port=3306 --user="$DBUSER" --database="$DBNAME" -s < "./procedures/$procedure") >/dev/null
            PROCEDURE_STATUS=$?
            if [ $PROCEDURE_STATUS -eq 0 ]
                then
                    echo -en $COLOR_GREEN
                    echo "Успешно."
                    echo -en $STYLE_DEFAULT
                else
                    echo -en $COLOR_RED
                    echo -e "Ошибка применения процедур."
                    echo -en $STYLE_DEFAULT
                    break
            fi
        done
    fi
}

function migrate {
    echo -en $COLOR_GREEN
    echo -e "Миграция базы к версии $STYLE_DEFAULT$1:"
    echo -en $STYLE_DEFAULT
    (mysql --host=$DBHOST --port=3306 --user="$DBUSER" --database="$DBNAME" -s < "./migration/$1.sql") >/dev/null
    MIGRATION_STATUS=$?
    if [ $MIGRATION_STATUS -eq 0 ]
        then
            echo -en $COLOR_GREEN
            echo "Успешно."
            echo -en $STYLE_DEFAULT
            mArray=(${1//./ })
            mysql --database="$DBNAME" --user="$DBUSER" -s -e"
                UPDATE \`sqlversion\` SET \`value\`='$1' WHERE \`name\`='version';
            ";
        else
            echo -en $COLOR_RED
            echo -e "Ошибка миграции $STYLE_DEFAULT$1"
            echo -en $STYLE_DEFAULT
    fi
}

function migrationsList {
    VERSIONS=(`LANG=C ls migration | grep  '.sql' | sed -r 's/\.sql//'`)
    echo -en $COLOR_GREEN
    echo "Версии миграций:"
    echo -en $STYLE_DEFAULT
    for value in "${VERSIONS[@]}"
    do
        echo $value
    done
}

function echoDbName {
    if [ ! -f ./config.sh ]
        then
            echo -en $COLOR_RED
            echo "Конифигурационный файл config.sh не найден."
            echo -en $STYLE_DEFAULT
        else
            echo -en $COLOR_GREEN
            echo "Работа с базой данных: $DBNAME"
            echo -en $STYLE_DEFAULT
    fi
}

function echoDbUser {
    if [ ! -f ./config.sh ]
        then
            echo -en $COLOR_RED
            echo "Конифигурационный файл config.sh не найден."
            echo -en $STYLE_DEFAULT
        else
            echo -en $COLOR_GREEN
            echo "Работа с базой данных от пользователя: $DBUSER"
            echo -en $STYLE_DEFAULT
    fi
}

function echoDbConf {
    if [ ! -f ./config.sh ]
        then
            echo -en $COLOR_RED
            echo "Конифигурационный файл config.sh не найден."
            echo -en $STYLE_DEFAULT
        else
            echo -en $COLOR_GREEN
            echo -e "Работа с базой данных: $STYLE_DEFAULT$DBNAME"
            echo -en $COLOR_GREEN
            echo -e "на:                    $STYLE_DEFAULT$DBHOST"
            echo -en $COLOR_GREEN
            echo -e "От пользователя:       $STYLE_DEFAULT$DBUSER"
            echo -en $STYLE_DEFAULT
    fi
}

