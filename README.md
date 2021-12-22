# Jennifer Install Script

`./jennifer_install.sh` : 제니퍼 에이전트를 스크립트에서 다운받아 실행하는 스크립트  
본 프로젝트안에는 Java 와 PHP 에이전트 설치를 설치할 수 있도록 Dockerfile 이 샘플로 포함되어있음
스크립트는 예제와 같이 Dockerfile 내에 포함되어도 되지만 이미지와는 별도로 동작 가능함

## Requirements
1. 접근할 수 있는 Jennifer Server 가 있어야 함
   본 예제에서는 `server.dockerfile` 로 이를 대체하였으며, `agent.*.dockerfile` 을 빌드하기 위해선 `server-compose.yml` 을 먼저 실행해야 함
2. 프로젝트에 포함된 dockerfile 을 사용하기 위해선 별도의 라이센스 발급 필요
3. 예제를 실행하기 위해선 Docker 가 설치된 환경이여야 함
4. 예제용 Jennifer Server 를 실행시키기 위해서 docker host network 를 사용하므로 포트를 열 수 있는지 확인하여야 함

## Desc

```shell
$ ./jennifer_install.sh --help
Jennifer Installer Script version 0.0.1
 Usage: 
  ./jennifer_install.sh [option]...
 
 Options: 
  -v, --version                     Print Jennifer install script version.
  -H, --jennifer-host string        (Required) Jennifer server IP.
      --view-port string            Jennifer view server Port. (default "7900")
      --server-port string          Jennifer data server Port. (default "5000")
  -d, --domain-id string            Jennifer domain id. (default "1000")
  -a, --agent-type string           (Required) Jennifer agent type {java|dotnet|php}.
  -t, --target-version string       Target jennifer agent version.
  -c, --config-path string          Application config path.
  -P, --php-version string          PHP application version. (Only for PHP Agent)

```

아래 예제와 같이 Jennifer Server 가 설치된 호스트 정보와 Agent type 을 추가하여 사용 가능하다.

### Java Agent Install
Java 의 경우 `jennifer_install.sh` 와는 별개로 Java 프로그램 실행시 아래와 같은 옵션을 추가하여 사용한다.
1. javaagent 옵션에 jennifer.jar 를 추가 한다.                   ex) -javaagent:%JENNIFER_HOME%\jennifer.jar 
2. -Djennifer.config 옵션을 통해 agent config 파일을 설정 한다.    ex) -Djennifer.config=..\jennifer.conf
  
Java Agent 의 dockerfile 예제
```dockerfile
###### AGENT INSTALL

# TODO: 제니퍼 서버의 정보를 를 넣어야함
ENV JENNIFER_SERVER_HOST=192.168.0.248
ENV JENNIFER_VIEW_PORT=7900
ENV JENNIFER_DATA_PORT=5000
ENV JENNIFER_AGENT_TYPE=java
ENV JENNIFER_APPLICATION_PATH=/usr/local/tomcat/bin

COPY ../jennifer_install.sh /usr/local
RUN /usr/local/jennifer_install.sh \
    -H ${JENNIFER_SERVER_HOST} \
    --view-port ${JENNIFER_VIEW_PORT} \
    --server-port ${JENNIFER_DATA_PORT} \
    -a ${JENNIFER_AGENT_TYPE} 

# setenv.sh 파일이 모든 자바환경은 아님
# 환경 변수로 JAVA_OPTS 에 추가하는 방법으로 가이드가 필요
RUN touch $JENNIFER_APPLICATION_PATH/setenv.sh
RUN printf 'AGENT_HOME=/opt/agent.java\n' >> $JENNIFER_APPLICATION_PATH/setenv.sh
RUN printf 'export CATALINA_OPTS="$CATALINA_OPTS -javaagent:$AGENT_HOME/jennifer.jar -Djennifer.config=$AGENT_HOME/conf/jennifer.conf"\n' >> $JENNIFER_APPLICATION_PATH/setenv.sh
```

### PHP Agent Install
PHP 의 경우 `jennifer_install.sh` 사용시 `-c` 옵션과 `-P` 옵션을 사용하여 설정 정보를 추가해주어야 한다.
1. `-c, --config-path`  : `php.ini` 파일의 절대경로.
2. `-P, --php--version` : 사용중인 PHP 의 버전. ex) 7.4.14
  
만약 위 옵션을 사용하지 않는 경우 별도로 에이전트에 포함된 `agent-installer` 프로그램을 실행시켜서 설치하거나, 아래의 내용을 `php.ini` 파일에 직접 추가해 주어야 한다.  
  
```conf
# 설치된 PHP 버전에 맞는 so 파일 적용
[jennifer]
jenniferAgent.agent_file_root=/opt/agent.php
extension=/opt/agent.php/bin/jennifer5-php-7.4.x-NTS.so
```

PHP Agent 의 dockerfile 예제
```dockerfile
ENV PHP_VERSION=7.4.14
#...

###### AGENT INSTALL

# TODO: 제니퍼 서버의 정보를 를 넣어야함
ENV JENNIFER_SERVER_HOST=192.168.0.248
ENV JENNIFER_VIEW_PORT=7900
ENV JENNIFER_DATA_PORT=5000
ENV JENNIFER_AGENT_TYPE=php

COPY ../jennifer_install.sh /usr/local
RUN /usr/local/jennifer_install.sh \
    -H ${JENNIFER_SERVER_HOST} \
    --view-port ${JENNIFER_VIEW_PORT} \
    --server-port ${JENNIFER_DATA_PORT} \
    -a ${JENNIFER_AGENT_TYPE} \
    -c $PHP_HOME/php-${PHP_VERSION}/etc/php-fpm/php.ini \
    --php-version ${PHP_VERSION}
```

## How to run the example

1. Edit `JENNIFER_AGENT_TYPE` environment variable in `./docker/server.dockerfile` with the agent you want to install.
2. Build server image
    ```
    $ docker-compose -f ./docker/server-compose.yml build
    ```
3. Start server container
    ```
    $ docker-compose -f ./docker/server-compose.yml up -d
    ```
4. Set jennifer `license key`
5. Build agents images
    ```
    $ docker-compose -f ./docker/php-compose.yml build
    or
    $ docker-compose -f ./docker/java-compose.yml build
    ```
6. Start a agent container
    ```
    $ docker-compose -f ./docker/php-compose.yml up -d
    or
    $ docker-compose -f ./docker/java-compose.yml up -d
    ```