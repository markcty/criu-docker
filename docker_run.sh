#!/bin/bash
docker run --privileged --cap-add=ALL --security-opt seccomp=unconfined --userns=host -it -v $PWD:/root -w /root criu-docker
