FROM ubuntu:18.04

RUN sed -i 's/security.ubuntu/mirrors.aliyun/g' /etc/apt/sources.list
RUN sed -i 's/archive.ubuntu/mirrors.aliyun/g' /etc/apt/sources.list
RUN apt clean
RUN apt-get update && apt-get install -y sudo default-jdk criu curl

CMD [ "/bin/bash" ]
