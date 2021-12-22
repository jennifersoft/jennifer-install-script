FROM ubuntu:20.04

RUN apt-get update && \
    apt-get install -y openjdk-8-jdk && \
    apt-get install -y ant && \
    apt-get clean;
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata

RUN echo $JAVA_HOME

# enable Jennifer server
RUN apt install unzip -y
ENV JENNIFER_SERVER_VERSION='5.6.0.10'

COPY ./docker/jennifer-server-${JENNIFER_SERVER_VERSION}.zip /opt
RUN cd /opt && unzip jennifer-server-${JENNIFER_SERVER_VERSION}.zip
RUN cd /opt && unzip jennifer-data-server-${JENNIFER_SERVER_VERSION}.zip 
RUN cd /opt && unzip jennifer-view-server-${JENNIFER_SERVER_VERSION}.zip 

# TODO: Agent perspective 설정
ENV JENNIFER_AGENT_TYPE=java
COPY ./docker/scripts/jennifer_view.sh /opt/server.view/bin/jennifer_view.sh

# Exposing Jennifer port to host
EXPOSE 7900
COPY ./docker/scripts/run_server.sh /usr/local
CMD ["/usr/local/run_server.sh"]
