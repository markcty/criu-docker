# CRIU SpringBoot Server in Docker

**Note: the followings are only tested in ubuntu 18.04. Other versions of host OS may not apply.**

## Prerequisites 

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

## CRIU A SpringBoot Server

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

## Performance

Note time cost is estimiated very roughly.

The cold boot time cost of a SpringBoot server is around **6s**(according to springboot log in `test.log`).

The checkpoint and restore step both take around **0.3s**. I measure the checkpoing time using `time`. And the restore step is measured using a very naive method: after restore is executed in backend, I use sleep to wait for 0.3s and then execute `curl`. If I set the wait time to 0.2s, the restore may fail.

So comparing to cold boot, restore is around 10 to 20 times faster.