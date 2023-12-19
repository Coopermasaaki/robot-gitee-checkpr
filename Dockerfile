FROM openeuler/openeuler:23.03 as BUILDER
RUN dnf update -y && \
    dnf install -y golang && \
    go env -w GOPROXY=https://goproxy.cn,direct

MAINTAINER zengchen1024<chenzeng765@gmail.com>

# build binary
WORKDIR /go/src/github.com/opensourceways/robot-gitee-checkpr
COPY . .
RUN GO111MODULE=on CGO_ENABLED=0 go build -a -o robot-gitee-checkpr -buildmode=pie --ldflags "-s -linkmode 'external' -extldflags '-Wl,-z,now'" .

# copy binary config and utils
FROM openeuler/openeuler:22.03
RUN dnf -y update && \
    dnf in -y shadow && \
    dnf remove -y gdb-gdbserver && \
    groupadd -g 1000 checkpr && \
    useradd -u 1000 -g checkpr -s /sbin/nologin -m checkpr && \
    echo > /etc/issue && echo > /etc/issue.net && echo > /etc/motd && \
    mkdir /home/checkpr -p && \
    chmod 700 /home/checkpr && \
    chown checkpr:checkpr /home/checkpr && \
    echo 'set +o history' >> /root/.bashrc && \
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs && \
    rm -rf /tmp/*

USER checkpr

WORKDIR /opt/app

COPY  --chown=checkpr --from=BUILDER /go/src/github.com/opensourceways/robot-gitee-checkpr/robot-gitee-checkpr /opt/app/robot-gitee-checkpr

RUN chmod 550 /opt/app/robot-gitee-checkpr && \
    echo "umask 027" >> /home/checkpr/.bashrc && \
    echo 'set +o history' >> /home/checkpr/.bashrc

ENTRYPOINT ["/opt/app/robot-gitee-checkpr"]
