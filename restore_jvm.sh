#!/bin/bash
cd temp-test
criu restore -o restore.log  &

sleep 0.3
curl localhost:8080

# until lsof -i -P -n | grep -m 1 "8080" > /dev/null
# do 
#   sleep 0.01
#   echo "sleep 0.01"
# done

# curl localhost:8080
# until curl -s -f "localhost:8080"
# do
#   sleep 1
#   echo "sleep 0.1"
# done

sleep 5
kill $(pgrep java)
echo OK