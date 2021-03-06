#!/bin/bash

## Ensure this file can only be sourced
[[ "${FUNCNAME[0]}" != source ]] && exit 1

## Ensure this file is sourced only once
[[ -n ${module_name} ]] && return 0


## --------------------------------------------------------
##  Configuration
## --------------------------------------------------------

## Bash options
shopt -s expand_aliases

## Paths to search for modules, ordered by priority
declare -ga module_search_paths=(
    '.'
    'node_modules'
)


## --------------------------------------------------------
##  Functions
## --------------------------------------------------------

## Usage: module_init <path_to_module>
module_init() {
    ## Determine canonical path to this file
    local path="$(module_readlink ${1} 2>/dev/null)"
    if [[ ! -f ${path} ]]; then
        module_log "init: could not resolve canonical name of '${1}'"
        exit 1
    fi
    ## Initialize global vars
    declare -gA module_exports=()
    declare -g module_path="${path}"
    declare -g module_dirname="$(dirname ${path})"
    declare -g module_filename="$(basename ${path})"
    declare -g module_name="${module_filename%.*}"
}

module_log() {
    echo "module: ${@}" >&2
}

## Returns full path to a module.
## Usage: module_resolve <module_name>
module_resolve() {
    local file path
    ## Search for module in pre-defined paths
    for path in "${module_search_paths[@]}"; do
        path="${module_dirname}/${path}"
        if [[ -f "${path}/${1}.sh" ]]; then
            file="${path}/${1}.sh"
            break
        elif [[ -f "${path}/${1}" ]]; then
            file="${path}/${1}"
            break
        elif [[ -d "${path}/${1}" ]]; then
            ## TODO: check for package.json
            if [[ -f "${path}/${1}/index.sh" ]]; then
                file="${path}/${1}/index.sh"
                break
            fi
        fi
    done
    ## Fail if module was not found
    [[ -z ${file} ]] && return 1
    ## Return path to module
    echo "${file}"
}

## Get canonical path to file
## Usage: module_readlink <file>
module_readlink() {
    local path="$(readlink -f ${1} 2>/dev/null)"
    if [[ ! -f ${path} ]]; then
        ## TODO: implement alternatives
        return 1
    fi
    echo "${path}"
}

## Runs a module function inside a subshell.
## Usage: module_run <path_to_module> <exported_name> [arguments...]
module_run() {
    (
        ## NOTE: module is initialized every time we call its functions.
        module_init "${1}"
        source "${1}"
        if [[ -z ${module_exports[$2]} ]]; then
            module_log "run: exported function not found '${2}'"
            exit 1
        fi
        "${module_exports[$2]}" "${@:3}"
    )
}

## Export a function of current module.
## Usage: module_export <function_name> [as <alias>]
module_export() {
    if [[ ${#} -eq 0 ]]; then
        module_log "export: missing arguments"
        exit 1
    fi
    local name="${1}"
    local alias="${1}"
    shift
    if [[ -n ${1} ]]; then
        case "${1}" in
            'as')
                alias="${2}"
                shift 2
            ;;
            *)
                module_log "export: invalid keyword: ${1}"
                exit 1
            ;;
        esac
    fi
    module_exports[${alias}]="${name}"
}

## Import a module or a function from the module.
## Searches for modules in pre-defined paths.
## Usage:
##   module_import <module_name> [as <alias>]
##   module_import <exported_name> [as <alias>] from <module_name>
module_import() {
    ## TODO: Implement all use cases
    case ${#} in
        0)
            module_log "import: missing arguments"
            exit 1
        ;;
        1)
            local path="$(module_resolve ${1})"
            if [[ -z ${path} ]]; then
                module_log "import: module '${1}' not found"
                exit 1
            fi
            local filename="$(basename ${path})"
            local alias="${1%.*}"
            alias ${alias}="module_run \"${path}\""
        ;;
        *)
            module_log "import: invalid number of arguments"
            exit 1
        ;;
    esac
}

## Public interface to module loader
module() {
    case "${1}" in
        'export') module_export "${@:2}" ;;
        'import') module_import "${@:2}" ;;
    esac
}


## --------------------------------------------------------
##  Initialization
## --------------------------------------------------------

## Determine correct path to the root module
declare -g module_root_path
if [[ -n ${OLDPWD} ]]; then
    module_root_path="${OLDPWD}/${0}"
else
    module_root_path="$(pwd -P)/${0}"
fi

## Initialize root module vars
declare -g module_root_dirname="$(dirname ${module_root_path})"
declare -g module_root_filename="$(basename ${module_root_path})"

## Verify root module path
if [[ ! -f ${module_root_path} ]]; then
    module_log "could not determine path to root module: '${0}'"
    exit 1
fi

## Initialize root module
module_init "${module_root_path}"
