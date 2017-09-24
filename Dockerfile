FROM ruby:2.4.0-alpine

ENV APP /app
WORKDIR $APP

RUN apk --update add --virtual build-deps \
    build-base \
  && apk add \
    postgresql-dev \
    make \
    tzdata \
    nodejs \
    curl-dev \
    curl \
		imagemagick \
		imagemagick-dev \
  && rm -rf /var/cache/apk/* \
  && cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

COPY . $APP

RUN bundle update && gem update && \
bundle install --jobs=4 --path vendor/bundle \
  && mkdir -p $APP/tmp/cache \
  && mkdir -p $APP/tmp/pids \
  && mkdir -p $APP/tmp/sockets

CMD ["bundle", "exec", "ruby", "app.rb"]
