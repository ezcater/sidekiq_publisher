FROM ezcater-production.jfrog.io/ruby:f08726283c
RUN mkdir /usr/src/gem
WORKDIR /usr/src/gem
ADD . /usr/src/gem
