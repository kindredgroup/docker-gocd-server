[![Build Status](https://travis-ci.org/unibet/docker-gocd-server.svg?branch=master)](https://travis-ci.org/unibet/docker-gocd-server)

# GoCD Server Docker image

This is a minimal Docker image for the GoCD Server that actually works with mounted volumes.

## Using this Docker image

*Important: Make sure the mounted folders (in the examples below the folder `go-data` and subfolders) are owned by the same user id and group is as inside the container is defined!*

Create the data folders and make sure the permissions are ok:

```
mkdir -p go-data/etc go-data/lib go-data/log
chown -R 500:500 go-data
```

Start the GoCD Server container:

```
docker run -t  \
  -p 8153:8153 \
  -p 8154:8154 \
  -v $(pwd)/go-data/etc:/etc/go \
  -v $(pwd)/go-data/lib:/var/lib/go-server \
  -v $(pwd)/go-data/log:/var/log/go-server \
  -e "AGENT_KEY=VERYSECRETAGENTKEYLOLKTNXBYE" \
  -e "GOCD_API_USERNAME=apiuser" \
  -e "GOCD_API_PASSWORD=secret" \
  -d unibet/gocd-server
```

The above example as a `docker-compose.yml` file:

```
version: '2'
services:
  gocd-server:
    build: .
    ports:
      - 8153:8153
      - 8154:8154
    volumes:
      - ./go-data/etc:/etc/go
      - ./go-data/lib:/var/lib/go-server
      - ./go-data/log:/var/log/go-server
    environment:
      - AGENT_KEY=VERYSECRETAGENTKEYLOLKTNXBYE
      - GOCD_API_USERNAME=apiuser
      - GOCD_API_PASSWORD=secret
```

A `docker-compose.yml` file that starts both the server and 1 agent:

```
version: '2'
services:
  gocd-server:
    build: .
    ports:
      - 8153:8153
      - 8154:8154
    volumes:
      - ./go-data/etc:/etc/go
      - ./go-data/lib:/var/lib/go-server
      - ./go-data/log:/var/log/go-server
    environment:
      - AGENT_KEY=VERYSECRETGOAGENTKEY
      - GOCD_API_USERNAME=apiuser
      - GOCD_API_PASSWORD=secret

  gocd-agent:
    image: unibet/gocd-agent
    environment:
      - GO_SERVER_URL=https://gocd-server:8154/go/
      - AGENT_KEY=VERYSECRETGOAGENTKEY
      - AGENT_RESOURCES=docker
      - AGENT_ENVIRONMENTS=prod
      - AGENT_HOSTNAME=deploy-agent-01
```

## Maintenance status

Actively maintained.

Status updated: 11/11/2016


## LICENSE

The MIT License (MIT)

Copyright (c) 2016 Unibet Group

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
