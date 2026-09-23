#!/usr/bin/env bash

set -u # Exit on undeclared variable
set -o pipefail # Catch failures in pipes

BASEDIR=`pwd`
SLUG="$1"
INPUT_DIR=$(readlink -f $2)
OUTPUT_DIR=$(readlink -f $3)

rm -f $OUTPUT_DIR/$SLUG $OUTPUT_DIR/compile.* && mkdir -p $OUTPUT_DIR
cd $INPUT_DIR

ponyc . -o $OUTPUT_DIR -b $SLUG > $OUTPUT_DIR/compile.stdout 2> $OUTPUT_DIR/compile.stderr

$BASEDIR/bin/pony_test_parser $SLUG $INPUT_DIR $OUTPUT_DIR

