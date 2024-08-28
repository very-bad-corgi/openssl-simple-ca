
# Certification center

## Содержание  
[0. Описание проекта](#0-описание-проекта)
* [0.1 Функционал](#01-функционал)

[1. Предварительная настройка](#1-предварительная-настройка)
* [1.1 Установка зависимостей](#11-установка-зависимостей)
* [ 1.2 Переопределение символьной ссылки до исполняемого файла OpenSSL](#12-переопределение-символьной-ссылки-до-исполняемого-файла-openssl)
* [1.3 Активация автодополнения команд по TAB](#13-активация-автодополнения-команд-по-tab)

[2. Начало работы с УЦ](#2-начало-работы-с-уц)
* [2.1 Инициализация](#21-инициализация)
* [2.2 Отчистка УЦ](#22-отчистка-уц)
* [2.3 Издание сертификатов конечных участников](#23-издание-сертификатов-конечных-участников)
* [2.4 Отзыв сертификатов](#24-отзыв-сертификатов)
* [2.5 Издание списка отозванных сертификатов](#25-издание-списка-отозванных-сертификатов)
* [2.6 Публикация списка сертификатов либо CRL по FTP](#26-публикация-списка-сертификатов-либо-crl-по-ftp)

[3. Структура УЦ](#3-структура-уц)
* [3.1 Файловая структура проекта](#31-файловая-структура-проекта)
* [ 3.2 Базы данных](#32-базы-данных)
  * [3.2.1 База данных изданных сертификатов](#321-база-данных-изданных-сертификатов)
  * [3.2.2 База данных серийных номеров сертификатов](#322-база-данных-серийных-номеров-сертификатов)
  * [3.2.3 База данных серийных номеров списка отозванных сертификатов](#323-база-данных-серийных-номеров-списка-отозванных-сертификатов)

## 0. Описание проекта
Перейти к [Содержание](#содержание)

## 0.1 Функционал

Реализованы механизмы:
- Выпуска одноуровневой / двухуровневой цепочки УЦ с уровнем стойкости **128**, алгоритму подписи **prime256v1** + хэширования **SHA-256** и шифрованием **AES-256**
- enroll ( Выпуск ) сертификатов
  - по запросу на сертификат
  - с генерацией одного файла личного ключа ( с шифрованием / без )
- revoke ( Отзыв ) сертификатов конечных участников и промежуточного УЦ
- issuing-crl, издание списка отозванных сертификатов
- clear-ca, отчистка УЦ ( с целью пересоздать )
- publish, отправки сертификатов УЦ и CRL на список FTP-серверов

Используются команды OpenSSL, которые совместимы с версиями от 1.1.1 до самой актуальной ( 3.3.1, например ). Можно организовать работу УЦ на СТБ криптографии, например, собрав исполняемый файл ( https://github.com/agievich/bee2 ), либо на ГОСТ, определим соответствующие алгоритмы

> УЦ наполнен небольшим количеством тестовых данных для демонстрации структур БД, а так же изданных сертификатов. Была издана двухуровневая цепочка. Перед работой с УЦ [2.1 Инициализация](#21-инициализация) требуется отчистить выполнить пункт [2.2 Отчистка УЦ](#22-отчистка-уц)

## 1. Предварительная настройка
Перейти к [Содержание](#содержание)

### 1.1 Установка зависимостей 
На основе RedHat ( Fedora, Alma Linux, Oracle Linux )
```sh
sudo dnf install -y perl ncftp
```
На основе Debian ( Ubuntu, Mint )
```sh
sudo apt install -y perl ncftp
```

Perl используется для формирования копии Базы данных сертификатов из кодировки ASCII в UTF-8 - для удобного визуального просмотра ( необходимо для сертификатов, содержащих русские символы в описании данных о субъекте )

ncftp используется для распространения сертификатов и CRL на список FTP-серверов

### 1.2 Переопределение символьной ссылки до исполняемого файла OpenSSL

```
ln -sfT $(whereis openssl | awk '/bin/ {print $2}') ./openssl
```

Проверка 
```
./openssl version
```

Если исполняемый файл отсутствует в системе, то требуется его установить командой

Fedora
```
sudo dnf install -y openssl
```
Ubuntu
```
sudo apt install -y openssl
```


### 1.3 Активация автодополнения команд по TAB

Для удобной работы в скрипте по взаимодействию с УЦ реализовано автодополнение допустимых команд по **TAB**-у, для его активации требуется и выполнить команду ( Временный вариант ):
```sh
source ./do.sh
```
## 2. Начало работы с УЦ
Перейти к [Содержание](#содержание)

## 2.1 Инициализация

Сперва требуется определиться с длиной цепочки удостоверяющего центра - будет она состоять:
1) из одного корневого сертификата RootCA ( одноуровневая )
2) либо из корневого и подчиненного сертификатов Root CA + Subordinate CA ( двухуровневая )

Далее переопределить значения по умолчанию для данных о субъекте УЦ ( блок `[ subjects_ca ]` ) в файле
```sh
./profiles/root.conf
```
и при необходимости в 
```sh
./profiles/subca.conf
```

Пример блока `[ subjects_ca ]` для Корневого УЦ
```
[ subjects_ca ]
countryName             = "BY"
stateOrProvinceName     = "Минская область"
localityName            = "Минск"
organizationName        = "My Test Organization"
commonName              = "Root CA"
streetAddress           = "Unknown street"
description             = "Test root Dev-сертификат"
```

Личные ключи сертификатов УЦ шифруются по паролю ( алгоритм `-aes256` ), для автоматизации процесса издания сертификатов рекомендуется определить переменные среды `ENV_PRIVATE_KEY_ROOT` и `ENV_PRIVATE_KEY_SUBCA` в файле `.env`, в противном случае потребуется ручной ввод пароля на все процедуры, требующие выработки подписи. Переменные среды по умолчанию закомментированы

В зависимости от желаемой длины цепочки инициализируем УЦ командой:

```sh
./do.sh init-ca root
```
либо
```sh
./do.sh init-ca subca+root
```

Итогом выполнения команды является:
- издание личных ключей и сертификатов УЦ в каталоги `ca/root` и ( опционально ) `ca/subca`
- формирование файлов базы данных в каталоге `db`
  - index.txt ( в кодировке ASCII ), содержит сведения о изданных сертификатах
  - index_utf8.txt, копия файла index.txt в кодировке UTF-8 ( для корректного отображения русских символов )
  - serial, содержит серийный номер сертификата, который присвоится новоизданному сертификату
  - crlnumber, содержит серийный номер списка отозванных сертификатов ( СОС ), который присвоится новоизданному СОС

Первые серийные номера ( в **hex** формате ) сертификатов открытого ключа и списков отозванных сертификатов определяются в файле:
```
./scripts/init-ca.sh  
```
в строках 
```
    echo "010000000000000000" > ./db/root/serial     # First serial number user certificate
    echo "010000000000000000" > ./db/root/crlnumber  # First serial number CRL
```
как для корневого УЦ, так и для Подчиненного УЦ

## 2.2 Отчистка УЦ

При возникновении проблем с формированием УЦ ( опечатка в наименовании данных о субъекте Корневого / Подчиненного УЦ, ошиблись с длиной УЦ ) есть возможность отчистить УЦ от изданных сертификатов и Базы данных, и произвести инициализацию заново

Команда по отчистке:
```
./do.sh clear-ca
```

Будет удалено содержимое дирректорий:
|Директория|Содержит в себе|
|---|---|
|/ca/root| Сертификат, личный ключ и СОС Корневого УЦ|
|/ca/subca|Сертификат, личный ключ и СОС Подчиненного УЦ|
|/db/root|База данных Корневого УЦ|
|/db/subca|База данных Подчиненного УЦ|
|/user-certs-issuing-ca|Список файлов всех изданных через OpenSSL сертификатов, содержащий как сертификаты в PEM формате, так и их человекочитабельное представление|
|/user-certs-package/clients|Пакет для передачи TLS-клиентов |
|/user-certs-package/servers|Пакет для передачи TLS-серверов|

## 2.3 Издание сертификатов конечных участников

Производится командой

```
./do.sh enroll
```
где **2-ой** входной параметр представляет на выбор 2 профиля сертификатов:
- `client`, TLS-клиента
- `server`, TLS-сервера

где **3-ий** входной параметр представляет возможность выпустить сертификат:
- `by-request`, по запросу пользователя
  - последующее нажатие **TAB** отобразит список доступных запросов на издание ( перечислит файлы, содержащиеся в каталоге **user-requests** с расширениями `.req` и `.csr` )
  - **4-ым** параметром можно выбрать как конкретный запрос на сертификат, так и параметр **all**, который выпустит сертификаты на все запросы, приведя в конце статистику по их выпуску 
- `one-key-file-gen`, с генерацией программного личного ключа, размещаемого в одном файле. Если на данном этапе отбить команду, то пойдет генерация личного ключа в открытом виде
  - профили по умочанию для запросов ( client и server ) на сертификат определены в `./profiles/default-users/`, которые можно переопределить
  - существует **4-ый** параметр для `one-key-file-gen` - `encrypt-by-aes256`, выбор которого позволит защифровать личный ключ конечного участника по паролю на `-aes256`, ввод пароля будет в дальнейшем запрошен
  - если личный ключ шифруется по паролю, то генерируется файл `pass.txt` с введенным паролем, который размещается в каталоге упаковки для конечного участника

Примеры команд:

1) Выпуск сертификата по запросу пользователя
```
./do.sh enroll client by-request 24_07_2024_13_59.req
```
Выпуск сертификатов по всем запросам на СОК
```
./do.sh enroll client by-request all
```
1) Выпуск сертификата с генерацией личного ключа, зашифрованного по паролю
```
./do.sh enroll server one-key-file-gen encrypt-by-aes256
```
Выпуск сертификата с генерацией личного ключа в открытом виде
```
./do.sh enroll server one-key-file-gen
```

## 2.4 Отзыв сертификатов

Конечных участников. Входным параметром требуется задать серийный номер отзываемого сертификата, например, `01000000000000000001`:
```
./do.sh revoke 01000000000000000001
```

Промежуточного УЦ ( в случае компрометации личного ключа )
``` 
./do.sh revoke subca
```

По окончании процедуры отзыва автоматически издается список отозванных сертификатов

## 2.5 Издание списка отозванных сертификатов

Издание СОС для Корневого УЦ
```
./do.sh issuing-crl root
```
Размещается по умолчанию в `ca/root/root.crl`

[ Опционально ] Издание СОС для Подчиненного УЦ
```
./do.sh issuing-crl subca
```
Размещается по умолчанию в `ca/subca/subca.crl`

## 2.6 Публикация списка сертификатов либо CRL по FTP

После процедуры отзыва сертификатов происхода обновление CRL на всех FTP-серверах, так же есть возможность отправить сертификаты УЦ ( Корневого и Подчиненного ) на список FTP-серверов, которые требуется определить в ассоциативном массиве `ftp_servers` файла `publish-by-ftp.hosts.sh`. Рекоменджуется использовать в связке с файловым HTTP-сервером ( на основе Nginx, например ) для их последующего распространения

Синтаксис команды:
```
./do.sh publish-by-ftp {2}
```

где **2-ой** параметр может принимать значения
- **certificates** 
- **crl**

Пример команд:
```
./do.sh publish-by-ftp crl
```
```
./do.sh publish-by-ftp certificates
```
## 3. Структура УЦ
Перейти к [Содержание](#содержание)

### 3.1 Файловая структура проекта

```sh
prod-0/
.
├── do.sh                           # Основной скрипт, через который ведется работа с УЦ
├── openssl                         # Исполняемый файл OpenSSL, реализующий все механизмы CA, и ведущий базы данных
├── README.md                       # Описание по работе с УЦ в Markdown формате
├── ca                              # Каталог с сертификатами, личными ключами и CRL удостоверяющего центра
│   ├── root
│   └── subca
├── db
│   ├── root                        # Каталог для базы данных сертификатов, изданных Корневым УЦ 
│   └── subca                       # Каталог для базы данных сертификатов, изданных Подчиненным УЦ 
├── profiles                        # Каталог для профилей сертификатов
│   ├── default-users
│   │   ├── client.conf
│   │   └── server.conf
│   ├── root.conf
│   └── subca.conf
├── scripts                         # Каталог для скриптов, которые реализуют все мехнизмы УЦ
│   ├── clear-ca.sh
│   ├── enroll.sh
│   ├── init-ca.sh
│   ├── issuing-crl.sh
│   ├── publish.sh
│   ├── revoke.sh
│   └── shared-functions.sh
├── user-certs-issuing-ca           # Сюда издает сертификаты `openssl ca`, а распаршенном виде и PEM-формате
│   ├── 01000000000000000000.pem
│   ├── 01000000000000000001.pem
│   ├── 01000000000000000002.pem
├── user-certs-package              # Пакет для передачи пользователю ( л. ключ, пароль от него, конечный сертификат )
│   ├── clients                     ## Для TLS-клиентов
│   └── servers                     ## Для TLS-серверов
└── user-requests                   # Каталог хранит в себе запросы на сертификат от пользоваетелей, на которые на были изданы сертификаты
    └── 24_07_2024_13_59.req
```

### 3.2 Базы данных

#### 3.2.1 База данных изданных сертификатов

Представляет из себя файлы **index.txt** и **index_utf8.txt** в каталоге **db**, за каждой ролью ( RootCA / SubCA ) закреплен свой соответствующий каталог

Пример записи изданного сертификата:
```
V	270826070813Z		010000000000000001	unknown	/C=BY/CN=Bob ( World Famous person )/description=TLS-client, default profile
```

Пример записи отозванного сертификата:
```
R	270826070349Z	240826072157Z,unspecified	010000000000000000	unknown	/C=BY/CN=Bob ( World Famous person )/description=TLS-client, default profile
```

Описание расположенных параметров в порядке слева на право:

1) **V** / **R** : Это статус сертификата

- **V** означает `Valid`, действителен
- **R** означает `Revoked`, отозван
- **E** означает `Expired`, истек

2) Дата отзыва сертификата с причиной отзыва

- Дата отзыва содержится в формате `YYMMDDHHMMSSZ`
- Причина отзыва ( через запятую ), по умолчанию - `unspecified`

3) Серийный номер сертификата в шестнадцатеричном виде

4) Поле `notBefore` - дата начала срока действия сертификата, и значение `unknown` означает, что это поле не было задано при издании сертификата, соответственно началом срока действия считается момент издания сертификата

5) Данные о субъекте
- в файле **index.txt** размещены в формате `ASCII`
- в файле **index_utf8.txt** размещены в формате `UTF-8`, с возможностью отображения русских символов

#### 3.2.2 База данных серийных номеров сертификатов

Представлена в файлах:
- `serial`, содержит серийный номер сертификата в формате `Hex`, который присвоится следующему издаваемому сертификату
- `serial.old`, содержит серийный номер крайнего изданного сертификата


#### 3.2.3 База данных серийных номеров списка отозванных сертификатов

Представлена в файлах:
- `crlnumber`, содержит серийный номер **CRL** в формате `Hex`, который присвоится следующему издаваемому **CRL**
- `crlnumber.old`, содержит серийный номер крайнего изданного **CRL**
