FROM debian:jessie

MAINTAINER kfei <kfei@kfei.net>

ENV VER_LIBTORRENT 0.13.4
ENV VER_RTORRENT 0.9.4

WORKDIR /usr/local/src

# This long disgusting instruction saves your image ~130 MB
RUN build_deps="automake build-essential ca-certificates libc-ares-dev libcppunit-dev libtool"; \
    build_deps="${build_deps} libssl-dev libxml2-dev libncurses5-dev pkg-config subversion wget"; \
    set -x && \
    apt-get update && apt-get install -q -y --no-install-recommends ${build_deps} && \
    wget http://curl.haxx.se/download/curl-7.39.0.tar.gz && \
    tar xzvfp curl-7.39.0.tar.gz && \
    cd curl-7.39.0 && \
    ./configure --enable-ares --enable-tls-srp --enable-gnu-tls --with-zlib --with-ssl && \
    make && \
    make install && \
    cd .. && \
    rm -rf curl-* && \
    ldconfig && \
    svn --trust-server-cert checkout https://svn.code.sf.net/p/xmlrpc-c/code/stable/ xmlrpc-c && \
    cd xmlrpc-c && \
    ./configure --enable-libxml2-backend --disable-abyss-server --disable-cgi-server && \
    make && \
    make install && \
    cd .. && \
    rm -rf xmlrpc-c && \
    ldconfig && \
    wget -O libtorrent-$VER_LIBTORRENT.tar.gz https://github.com/rakshasa/libtorrent/archive/$VER_LIBTORRENT.tar.gz && \
    tar xzf libtorrent-$VER_LIBTORRENT.tar.gz && \
    cd libtorrent-$VER_LIBTORRENT && \
    ./autogen.sh && \
    ./configure --with-posix-fallocate && \
    make && \
    make install && \
    cd .. && \
    rm -rf libtorrent-* && \
    ldconfig && \
    wget -O rtorrent-$VER_RTORRENT.tar.gz https://github.com/rakshasa/rtorrent/archive/$VER_RTORRENT.tar.gz && \
    tar xzf rtorrent-$VER_RTORRENT.tar.gz && \
    cd rtorrent-$VER_RTORRENT && \
    ./autogen.sh && \
    ./configure --with-xmlrpc-c --with-ncurses && \
    make && \
    make install && \
    cd .. && \
    rm -rf rtorrent-* && \
    ldconfig && \
    mkdir -p /usr/share/nginx/html && \
    cd /usr/share/nginx/html && \
    mkdir rutorrent && \
    curl -L -O https://github.com/Novik/ruTorrent/archive/master.tar.gz && \
    tar xzvf master.tar.gz -C rutorrent --strip-components 1 && \
    rm -rf *.tar.gz && \
    apt-get purge -y --auto-remove ${build_deps} && \
    apt-get autoremove -y

# Install required packages
RUN apt-get update && apt-get install -q -y --no-install-recommends \
    apache2-utils \
    libc-ares2 \
    nginx \
    php5-cli \
    php5-fpm

# Install packages for ruTorrent plugins
RUN apt-get update && apt-get install -q -y --no-install-recommends \
    mediainfo \
    unzip \
    wget

#Unrar non free
WORKDIR /tmp
RUN wget http://ftp.us.debian.org/debian/pool/non-free/u/unrar-nonfree/unrar_5.2.7-0.1_amd64.deb && \
dpkg -i unrar_5.2.7-0.1_amd64.deb


# For ffmpeg, which is required by the ruTorrent screenshots plugin
# This increases ~53 MB of the image size, remove it if you really don't need screenshots
RUN echo "deb http://www.deb-multimedia.org jessie main" >> /etc/apt/sources.list && \
    apt-get update && apt-get install -q -y --force-yes --no-install-recommends \
    deb-multimedia-keyring \
    ffmpeg

# IMPORTANT: Change the default login/password of ruTorrent before build
RUN htpasswd -cb /usr/share/nginx/html/rutorrent/.htpasswd docktorrent p@ssw0rd

#Dtach for rtorrent
RUN apt-get update && apt-get install -q -y --no-install-recommends dtach

# Copy config files
COPY config/nginx/default /etc/nginx/sites-available/default
COPY config/rtorrent/.rtorrent.rc /root/.rtorrent.rc
COPY config/rutorrent/config.php /usr/share/nginx/html/rutorrent/conf/config.php
COPY config/rutorrent/plugins.ini /usr/share/nginx/html/rutorrent/conf/plugins.ini

#SSL
RUN apt-get install -q -y --no-install-recommends wget 
RUN apt-get install -q -y --no-install-recommends ca-certificates

RUN mkdir -p /etc/ssl/certs && \
cd /etc/ssl/certs && \
wget --no-check-certificate https://www.geotrust.com/resources/root_certificates/certificates/Equifax_Secure_Global_eBusiness_CA-1.cer && \
mv Equifax_Secure_Global_eBusiness_CA-1.cer Equifax_Secure_Global_eBusiness_CA-1.pem && \ 
update-ca-certificates

# Add the s6 binaries fs layer
ADD s6-1.1.3.2-musl-static.tar.xz /

# Service directories and the wrapper script
COPY rootfs /

# Run the wrapper script first
#ENTRYPOINT ["/usr/local/bin/docktorrent"]

# Declare ports to expose
EXPOSE 5000 80 9527 45566

# Declare volumes
VOLUME ["/rtorrent","/media_data", "/var/log"]

# This should be removed in the latest version of Docker
ENV HOME /root
