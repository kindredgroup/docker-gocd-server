#!/bin/bash
set -e

export -a

CRUISE_CONFIG=/etc/go/cruise-config.xml

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
if [ -f "$CRUISE_CONFIG" ]; then
  if [ ! -z "$AGENT_KEY" ]; then
    echo -n "Updating existing go-server configuration file with AGENT_KEY..."
    xmlstarlet ed --inplace -u /cruise/server/@agentAutoRegisterKey -v ${AGENT_KEY} "$CRUISE_CONFIG"
  fi
else
    echo -n "No go-server configuration file found, creating default config..."

cat >$CRUISE_CONFIG <<EOL
<?xml version="1.0" encoding="utf-8"?>
<cruise xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="cruise-config.xsd" schemaVersion="87">
    <server agentAutoRegisterKey="${AGENT_KEY}">
    </server>
</cruise>
EOL
fi

echo " Done!"

# Create a password file that contains 1 entry for now.
# We need this to be able to send API calls to the REST interface after the server has been booted
if [ ! -z "$GOCD_API_USERNAME" ] && [ ! -z "$GOCD_API_PASSWORD" ]; then
    echo -n "Creating local gocd user in password file... "
    if [ ! -f /etc/go/passwd ]; then
        htpasswd -b -s -c /etc/go/passwd ${GOCD_API_USERNAME} ${GOCD_API_PASSWORD} >/dev/null
    else
        htpasswd -b -s /etc/go/passwd ${GOCD_API_USERNAME} ${GOCD_API_PASSWORD} >/dev/null
    fi
    chown go:go /etc/go/passwd
    echo " Done!"

    set +e
    xmlstarlet sel -T -t -v /cruise/server/security $CRUISE_CONFIG > /dev/null
    if [ "$?" != "0" ]; then
      xmlstarlet ed --inplace --subnode /cruise/server -t elem -n security $CRUISE_CONFIG
    fi
    xmlstarlet sel -T -t -v "/cruise/server/security/passwordFile/@path" $CRUISE_CONFIG >/dev/null
    if [ "$?" != "0" ]; then
      echo -n "Adding passwordfile configuration to cruise xml..."
      xmlstarlet ed --inplace --subnode /cruise/server/security -t elem -n passwordFileTMP -i //passwordFileTMP -t attr -n path -v /etc/go/passwd -r //passwordFileTMP -v passwordFile $CRUISE_CONFIG
      echo " Done!"
    fi
    set -e
fi

# start go.cd server as go user
echo "Starting go.cd server..."
/usr/local/go-server/server.sh
