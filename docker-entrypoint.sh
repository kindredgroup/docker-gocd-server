#!/bin/bash
set -e

# We overwrite this file everytime we run the container, so all your local changes
# will be lost. If you need to change the logging, fork this repo or build your
# own Docker image on top of this.
#
# Log to stdout instead of files
if [ -d /etc/go ]; then
cat >/etc/go/log4j.properties <<EOL
log4j.rootLogger=WARN, ConsoleAppender
log4j.logger.com.thoughtworks.go=INFO

# turn on all shine logging
log4j.logger.com.thoughtworks.studios.shine=WARN,ShineConsoleAppender
log4j.logger.com.thoughtworks.go.server.Rails=WARN

log4j.logger.org.springframework=WARN
log4j.logger.org.apache.velocity=WARN

# console output...
log4j.appender.ConsoleAppender=org.apache.log4j.ConsoleAppender
log4j.appender.ConsoleAppender.layout=org.apache.log4j.PatternLayout
log4j.appender.ConsoleAppender.layout.conversionPattern=%d{ISO8601} %5p [%t] %c{1}:%L - %m%n

# console output for shine...
log4j.appender.ShineConsoleAppender=org.apache.log4j.ConsoleAppender
log4j.appender.ShineConsoleAppender.layout=org.apache.log4j.PatternLayout
log4j.appender.ShineConsoleAppender.layout.conversionPattern=%d{ISO8601} %5p [%t] %c{1}:%L - %m%n
EOL
fi

# Server config
#
# Update it with the AGENT_KEY if needed, otherwise create a new clean config.
if [ -f /etc/go/cruise-config.xml ]; then
  if [ ! -z "$AGENT_KEY" ]; then
    xmlstarlet ed -u /cruise/server/@agentAutoRegisterKey -v ${AGENT_KEY} go-data/etc/cruise-config.xml
  fi
else
cat >/etc/go/cruise-config.xml <<EOL
<?xml version="1.0" encoding="utf-8"?>
<cruise xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="cruise-config.xsd" schemaVersion="87">
    <server agentAutoRegisterKey="${AGENT_KEY}">
        <security>
            <passwordFile path="/etc/go/passwd" />
        </security>
    </server>
</cruise>
EOL
fi

# Create a password file that contains 1 entry for now.
# We need this to be able to send API calls to the REST interface after the server has been booted
if [ ! -z "$GOCD_API_USERNAME" ] && [ ! -z "$GOCD_API_PASSWORD" ]; then
    echo "Updating /etc/go/passwd file with API user credentials..."

    if [ ! -f /etc/go/passwd ]; then
        htpasswd -b -s -c /etc/go/passwd ${GOCD_API_USERNAME} ${GOCD_API_PASSWORD}
    else
        htpasswd -b -s /etc/go/passwd ${GOCD_API_USERNAME} ${GOCD_API_PASSWORD}
    fi
    chown go:go /etc/go/passwd

    echo "Done!"
fi

# start go.cd server as go user
echo "Starting go.cd server..."
/usr/local/go-server/server.sh
