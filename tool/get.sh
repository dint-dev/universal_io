#!/bin/sh

set -e
cd `dirname $0`/..

function visit {
  echo ""
  echo "----------------------------------------"
  echo "Getting dependencies: $1"
  echo "----------------------------------------"
  cd $1
  pub get
  cd ../..
  echo ""
}

function visit_flutter {
  echo ""
  echo "----------------------------------------"
  echo "Getting dependencies: $1"
  echo "----------------------------------------"
  cd $1
  flutter pub get
  cd ../..
  echo ""
}

visit packages/universal_io
visit packages/test_io
visit packages/nodejs_io
visit packages/chrome_os_io
visit samples/chrome_app_example
visit_flutter samples/flutter_example