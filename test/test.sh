#!/bin/bash
cd $(dirname ${0})
source ../src/module.sh

echo "module_name: ${module_name}"

## Import modules
module import sample
module import package

## Use exported functions from module 'sample'
## Path: sample.sh
sample foo
sample bar

## Use exported functions from module 'package'
## Path: package/index.sh
package foo
package bar

echo "it works!"
