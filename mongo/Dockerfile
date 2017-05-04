FROM alpine:edge

MAINTAINER Nacho Cañón <icanon@paradigmatecnologico.com>

RUN apk --update add bash openssl mongodb && \
    rm /usr/bin/mongoperf

RUN mkdir -p /srv/mongodb && \
    openssl rand -base64 741 > /srv/mongodb/mongodb-keyfile && \
    chmod 600 /srv/mongodb/mongodb-keyfile

ADD mongod.conf /etc/mongod.conf

VOLUME /data/db
EXPOSE 27017 28017

COPY run.sh /root
RUN chmod +x /root/run.sh

ENTRYPOINT [ "/root/run.sh" ]
CMD [ "mongod","-f","/etc/mongod.conf" ]