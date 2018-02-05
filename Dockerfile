FROM lsiobase/alpine:3.7

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="phybersplice"

# package version
# (stable-download or testing-download)
ARG NZBGET_BRANCH="stable-download"

RUN \
 echo "**** install packages ****" && \
 apk add --no-cache \
	curl \
	p7zip \
	python2 \
	unrar \
	git \
  make \
  automake \
	ffmpeg \
	wget && \
 echo "**** install nzbget ****" && \
 mkdir -p \
	/app/nzbget && \
 curl -o \
 /tmp/json -L \
	http://nzbget.net/info/nzbget-version-linux.json && \
 NZBGET_VERSION=$(grep "${NZBGET_BRANCH}" /tmp/json  | cut -d '"' -f 4) && \
 curl -o \
 /tmp/nzbget.run -L \
	"${NZBGET_VERSION}" && \
 sh /tmp/nzbget.run --destdir /app/nzbget && \
 echo "**** configure nzbget ****" && \
 cp /app/nzbget/nzbget.conf /defaults/nzbget.conf && \
 sed -i \
	-e "s#\(MainDir=\).*#\1/downloads#g" \
	-e "s#\(ScriptDir=\).*#\1$\/scripts#g" \
	-e "s#\(WebDir=\).*#\1$\{AppDir\}/webui#g" \
	-e "s#\(ConfigTemplate=\).*#\1$\{AppDir\}/webui/nzbget.conf.template#g" \
 /defaults/nzbget.conf && \
 echo "**** cleanup ****" && \
 rm -rf \
	/tmp/*

# add local files
COPY root/ /

#Add par2cmdline
FROM frolvlad/alpine-gcc
RUN apk update && \
	apk add --no-cache --virtual .build-dependencies make g++ ca-certificates wget automake autoconf && \
	update-ca-certificates
RUN wget https://github.com/Parchive/par2cmdline/archive/v0.6.13.tar.gz && \
	tar -xzvf v0.6.13.tar.gz && \
	cd par2cmdline-0.6.13 && \
	aclocal && \
	automake --add-missing && \
	autoconf && \
	./configure && \
	make && \
	make install
RUN apk del .build-dependencies && \
	cd / && \
	rm -rf par2cmdline-0.6.13 v0.6.13.tar.gz
ENTRYPOINT ["par2"]

#Download nzbToMedia from github
RUN \
git clone https://github.com/clinton-hall/nzbToMedia.git scripts

# install nzbToMedia
RUN \
mkdir /scripts/logs

#Set script file permissions
RUN chmod 777 -R /scripts
RUN chmod 777 /scripts/logs

# ports and volumes
VOLUME /config /downloads
EXPOSE 6789
