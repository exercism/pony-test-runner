#!/usr/bin/env sh

set -u # Exit on undeclared variable
set -o pipefail # Catch failures in pipes

SLUG="$1"
INPUT_DIR=$(readlink -f $2)
OUTPUT_DIR=$(readlink -f $3)

WORK_DIR=/tmp/solution
mkdir -p $WORK_DIR && rm -rf $WORK_DIR
cp -r $INPUT_DIR $WORK_DIR
cd $INPUT_DIR

rm -f $OUTPUT_DIR/$SLUG
ponyc . -o $OUTPUT_DIR -b $SLUG > $WORK_DIR/compile.stdout 2> $WORK_DIR/compile.stderr

if [ -f "$OUTPUT_DIR/$SLUG" ]; then
  $OUTPUT_DIR/$SLUG --verbose > $WORK_DIR/tests.stdout
  /opt/test-runner/bin/pony_test_parser $WORK_DIR/tests.stdout $INPUT_DIR/test.pony > $OUTPUT_DIR/results.json
else
  /opt/test-runner/bin/wrap_error $WORK_DIR/compile.stderr > $OUTPUT_DIR/results.json
fi

echo "${SLUG}: done"

