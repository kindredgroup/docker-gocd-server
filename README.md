# Alpine Linux GoCD Server Docker image

This is a minimal Alpine Linux Docker image for the GoCD Server that actually works with mounted volumes.

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


