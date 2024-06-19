#!/bin/bash -

# Copyright (C) 2017-2023 Alex deBeus

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

readonly COPYRIGHT_YEARS='2017-2023'
readonly DEFAULT_CONFIG_FILE=/etc/snapraid.conf
readonly DEFAULT_SNAPPER_CONFIG_DIR=/etc/snapper/configs
readonly DEFAULT_TMPDIR=/tmp
readonly DEFAULT_USERDATA_KEY=snapraid-btrfs
readonly E_MISSING_DEPENDENCY=63
readonly E_INTERNAL_ERROR=64
readonly E_INVALID_ARGUMENT=65
readonly E_INVALID_CONFIG=66
readonly E_NO_PERMISSION=67
readonly E_SNAPSHOT_NOT_FOUND=68
readonly E_INTERACTIVE_NO=69
# for use with awk
# mawk versions < 1.3.4 don't support [:lower:],
# so we use [$LOWER] instead for portability
readonly LOWER=abcdefghijklmnopqrstuvwxyz
readonly MY_VERSION='0.14.1+git'
# snapraid short options, sorted by whether or not they accept arguments
readonly SNAPRAID_OPTS_ARG=BCLScdfilop
readonly SNAPRAID_OPTS_NOARG=DEFGHLNRTUVZaehmqv

# bash version 4+ required for associative arrays, coprocesses, and
# ;& and ;;& terminators in case statements
# 4.1+ required for ACL support, <{var} fd variable assignment, and
# BASH_XTRACEFD
if [ -z "${BASH_VERSION-}" ] ||
       ! { ((BASH_VERSINFO[0] > 4)) ||
               { ((BASH_VERSINFO[0] == 4)) && ((BASH_VERSINFO[1] >= 1)) ; } ; }
then
    echo 'bash version 4.1+ is required to use this script' >&2
    exit ${E_MISSING_DEPENDENCY:-63}
fi

set -o errexit
set -o errtrace
set -o functrace
set -o noglob
set -o nounset
set -o pipefail
set +o noclobber
set +o posix
shopt -s dotglob
shopt -s extglob
shopt -s extquote
shopt -s nullglob
# Use lastpipe if available (bash 4.2+) since it's faster,
# but we don't need the behavior
shopt -s lastpipe &> /dev/null || true

# Add $1 to snapper_configs_specified array if not duplicate
add_snapper_config() {
    [[ "${snapper_configs_specified_seen[$1]+x}" ]] ||
        snapper_configs_specified+=( "$1" )
    snapper_configs_specified_seen[$1]=1
}

# Apply the --pre-post and --no-pre-post command line options
apply_pre_post_options() {
    local i j
    if ((${#pre_post_option[@]} > 0)) ; then
        for i in "${pre_post_option[@]}" ; do
            config_must_exist "$i"
        done
        pre_post_configs=( "${pre_post_option[@]}" )
    else
        pre_post_configs=( "${snapper_configs[@]}" )
    fi
    if ((${#no_pre_post_option[@]} > 0)) ; then
        local -a temp_array
        for i in "${no_pre_post_option[@]}" ; do
            config_must_exist "$i"
            temp_array=()
            for j in "${pre_post_configs[@]}" ; do
                [[ "$j" = "$i" ]] || temp_array+=( "$j" )
            done
            pre_post_configs=( "${temp_array[@]}" )
        done
    fi
}

# apply the --snapper-configs-file command line option
apply_snapper_configs_file_option() {
    [[ -r "$1" ]] ||
        error $E_INVALID_CONFIG "$1 is not a readable file"
    local config=
    while IFS= read -r config || [[ "$config" ]] ; do
        add_snapper_config "$config"
    done < "$1"
}

# apply the --snapper-configs command line option
apply_snapper_configs_option() {
    local -a configs
    IFS=',' read -r -a configs <<< "$1"
    local i
    for i in "${configs[@]}" ; do
        add_snapper_config "$i"
    done
}

# Set use_snapshot from comma-separated key=value pairs specified in $1
apply_use_snapshot_option() {
    local -a args
    local config config_using i
    IFS=',' read -r -a args <<< "$1"
    for i in "${args[@]}" ; do
        IFS='=' read -r config config_using <<< "$i"
        config_must_exist "$config"
        use_snapshot[$config]="$config_using"
    done
}

# Prints a function call stack, not including itself
call_stack() {
    local func line script
    local -i frame=1
    echo 'Call stack:'
    while IFS=' ' read -r line func script ; do
        printf -- '%s: %s: %s\n' "$script" "$func" "$line"
    done < <(while caller $frame ; do ((++frame)) ; done)
}

# Sanity checks to run after reading configuration from
# snapraid.conf and snapper list-configs
check_config() {
    if ((${#snapper_configs[@]} > 0)) ; then
        check_content_files
        check_snapper_configs
    else
        error_nonshell "$1" $E_INVALID_CONFIG \
            "No snapper configs found for any data drives in $config_file"
    fi
}

# Sanity checks to run before reading snapraid.conf file
check_config_file() {
    if ! [[ -r "$config_file" ]] ; then
        error_nonshell "$1" $E_INVALID_ARGUMENT \
            "Could not read snapraid config file at $config_file"
        return 0
    fi
    verbose "Using snapraid config file $config_file"
    # check for trailing newline in snapraid.conf
    # Lack of a trailing newline will cause problems.
    # Therefore, if there is no trailing newline, create a
    # temporary config file with a newline added and use that instead.
    if [[ "$(tail -c 1 "$config_file")" ]] ; then
        warn "No newline at end of $config_file"
        local new_config_file
        new_config_file="$(mktemp -- "$temp_dir/$my_name.XXXXXX")"
        rm_on_exit+=( "$new_config_file" )
        cat < "$config_file" > "$new_config_file"
        echo >> "$new_config_file"
        config_file="$new_config_file"
    fi
}

# We don't want to snapshot the content files. So, check the
# directories of the content files, and compare their mount points with
# those of the subvolumes we are snapshotting, to see if any match
check_content_files() {
    local field1 field2 content_dir content_mount i
    while IFS=$' \t' read -r field1 field2 ; do
        if [[ "$field1" = content ]] ; then
            if [[ -f "$field2" ]] ; then
                content_dir="$(dirname -- "$field2")"
                if [[ -d "$content_dir" ]] ; then
                    content_mount="$(stat --format=%m -- "$content_dir")"
                    for i in "${snapper_configs[@]}" ; do
                        if [[ "$content_mount" -ef \
                            "${snapper_subvols[$i]}" ]]
                        then
                            error $E_INVALID_CONFIG \
                                "$field2 found in subvolume" \
                                "${snapper_subvols[$i]}" \
                                '- content files must be in separate subvolume'
                        fi
                    done
                else
                    warn "content directory $content_dir not found"
                fi
            else
                warn "content file $field2 not found"
            fi
        fi
    done < "$config_file"
}

# Make sure all external binaries in $@ can be found
check_dependencies() {
    while (($# > 0)) ; do
        if ! type "$1" &> /dev/null ; then
            error $E_MISSING_DEPENDENCY "Could not find dependency $1"
        fi
        shift
    done
}

check_snapper_configs() {
    local i
    for i in "${snapper_configs[@]}" ; do
        # Check that .snapshots subvolume exists
        if ! is_btrfs_subvolume "${snapper_subvols[$i]}/.snapshots" ; then
            error $E_INVALID_CONFIG "${snapper_subvols[$i]}/.snapshots" \
                'is not a valid btrfs subvolume'
        # Check that we have read permission for the .snapshots subvolume
        # If not, try running snapper ls, in case ACLs need to be synced
        elif ! { [[ -r "${snapper_subvols[$i]}/.snapshots" ]] ||
                     { snapper_ls_sync_acl "$i" &&
                           [[ -r "${snapper_subvols[$i]}/.snapshots" ]] ; } ; }
        then
            error $E_NO_PERMISSION 'No read permission for' \
                "${snapper_subvols[$i]}/.snapshots" \
                '- is SYNC_ACL set in snapper configuration?'
        fi
    done
}

# Make sure the user hasn't tried to pass through the -c option to snapraid
check_snapraid_arguments() {
    while (($# > 0)) ; do
        case $1 in
            --)
                break ;;
            --conf|-*(["$SNAPRAID_OPTS_NOARG"])c*)
                error $E_INVALID_ARGUMENT \
                    "The -c/--conf option can't be passed through to snapraid"
                ;;
        esac
        if snapraid_opt_has_arg "$@" ; then
            shift 2
        else
            shift
        fi
    done
}

cleanup_coproc_debug() {
    [[ "${debug_fd}" ]] || return 0
    trap - DEBUG
    eval "${debug_fd:+exec ${debug_fd}>&-}"
    eval "${sed_escape_debug[1]:+exec ${sed_escape_debug[1]}>&-}"
    # shellcheck disable=2154
    # Shellcheck doesn't understand named coprocesses
    # See https://github.com/koalaman/shellcheck/issues/1066
    eval "${sed_escape_debug_PID:+wait $sed_escape_debug_PID}"
    debug_fd=
}

cleanup_coproc_xtrace() {
    [[ "${xtrace_fd}" ]] || return 0
    set +o xtrace
    BASH_XTRACEFD="${xtrace_fd_old:-2}"
    eval "${xtrace_fd:+exec ${xtrace_fd}>&-}"
    eval "${sed_escape_xtrace[1]:+exec ${sed_escape_xtrace[1]}>&-}"
    # shellcheck disable=2154
    # Shellcheck doesn't understand named coprocesses
    # See https://github.com/koalaman/shellcheck/issues/1066
    eval "${sed_escape_xtrace_PID:+wait $sed_escape_xtrace_PID}"
    xtrace_fd=
    xtrace_fd_old=
}

cleanup_coprocs() {
    cleanup_coproc_debug
    cleanup_coproc_xtrace
}

# Run snapper rm on config $1, with $2, $3, ... specifying snapshots to delete
cleanup_snapshots() {
    if (($# < 2)) ; then
        return 0
    fi
    local config="$1"
    shift
    local -i ret
    if ((interactive > 0)) ; then
        snapper_ls_wrapper "$config" >&2
        echo >&2
    fi
    verbose_command_run "$my_snapper" -c "$config" \
        rm${sync:+ --sync} "$@" && true
    ret=$?
    if ((interactive > 0)) ; then
        echo >&2
    fi
    return $ret
}

# Check that the user didn't specify a nonexistent snapper config by ensuring
# that a subvolume is set for the config name
config_must_exist() {
    [[ "${snapper_subvols[$1]-}" ]] ||
        error $E_INVALID_ARGUMENT "Invalid snapper configuration $1"
}

# Calling once creates pre snapshots, calling again creates corresponding post
create_pre_post_snapshots() {
    local -a snapper_cmd
    local post_snapshot i
    for i in "${pre_post_configs[@]}" ; do
        # skip configs where we're using a readonly snapshot
        [[ "${use_snapshot[$i]}" = 0 ]] || continue
        snapper_cmd=( "$my_snapper" -c "$i" create )
        if [[ "$snapper_cleanup" ]] ; then
            snapper_cmd+=( -c "$snapper_cleanup" )
        fi
        # Check if we've already done a pre snapshot
        if [[ "${pre_snapshot[$i]-}" ]] ; then
            # We've already done pre snapshots, so create corresponding post
            if [[ "$snapper_description" ]] ; then
                snapper_cmd+=( -d "$snapper_description" )
            else
                snapper_cmd+=( -d "$my_name post-$1" )
            fi
            snapper_cmd+=(
                -u "$snapper_userdata$snapper_userdata_key=post-$1"
                -t post
                --pre-number "${pre_snapshot[$i]}"
                -p
            )
            if post_snapshot="$("${snapper_cmd[@]}")" ; then
                verbose "Created post snapshot" \
                    "${snapper_subvols[$i]}/.snapshots/$post_snapshot"
            else
                warn "Failed to create post snapshot for pre snapshot" \
                    "${snapper_subvols[$i]}/.snapshots/${pre_snapshot[$i]}"
            fi
        else
            # We haven't created pre snapshots yet, so create them and store
            # the snapshot numbers from snapper -p option in ${pre_snapshot[@]}
            if [[ "$snapper_description" ]] ; then
                snapper_cmd+=( -d "$snapper_description" )
            else
                snapper_cmd+=( -d "$my_name pre-$1" )
            fi
            snapper_cmd+=(
                -u "$snapper_userdata$snapper_userdata_key=pre-$1"
                -t pre
                -p
            )
            pre_snapshot[$i]="$("${snapper_cmd[@]}")"
            verbose "Created pre snapshot" \
                "${snapper_subvols[$i]}/.snapshots/${pre_snapshot[$i]}"
        fi
    done
}

# display current state of variables
# DEBUG is trapped in enable_debug_mode()
debug_trap() {
    local -r div='----------------------------------------'
    printf -- '%s\n%s: %s%s\n' "$div" "$1" "$3" "$2"
    shift 3
    call_stack
    printf -- '%s\n%s' "$div" 'set -- '
    print_array "$@"
    declare -p "${debug_vars[@]}"
    printf -- '%s\n' "$div"
} >&"$debug_fd"

# get variable names to pass as arguments to declare -p
declare-p_vars() {
    declare -p | declare-p_vars_awk "$@"
}

declare-p_vars_awk() {
    local args
    printf -v args -- '%s|' "$@"
    args="${args%|}"
    awk -f <(cat <<_EOF_
BEGIN {
    FS = "[ \t=]+"
    ORS = " "
}
/^declare -[-Aair]+ ($args)/ {
    print \$3
}
_EOF_
            )
}

declare-p_vars_debug() {
    declare-p_vars "[$LOWER]" 'BASH' \
        '(DEBUG_FD|FUNCNAME|IFS|MY_VERSION|PIPESTATUS|TMPDIR)='
}

declare-p_vars_shell() {
    declare-p_vars "[_$LOWER]" 'LOWER=' '(COPYRIGHT|DEFAULT|E|MY|SNAPRAID)_'
}

# In each config, delete snapshots with userdata key $snapper_userdata_key
# older than use_snapshot[$i], or all such snapshots if use_snapshot[$i]=0
do_cleanup() {
    local i j
    local -i ret=0
    local -i snapper_ret
    local -a snapshots_to_consider snapshots_to_delete
    for i in "${snapper_configs[@]}" ; do
        # skip this config if we couldn't find a synced snapshot
        if [[ -z "${use_snapshot[$i]}" ]] ; then
            warn "No synced snapshot found for config $i - skipping"
            continue
        fi
        IFS=' ' read -r -a snapshots_to_consider \
            <<< "$(snapper_ls_wrapper "$i" 'C' |
            parse_snapper_ls "$snapper_userdata_key" '' ' ')"
        snapshots_to_delete=()
        for j in "${snapshots_to_consider[@]}" ; do
            if [[ "${use_snapshot[$i]}" -gt "$j" ]] ||
                   [[ "${use_snapshot[$i]}" = 0 ]]
            then
                snapshots_to_delete+=( "$j" )
            fi
        done
        cleanup_snapshots "$i" "${snapshots_to_delete[@]}" && true
        snapper_ret=$?
        if ((snapper_ret != 0)) ; then
            ret=$snapper_ret
        fi
    done
    return $ret
}

# start interactive shell in context of script
do_shell() {
    cleanup_coprocs
    (
        # shellcheck disable=2030
        rm_on_exit=()
        local _funcs _vars
        local -a _funcs_arr _vars_arr
        _funcs="$(declare -F |
            awk -v ORS=' ' "/^declare -f [$LOWER]/{print \$3}")"
        IFS=' ' read -r -a _funcs_arr <<< "$_funcs"
        IFS=' ' read -r -a _vars_arr <<< "$(declare-p_vars_shell)"
        _vars="$(declare -p "${_vars_arr[@]}")"
        export BASHOPTS SHELLOPTS _funcs _vars
        export -f "${_funcs_arr[@]}"
        set +o errexit
        set +o nounset
        exec "$BASH" --rcfile \
            <(cat <<'_EOF_'
eval "$_vars"
export -fn "${_funcs_arr[@]}"
export -n BASHOPTS SHELLOPTS
unset -v _funcs _vars _funcs_arr _vars_arr
trap 'exit_trap' EXIT
exit() {
    printf -- 'Hooked exit command with status %s\n' "${1:-$?}"
    printf -- 'Use quit to exit the %s interactive shell\n' "$my_name"
}
quit() {
    command exit "${@:-0}"
}
vars() {
    local -a _vars_arr
    IFS=' ' read -r -a _vars_arr <<< "$(declare-p_vars_debug)"
    declare -p "${_vars_arr[@]}"
}
if [[ -e "$HOME/.bashrc" ]] ; then
    source "$HOME/.bashrc"
fi
if ((verbose >= 0)) ; then
    cat <<__EOF__
Started interactive bash session in $my_name context.
Commands:
    quit - exit the interactive shell
    vars - display variable values

__EOF__
fi
_EOF_
             ) -O extglob -i "$@"
    )
}

# run the specified snapper command on each config
do_snapper() {
    local i
    for i in "${snapper_configs[@]}" ; do
        if [[ "${use_snapshot[$i]}" = 0 ]] ; then
            continue
        else
            verbose_command_run "$my_snapper" -c "$i" "$@"
        fi
    done
}

# Set DEBUG trap to display variables with each command
enable_debug_mode() {
    IFS=' ' read -r -a debug_vars <<< "$(declare-p_vars_debug)"
    cleanup_coproc_debug
    local debug_out_fd
    if [[ "$debug_file" ]] ; then
        exec {debug_out_fd}>"$debug_file"
    else
        debug_out_fd="${DEBUG_FD:-2}"
    fi
    coproc sed_escape_debug {
        sed_escape_output
    } >&"${debug_out_fd}"
    exec {debug_fd}<&"${sed_escape_debug[1]}"
    # shellcheck disable=1004
    trap 'debug_trap "$LINENO" "$BASH_COMMAND" \
        "${FUNCNAME[0]:+${FUNCNAME[0]}(): }" "$@"' DEBUG
}

enable_debug_modes() {
    if ((debug_mode > 0)) ; then
        enable_debug_mode
    fi
    if ((xtrace_mode > 0)) ; then
        enable_xtrace_mode
    fi
}

# Use sed coproc to escape BASH_XTRACEFD
enable_xtrace_mode() {
    cleanup_coproc_xtrace
    local xtrace_out_fd
    if [[ "$xtrace_file" ]] ; then
        exec {xtrace_out_fd}>"$xtrace_file"
    else
        xtrace_out_fd="${BASH_XTRACEFD:-2}"
    fi
    xtrace_fd_old="${BASH_XTRACEFD:-2}"
    coproc sed_escape_xtrace {
        sed_escape_output
    } >&"${xtrace_out_fd}"
    exec {xtrace_fd}<&"${sed_escape_xtrace[1]}"
    BASH_XTRACEFD="$xtrace_fd"
    set -o xtrace
}

# Intended to be called by ERR trap. Accepts the following arguments:
# $1 - Line number where ERR condition occurred
# $2 - Command that caused the ERR condition
# $3 - Exit status that caused the ERR condition
err_trap() {
    trap - DEBUG
    printf -- '%s: %s: %s failed%s\n' "$my_name" "${1:-0}" \
        "${2:-unknown command}" "${3:+ with exit status $3}"
    call_stack
    exit "${3:-$E_INTERNAL_ERROR}"
} >&2

# $1 - exit status to exit with
# $2,$3,... - error message to print as $* after shifting
error() {
    local -i errno="${1-}"
    if ((errno < 1)) || ((errno > 255)) ; then
        printf -- 'error called with invalid exit status %s\n' "${1:-(none)}"
        errno="$E_INTERNAL_ERROR"
    fi
    shift || true
    printf -- '%s: ' "$my_name"
    print_array "${@:-fatal error}"
    case $errno in
        "$E_INVALID_ARGUMENT")
            printf -- 'Use %s -h for help\n' "$my_name" ;;
    esac
    exit "$errno"
} >&2

# error if not running the shell command, otherwise warning
# $1 - command being run
# $2,$3,... - args to pass to error() if $1 != shell
error_nonshell() {
    if ! { [[ "$1" =~ ^[a-z-]*$ ]] && [[ "$2" =~ ^[0-9]*$ ]] ; } ; then
        error $E_INTERNAL_ERROR \
            'error_nonshell() called with invalid arguments'
    elif [[ "$1" = 'shell' ]] ; then
        shift 2
        warn "$@" '- ignoring to start interactive shell'
    else
        shift
        error "$@"
    fi
}

# Intended to be called by EXIT trap
# Removes rm_on_exit if nonempty and cleans up coprocess if necessary
exit_trap() {
    # shellcheck disable=2031
    if ((${#rm_on_exit[@]} > 0)) ; then
        rm -f -- "${rm_on_exit[@]}" || true
    fi
    cleanup_coprocs
}

# remove -h / --pre-hash from snapraid arguments
# used with diff-sync command since -h is only supported with sync command
filter_pre_hash_option() {
    local args=()
    local i
    for i in "$@" ; do
        if [[ "$i" =~ !(-h|--pre-hash) ]] ; then
            args+=( "$i" )
        fi
    done
    print_array "${args[@]}"
}

find_configs() {
    if ((${#snapper_configs_specified[@]} > 0)) ; then
        find_configs_specified
    else
        find_configs_snapper_get-config "$@"
    fi
}

# if the user has specified --snapper-configs and/or --snapper-configs-file
# command line options, use them to find snapper configs
find_configs_specified() {
    local i
    for i in "${snapper_configs_specified[@]}" ; do
        find_configs_try "$i" && true
        case $? in
            1)
                error $E_INVALID_CONFIG \
                    "SUBVOLUME for config $i not found in $config_file" ;;
            2)
                error $E_INVALID_CONFIG \
                    "Failed to run snapper get-config for config $i" ;;
        esac
    done
    verbose
}

# try snapper get-config for all configs found in /etc/snapper/configs
# and look for SUBVOLUME matching /etc/snapraid.conf
find_configs_snapper_get-config() {
    local config dir i
    local -a files
    dir="${SNAPPER_CONFIG_DIR-$DEFAULT_SNAPPER_CONFIG_DIR}"
    if ! [[ -d "$dir" ]] ; then
        error $E_INVALID_CONFIG "$dir is not a directory"
    elif ! [[ -r "$dir" ]] ; then
        error $E_NO_PERMISSION "No read permission for $dir"
    fi
    set +o noglob
    files=( "$dir"/* )
    set -o noglob
    if (("${#files[@]}" == 0)) ; then
        error_nonshell "$1" $E_INVALID_CONFIG "No files in $dir"
    fi
    for i in "${files[@]}" ; do
        config="$(basename -- "$i")"
        find_configs_try "$config" && true
        case $? in
            1)
                verbose \
                    "SUBVOLUME for config $config not found in $config_file" ;;
            2)
                verbose \
                    "Failed to run snapper get-config for config $config" ;;
        esac
    done
    verbose
}

# Try to find a match between the snapper config $1 and snapraid.conf and
# add it to snapper_configs array if successful
# return 0 if $1 matches snapraid.conf
# return 1 if $1 doesn't match snapraid.conf
# return 2 if we couldn't run snapper get-config for $1
find_configs_try() {
    local config field1 field2 field3 found subvol
    config="$1"
    found=
    if subvol="$("$my_snapper" -c "$config" get-config 2>/dev/null |
        sed -e '/^SUBVOLUME /!d' -e 's/^SUBVOLUME[ ]*[|│] //')" # TODO https://github.com/automorphism88/snapraid-btrfs/issues/35
    then
        while IFS=$' \t' read -r field1 field2 field3 ; do
            if [[ "$field1" =~ ^(data|disk)$ ]] &&
                   [[ "$field3" -ef "$subvol" ]]
            then
                found=1
                snapper_configs+=( "$config" )
                snapper_subvols[$config]="$subvol"
                snapraid_names[$config]="$field2"
            fi
        done < "$config_file"
        if [[ "$found" ]] ; then
            verbose \
                "Found $subvol in $config_file - using snapper config $config"
            return 0
        else
            return 1
        fi
    else
        return 2
    fi
}

# output the last snapshot number from config $1 matching userdata key $2
# (or any if $2 is undefined or empty)
find_snapshot() {
    snapper_ls_wrapper "$1" 'C' |
        parse_snapper_ls "$snapper_userdata_key" "${2:+$2}" |
        tail -n 1
}

# replace keywords in use_snapshot with actual snapshot numbers, or with the
# empty string if a snapshot matching the keyword cannot be found
find_snapshots() {
    local -i n=0
    local i
    for i in "${snapper_configs[@]}" ; do
        use_snapshot_missing[$i]="${use_snapshot[$i]}"
        case ${use_snapshot[$i]} in
            0|'')
                continue ;;
            diff)
                use_snapshot[$i]="$(find_snapshot "$i" 'diff')" ;;
            last)
                use_snapshot[$i]="$(find_snapshot "$i")" ;;
            menu)
                snapshot_menu "$i" "$1" ;;
            new)
                new_snapshot "$i" "$1" ;;
            res?(ume))
                use_snapshot[$i]="$(find_snapshot "$i" 'syncing,synced')" ;;
            scrub)
                use_snapshot[$i]="$(find_snapshot "$i" \
                    'syncing,synced,post-fix,post-touch')" ;;
            sync)
                use_snapshot[$i]="$(find_snapshot "$i" 'synced')" ;;
            +([0123456789]))
                if ! { snapper_ls_wrapper "$i" 'C' |
                           parse_snapper_ls |
                           grep -Fx "${use_snapshot[$i]}" > /dev/null ; }
                then
                    use_snapshot[$i]=
                fi ;;
            *)
                error $E_INVALID_ARGUMENT \
                    'Could not understand snapshot selection' \
                    "${use_snapshot[$i]} for config $i" ;;
        esac
        if [[ "${use_snapshot[$i]}" ]] ; then
            ((++n))
            use_snapshot_missing[$i]=
            if [[ "${use_snapshot[$i]}" = '0' ]] ; then
                verbose "Using live filesystem for config $i"
            else
                verbose "Using snapshot ${use_snapshot[$i]} for config $i"
            fi
        fi
    done
    if ((n > 0)) ; then
        verbose
    fi
}

# generate sed script to replace subvolume paths with corresponding snapshots
# (and pool directory, if --pool-dir is specified) and run it on snapraid.conf
generate_temp_snapraid_conf() {
    local match_line new_path sed_find sed_replace i
    local sed_exps=()
    # sed BRE matching data line up to the point where the path starts
    local -r data_line=$'^[ \t]*data[ \t]\{1,\}[^ \t]\{1,\}[ \t]\{1,\}'
    if [[ "$pool_dir" ]] ; then
        sed_exps+=( $'/^[ \t]*pool[ \t]\{1,\}/d'
                    "\$apool $pool_dir" )
    fi
    for i in "${snapper_configs[@]}" ; do
        if [[ "${use_snapshot[$i]}" != 0 ]] ; then
            new_path="${snapper_subvols[$i]}/.snapshots/"
            new_path+="${use_snapshot[$i]}/snapshot"
            if ! is_btrfs_subvolume "$new_path" ; then
                error $E_SNAPSHOT_NOT_FOUND "Invalid snapshot $new_path"
            elif ! [[ -r "$new_path" ]] ; then
                error $E_NO_PERMISSION "No read permission for $new_path"
            fi
            # Escape special characters in paths so that they can be
            # passed to sed as literal strings
            sed_find="$(sed_escape_bre <<< "${snapper_subvols[$i]}")"
            sed_replace="$(sed_escape_replacement <<< "$new_path")"
            match_line="$data_line$sed_find"'\/\{0,1\}$'
            # also match the deprecated token 'disk' using separate sed
            # expression to avoid depending on the GNU extension \|
            sed_exps+=( "/$match_line/s/$sed_find/$sed_replace/"
                        "/${match_line/data/disk}/s/$sed_find/$sed_replace/" )
        fi
    done
    if ((${#sed_exps[@]} == 0)) ; then
        cat < "$config_file"
    else
        sed -f <(printf -- '%s\n' "${sed_exps[@]}") -- "$config_file"
    fi
}

# given the snapraid.conf name for a disk (e.g. d1 in disk d1 /foo/bar),
# find the corresponding snapper config name, if any
get_snapper_config_name() {
    local i
    for i in "${snapper_configs[@]}" ; do
        if [[ "$1" = "${snapraid_names[$i]}" ]] ; then
            printf -- '%s\n' "$i"
            break
        fi
    done
}

get_snapper_version() {
    "$my_snapper" --version | sed -n '1s/^[^0123456789]*//p'
}

interactive_ask() {
    echo 'About to run the following command:'
    print_array "$@"
    local choice
    while true ; do
        read -r -p 'Do it [Y/N]? ' choice
        case $choice in
            [Yy]?([Ee][Ss]))
                break ;;
            [Nn]?([Oo]))
                exit $E_INTERACTIVE_NO ;;
            *)
                echo 'Invalid choice. Please enter y or n.' ;;
        esac
    done
} >&2

invalid_argument() {
    error $E_INVALID_ARGUMENT "Invalid argument $1"
}

# Returns:
# 0 if $1 is a btrfs subvolume
# 1 if $1 is an "empty subvolume" inside a snapshot
# 2 if $1 is an ordinary directory
# 3 if $1 is not a directory
# 4 if we couldn't determine the inode number with stat
is_btrfs_subvolume() {
    [[ -d "$1" ]] || return 3
    case $(stat --format=%i -- "$1") in
        256)
            return 0 ;;
        2)
            return 1 ;;
        '')
            return 4 ;;
        *)
            return 2 ;;
    esac
}

main() {
    check_dependencies awk basename cat dirname grep mktemp rm sed stat tail

    # Declare "global" variables as local to main since they will be
    # accessible from any functions called from main
    # These variables are set during processing of command line arguments and
    # snapraid/snapper configurations and are initialized to defaults here

    # snapraid config file location
    local config_file="${SNAPRAID_CONFIG_FILE:-$DEFAULT_CONFIG_FILE}"
    # fd to send debug output to if -X/--debug is enabled
    local debug_fd=
    # --debug-file option argument
    local debug_file=
    # indicates whether the -X/--debug option has been enabled
    local -i debug_mode=0
    # array storing variables to print in DEBUG trap
    local debug_vars=()
    # indicates whether the -i/--interactive option has been enabled
    local -i interactive=0
    # filename of script determined at runtime
    local my_name
    my_name="$(basename -- "${BASH_SOURCE[0]}")"
    # snapper/snapraid commands to use, can be specified with the
    # --snapper-path and --snapraid-path command line options
    local my_snapper=snapper
    local my_snapraid=snapraid
    # --pool-dir option argument
    local pool_dir=
    # list of snapper configs to create pre/post snapshots for
    local pre_post_configs=()
    # --pre-post option argument, after splitting
    local pre_post_option=()
    # --no-pre-post option argument, after splitting
    local no_pre_post_option=()
    # names of temp files to rm upon exiting
    local rm_on_exit=()
    # snapper cleanup algorithm to specify when creating new snapshots
    local snapper_cleanup=
    # names of all snapper configs that match snapraid.conf
    local snapper_configs=()
    # These associative arrays are indexed by snapper configs in the
    # snapper_configs array, and hold the following data:
    # number of pre snapshot created, to use when creating post
    local -A pre_snapshot
    # subvolume corresponding to the snapper config
    local -A snapper_subvols
    # snapraid disk name corresponding to the snapper config
    local -A snapraid_names
    # which snapshot should be used for the snapper config
    local -A use_snapshot
    # values of use_snapshot not found by find_snapshots()
    local -A use_snapshot_missing
    # indexes are configs specified with either the
    # --snapper-configs or --snapper-configs-file options
    # associative array used to track duplicates,
    # regular array to preserve the order configs were specified
    local snapper_configs_specified=()
    local -A snapper_configs_specified_seen
    # description to specify to snapper when creating new snapshots
    local snapper_description=
    # variable to be set if snapper ls supports --disable-used-space
    # (version 0.6.0 or newer) and --used-space option was not specified
    local snapper_ls_quota_disable=
    # variable to be set if snapper ls supports --disable-used-space
    # (version 0.6.0 or newer)
    local snapper_ls_quota_support=
    # snapper userdata key that will be specified to track created snapshots
    # can be changed by setting the SNAPRAID_USERDATA_KEY environment variable
    local \
        snapper_userdata_key="${SNAPRAID_USERDATA_KEY:-$DEFAULT_USERDATA_KEY}"
    # additional userdata to set, specified with the --snapper-userdata option
    local snapper_userdata=
    # variable to be set if -s/--sync option is specified
    local sync=
    # location of temporary snapraid.conf
    local temp_config_file=
    # directory to create temporary snapraid.conf file in
    local temp_dir="${TMPDIR:-$DEFAULT_TMPDIR}"
    # --use-snapshot-all option argument
    local use_snapshot_all_option=
    # --use-snapshot option argument
    local use_snapshot_option=
    # variable to be set if --used-space option is specified
    local -i used_space_option=0
    # controls verbosity, incremented by -v/--verbose or
    # decremented by -q/--quiet command line option
    local -i verbose=0
    # fd to send xtrace output to if -x/--xtrace is enabled
    local xtrace_fd=
    # backup of original BASH_XTRACEFD
    local xtrace_fd_old=
    # --xtrace-file option argument
    local xtrace_file=
    # indicates whether the -x/--xtrace option has been enabled
    local -i xtrace_mode=0

    trap 'err_trap $LINENO "$BASH_COMMAND" $?' ERR
    trap 'exit_trap' EXIT

    # Iterate through command line arguments and process snapraid-btrfs options
    # until a command is reached, then run the specified command, passing
    # through any remaining command line arguments appearing after the command

    # These are genuinely local variables used for option processing
    # and will be unset after use
    local opt_str
    local -i length i
    local command=
    while (($# > 0)) ; do
        case $1 in
            # matching a snapraid command means option processing is complete
            # and any further options will be passed through to snapraid
            check) ;&
            diff) ;&
            fix) ;&
            pool) ;&
            resume) ;&
            scrub) ;&
            ?(diff-|d)sync) ;&
            touch) ;&
            # Option processing is also complete for other commands which
            # accept arguments
            ls|list) ;&
            shell) ;&
            snapper) ;&
            undochange)
                break ;;
            # support options specified either before or after the command
            # for commands which don't invoke snapraid or accept argument
            cleanup?(-all)) ;&
            config) ;&
            create)
                if [[ -z "$command" ]] ; then
                    command="$1"
                    shift
                else
                    invalid_argument "$1 to command $command"
                fi ;;
            # snapraid-btrfs options specified before command
            # long form options that don't take arguments
            --debug) ;&
            --help) ;&
            --?(non)interactive) ;&
            --quiet) ;&
            --sync) ;&
            --used-space) ;&
            --verbose) ;&
            --version) ;&
            --xtrace)
                set_option "$1"
                shift ;;
            # long form options that require arguments
            --conf?(=*)) ;&
            --cleanup?(=*)) ;&
            --@(debug|xtrace)-file?(=*)) ;&
            --description?(=*)) ;&
            --pool-dir?(=*)) ;&
            --?(no-)pre-post?(=*)) ;&
            --snapper-configs?(-file)?(=*)) ;&
            --snapper-@(path|userdata)?(=*)) ;&
            --snapraid-path?(=*)) ;&
            --use-snapshot?(-all)?(=*))
                # allow POSIX --argument option or --argument=option formats
                opt_str="${1%%=*}"
                if [[ "$opt_str" = "$1" ]] ; then
                    set_option "$opt_str" "${2-}"
                    shift 2
                else
                    set_option "$opt_str" "${1#"${opt_str}="}"
                    shift
                fi ;;
            --*)
                invalid_argument "$1" ;;
            # allow POSIX-style combining of short options
            -*)
                opt_str="${1#-}"
                length="${#opt_str}"
                for ((i=0;i<length;i++)) ; do
                    case ${opt_str:$i:1} in
                        # short options that don't take arguments
                        [VXhiqsvx])
                            set_option "-${opt_str:$i:1}"
                            if ((i == length-1)) ; then
                                shift
                            fi ;;
                        # short options that require arguments
                        [CUcdu])
                            if ((i == length-1)) ; then
                                set_option "-${opt_str:$i:1}" "${2-}"
                                shift 2
                            else
                                set_option "-${opt_str:$i:1}" \
                                    "${opt_str:$((i+1))}"
                                shift
                                break
                            fi ;;
                        *)
                            invalid_argument "-${opt_str:$i:1}" ;;
                    esac
                done ;;
            *)
                invalid_argument "$1" ;;
        esac
    done
    # wait until after option parsing is complete to enable --debug/--xtrace
    # to allow for --debug-file/--xtrace-file to be parsed first
    enable_debug_modes
    if [[ "${command-}" ]] ; then
        set -- "$command"
    fi
    # done processing arguments, so unset truly local variables and run command
    unset -v command length opt_str i
    warn_if_root
    if (($# > 0)) ; then
        setup_config "$@"
        run_command "$@"
    else
        error $E_INVALID_ARGUMENT "No command specified"
    fi
}

# set $snapper_userdata_key userdata key to $1
modify_userdata() {
    local i
    local -i ret=0
    local -i snapper_ret
    for i in "${snapper_configs[@]}" ; do
        [[ "${use_snapshot[$i]}" = 0 ]] && continue
        "$my_snapper" -c "$i" modify -u "$snapper_userdata_key=$1" \
            "${use_snapshot[$i]}" && true
        snapper_ret=$?
        if ((snapper_ret != 0)) ; then
            ret=$snapper_ret
        fi
    done
    return $ret
}

must_be_executable() {
    [[ -x "$1" ]] ||
        error $E_INVALID_ARGUMENT "$1 is not an executable file"
}

must_be_writable_dir() {
    [[ -d "$1" ]] ||
        error $E_INVALID_ARGUMENT "$1 is not a directory${2:+ - $2}"
    [[ -w "$1" ]] ||
        error $E_NO_PERMISSION "No write permission for $1${2:+ - $2}"
}

must_be_writable_file() {
    if [[ -d "$1" ]] ; then
        error $E_INVALID_ARGUMENT "$1 is a directory, not a file"
    elif [[ -f "$1" ]] && ! [[ -w "$1" ]] ; then
        error $E_NO_PERMISSION "No write permission for $1"
    else
        local dir
        dir="$(dirname "$1")"
        must_be_writable_dir "$dir"
    fi
}

new_snapshot() {
    local snapper_create_opts=(
        -u "$snapper_userdata$snapper_userdata_key=created"
    )
    if [[ "$snapper_cleanup" ]] ; then
        snapper_create_opts+=( -c "$snapper_cleanup" )
    fi
    if [[ "$snapper_description" ]] ; then
        snapper_create_opts+=( -d "$snapper_description" )
    else
        snapper_create_opts+=( -d "$my_name${2:+ $2}" )
    fi
    use_snapshot[$1]="$("$my_snapper" -c "$1" create -p \
        "${snapper_create_opts[@]}")"
    verbose "Created new snapshot ${use_snapshot[$1]} for config $1"
}

# call this to make sure $2 is defined when user specifies option requring it
option_requires_argument() {
    [[ "${2-}" ]] ||
        error $E_INVALID_ARGUMENT "Option $1 requires an argument"
}

# use awk to parse piped snapper ls output and find snapshot numbers
# matching the specified userdata constraints:
# if $1 and $2 are nonempty, match snapshots with userdata key $1=$2
# (multiple userdata values can be comma-separated in $2 to match any of them)
# else if $1 is nonempty, match snapshots with userdata key $1 defined
# else match all snapshots
# if multiple snapshots match, separate their numbers with $3, or
# if $3 is undefined or empty, separate the snapshot numbers with newlines
parse_snapper_ls() {
    awk -F '|' \
        -v key="${1-}" \
        -v value="${2-}" \
        -v ORS="${3:-$'\n'}" \
        -f <(cat <<'_EOF_'
# create array of values to match from comma-separated variable
BEGIN {
    if (value != "") {
        split(value,values,",")
    }
}
# read column titles in header, so as to work with different versions of
# snapper that reorder columns
NR==1 {
    for (i=1;i<=NF;i++) {
        # remove padding spaces, then store column number indexed by title
        gsub(/[ ]+/,"",$i)
        column[$i] = i
    }
    # check to make sure we found columns labelled "#" and "Userdata"
    if (column["#"] == "" || column["Userdata"] == "") {
        printf("error: expected snapper ls column names not found\n",
               "/dev/stderr")
        exit 1
    }
}
# snapshot data begin on line 3
NR>=3 {
    # remove nonnumeric characters (padding spaces, mount status) from #
    gsub(/[^0123456789]+/,"",$column["#"])
    if (key == "") {
        # match all snapshots
        print $column["#"]
    } else {
        # split userdata column into key=value pairs in case
        # multiple userdata keys are defined for a snapshot
        split($column["Userdata"],pairs,",")
        # construct an array 'userdata' whose indices we will search in
        for (i in pairs) {
            # remove padding spaces
            gsub(/^[ ]+/,"",pairs[i])
            gsub(/[ ]+$/,"",pairs[i])
            if (value == "") {
                # we don't care about the value of the userdata key, so
                # split key=value pairs and store only the key
                split(pairs[i],keys,"=")
                userdata[keys[1]]
            } else {
                # we care about both halves of the userdata key=value
                # pair, so store the whole key=value string
                userdata[pairs[i]]
            }
        }
        # find and print our matches
        if (value == "") {
            # match key only
            if (key in userdata) {
                print $column["#"]
            }
        } else {
            # match both key and value
            for (i in values) {
                if (key "=" values[i] in userdata) {
                    print $column["#"]
                    break
                }
            }
        }
        # (portably) clear userdata before moving on to next snapshot
        split("",userdata)
    }
}
_EOF_
            )
}

print_array() {
    local ret=
    if [[ "$#" -gt 0 ]] ; then
        printf -v ret -- '%s ' "$@"
        ret="${ret% }"
    fi
    printf -- '%s\n' "$ret"
}

print_version() {
    cat <<_EOF_
snapraid-btrfs $MY_VERSION
Copyright (C) $COPYRIGHT_YEARS Alex deBeus
License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>
This is free software; you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
_EOF_
}

# Run the command given in $1
run_command() {
    case $1 in
        # Implementation of commands that don't invoke snapraid
        cleanup?(-all))
            do_cleanup ;;
        config)
            generate_temp_snapraid_conf ;;
        ls|list)
            shift
            snapper_ls "$@" ;;
        shell)
            shift
            do_shell "$@" ;;
        snapper)
            shift
            do_snapper "$@" ;;
        undochange)
            shift
            snapper_undochange "$@" ;;
        # Implementation of commands that invoke snapraid
        check|diff|fix|pool|scrub|sync|touch)
            run_snapraid "$@" && true ;;
        resume)
            shift
            run_snapraid sync "$@" && true ;;
        @(d|diff-)sync)
            if ((interactive < 0)) ; then
                error $E_INVALID_ARGUMENT \
                    'diff-sync and --noninteractive are incompatible'
            fi
            shift
            local -i diff_ret
            # shellcheck disable=2046
            run_snapraid diff $(filter_pre_hash_option "$@") && true
            diff_ret=$?
            # snapraid diff returns 2 if a sync is required
            if ((diff_ret == 2)) ; then
                ((++interactive))
                run_snapraid sync --force-empty "$@" && true
            else
                exit $diff_ret
            fi ;;
    esac
    exit
}

# Returns exit status of snapraid, postfix calls with '&& true' to avoid
# triggering errexit if snapraid's return status is nonzero
# Because errexit will not trigger within this function, we postfix anything
# inside it which cannot fail with || err_trap to trigger ERR trap manually
run_snapraid() {
    local -a snapraid_command
    local -i ret
    check_snapraid_arguments "$@"
    if [[ -z "${temp_config_file}" ]] ; then
        temp_config_file="$(mktemp -- "$temp_dir/$my_name.XXXXXX")" ||
            err_trap $LINENO mktemp $?
        rm_on_exit+=( "$temp_config_file" )
        generate_temp_snapraid_conf > "$temp_config_file" ||
            err_trap $LINENO generate_temp_snapraid_conf $?
        show_temp_snapraid_conf \
            "Using temporary snapraid config file ${temp_config_file}:" ||
            err_trap $LINENO show_temp_snapraid_conf $?
    elif ((verbose > 0)) ; then
        show_temp_snapraid_conf \
            "(Re)using temporary snapraid config file ${temp_config_file}:" ||
            err_trap $LINENO show_temp_snapraid_conf $?
    fi
    snapraid_command=( "$my_snapraid" -c "$temp_config_file" "$@" )
    verbose_command "${snapraid_command[@]}"
    case $1 in
        fix|touch)
            create_pre_post_snapshots "$1" ||
                err_trap $LINENO create_pre_post_snapshots $? ;;
        sync)
            modify_userdata syncing ||
                err_trap $LINENO modify_userdata $?
            # set up a trap to track whether snapraid sync returned exit status
            # 0 because it completed successfully, or because it was
            # interrupted with ctrl-C, but was able to clean up before exiting
            local -i interrupted=0
            trap '((++interrupted)) ; trap - INT TERM QUIT' INT TERM QUIT ;;
    esac
    # Run snapraid
    "${snapraid_command[@]}"
    ret=$?
    case $1 in
        fix|touch)
            create_pre_post_snapshots "$1" ||
                err_trap $LINENO create_pre_post_snapshots $? ;;
        diff)
            # snapraid diff returns 0 if no changes, 2 if sync needed
            if ((ret == 0)) || ((ret == 2)) ; then
                modify_userdata "$1" ||
                    err_trap $LINENO modify_userdata $?
            fi ;;
        sync)
            trap - INT TERM QUIT
            # don't mark sync as completed if INT/TERM/QUIT trap was triggered
            if ((ret == 0)) && ((interrupted == 0)) ; then
                modify_userdata synced ||
                    err_trap $LINENO modify_userdata $?
            fi ;;
    esac
    return $ret
}

# make input suitable to be used in sed BRE as fixed string
# in sed BRE, outside a bracket expression, the following must be escaped:
# . * $ ^ [ / \
sed_escape_bre() {
    sed 's/[.*$^/\[]/\\&/g'
}

# escape output containing the following literal nonprintable ASCII characters:
# \e \r \t
sed_escape_output() {
    sed -e $'s/\e/\e[7m\\\\e\e[0m/g' \
        -e $'s/\r/\e[7m\\\\r\e[0m/g' \
        -e $'s/\t/\e[7m\\\\t\e[0m/g'
}

# make input suitable to be used in sed replacement text as fixed string
# in sed replacement text, the following must be escaped:
# & / \
sed_escape_replacement() {
    sed 's/[&/\]/\\&/g'
}

# $1 is option being set, $2 is argument. If no argument,
# $2 can be either undefined or empty
set_option() {
    case $1 in
        --conf) ;&
        --cleanup) ;&
        --@(debug|xtrace)-file) ;&
        --description) ;&
        --pool-dir) ;&
        --?(no-)pre-post) ;&
        --snapper-@(path|userdata)) ;&
        --snapraid-path) ;&
        --use-snapshot?(-all)) ;&
        -[CUcdu])
            option_requires_argument "$@" ;;&
        -c|--conf)
            config_file="$2" ;;
        -C|--cleanup)
            snapper_cleanup="$2" ;;
        -d|--description)
            snapper_description="$2" ;;
        -h|--help)
            usage
            exit ;;
        -i|--interactive)
            ((++interactive)) || true ;;
        -q|--quiet)
            ((--verbose)) || true ;;
        -s|--sync)
            sync=1 ;;
        -u|--use-snapshot-all)
            use_snapshot_all_option="$2" ;;
        -U|--use-snapshot)
            use_snapshot_option="$2" ;;
        -v|--verbose)
            ((++verbose)) || true ;;
        -V|--version)
            print_version
            exit ;;
        -x|--xtrace)
            ((++xtrace_mode)) ;;
        -X|--debug)
            ((++debug_mode)) ;;
        --debug-file)
            must_be_writable_file "$2"
            debug_file="$2" ;;
        --no-pre-post)
            IFS=',' read -r -a no_pre_post_option <<< "$2" ;;
        --noninteractive)
            ((--interactive)) || true ;;
        --pool-dir)
            must_be_writable_dir "$2"
            pool_dir="$2" ;;
        --pre-post)
            IFS=',' read -r -a pre_post_option <<< "$2" ;;
        --snapper-configs)
            apply_snapper_configs_option "$2" ;;
        --snapper-configs-file)
            apply_snapper_configs_file_option "$2" ;;
        --snapper-path)
            must_be_executable "$2"
            my_snapper="$2" ;;
        --snapper-userdata)
            use_snapper_userdata "$2" ;;
        --snapraid-path)
            must_be_executable "$2"
            my_snapraid="$2" ;;
        --used-space)
            ((++used_space_option)) ;;
        --xtrace-file)
            must_be_writable_file "$2"
            xtrace_file="$2" ;;
        *)
            invalid_argument "$1" ;;
    esac
}

# Called immediately after all command line options have been parsed to
# read snapraid configuration file and initialize the arrays local to main()
# which track the configuration
setup_config() {
    must_be_writable_dir "$temp_dir" 'is TMPDIR set correctly?'
    check_dependencies "$my_snapper" "$my_snapraid"
    readonly my_snapper my_snapraid
    if version_is_at_least "$(get_snapper_version)" '0.6.0' ; then
        snapper_ls_quota_support=1
        if ((used_space_option == 0)) ; then
            snapper_ls_quota_disable=1
        fi
    fi
    check_config_file "$@"
    find_configs "$@"
    show_configs
    check_config "$@"
    if [[ "$use_snapshot_option" ]] ; then
        apply_use_snapshot_option "$use_snapshot_option"
    fi
    local i
    if [[ "$use_snapshot_all_option" ]] ; then
        for i in "${snapper_configs[@]}" ; do
            [[ "${use_snapshot[$i]-}" ]] ||
                use_snapshot[$i]="$use_snapshot_all_option"
        done
    fi
    apply_pre_post_options
    case $1 in
        check|pool|scrub|undochange)
            use_snapshot_default scrub ;;&
        cleanup)
            use_snapshot_all sync ;;&
        cleanup-all|touch)
            use_snapshot_all 0 ;;&
        config)
            use_snapshot_default last ;;&
        create|diff|?(d|diff-)sync)
            use_snapshot_default new ;;&
        fix)
            use_snapshot_fix "$@" ;;&
        resume)
            use_snapshot_default resume ;;&
        shell|snapper)
            use_snapshot_default '' ;;&
        !(cleanup-all|ls|list|snapper|touch))
            find_snapshots "$1" ;;&
        !(cleanup?(-all)|ls|list|shell|snapper|touch))
            use_snapshot_check "$1" ;;
    esac
}

show_configs() {
    ((verbose > 0)) || return 0
    local i
    echo 'Snapper configs found:'
    for i in "${snapper_configs[@]}" ; do
        printf -- '%s %s\n' "$i" "${snapper_subvols[$i]}"
    done
    echo
} >&2

show_temp_snapraid_conf() {
    ((verbose >= 0)) || return 0
    print_array "$@"
    cat < "$temp_config_file" && echo
} >&2

# Do a snapper ls in all configs, and if argument(s) are specified,
# additionally identify which snapshots we found with userdata
# key $snapper_userdata_key matching the arguments
snapper_ls() {
    local i j
    for i in "${snapper_configs[@]}" ; do
        printf -- '%s %s\n' "$i" "${snapper_subvols[$i]}"
        snapper_ls_wrapper "$i"
        for j in "$@" ; do
            printf -- 'Snapshots with userdata key %s=%s:\n' \
                "$snapper_userdata_key" "$j"
            snapper_ls_wrapper "$i" 'C' |
                parse_snapper_ls "$snapper_userdata_key" "$j" ' '
            echo
        done
        echo
    done
}

# Run snapper ls > /dev/null on config $1 to sync ACLs, using
# --disable-used-space option if supported by snapper version in use
snapper_ls_sync_acl() {
    LC_ALL=C "$my_snapper" -c "$1" \
        ls${snapper_ls_quota_support:+ --disable-used-space} > /dev/null ||
        error $E_NO_PERMISSION 'Failed to sync ACLs with snapper ls'
}

# Run snapper ls on config $1, using --disable-used-space option if supported
# by snapper version in use and if --used-space option wasn't specified
# if $2 is set, use LC_ALL=$2
snapper_ls_wrapper() {
    if [[ "${2-}" ]] ; then
        LC_ALL="$2" "$my_snapper" -c "$1" \
            ls${snapper_ls_quota_disable:+ --disable-used-space}
    else
        "$my_snapper" -c "$1" \
            ls${snapper_ls_quota_disable:+ --disable-used-space}
    fi
}

# Run snapper undochange in each snapper config to revert to the state at the
# time ${use_snapshot[$i]} was created, creating snapshots before and after
snapper_undochange() {
    local i
    local -i ret=0
    local -i snapper_ret
    local undochange_files=()
    local undochange_opts=()
    create_pre_post_snapshots undochange
    # ensure that -i option, if specified, appears before snapshots
    # and any other arguments specified (except --) appear after snapshots
    while (($# > 0)) ; do
        case $1 in
            --)
                shift
                break ;;
            -i|--input)
                if (($# > 1)) ; then
                    undochange_opts+=( "$1" "$2" )
                    shift 2
                else
                    undochange_files+=( "$1" )
                    shift
                fi ;;
            *)
                undochange_files+=( "$1" )
                shift ;;
        esac
    done
    undochange_files+=( "$@" )
    for i in "${snapper_configs[@]}" ; do
        if [[ "${use_snapshot[$i]}" = 0 ]] ; then
            continue
        else
            verbose_command_run "$my_snapper" -c "$i" undochange \
                "${undochange_opts[@]}" "${use_snapshot[$i]}..0" -- \
                "${undochange_files[@]}"
            snapper_ret=$?
            if ((snapper_ret != 0)) ; then
                ret=$snapper_ret
            fi
        fi
    done
    create_pre_post_snapshots undochange
    return $ret
}

# returns 0 if $2 is an argument to $1, and 1 if not
snapraid_opt_has_arg() {
    if (($# < 2)) ; then
        return 1
    fi
    case $1 in
        # snapraid long-form options that require arguments
        --count) ;&
        --error-limit) ;&
        --filter?(-disk)) ;&
        --gen-conf) ;&
        --import) ;&
        --log) ;&
        --older-than) ;&
        --percentage) ;&
        --plan) ;&
        --test-fmt) ;&
        --test-force-@(autosave|scrub)-at) ;&
        --test-import-content) ;&
        --test-io-cache) ;&
        --test-parity-limit) ;&
        --test-run) ;&
        # snapraid short-form options that require arguments
        -*(["$SNAPRAID_OPTS_NOARG"])["$SNAPRAID_OPTS_ARG"])
            return 0 ;;
    esac
    return 1
}

# Display a menu of snapshots for config $1 using snapper ls, and
# let the user pick which one to use
snapshot_menu() {
    if ((interactive < 0)) ; then
        error $E_SNAPSHOT_NOT_FOUND \
            'not displaying snapshot menu since --noninteractive'
    fi
    local choice
    printf -- '%s %s\n' "$1" "${snapper_subvols[$1]}"
    snapper_ls_wrapper "$1"
    while true ; do
        read -r -p 'Enter a snapshot (0 for none, n for new, q to quit): ' \
            choice
        case $choice in
            [Qq]?([Uu][Ii][Tt]))
                exit $E_INTERACTIVE_NO ;;
            [Nn]?([Ee][Ww]))
                new_snapshot "$1" "$2"
                break ;;
            +([0123456789]))
                if [[ "$choice" = 0 ]] ||
                       { snapper_ls_wrapper "$1" 'C' |
                             parse_snapper_ls |
                             grep -Fx "$choice" > /dev/null ; }
                then
                    use_snapshot[$1]="$choice"
                    break
                else
                    printf -- 'Snapshot %s not found\n' "$choice"
                fi ;;
            *)
                printf -- 'Invalid selection %s\n' "$choice" ;;
        esac
    done
    echo
}

#if snapshot not found for a config, prompt the user to choose a different one
snapshot_not_found() {
    printf -- '%s: Snapshot %s not found for config %s at %s\n' "$my_name" \
        "${use_snapshot_missing[$1]}" "$1" "${snapper_subvols[$1]}"
    snapshot_menu "$1" "$2"
} >&2

usage() {
    cat <<_EOF_
Usage: $my_name [options] <command> [arguments]

Arguments appearing after the command are passed through to snapraid, while
the following options appearing before the command are interpreted by
$my_name:

  -h, --help                    Show this help
  -V, --version                 Show version info
  -c, --conf FILE               Specify location of snapraid config file
                                (default $DEFAULT_CONFIG_FILE)
  -C, --cleanup ARG             Specify snapper cleanup algorithm to set for
                                any snapshots created (default none)
  -d, --description ARG         Specify snapper description to set for any
                                snapshots created
  -i, --interactive             Ask before running snapraid or any potentially
                                destructive snapper commands (when using the
                                cleanup(-all), snapper, or undochange commands)
  -q, --quiet                   Only show snapraid/snapper output and errors
  -s, --sync                    Pass the --sync option to snapper rm (when
                                using the cleanup(-all) command)
  -u, --use-snapshot-all ARG    Use one of the following arguments:
                                    diff  - Use last snapshot a diff was
                                            completed with
                                    last  - Use last snapshots created
                                    menu  - Select the snapshot to use
                                            interactively from a menu
                                    new   - Create new snapshots
                                    res   - Resume using snapshots from an
                                            interrupted sync, or last completed
                                            sync if more recent
                                    scrub - Same as res, unless a fix/touch was
                                            done more recently than sync, then
                                            use post-fix/touch snapshot
                                    sync  - Use last snapshots a successful
                                            sync was completed with
                                or specify the snapshot number (0 for the live
                                filesystem, following snapper syntax)
                                Default is:
                                    'new' for diff|dsync|sync
                                    'last' for config
                                    'scrub' for all other readonly commands
  -U, --use-snapshot ARG        Specify snapshots to use for specific snapper
                                configurations, using the snapper config name
                                followed by an equals sign. Multiple
                                configurations should be separated by commas,
                                e.g. 'config1=5,config2=last'. Overrides -u
  -v, --verbose                 Increase verbosity of output
  -x, --xtrace                  Enable bash xtrace
  -X, --debug                   Enable debugging output
  --debug-file FILE             File to save -X/--debug output to
  --no-pre-post ARG             Don't create pre/post snapshots for the
                                specified snapper configuration(s). Multiple
                                configurations should be separated by commas.
  --noninteractive              Never prompt the user on error, instead fail
  --pool-dir DIR                Create pool symlinks in DIR (defaults to
                                directory specified in snapraid config file)
  --pre-post ARG                Create pre/post snapshots only for the
                                specified snapper configuration(s). Multiple
                                configurations should be separated by commas.
  --snapper-configs ARG         Comma-separated list of snapper configs to
                                try matching with snapraid.conf file instead
                                of looking in $DEFAULT_SNAPPER_CONFIG_DIR.
                                Can be specified multiple times.
  --snapper-configs-file FILE   Newline-separated list of snapper configs to
                                try matching with snapraid.conf file instead
                                of looking in $DEFAULT_SNAPPER_CONFIG_DIR.
                                Can be specified multiple times.
  --snapper-path PATH           Path to the snapper executable (defaults to
                                first found in PATH)
  --snapper-userdata ARG        Specify snapper userdata to set for any
                                snapshots created in addition to the
                                $my_name attribute, which is set by
                                default and cannot be changed. Argument should
                                be in key=value format accepted by snapper,
                                with multiple keys separated by commas (e.g.
                                key1=value1,key2=value2)
  --snapraid-path PATH          Path to the snapraid executable (defaults to
                                first found in PATH)
  --used-space                  Don't pass the --disable-used-space option to
                                snapper ls.
  --xtrace-file FILE            File to save -x/--xtrace output to

  NOTE: The snapraid -c/--conf option will not work unless placed before the
  command, allowing it to be interpreted as a $my_name option. Snapraid
  will be run with a temporary configuration file, generated using whatever
  snapraid.conf file is specified using the $my_name -c/--conf option
  ($DEFAULT_CONFIG_FILE by default).

Commands are either one of the following snapraid commands:
  'check'|'diff'|'pool'|'scrub'|'sync':
        Run the snapraid command given, replacing data drives in snapraid
        config file that have corresponding snapper configs with read-only
        snapshots.
  'fix'|'touch':
        Run the snapraid command given, creating a set of pre/post snapshots
        before and after (for fix, if the snapraid -d/--filter-disk option is
        specified, create pre/post snapshots only for the specified disk(s),
        and use the 'scrub' snapshot for the rest (see -u option above)).

or one of the following $my_name specific commands:
  'config':
        Show the modified snapraid config file that would be used, but don't
        actually run snapraid.
  'create':
        Create a new snapshot for all snapper configs corresponding to data
        drives found in snapraid config file.
  'cleanup':
        Delete all snapshots created by $my_name before the last one a
        successful sync has been completed with.
  'cleanup-all':
        Delete all snapshots created by $my_name.
  'dsync'|'diff-sync':
        Create a new snapshot for all snapper configs found in snapraid config
        file, do a snapraid diff, then sync. Implies --interactive option for
        the sync operation. Uses --force-empty for the sync operation, since
        the diff must be manually approved anyway.
  'list'|'ls':
        Run snapper ls for all snapper configs found in snapraid config file.
        If an argument is given, also list which snapshots in each config were
        identified as having snapper userdata key equal to the argument.
  'resume':
        Resume an interrupted sync, using the same set of snapshots.
  'shell':
        Start an interactive bash session in $my_name context. Useful for
        testing and debugging.
  'snapper':
        Run the given snapper command in all configs, unless they are disabled
        by --use-snapshot exampleconfig=0 - for example:
           $my_name -U foo=0 snapper get-config
        would run
           snapper -c "\$i" get-config
        substituting "\$i" for each snapper config matching the snapraid.conf
        file, except foo.
  'undochange':
        Use snapper undochange to revert the array to the state it was in at
        the time of the last successful sync (or another snapshot if the -u or
        -U option is specified), creating pre/post snapshots. Arguments are
        passed through to snapper undochange, including the snapper undochange
        -i option.

Environment variables:
  DEBUG_FD -
        File descriptor to send debug output to if -X/--debug is used. For
        example, running "DEBUG_FD=3 $my_name -Xh 3>/tmp/debug" would
        send debug output to /tmp/debug while displaying only the normal output
        of "$my_name -h" on the console. If unset, the default behavior
        is to send debug output to stderr.
  SNAPPER_CONFIG_DIR -
        Location of snapper config files. If unset, it defaults to
        $DEFAULT_SNAPPER_CONFIG_DIR.
  SNAPRAID_CONFIG_FILE -
        Default location of the snapraid.conf file if -c/--conf option is not
        used. If unset, it defaults to $DEFAULT_CONFIG_FILE.
  SNAPRAID_USERDATA_KEY -
        Snapper userdata key that is used to track snapshots. If unset, it
        defaults to $DEFAULT_USERDATA_KEY.
  TMPDIR -
        Directory to create temporary snapraid.conf file in. If unset, it
        defaults to $DEFAULT_TMPDIR.
_EOF_
}

# Add key/value pairs from $1 to snapper_userdata, unless key is
# $snapper_userdata_key
use_snapper_userdata() {
    local key value i
    local -a args
    IFS=',' read -r -a args <<< "$1"
    for i in "${args[@]}" ; do
        IFS='=' read -r key value <<< "$i"
        if [[ "$key" = "$snapper_userdata_key" ]] ; then
            error $E_INVALID_ARGUMENT \
                "Cannot set reserved userdata key $key"
        else
            snapper_userdata+="$key=$value,"
        fi
    done
}

# Set use_snapshot to $1 for all configs, overriding any previous values
use_snapshot_all() {
    local i
    for i in "${snapper_configs[@]}" ; do
        use_snapshot[$i]="$1"
    done
}

# If use_snapshot[$i] is the empty string for any snapper config, indicating
# that find_snapshots did not find a match, handle the error
use_snapshot_check() {
    local i
    for i in "${snapper_configs[@]}" ; do
        [[ "${use_snapshot[$i]}" ]] || snapshot_not_found "$i" "$1"
    done
}

# For any configs where use_snapshot is undefined or empty, set it to $1
use_snapshot_default() {
    local i
    for i in "${snapper_configs[@]}" ; do
        if [[ -z "${use_snapshot[$i]-}" ]] ; then
            use_snapshot[$i]="$1"
        fi
    done
}

# When running a fix operation, parse the -d/--filter-disk snapraid option and
# set ${use_snapshot[@]} accordingly
use_snapshot_fix() {
    if [[ "${1-}" = fix ]] ; then
        shift
    else
        error $E_INTERNAL_ERROR \
            'use_snapshot_fix() called with unexpected arguments:' "$@"
    fi
    local disk snapper_config_name
    local -i disks_found=0
    while (($# > 0)) ; do
        disk=
        case $1 in
            --)
                break ;;
            --filter-disk=*)
                disk="${1#--filter-disk=}"
                shift ;;
            --filter-disk|-*(["$SNAPRAID_OPTS_NOARG"])d)
                option_requires_argument "$@"
                disk="$2"
                shift 2 ;;
            -*(["$SNAPRAID_OPTS_NOARG"])d*)
                disk="${1#*(["$SNAPRAID_OPTS_NOARG"])d}"
                shift ;;
            -*)
                if snapraid_opt_has_arg "$@" ; then
                    shift 2
                else
                    shift
                fi ;;
            *)
                error $E_INVALID_ARGUMENT \
                    'The following could not be interpreted as valid' \
                    'snapraid arguments:' $'\n' "$@" ;;
        esac
        if [[ "$disk" ]] ; then
            ((++disks_found))
            snapper_config_name="$(get_snapper_config_name "$disk")"
            if [[ "$snapper_config_name" ]] ; then
                # for disks we are fixing, use the live filesystem
                if ! [[ "${use_snapshot[$snapper_config_name]-}" =~ ^0?$ ]]
                then
                    error $E_INVALID_ARGUMENT \
                        "Must use live filesystem for $snapper_config_name" \
                        'since it is being fixed, but' \
                        "${use_snapshot[$snapper_config_name]} was specified"
                fi
                use_snapshot[$snapper_config_name]=0
            fi
        fi
    done
    if ((disks_found > 0)) ; then
        # for disks we are not fixing, use the 'scrub' snapshot
        use_snapshot_default scrub
    else
        # snapraid fix --filter-disk option was not specified
        # snapraid will try to fix all disks, so use the live filesystem
        use_snapshot_default 0
    fi
}

verbose() {
    ((verbose > 0)) || return 0
    print_array "$@"
}

verbose_command() {
    if ((interactive > 0)) ; then
        interactive_ask "$@"
    elif ((verbose >= 0)) ; then
        print_array "$@"
    fi
} >&2

verbose_command_run() {
    verbose_command "$@"
    "$@" && true
}

# compares version numbers specified in $1 and $2
# returns 0 if $1 >= $2
version_is_at_least() {
    local -i i
    local -a ver1 ver2
    IFS='.' read -r -a ver1 <<< "$1"
    IFS='.' read -r -a ver2 <<< "$2"
    # if ver1 contains fewer components than ver2, pad with zeroes
    for ((i=${#ver1[@]};i<${#ver2[@]};i++)) ; do
        ver1[i]=0
    done
    # ensure version components are suitable for numeric comparison
    for ((i=0;i<${#ver1[@]};i++)) ; do
        ver1[i]="${ver1[i]##*([^0123456789])}"
        ver1[i]="${ver1[i]%%[^0123456789]*}"
    done
    # iterate through version components until we find the first difference
    for ((i=0;i<${#ver2[@]};i++)) ; do
        if ((ver1[i] > ver2[i])) ; then
            return 0
        elif ((ver1[i] < ver2[i])) ; then
            return 1
        fi
    done
    # if we reach this point, ver1 and ver2 are the same
    # (possibly with ver1 having extra components)
    return 0
}

warn() {
    ((verbose >= 0)) || return 0
    printf -- '%s: WARNING: ' "$my_name"
    print_array "$@"
} >&2

warn_if_root() {
    [[ "$EUID" = 0 ]] || return 0
    warn "Running $my_name as root is not recommended"
    warn '(nor is running snapraid as root)'
}

if [[ "$0" = "${BASH_SOURCE[0]}" ]] ; then
    main "$@"
fi