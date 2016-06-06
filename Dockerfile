FROM gliderlabs/alpine:edge

# Version of RabbitMQ to install
ENV RABBITMQ_VERSION=3.6.2
ENV PLUGIN_BASE=v3.6.x

RUN \
  apk --update add bash coreutils curl erlang erlang-asn1 erlang-crypto erlang-eldap erlang-erts erlang-inets erlang-mnesia erlang-os-mon erlang-public-key erlang-sasl erlang-ssl erlang-syntax-tools erlang-xmerl xz && \
  curl -sL -o /tmp/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.gz https://www.rabbitmq.com/releases/rabbitmq-server/v${RABBITMQ_VERSION}/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.xz && \
  cd /usr/lib/ && \
  tar xf /tmp/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.gz && \
  rm /tmp/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.gz && \
  mv /usr/lib/rabbitmq_server-${RABBITMQ_VERSION} /usr/lib/rabbitmq

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN adduser -s /bin/bash -D -h /var/lib/rabbitmq rabbitmq

ADD erlang.cookie /var/lib/rabbitmq/.erlang.cookie
ADD rabbitmq.config /usr/lib/rabbitmq/etc/rabbitmq/rabbitmq.config

# Environment variables required to run
ENV ERL_EPMD_PORT=4369
ENV HOME /var/lib/rabbitmq
ENV PATH /usr/lib/rabbitmq/bin:/usr/lib/rabbitmq/sbin:$PATH

ENV RABBITMQ_LOGS=-
ENV RABBITMQ_SASL_LOGS=-
ENV RABBITMQ_DIST_PORT=25672
ENV RABBITMQ_SERVER_ERL_ARGS="+K true +A128 +P 1048576 -kernel inet_default_connect_options [{nodelay,true}]"
ENV RABBITMQ_MNESIA_DIR=/var/lib/rabbitmq/mnesia
ENV RABBITMQ_PID_FILE=/var/lib/rabbitmq/rabbitmq.pid
ENV RABBITMQ_PLUGINS_DIR=/usr/lib/rabbitmq/plugins
ENV RABBITMQ_PLUGINS_EXPAND_DIR=/var/lib/rabbitmq/plugins

# Fetch the external plugins and setup RabbitMQ
RUN \
  apk --purge del curl tar gzip xz && \
  chown rabbitmq /var/lib/rabbitmq/.erlang.cookie /var/lib/rabbitmq /usr/lib/rabbitmq && \
  chmod 0600 /var/lib/rabbitmq/.erlang.cookie && \
  rabbitmq-plugins enable --offline rabbitmq_management && \
  rabbitmq-plugins list

EXPOSE 4369 5672 25672

USER rabbitmq
CMD /usr/lib/rabbitmq/sbin/rabbitmq-server
