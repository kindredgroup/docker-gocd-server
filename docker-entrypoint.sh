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

# start go.cd server as go user
echo "Starting go.cd server..."
/usr/local/go-server/server.sh
