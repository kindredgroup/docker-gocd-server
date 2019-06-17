FROM centos:7
MAINTAINER karel.bemelmans@unibet.com

# Install more apk packages we might need
RUN set -x \
  && yum clean all \
  && yum -y install epel-release \
  && yum update -y \
  && yum install -y \
    git \
    httpd-tools \
    java-11-openjdk \
    subversion \
    xmlstarlet \
    unzip \
  && yum clean all

# Add go user and group
# You can override this when building the container, make sure this matches the
# ownership of the mounted volumes!
ARG GO_USER_ID=500
ARG GO_GROUP_ID=500
RUN groupadd --gid ${GO_GROUP_ID} go \
  && adduser --shell /bin/bash --home /var/lib/go-server --no-create-home --uid ${GO_USER_ID} -g go go

# Install GoCD Server from zip file
ARG GO_MAJOR_VERSION=19.5.0
ARG GO_BUILD_VERSION=9272
ARG GO_VERSION="${GO_MAJOR_VERSION}-${GO_BUILD_VERSION}"
ARG GOCD_SHA256=bd98be5cd537b1e9ffd797c5131d3106c21f460252918a3bb8823f74a9730f32

RUN set -x && curl -L --silent https://download.gocd.org/binaries/${GO_VERSION}/generic/go-server-${GO_VERSION}.zip \
       -o /tmp/go-server.zip \
  && echo "${GOCD_SHA256}  /tmp/go-server.zip" | sha256sum -c - \
  && unzip /tmp/go-server.zip -d /usr/local \
  && ln -s /usr/local/go-server-${GO_MAJOR_VERSION} /usr/local/go-server \
  && chown -R go:go /usr/local/go-server-${GO_MAJOR_VERSION} \
  && rm /tmp/go-server.zip

RUN set -x && mkdir -p /etc/default \
  && cp /usr/local/go-server-${GO_MAJOR_VERSION}/go-server.default /etc/default/go-server \
  && sed -i -e "s/DAEMON=Y/DAEMON=N/" /etc/default/go-server

RUN set -x && mkdir /etc/go && chown go:go /etc/go \
  && mkdir /var/lib/go-server && chown go:go /var/lib/go-server \
  && mkdir /var/log/go-server && chown go:go /var/log/go-server

# Expose ports needed
EXPOSE 8153 8154

VOLUME /etc/go
VOLUME /var/lib/go-server
VOLUME /var/log/go-server

# add the entrypoint config and run it when we start the container
COPY ./docker-entrypoint.sh /
RUN chown go:go /docker-entrypoint.sh && chmod 500 /docker-entrypoint.sh

# With the upgrade to java8 we need to add this option to prevent curl and
# other SSL options inside Go from breaking.
ENV GO_SERVER_SYSTEM_PROPERTIES="-Dcom.sun.net.ssl.enableECC=false"

USER go
ENTRYPOINT ["/docker-entrypoint.sh"]
