#!/usr/bin/env bash

set -euxo pipefail

which komet
komet --help

cd test-project
komet prove run --id 'test_true'
