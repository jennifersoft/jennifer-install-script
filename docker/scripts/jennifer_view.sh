#!/bin/sh

# ----------------------------------------------------------------------
# ----- Customizable Variables -----------------------------------------
# ----------------------------------------------------------------------
# JAVA_HOME=
JENNIFER_VIEW_SERVER_HOME=$(dirname $(cd "$(dirname "$0")" && pwd))
JENNIFER_VIEW_SERVER_CONF=${JENNIFER_VIEW_SERVER_HOME}/conf/server_view.conf # Must be absolute path. 
JENNIFER_VIEW_SERVER_LOG_CONF=${JENNIFER_VIEW_SERVER_HOME}/conf/logback.xml # Must be absolute path.

# ----------------------------------------------------------------------
# ----- You can choice platform 'java' or 'php' or 'net' ---------------
# ----------------------------------------------------------------------
JENNIFER_PLATFORM=${JENNIFER_AGENT_TYPE}

# ----------------------------------------------------------------------
# ----- Do not touch below this line!-----------------------------------
# ----------------------------------------------------------------------
export JENNIFER_VIEW_SERVER_HOME
cd ${JENNIFER_VIEW_SERVER_HOME}/bin
PATH=${JAVA_HOME}/bin:${PATH}

JAVA_OPTS=" ${JAVA_OPTS} -Xms2g -Xmx2g"
JAVA_OPTS=" ${JAVA_OPTS} -XX:+HeapDumpOnOutOfMemoryError"
JAVA_OPTS=" ${JAVA_OPTS} -Dfile.encoding=UTF-8"
JAVA_OPTS=" ${JAVA_OPTS} -Djennifer.lib=${JENNIFER_VIEW_SERVER_HOME}/lib"
JAVA_OPTS=" ${JAVA_OPTS} -Djennifer.viewserver.config=${JENNIFER_VIEW_SERVER_CONF}"
JAVA_OPTS=" ${JAVA_OPTS} -Dlogback.configurationFile=${JENNIFER_VIEW_SERVER_LOG_CONF}"
JAVA_OPTS=" ${JAVA_OPTS} -Djennifer.help=${JENNIFER_VIEW_SERVER_HOME}/help"
JAVA_OPTS=" ${JAVA_OPTS} -XX:+IgnoreUnrecognizedVMOptions"
JAVA_OPTS=" ${JAVA_OPTS} -XX:-OmitStackTraceInFastThrow"
JENNIFER_JAR=${JENNIFER_VIEW_SERVER_HOME}/lib/jennifer.launcher.jar
JENNIFER_MAIN_CLASS=com.jennifersoft.view.Main

echo $JENNIFER_JAR
echo $JENNIFER_MAIN_CLASS
echo $JENNIFER_PLATFORM

if [ "$1" = "start" ]; then
        java ${JAVA_OPTS} -jar ${JENNIFER_JAR} ${JENNIFER_MAIN_CLASS} start ${JENNIFER_PLATFORM}  > /dev/null 2>&1 &
        echo "Starting Jennifer5 view server is requested. For more information, see the log files."
elif [ "$1" = "run" ]; then
        java ${JAVA_OPTS} -jar ${JENNIFER_JAR} ${JENNIFER_MAIN_CLASS} start ${JENNIFER_PLATFORM}
elif [ "$1" = "stop" ]; then
        java ${JAVA_OPTS} -jar ${JENNIFER_JAR} ${JENNIFER_MAIN_CLASS} stop > /dev/null 2>&1 &
        echo "Stopping Jennifer5 view server is requested. For more information, see the log files."
elif [ "$1" = "version" ]; then
        java ${JAVA_OPTS} -jar ${JENNIFER_JAR} ${JENNIFER_MAIN_CLASS} version ${JENNIFER_PLATFORM}
else
        echo "Usage: jennifer_view.sh [command]"
        echo "Available command : start, stop, version"
fi
