FROM alpine:3.17

RUN apk add --no-cache py3-pip openssl \
    python3-dev openssl-dev libffi-dev musl-dev gcc

RUN pip install pykmip

RUN mkdir -p /etc/pykmip \
    mkdir -p /etc/pykmip/policy \
    mkdir -p /var/lib/certs \
    mkdir -p /var/lib/state

COPY assets/server.conf /etc/pykmip

COPY assets/policy.json /etc/pykmip/policy

COPY config.sh /etc/pykmip

COPY assets/init.sh /bin/init.sh

RUN chmod 755 /bin/init.sh

EXPOSE 5696

ENTRYPOINT /bin/init.sh
