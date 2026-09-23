## Using the Official Ponylang Docker Images
ARG FROM_TAG=0.72.1
FROM ghcr.io/ponylang/ponyc:${FROM_TAG}

RUN apk add --update --no-cache pcre2-dev bash

WORKDIR /opt/test-runner
COPY . .

WORKDIR /opt/test-runner/src
RUN ponyc . -o ../bin -b pony_test_parser

WORKDIR /opt/test-runner
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
