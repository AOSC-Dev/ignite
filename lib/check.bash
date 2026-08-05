check_exe() {
    command -v "$1" >/dev/null 2>&1
}

# We don't have a real package manager, so we check for "virtual" packages

# $1: virtual package name
# $2: command to check for
# $3: (optional) URL to install instructions
_check_vpkg_simple() {
    if ! check_exe "$2"; then
        if [ -n "$3" ]; then
            abdie "Please install $1 on your system. See $3 for instructions."
        else
            abdie "Please install $1 on your system."
        fi
    fi
}
_check_package() {
    local pkg="$1"
    local cmd="check_vpkg_$pkg"
    if ! declare -f "$cmd" >/dev/null 2>&1; then
        abdie "Unknown package '$pkg'."
    fi
    abinfo "Checking for package '$pkg' ..."
    "$cmd"
}
check_packages() {
    local pkg
    for pkg in "$@"; do
        _check_package "$pkg"
    done
}

# Following are the checks for the virtual packages we support/need to use.

check_vpkg_nasm() {
    _check_vpkg_simple "nasm" "nasm"
}

check_vpkg_jwasm() {
    _check_vpkg_simple "jwasm" "jwasm"
}

check_vpkg_make() {
    _check_vpkg_simple "make" "make"
}

check_vpkg_git() {
    _check_vpkg_simple "git" "git"
}

check_vpkg_gcc() {
    _check_vpkg_simple "gcc" "gcc"
}

check_vpkg_upx() {
    _check_vpkg_simple "upx" "upx"
}

check_vpkg_ia16-gcc() {
    _check_vpkg_simple "ia16-gcc" "ia16-gcc" "https://github.com/tkchia/gcc-ia16"
}

check_vpkg_djgpp-gcc() {
    _check_vpkg_simple "djgpp-gcc" "i586-pc-msdosdjgpp-gcc" "https://www.delorie.com/djgpp/"
}

check_vpkg_open-watcom() {
    # Open Watcom is a bit more complicated, since it has a custom installer and environment variables.
    local _wpath
    if check_exe "wcc" && check_exe "wcl" && check_exe "wlink"; then
        # We need to set the $WATCOM variable for the build scripts to work properly.
        if [ -z "$WATCOM" ]; then
            _wpath="$(readlink -f "$(command -v wcc)")"
            _wpath="$(dirname "$_wpath")/.."
            _wpath="$(readlink -f "$_wpath")"
            if ! test -f "$_wpath/lh/stddef.h"; then
                abdie "Failed to auto-detect the Open Watcom installation path. Please set the WATCOM environment variable manually."
            fi
            export WATCOM="$_wpath"
        fi
        return 0
    else
        if test -d "$WATCOM" && test -x "$WATCOM/binl64/wcc"; then
            # set the PATH variable to include the Open Watcom binaries.
            export PATH="$PATH:$WATCOM/binl64"
            return 0
        else
            abdie "Please install Open Watcom on your system. See https://open-watcom.github.io/ for instructions."
        fi
    fi
}