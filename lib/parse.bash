# $1: package path
# $2: no dependency check (optional)
_load_defines_file() {
    source "$1/defines"
    local no_dep_check="${2:-}"
    if [ -z "$VER" ]; then
        abdie "Package '$1' does not define a version number (VER)."
    fi
    if [ -z "$PKGNAME" ]; then
        abdie "Package '$1' does not define a package name (PKGNAME)."
    fi
    if [ -n "$PKGDEP" ]; then
        abdie "Package '$1' defines runtime dependencies (PKGDEP), which is not supported."
    fi
    if [ -z "$no_dep_check" ] && declare -p BUILDDEP >/dev/null 2>&1; then
        check_packages "${BUILDDEP[@]}"
    fi
    if ! declare -f build >/dev/null 2>&1; then
        abdie "Package '$1' does not define a build function."
    fi
}

# $1: package path
# $2: no dependency check (optional)
get_package_slug() {
    _load_defines_file "$@"
    echo "${PKGNAME}-${VER}"
}
