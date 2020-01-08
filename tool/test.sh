#!/bin/sh

set -e
cd `dirname $0`/..

cd packages/universal_io
pub get
pub run test
cd ../..

cd packages/test_io
pub get
pub run test
cd ../..

cd packages/nodejs_io
pub get
pub run test
cd ../..

cd packages/chrome_os_io
pub get
pub run test
cd ../..