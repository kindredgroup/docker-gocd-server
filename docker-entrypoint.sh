#!/bin/bash
set -e

# We overwrite this file everytime we run the container, so all your local changes
# will be lost. If you need to change the logging, fork this repo or build your
# own Docker image on top of this.
#
# Log to stdout instead of files
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

# Fix directory permissions if needed
#
# /var/lib/go-server
if [ -d "/var/lib/go-server" ]
then
  echo "Setting owner for /var/lib/go-server..."
  chown go:go /var/lib/go-server
else
  echo "Directory /var/lib/go-server does not exist"
fi

# /var/log/go-server
if [ -d "/var/log/go-server" ]
then
  echo "Setting owner for /var/log/go-server..."
  chown -R go:go /var/log/go-server
else
  echo "Directory /var/log/go-server does not exist"
fi

# /etc/go
if [ -d "/etc/go" ]
then
  echo "Setting owner for /etc/go..."
  chown -R go:go /etc/go
else
  echo "Directory /etc/go does not exist"
fi

# start go.cd server as go user
echo "Starting go.cd server..."
/usr/local/go-server/server.sh
