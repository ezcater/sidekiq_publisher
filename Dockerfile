# See https://github.com/ezcater/ruby-docker/#about-the-multiruby-image for
# context on the multiruby2 image
FROM ezcater-production.jfrog.io/multiruby:latest

ARG BUNDLE_EZCATER__JFROG__IO

RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main' >> /etc/apt/sources.list.d/postgresql.list
RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get update && apt-get upgrade -y && apt-get install -y build-essential libpq-dev postgresql-client-12

WORKDIR /usr/src/gem
ADD . /usr/src/gem
