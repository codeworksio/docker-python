FROM codeworksio/ubuntu:18.04-20190220

# SEE: https://github.com/docker-library/python/blob/master/3.7/stretch/Dockerfile

ARG APT_PROXY
ARG APT_PROXY_SSL
ENV PYTHON_VERSION="3.7.2" \
    PYTHON_DOWNLOAD_URL="https://www.python.org/ftp/python" \
    PYTHON_PIP_VERSION="19.0.2" \
    PYTHON_PIP_DOWNLOAD_URL="https://bootstrap.pypa.io/get-pip.py"

RUN set -ex && \
    \
    buildDependencies="\
        gcc \
        libffi-dev \
        libssl-dev \
        tcl-dev \
        tk-dev \
        uuid-dev \
    " && \
    if [ -n "$APT_PROXY" ]; then echo "Acquire::http { Proxy \"http://${APT_PROXY}\"; };" > /etc/apt/apt.conf.d/00proxy; fi && \
    if [ -n "$APT_PROXY_SSL" ]; then echo "Acquire::https { Proxy \"https://${APT_PROXY_SSL}\"; };" > /etc/apt/apt.conf.d/00proxy; fi && \
    apt-get --yes update && \
    apt-get --yes install \
        $buildDependencies \
    && \
    curl -L "$PYTHON_DOWNLOAD_URL/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" -o python.tar.xz && \
    curl -L "$PYTHON_DOWNLOAD_URL/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" -o python.tar.xz.asc && \
    rm -rf python.tar.xz.asc && \
    mkdir -p /usr/src/python && \
    tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz && \
    rm python.tar.xz && \
    cd /usr/src/python && \
    ./configure \
        --build="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
        --enable-loadable-sqlite-extensions \
        --enable-shared \
        --with-system-expat \
        --with-system-ffi \
        --without-ensurepip \
    && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    ln -s /usr/local/bin/idle3 /usr/local/bin/idle && \
    ln -s /usr/local/bin/pydoc3 /usr/local/bin/pydoc && \
    ln -s /usr/local/bin/python3 /usr/local/bin/python && \
    ln -s /usr/local/bin/python3-config /usr/local/bin/python-config && \
    \
    curl -L "$PYTHON_PIP_DOWNLOAD_URL" -o /tmp/get-pip.py && \
    python /tmp/get-pip.py \
        --disable-pip-version-check \
        --no-cache-dir \
        "pip==$PYTHON_PIP_VERSION" \
    && \
    rm /tmp/get-pip.py && \
    find /usr/local -depth \( \( -type d -a -name test -o -name tests \) -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \) -exec rm -rf '{}' + && \
    rm -rf /usr/src/python && \
    apt-get purge --yes --auto-remove $buildDependencies && \
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /var/cache/apt/* && \
    rm -f /etc/apt/apt.conf.d/00proxy

### METADATA ###################################################################

ARG IMAGE
ARG BUILD_DATE
ARG VERSION
ARG VCS_REF
ARG VCS_URL
LABEL \
    org.label-schema.name=$IMAGE \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.version=$VERSION \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=$VCS_URL \
    org.label-schema.schema-version="1.0"
