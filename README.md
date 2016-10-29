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
      - ./go-data/lib:/var/lib/gocd-server
      - ./go-data/log:/var/log/gocd-server
```


## Issues

The $LIBDIR/work/jetty* folder needs to be removed before being able to restart the container. Is this only a problem on OSX? Or do we need to add this `rm -rf` command to the entrypoint script?

```
karel:Hostile ~/Github/unibet/docker-gocd-server$ docker logs a52282c704f10567e5aa032c63a32c669f473331db28af76b8b4ada2b4a40178
Starting go.cd server...
[Sat Oct 29 17:22:01 UTC 2016] using default settings from /etc/default/go-server
Error trying to remove Jetty working directory /var/lib/go-server/work: java.io.IOException: Unable to delete directory /var/lib/go-server/work/jetty-0.0.0.0-8153-cruise.war-_go-any-/webapp/WEB-INF/rails.new/vendor/bundle/jruby/1.9.
```
