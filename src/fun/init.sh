#!/bin/bash

# Список функций:
# init                   — входная функция
# createConfig           — создание конфигурационного файла пользователя
# createDefaultFolders   — создание необходимых папок
# checkGitignore         — проверка и зоздания .gitignore
# checkTableVersionExist — провверка существования таблицы версий в бд
# createTableVersion     — создание таблицы версий
# echoVersion            — вывод версии базы данных и миграций
# getDbVersion           — получение версии базы данных
# echoDbName             — имя БД из конфига
# echoDbUser             — имя пользователя БД из конфига
# echoDbConf             — вывод Конйигурационного файла
# reset                  — удалить и создать базу данных

function init {
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

TEXT_BOLD='\033[1m'
COLOR_RED='\033[31m'
COLOR_GREEN='\033[32m'
STYLE_DEFAULT='\033[0m'

DBHOST=\"$DBHOST\"
DBNAME=\"$DBNAME\"
DBUSER=\"$DBUSER\"
DBPASS=\"$DBPASS\"

REMOTE_NAME=\"$REMOTE_NAME\"
REMOTE_PATH=\"$REMOTE_PATH\"

SQL_DEBUG=0

if [[ \$SQL_DEBUG -eq 1 ]]
    then
        echo -en \$COLOR_GREEN
        echo -e \"Включён локальный конфигурационный файл: \$STYLE_DEFAULT\$BASH_ARGV.\"
        echo -en \$STYLE_DEFAULT
fi
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

function checkTableVersionExist {
    export MYSQL_PWD="$DBPASS"
    SQL="
SELECT TABLE_NAME
FROM information_schema.tables
WHERE table_schema = '$DBNAME'
AND table_name = 'sqlversion';
"
    if [[ $SQL_DEBUG -eq 1 ]]
        then
        echo -en $COLOR_YELLOW
        echo "$SQL"
        echo -en $STYLE_DEFAULT
    fi
    TEMP=`mysql --host=$DBHOST --port=3306 --user="$DBUSER" --database="$DBNAME" --execute="$SQL"`
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

function reset {
    `mysql --host=$DBHOST --port=3306 --user="$DBUSER" -e"DROP DATABASE $DBNAME;"` >/dev/null
    MYSQL_STATUS=$?
    if [[ $MYSQL_STATUS -eq 0 ]]
        then
            echo -en $COLOR_GREEN
            echo "БД $DBNAME удалена успешно."
            echo -en $STYLE_DEFAULT
        else
            echo -en $COLOR_RED
            echo -e "Ошибка удаления."
            echo -en $STYLE_DEFAULT
    fi
    `mysql --host=$DBHOST --port=3306 --user="$DBUSER" -e"CREATE SCHEMA $DBNAME DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"` >/dev/null
    MYSQL_STATUS=$?
    if [[ $MYSQL_STATUS -eq 0 ]]
        then
            echo -en $COLOR_GREEN
            echo "БД $DBNAME создана успешно."
            echo -en $STYLE_DEFAULT
        else
            echo -en $COLOR_RED
            echo -e "Ошибка создания."
            echo -en $STYLE_DEFAULT
    fi
}
