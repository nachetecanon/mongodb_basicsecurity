FROM debian:jessie-slim

MAINTAINER Nacho Cañón <icanon@paradigmatecnologico.com>


# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r mongodb && useradd -r -g mongodb mongodb

RUN apt-get update \
	&& apt-get install -y --no-install-recommends openssl \
		ca-certificates \
		jq \
		numactl \
	&& rm -rf /var/lib/apt/lists/*



# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
	&& apt-get update && apt-get install -y --no-install-recommends wget && rm -rf /var/lib/apt/lists/* \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true \
	&& apt-get purge -y --auto-remove wget

RUN mkdir /docker-entrypoint-initdb.d

ENV GPG_KEYS \
# pub   4096R/A15703C6 2016-01-11 [expires: 2018-01-10]
#       Key fingerprint = 0C49 F373 0359 A145 1858  5931 BC71 1F9B A157 03C6
# uid                  MongoDB 3.4 Release Signing Key <packaging@mongodb.com>
	0C49F3730359A14518585931BC711F9BA15703C6
# https://docs.mongodb.com/manual/tutorial/verify-mongodb-packages/#download-then-import-the-key-file
RUN set -ex; \
	export GNUPGHOME="$(mktemp -d)"; \
	for key in $GPG_KEYS; do \
		gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	done; \
	gpg --export $GPG_KEYS > /etc/apt/trusted.gpg.d/mongodb.gpg; \
	rm -r "$GNUPGHOME"; \
	apt-key list

ENV MONGO_MAJOR 3.4
ENV MONGO_VERSION 3.4.4
ENV MONGO_PACKAGE mongodb-org

RUN echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/$MONGO_MAJOR main" > /etc/apt/sources.list.d/mongodb-org.list

RUN set -x \
	&& apt-get update \
	&& apt-get install -y \
		${MONGO_PACKAGE}=$MONGO_VERSION \
		${MONGO_PACKAGE}-server=$MONGO_VERSION \
		${MONGO_PACKAGE}-shell=$MONGO_VERSION \
		${MONGO_PACKAGE}-mongos=$MONGO_VERSION \
		${MONGO_PACKAGE}-tools=$MONGO_VERSION \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/lib/mongodb

RUN mkdir -p /data/db /data/configdb \
	&& chown -R mongodb:mongodb /data/db /data/configdb

RUN mkdir -p /srv/mongodb

COPY mongod.yaml /srv/mongodb
VOLUME /data/db /data/configdb

COPY docker-entrypoint.sh /usr/local/bin/
COPY generateCA_ssl.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh && \
    chmod +x /entrypoint.sh /usr/local/bin/*.sh && \
    chown mongodb:mongodb /entrypoint.sh && \
    . generateCA_ssl.sh



ENV MONGO_INITDB_SSL "mongoAdmin"
ENV dn_prefix="/C=ES/ST=Madrid/L=Madrid/O=BBVA/OU=BBVA"

ENTRYPOINT ["/entrypoint.sh"]

RUN chown mongodb:mongodb /srv/mongodb

EXPOSE 27017

CMD ["mongod",\
    "--sslMode","requireSSL", \
    "--sslPEMKeyFile","/srv/mongodb/mongodbhost.pem", \
    "--clusterAuthMode","x509", \
    "--sslCAFile","/srv/mongodb/RootCA/root-ca.pem", \
    "--sslAllowInvalidHostnames", \
    "--sslClusterFile","/srv/mongodb/mongodbhost.pem", \
    "--replSet","rs0"]
