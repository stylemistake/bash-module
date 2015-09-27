#!/bin/bash

module export foo
module export bar

echo "module_name: ${module_name}"

foo() {
    echo 'foo!'
}

bar() {
    echo 'bar!'
}
