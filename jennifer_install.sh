#!/bin/bash

set -a

VERSION=0.0.1

# 기본 값 확인 
if ([ $# -eq 1 ] && [ "$1" == "-h" -o "$1" == "--help" ]); then
    echo "Jennifer Installer Script version ${VERSION}"
    echo " Usage: "
    echo "  ./jennifer_install.sh [option]..."
    echo " "
    echo " Options: "
    echo "  -v, --version                     Print Jennifer install script version."
    echo "  -H, --jennifer-host string        (Required) Jennifer server IP."
    echo "      --view-port string            Jennifer view server Port. (default \"7900\")"
    echo "      --server-port string          Jennifer data server Port. (default \"5000\")"
    echo "  -d, --domain-id string            Jennifer domain id. (default \"1000\")"
    echo "  -a, --agent-type string           (Required) Jennifer agent type {java|dotnet|php}."
    echo "  -t, --target-version string       Target jennifer agent version."
    echo "  -c, --config-path string          Application config path."
    echo "  -P, --php-version string          PHP application version. (Only for PHP Agent)"
    exit 0
fi

if ([ $# -eq 1 ] && [ "$1" == "-v" -o "$1" == "--version" ]); then
    echo "Jennifer Installer Script version ${VERSION}"
    exit 0
fi

JENNIFER_SERVER_HOST=$JENNIFER_SERVER_HOST
JENNIFER_VIEW_PORT=$JENNIFER_VIEW_PORT
JENNIFER_DATA_PORT=$JENNIFER_DATA_PORT
JENNIFER_DOMAIN_ID=$JENNIFER_DOMAIN_ID
JENNIFER_AGENT_TYPE=$JENNIFER_AGENT_TYPE
JENNIFER_AGENT_VERSION=""

while (( "$#" )); do
    case "$1" in
        -H|--jennifer-host)
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                JENNIFER_SERVER_HOST=$2
                shift 2
            else
                echo "Error: Argument for $1 is missing" >&2
                exit 1
            fi
            ;;
        --view-port)
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                JENNIFER_VIEW_PORT=$2
                shift 2
            else
                echo "Error: Argument for $1 is missing" >&2
                exit 1
            fi
            ;;
        --server-port)
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                JENNIFER_DATA_PORT=$2
                shift 2
            else
                echo "Error: Argument for $1 is missing" >&2
                exit 1
            fi
            ;;
        -a|--agent)
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                JENNIFER_AGENT_TYPE=$2
                shift 2
            else
                echo "Error: Argument for $1 is missing" >&2
                exit 1
            fi
            ;;
        -t|--target-version)
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                JENNIFER_AGENT_VERSION=$2
                shift 2
            else
                echo "Error: Argument for $1 is missing" >&2
                exit 1
            fi
            ;;
        -c|--config-path)
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                JENNIFER_APPLICATION_CONFIG=$2
                shift 2
            else
                echo "Error: Argument for $1 is missing" >&2
                exit 1
            fi
            ;;
        -P|--php-version)
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                JENNIFER_PHP_VERSION=$2
                shift 2
            else
                echo "Error: Argument for $1 is missing" >&2
                exit 1
            fi
            ;;
        -d|--domain-id)
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                JENNIFER_DOMAIN_ID=$2
                shift 2
            else
                echo "Error: Argument for $1 is missing" >&2
                exit 1
            fi
            ;;
    esac
done

if [ -z "$JENNIFER_VIEW_PORT" ]; then
    JENNIFER_VIEW_PORT=7900
fi
if [ -z "$JENNIFER_DATA_PORT" ]; then
    JENNIFER_DATA_PORT=5000
fi
if [ -z "$JENNIFER_DOMAIN_ID" ]; then
    JENNIFER_DOMAIN_ID=1000
fi

cd /opt 
if [ ! -e jennifer-agent-${JENNIFER_AGENT_TYPE}-* ]; then
    echo "Agent download from jennifer view server"
    cd /opt && wget --content-disposition http://${JENNIFER_SERVER_HOST}:${JENNIFER_VIEW_PORT}/download/agent/${JENNIFER_AGENT_TYPE}/${JENNIFER_AGENT_VERSION}

    echo "Agent install"
    cd /opt && unzip jennifer-agent-${JENNIFER_AGENT_TYPE}-*
fi

# Move conf location
if [ $JENNIFER_AGENT_TYPE == 'java' ]; then
    cd /opt/agent.${JENNIFER_AGENT_TYPE}/conf
elif [ $JENNIFER_AGENT_TYPE == 'php' ]; then
    cd /opt/agent.${JENNIFER_AGENT_TYPE}
fi

## Write default configuration
touch ./jennifer.conf && \
   printf "server_address = %s
server_port = %s

# domain_id : Valid range is (1-32767)
domain_id = %s

# default log_dir "./logs"
# log_dir = ./logs
# log_max_age : Valid ragne is (1-365), log_max_age option specifies the maximum duration in days to keep the log files
# log_max_age = 1

#inst_name : inst_name option specifies the instance name.
#inst_name=example_name : This setting sets instance name to 'example_name'

# inst_id : Automatically assinged when agent is connected to server. Valid range is (1-32767)
# inst_id =

# log_rotation = true
" $JENNIFER_SERVER_HOST $JENNIFER_DATA_PORT $JENNIFER_DOMAIN_ID \
    > jennifer.conf

if [ $JENNIFER_AGENT_TYPE == 'java' ]; then
    # JENNIFER Java Agent
    echo "Please add javaagent option \"-javaagent:\$AGENT_HOME/jennifer.jar\" and agent config \"-Djennifer.config=\$AGENT_HOME/conf/jennifer.conf\""
elif [ $JENNIFER_AGENT_TYPE == 'php' ]; then
    # JENNIFER PHP Agent
    if [ -z "$JENNIFER_APPLICATION_CONFIG" ] || [ -z "$JENNIFER_PHP_VERSION" ]; then
        echo "Please set Jennifer PHP Agent configuration in php.ini file."
        echo "Add the \"-c\" and \"-P\" options or try \"agent-installer\" for a automatic install."
        echo "ERROR: Installing failed."
        exit 2
    fi

    while read line
    do
        if [[ $line =~ ^\s*\[jennifer\] ]]; then
            INSTALLED=1
            echo "Already jennifer installed"
            break
        fi
    done <<<$(cat $JENNIFER_APPLICATION_CONFIG)

    if [ -z "$INSTALLED" ]; then
        JENNIFER_PHP_VERSION_MAJOR=$(echo $JENNIFER_PHP_VERSION | cut -d '.' -f1)
        JENNIFER_PHP_VERSION_MINOR=$(echo $JENNIFER_PHP_VERSION | cut -d '.' -f2)
        printf '\n\n[jennifer]\n' >> $JENNIFER_APPLICATION_CONFIG
        printf 'jenniferAgent.agent_file_root=/opt/agent.php\n' >> $JENNIFER_APPLICATION_CONFIG
        printf 'extension=/opt/agent.php/bin/jennifer5-php-%s.%s.x-NTS.so\n' $JENNIFER_PHP_VERSION_MAJOR $JENNIFER_PHP_VERSION_MINOR >> $JENNIFER_APPLICATION_CONFIG
        echo "Setted default configuration in ${JENNIFER_APPLICATION_CONFIG} with PHP Version : ${JENNIFER_PHP_VERSION_MAJOR}.${JENNIFER_PHP_VERSION_MINOR}"
    fi
fi

echo "Install complete"