# Bash module system

This is a concept, showing that modular system in Bash with complete isolation
of scripts is possible.

To test it out, run from project directory:

```
bash test/test.sh
```


## Basic usage

```bash
#!/bin/bash
cd $(dirname ${0})

## Initialize module system
# source <path_to>/module.sh
source node_modules/bash-module/src/module.sh

## Import modules
# module import <module_name>
module import foo

## Modules are searched in:
##   * current directory
##   * 'node_modules' folder
## If name resolves to a file, then it uses that file as a module.
## If name resolves to a directory, it uses 'index.sh' from that directory.
## E.g. 'foo' -> 'foo.sh', 'foo/index.sh', 'node_modules/foo/index.sh'

## Export functions to current module
module export log

## You can call functions from imported modules
# foo <exported_name>
foo bar

## Define functions and add your logic
log() {
    echo "${@}"
}
```


## Notes

* This is a work-in-progress, use at your own risk!
* Current implementation comes at expense of running very slow. Each function
call spawns a subshell and every time runs through all module initialization
routines.
* Modules are not singletons (however it's possible to implement them using
background jobs and named pipes).


## Contacts

Style Mistake <[stylemistake@gmail.com]>

[stylemistake.com]: http://stylemistake.com
[stylemistake@gmail.com]: mailto:stylemistake@gmail.com
