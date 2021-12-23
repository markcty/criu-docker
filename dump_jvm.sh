#!/bin/bash
rm -rf ./temp-test
mkdir -p ./temp-test
cd ./temp-test
criu dump -t $(pgrep java) -o dump.log  -v4 && echo OK