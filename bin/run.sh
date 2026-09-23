#!/usr/bin/env bash

set -u # Exit on undeclared variable
set -o pipefail # Catch failures in pipes

BASEDIR=`pwd`
SLUG="$1"
INPUT_DIR=$(readlink -f $2)
OUTPUT_DIR=$(readlink -f $3)

WORK_DIR=/tmp/solution
rm -rf $WORK_DIR
cp -r $INPUT_DIR $WORK_DIR
cd $INPUT_DIR

rm -f $OUTPUT_DIR/$SLUG
ponyc . -o $WORK_DIR -b $SLUG > $WORK_DIR/compile.stdout 2> $WORK_DIR/compile.stderr

#if [ -f "$OUTPUT_DIR/$SLUG" ]; then
#  $OUTPUT_DIR/$SLUG --verbose > $WORK_DIR/tests.stdout
#else
  $BASEDIR/bin/pony_test_parser $SLUG $WORK_DIR $INPUT_DIR $OUTPUT_DIR
#fi

