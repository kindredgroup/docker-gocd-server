#!/bin/bash
set -e

export -a

# Path to go config
export GO_CONFIG_DIR=/etc/go

# Path to variable go data
export SERVER_WORK_DIR=/var/lib/go-server

# Enable stdout logging
export GO_SERVER_SYSTEM_PROPERTIES="${GO_SERVER_SYSTEM_PROPERTIES}${GO_SERVER_SYSTEM_PROPERTIES:+ }-Dgo.console.stdout=true"

# Log level
export GO_SERVER_SYSTEM_PROPERTIES="${GO_SERVER_SYSTEM_PROPERTIES}${GO_SERVER_SYSTEM_PROPERTIES:+ }-Dgocd.server.logback.root.level=WARN"

CRUISE_CONFIG=$GO_CONFIG_DIR/cruise-config.xml

# We overwrite this file everytime we run the container, so all your local changes
# will be lost. If you need to change the logging, fork this repo or build your
# own Docker image on top of this.
#
# Log to stdout instead of files
if [ -d $GO_CONFIG_DIR ]; then
cat > $GO_CONFIG_DIR/logback-include.xml <<EOL
<included>

    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>
                \${gocd.server.logback.defaultPattern:-%date{ISO8601} %-5level [%thread] %logger{0}:%line - %msg%n}
            </pattern>
        </encoder>
    </appender>

    <logger name="org.eclipse.jetty.server.RequestLog" level="INFO"/>

    <root>
        <appender-ref ref="CONSOLE"/>
    </root>

</included>
EOL

cat > $GO_CONFIG_DIR/logback.xml <<EOL
<?xml version="1.0" encoding="UTF-8"?>

<!--
  ~ Copyright 2017 ThoughtWorks, Inc.
  ~
  ~ Licensed under the Apache License, Version 2.0 (the "License");
  ~ you may not use this file except in compliance with the License.
  ~ You may obtain a copy of the License at
  ~
  ~     http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing, software
  ~ distributed under the License is distributed on an "AS IS" BASIS,
  ~ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  ~ See the License for the specific language governing permissions and
  ~ limitations under the License.
  -->

<configuration
    xmlns="http://ch.qos.logback/xml/ns/logback"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://ch.qos.logback/xml/ns/logback http://ch.qos.logback/xml/ns/logback/logback.xsd"
    debug="\${gocd.server.logback.debug:-false}"
    scan="\${gocd.server.logback.scan:-true}"
    scanPeriod="\${gocd.server.logback.scanPeriod:-5 seconds}"
>

  <root level="\${gocd.server.logback.root.level:-WARN}"/>

  <logger name="com.thoughtworks.go" level="INFO"/>

  <logger name="com.thoughtworks.studios.shine" level="WARN"/>

  <logger name="com.thoughtworks.go.server.Rails" level="WARN"/>

  <!-- make sure this is the last line in the config -->
  <include optional="true" file="\${cruise.config.dir:-config}/logback-include.xml"/>
</configuration>
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
    PASSWD_FILE="${GO_CONFIG_DIR}/passwd"
    echo -n "Creating local gocd user in password file... "
    if [ ! -f $PASSWD_FILE ]; then
        htpasswd -b -s -c $PASSWD_FILE ${GOCD_API_USERNAME} ${GOCD_API_PASSWORD} >/dev/null
    else
        htpasswd -b -s $PASSWD_FILE ${GOCD_API_USERNAME} ${GOCD_API_PASSWORD} >/dev/null
    fi
    chown go:go $PASSWD_FILE
    echo " Done!"

    set +e
    xmlstarlet sel -T -t -v /cruise/server/security $CRUISE_CONFIG > /dev/null
    if [ "$?" != "0" ]; then
      xmlstarlet ed --inplace --subnode /cruise/server -t elem -n security $CRUISE_CONFIG
    fi
    # Auth configs seem to have moved but gocd supports migrating from old config structure to new
    # For now simply validate that the new config node is not present
    #xmlstarlet sel -T -t -v "/cruise/server/security/passwordFile/@path" $CRUISE_CONFIG >/dev/null
    xmlstarlet sel -T -t -v '/cruise/server/security/authConfigs[authConfig/@pluginId="cd.go.authentication.passwordfile"]' $CRUISE_CONFIG > /dev/null
    if [ "$?" != "0" ]; then
      echo -n "Adding passwordfile configuration to cruise xml..."
      xmlstarlet ed --inplace --subnode /cruise/server/security -t elem -n passwordFileTMP -i //passwordFileTMP -t attr -n path -v $PASSWD_FILE -r //passwordFileTMP -v passwordFile $CRUISE_CONFIG
      echo " Done!"
    fi
    set -e
fi

# start go.cd server as go user
echo "Starting go.cd server..."
/usr/local/go-server/server.sh
