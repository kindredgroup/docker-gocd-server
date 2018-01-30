# let the gocd dog wake up first
setup() {

  retries=0
  max_retries=120

  # tolerate that commands fail
  set +e

  until curl -f http://gocd-server:8153 >/dev/null; do
    ((retries++))
    if [ "$retries" = "$max_retries" ]; then
      echo "GoCD doesn't seem to come up" >&1
      exit 1
    fi
    sleep 1
  done

  set -e

}

@test "can fetch cruise.xml with authentication enabled" {
  run curl -f -u $GOCD_API_USERNAME:$GOCD_API_PASSWORD http://gocd-server:8153/go/api/admin/config.xml
  [ "$status" -eq 0 ]
}
