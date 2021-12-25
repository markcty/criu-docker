# CRIU SpringBoot Server in Docker

## Motivation

FaaS services are currently deployed by all major cloud providers using Linux containers. However, there are two performance problems that impact the economic bottom-line of FaaS. The first is the bloat in the memory footprint and usage of system resources by containers. The second is the long start-up times, caused by the time to initialize a container for each FaaS function.

By utilizing CRIU, which provides a way to dump a booted FaaS service and restore it afterwards, we can reap the following two benefits. Firstly, without cold booting every time when a FaaS service is demonded, the start time of FaaS start-up time can be greatly shortened. Secondly, shared image makes it possible to reduce memory resources usage.

This report shows an experiment on how to use CRIU command line tools to checkpoint and restore a simple SpringBoot server. It then gives a rough estimation of the expected performance boost.

## CRIU A SpringBoot Server

**Note: the followings are only tested in ubuntu 18.04. Other versions of host OS may not apply.**

### Step 0. Prerequisites 

Build the docker using `Dockerfile`:

```dockerfile
FROM ubuntu:18.04

RUN sed -i 's/security.ubuntu/mirrors.aliyun/g' /etc/apt/sources.list
RUN sed -i 's/archive.ubuntu/mirrors.aliyun/g' /etc/apt/sources.list
RUN apt clean
RUN apt update && apt install -y sudo openjdk-11* criu curl

CMD [ "bin/bash" ]
```

```sh
docker build -t criu-docker .
```

### Step 1. Go into the Docker

Run `./docker_run.sh`:

```sh
#!/bin/bash
docker run --privileged --cap-add=ALL --security-opt seccomp=unconfined --userns=host -it -v $PWD:/root -w /root criu-docker
```

This will start the docker container and mount the current folder to `root`. Note that we add all the capacity to the container because `CRIU` requires many privileged syscalls.

### Step 2. Start JVM

Run `./start_jvm.sh`:

```sh
#!/bin/bash
setsid java -XX:-UsePerfData -jar springboot.jar < /dev/null &> test.log &
sleep 8
curl localhost:8080
echo OK
```

This will start the SpringBoot Server. If succeeds, `OK` will be printed.

Note that we use `setsid` to start the JVM in order to detach it from the shell session, which simplifies the `CRIU` procedure.

`-XX:-UserPerfData` is added to prevent JVM from storing performance data in `/tmp`. Otherwise, after restoring, JVM may fail to find the data and give an error.

If you encounter warnings or errors like this, just ignore them.

```log
Warn  (criu/kerndat.c:659): Can't load /run/criu.kdat
Error (criu/util.c:714): exited, status=1
Error (criu/util.c:714): exited, status=1
Warn  (criu/kerndat.c:698): Can't keep kdat cache on non-tempfs
```

### Step 3. Dump JVM

Run `./dump_jvm.sh`:

```sh
#!/bin/bash
rm -rf ./temp-test
mkdir -p ./temp-test
cd ./temp-test
criu dump -t $(pgrep java) -o dump.log && echo OK
```

If succeeds, `OK` will be printed.

### Step 4. Restore JVM

Run `./restore_jvm.sh`:

```sh
cd temp-test
criu restore -o restore.log  &
sleep 0.3
curl localhost:8080
```

## Performance Evaluation

### Cold Boot

According to default springboot log, The cold boot time cost of a SpringBoot server is around **6s**.

### Checkpoint

The checkpoint take around **0.26s**. I measure the checkpoing time by wrapping `time` around the dump command.

### Restore 

The restore takes around *0.2s*. I try to use `time` to measure, but it will cause the restore to fail and the reason is unknown. So I use a naive method to print a timestamp before restore and the server will print the timestamp after restoring. Thus the time cost is the substraction of the two timestamp.

Comparing to cold boot, restore is around 10 to 20 times faster.

## Future Work

- **More confined capacity control.** Currently we use `--privileged --cap-add=ALL --security-opt seccomp=unconfined` to give all possible permissions to the container. However, not all these permissions are needed to restore a service.
- **Reduce dump image size.** Run garbage collection before dumping.

## Reference

Replayable Execution Optimized for Page Sharing for a Managed Runtime Environment, EuroSys '19