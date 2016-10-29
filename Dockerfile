FROM unibet/alpine-jre:7
MAINTAINER karel.bemelmans@unibet.com

# Install more apk packages we might need
RUN apk --update add curl

# Add go user and group
RUN addgroup go && adduser -h /var/lib/go-server -H -S -G go go

# Install GoCD Server from zip file
ARG GO_MAJOR_VERSION=16.11.0
ARG GO_BUILD_VERSION=4185
ARG GO_VERSION="${GO_MAJOR_VERSION}-${GO_BUILD_VERSION}"
ARG GOCD_SHA256=c8fa2dc52dd4797d8f2aa85823f8896dc4d89ee77b3b23925c93afd885080875

RUN curl -L --silent https://download.go.cd/binaries/${GO_VERSION}/generic/go-server-${GO_VERSION}.zip \
       -o /tmp/go-server.zip \
  && echo "${GOCD_SHA256}  /tmp/go-server.zip" | sha256sum -c - \
  && unzip /tmp/go-server.zip -d /usr/local \
  && ln -s /usr/local/go-server-${GO_MAJOR_VERSION} /usr/local/go-server \
  && chown -R go:go /usr/local/go-server-${GO_MAJOR_VERSION} \
  && rm /tmp/go-server.zip

# Expose ports needed
EXPOSE 8153 8154

# These are the 3 volumes we define
# You should mount these as external mount points from the Docker host
RUN mkdir -p /etc/go /var/lib/go-server /var/log/go-server
VOLUME ['/var/lib/go-server', '/var/log/go-server', '/etc/go']

# add the entrypoint config and run it when we start the container
COPY ./docker-entrypoint.sh /
RUN chmod 500 /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
