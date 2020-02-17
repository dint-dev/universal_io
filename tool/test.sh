#!/bin/sh

set -e
cd `dirname $0`/..

function test {
  echo ""
  echo "----------------------------------------"
  echo "Testing: $1"
  echo "----------------------------------------"
  cd $1
  pub run test
  cd ../..
  echo ""
}

test packages/universal_io
test packages/test_io
test packages/nodejs_io
test packages/chrome_os_io

echo "----------------------------------------"
echo "Testing: samples/chrome_app_example"
echo "----------------------------------------"
cd samples/chrome_app_example
pub get
pub run webdev build --no-release
pub run webdev build --release
cd ../..

if hash flutter 2>/dev/null; then
  echo ""
  echo "----------------------------------------"
  echo "Testing: samples/flutter_example"
  echo "----------------------------------------"
  cd samples/flutter_example
  flutter pub get
  flutter build web
  cd ../..
  echo ""
fi