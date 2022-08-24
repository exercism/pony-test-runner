## Using the Official Ponylang Docker Images
ARG FROM_TAG=release
FROM ponylang/shared-docker-ci-x86-64-unknown-linux-builder:${FROM_TAG}

WORKDIR /opt/test-runner

RUN apk add --update --no-cache pcre2-dev

COPY . .

WORKDIR /opt/test-runner/src/pony_test_parser
RUN ponyc . 
RUN cp /opt/test-runner/src/pony_test_parser/pony_test_parser /opt/test-runner/bin/pony_test_parser

WORKDIR /opt/test-runner/src/wrap_error
RUN ponyc . 
RUN cp /opt/test-runner/src/wrap_error/wrap_error /opt/test-runner/bin/wrap_error

ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
