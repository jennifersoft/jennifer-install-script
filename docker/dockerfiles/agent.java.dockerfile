FROM tomcat:8.5-jre8-alpine

RUN apk update && apk upgrade
RUN apk add wget

# Exposing Apache port to host
EXPOSE 80


###### AGENT INSTALL

# TODO: 제니퍼 서버의 정보를 를 넣어야함
ENV JENNIFER_SERVER_HOST=192.168.0.248
ENV JENNIFER_VIEW_PORT=27900
ENV JENNIFER_DATA_PORT=25000
ENV JENNIFER_AGENT_TYPE=java
ENV JENNIFER_APPLICATION_PATH=/usr/local/tomcat/bin

COPY ./jennifer_install.sh /usr/local
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

COPY ./docker/scripts/run_java.sh /usr/local
CMD ["/usr/local/run_java.sh"]