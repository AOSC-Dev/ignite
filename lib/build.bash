shopt -s nullglob

# $1: package path
_load_defines_file() {
    source "$1/defines"
    if [ -z "$VER" ]; then
        abdie "Package '$1' does not define a version number (VER)."
    fi
    if [ -z "$PKGNAME" ]; then
        abdie "Package '$1' does not define a package name (PKGNAME)."
    fi
    if [ -n "$PKGDEP" ]; then
        abdie "Package '$1' defines runtime dependencies (PKGDEP), which is not supported."
    fi
    if ! declare -f build >/dev/null 2>&1; then
        abdie "Package '$1' does not define a build function."
    fi
    if declare -p BUILDDEP >/dev/null 2>&1; then
        check_packages "${BUILDDEP[@]}"
    fi
}

# $1: source URI (from sources file)
# $2: checksum entry
# $3: source depot path
# $4: build directory path
_do_single_source_checked() {
    # parse the URI
    local src_uri_parts=()
    local dst_path=""
    local pkg_slug="${PKGNAME}-${VER}"
    local fetch_opts=()
    local src_url=''

    mapfile -t src_uri_parts <<< "${1//::/$'\n'}"

    if [ "${#src_uri_parts[@]}" -lt 2 ]; then
        abdie "Ignite does not support auto-detection, please specify the source type explicitly."
    elif [ "${#src_uri_parts[@]}" -gt 3 ]; then
        abdie "Invalid source URI '${1}': too many separators."
    else
        dst_path="$3/${pkg_slug}/$(basename "${src_uri_parts[-1]}")"
        mkdir -p "$(dirname "$dst_path")"
        src_url="${src_uri_parts[-1]}"
        if [ "${#src_uri_parts[@]}" -eq 3 ]; then
            mapfile -t fetch_opts <<< "${src_uri_parts[1]//;/$'\n'}"
        fi
    fi
    fetch_source "${src_uri_parts[0]}" "${src_url}" "$dst_path" "${fetch_opts[@]}"
    if [[ "$2" != 'SKIP' ]]; then
        check_checksum "$dst_path" "${2%%::*}" "${2#*::}"
    fi
    export SRCDIR="$4/${pkg_slug}"
    mkdir -p "${SRCDIR}"
    process_source "${src_uri_parts[0]}" "$dst_path" "${SRCDIR}" "${fetch_opts[@]}"
}

# $1: package path
# $2: source depot path
# $3: build directory path
fetch_and_process_sources() {
    local pkg="$1"
    local depot="$2"
    _load_defines_file "$pkg"
    for ((idx=0; idx<${#SRCS[@]}; idx++)); do
        abinfo "[$PKGNAME] [$((idx+1))/${#SRCS[@]}] Fetching source ..."
        _do_single_source_checked "${SRCS[$idx]}" "${CHKSUMS[$idx]}" "$depot" "$3"
    done
}

_apply_patches() {
    if [ ! -d "${PROJECT_DIR}/patches" ]; then
        abinfo "[$PKGNAME] No patches to apply."
        return
    fi
    for i in "${PROJECT_DIR}"/patches/*.patch; do
        abinfo "[$PKGNAME] Applying patch: $i"
        patch -Np1 -i "$i"
    done
    for i in "${PROJECT_DIR}"/patches/*.dospatch; do
        abinfo "[$PKGNAME] Applying CRLF patch: $i"
        unix2dos "$i"
        patch -Np1 --binary -i "$i"
    done
}

# $1: package path
# $2: build directory path
run_build() {
    local pkg_slug="${PKGNAME}-${VER}"
    local wd="$2/${pkg_slug}/${SUBDIR:-}"
    PROJECT_DIR="$(readlink -f "$1")"
    export PROJECT_DIR

    echo "[$PKGNAME] Running build in '$wd' ..."
    mkdir -pv "$wd"
    cd "$wd" || abdie "Failed to change directory to '$wd'"
    _apply_patches
    abinfo "[$PKGNAME] Running build function ..."
    build
}

# $1: package path
# $2: source depot path
# $3: build directory path
# $4: staging directory path
build_one_package() {
    fetch_and_process_sources "$1" "$2" "$3"
    export PKGDIR="$4/${PKGNAME}-${VER}"
    mkdir -pv "$PKGDIR"
    run_build "$1" "$3"
    abinfo "[$PKGNAME] Build completed successfully. Artifacts in: $PKGDIR"
}