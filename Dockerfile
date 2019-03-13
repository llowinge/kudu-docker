FROM ubuntu:xenial

RUN apt-get update && apt-get -y install wget \
  default-jdk default-jre \
  telnet \
  curl && \
  cd /etc/apt/sources.list.d && \
  wget -qO - https://archive.cloudera.com/cdh5/ubuntu/xenial/amd64/cdh/archive.key | apt-key add - && \
  wget http://archive.cloudera.com/kudu/ubuntu/xenial/amd64/kudu/cloudera.list && \
  apt-get update && \
  apt-get -y install kudu kudu-master kudu-tserver libkuduclient0 libkuduclient-dev

RUN chmod g=u /etc/passwd
RUN umask 000 && mkdir -p /var/lib/kudu/master && mkdir -p /var/lib/kudu/tserver && chmod 777 /var/lib/kudu/master && chmod 777 /var/lib/kudu/tserver
USER 1001

VOLUME /var/lib/kudu/master /var/lib/kudu/tserver

COPY docker-entrypoint.sh /
COPY kudu-client-1.0-SNAPSHOT.jar /

ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 8050 8051 7050 7051
CMD ["help"]
