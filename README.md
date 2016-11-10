# Alpine Linux GoCD Server Docker image

This is a minimal Alpine Linux Docker image for the GoCD Server that actually works with mounted volumes.

## Using this Docker image

Example usage:

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

docker-compose.yml:

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

docker-compose.yml that starts both the server and 1 agent:

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

  gocd-agent:
    image: unibet/gocd-agent
    environment:
      - GO_SERVER_URL=https://gocd-server:8154
      - AGENT_KEY=secret-key
      - AGENT_RESOURCES=docker
      - AGENT_ENVIRONMENTS=prod
      - AGENT_HOSTNAME=deploy-agent-01
```
