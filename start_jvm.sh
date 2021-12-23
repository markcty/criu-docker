#!/bin/bash
setsid java -XX:-UsePerfData -jar springboot.jar < /dev/null &> test.log &
sleep 8
curl localhost:8080
echo OK