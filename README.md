# zlatov/sql (в разработке)


## Установка, настройка

1. `composer require zlatov/sql:~1.0.0`
2. `mkdir sql; cd sql; ln -s ../vendor/zlatov/sql/src/sql.sh ./sql`
3. `./sql init`

## Использование

`./sql init` — настройка доступа к бд и адреса удаленного сервера

`./sql reset` — удалит и создат базу данных

`./sql dbname` — вывести имя БД из конфигурационного файла

`./sql dumplist` — список дампов

`./sql dump` — создать дамп

`./sql dump filename` — восстановить из дампа filename

`./sql push` — список локальных дампов

`./sql push filename` — отправка локального дампа на сервер

`./sql pull` — список удаленных дампов

`./sql pull filename` — получение удаленного дампа с сервера

`./sql migrate` — выполнить все миграции которые больше текущей версии БД

`./sql version` — вывести текущую версию БД и последнюю версию миграции

## Документация разработки

### Цели (требования) достигаемые пакетом

1. Работа с дампами базы данных из консоли

  - Создавать дамп локальной базы
  - Восстанавливать дам локальной базы
  - Создавать дамп удаленной базы
  - Восстанавливать дам удаленной базы
  - Отправлять дамп на удаленный сервер
  - Получать дамп с удаленного сервера

2. Осуществлять миграции бд описанные sql запросами

  - В соответствии с текущей версией бд последовательно выполняются миграции, обновляется версия бд после выполнения каждой миграции. После выполения списка миграций осуществляется обновление процедур и триггеров

### Желаемые действия пользователя после установки пакета и поведение пакета в различных ситуациях

После установки пакета (composer require zlatov/sql[...]) в пользователю необходимо выполнить:
  - создать ссылку:
    - <code>mkdir sql</code>
    - <code>ln ./vendor/zlatov/sql/src/sql.sh ./sql/sql</code>
  - настройку
    - <code>cd sql</code>
    - <code>./sql init</code>

1. БД не существует
2. БД существует

### Разработка файловой структуры
- sql/
  - dump/
  - migration/
  - procedures/
  - .gitignore
  - config.sh
  - sql

### Разработка структуры бд

Версия БД хранится в таблице <var>sql</var>

### Разработка синтаксиса

- ./sql init
\- настройка доступа к бд и адреса удаленного сервера
- ./sql dump
\- создать дамп
- ./sql dump filename
\- восстановить из дампа filename
- ./sql push
\- список локальных дампов
- ./sql push filename
\- отправка локального дампа на сервер
- ./sql pull
\- список удаленных дампов
- ./sql pull filename
\- получение удаленного дампа с сервера
- ./sql migrate
\- выполнить все миграции которые больше текущей версии БД
- ./sql version
\- вывести текущую версию БД и последнюю версию миграции
