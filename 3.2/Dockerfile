FROM ryansch/su-exec as su-exec

FROM ruby:3.2.1-bullseye as base
LABEL maintainer="Ryan Schlesinger <ryan@ryanschlesinger.com>"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

COPY --from=su-exec /sbin/su-exec /sbin/

RUN set -eux; \
      \
      apt-get update -y; \
      apt-get install -y --no-install-recommends \
        locales \
        jq \
        openssl \
        tini \
      ; \
      apt-get clean; \
      rm -f /var/lib/apt/lists/*_*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ENV BUNDLER_VERSION 2.4.10
RUN gem install bundler -v ${BUNDLER_VERSION} -i /usr/local/lib/ruby/gems/$(ls /usr/local/lib/ruby/gems) --force


FROM base as plus

RUN set -eux; \
      \
      curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /usr/share/keyrings/yarnkey.gpg >/dev/null; \
      echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | tee /etc/apt/sources.list.d/yarn.list; \
      curl -sL https://deb.nodesource.com/setup_18.x | bash -; \
      apt-get install -y --no-install-recommends \
        nodejs \
        yarn \
        libicu-dev \
        neovim \
      ; \
      apt-get clean; \
      rm -rf /var/lib/apt/lists/*


FROM plus as test

RUN set -eux; \
      \
      apt-get update ; \
      apt-get install -y --no-install-recommends \
        default-mysql-client \
        redis-tools \
        unzip \
        libnss3-tools \
      ; \
      apt-get clean; \
      rm -rf /var/lib/apt/lists/*

ENV DOCKERIZE_VERSION v0.6.1
RUN set -eux; \
      \
      wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz; \
      tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz; \
      rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

# download and setup chromdriver
ARG CHROME_VERSION="google-chrome-stable"
RUN set -eux; \
      \
      apt-get update -y; \
      apt-get install -y \
        wget \
        unzip \
        xvfb \
        netcat \
      ; \
      \
      wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
        && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
        && apt-get update -qqy \
        && apt-get -y install \
          ${CHROME_VERSION:-google-chrome-stable} \
        && MAJOR_VERSION=$(apt-cache policy ${CHROME_VERSION} | grep Installed: | cut -d : -f 2 | cut -d . -f 1-3) \
        && CD_VERSION=$(wget -qO- https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${MAJOR_VERSION## }) \
        && echo "Using chromedriver version: "$CD_VERSION \
        && wget --no-verbose -O /tmp/chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/$CD_VERSION/chromedriver_linux64.zip \
        && rm -rf /opt/selenium/chromedriver \
        && unzip /tmp/chromedriver_linux64.zip -d /opt/selenium \
        && rm /tmp/chromedriver_linux64.zip \
        && mv /opt/selenium/chromedriver /opt/selenium/chromedriver-$CD_VERSION \
        && chmod 755 /opt/selenium/chromedriver-$CD_VERSION \
        && ln -fs /opt/selenium/chromedriver-$CD_VERSION /usr/bin/chromedriver \
        && rm /etc/apt/sources.list.d/google-chrome.list \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* /var/cache/apt/*
