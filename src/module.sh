#!/bin/bash

## Ensure this file is sourced only once
if [[ -n ${module_name} ]]; then
    return 0
fi

## Force some bash options
shopt -s expand_aliases

## Paths to search for modules, ordered by priority
declare -ga module_search_paths=(
    '.'
    'node_modules'
)

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
    for path in "${module_search_paths[@]}"; do
        path="${module_dirname}/${path}"
        if [[ -e "${path}/${1}" ]]; then
            if [[ -d "${path}/${1}" ]]; then
                ## TODO: check for package.json
                if [[ -e "${path}/${1}/index.sh" ]]; then
                    file="${path}/${1}/index.sh"
                    break
                fi
            else
                file="${path}/${1}"
                break
            fi
        elif [[ -f "${path}/${1}.sh" ]]; then
            file="${path}/${1}.sh"
            break
        fi
    done
    [[ -z ${file} ]] && return 1
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
    local action="${1}"
    shift
    case ${action} in
        'export') module_export "${@}" ;;
        'import') module_import "${@}" ;;
    esac
}

## Initialize current file as a module
if [[ -f ${0} ]]; then
    module_init "${0}"
elif [[ -f "$(pwd)/$(basename ${0})" ]]; then
    ## This one is ugly, but what can I do :(
    module_init "$(pwd)/$(basename ${0})"
else
    module_log "could not determine path to root module: '${0}'"
    exit 1
fi
