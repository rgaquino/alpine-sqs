# Copyright 2017 Ronald E. Oribio R.
#
# This file is part of alpine-sqs which is released under the GPLv3.
# See https://github.com/roribio/alpine-sqs for details.

FROM appropriate/curl as Builder

ARG jq_version=1.5

WORKDIR /tmp/sqs-alpine

RUN \
  apk add --update git \
  && rm -rf /var/cache/apk/* \
  && curl -L -o /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-${jq_version}/jq-linux64 \
  && chmod +x /usr/local/bin/jq \
  && export elasticmq_version=$(curl -sL https://api.github.com/repos/adamw/elasticmq/releases/latest | jq -r .tag_name) \
  && elasticmq_version=${elasticmq_version//v} \
  && curl -LO https://s3-eu-west-1.amazonaws.com/softwaremill-public/elasticmq-server-${elasticmq_version}.jar \
  && mv elasticmq-server-${elasticmq_version}.jar elasticmq-server.jar

FROM anapsix/alpine-java:8
LABEL maintainer="Ralph Gregor Aquino https://github.com/rgaquino"

COPY --from=Builder /tmp/sqs-alpine/ /opt/
COPY etc/ /etc/
COPY opt/ /opt/

RUN \
  apk add --update \
    nodejs \
    nodejs-npm \
    supervisor \
  && rm -rf \
    /var/cache/apk/* \
    /etc/supervisord.conf \
  && ln -s /etc/supervisor/supervisord.conf /etc/supervisord.conf

EXPOSE 9324

ENTRYPOINT ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]

