_fetch_source_wget() {
    local url="$1"
    local dest="$2"

    wget -c -O "$dest" "$url"
}
_fetch_source_git() {
    local url="$1"
    local dest="$2"

    if [ -d "$dest" ]; then
        abinfo "Updating existing git repository at '$dest' ..."
        git --git-dir="$dest" fetch --all
        return
    fi
    git clone --bare "$url" "$dest"
}

# $1: source path
# $2: checksum type (md5, sha1, sha256, sha384, sha512)
# $3: checksum value
check_checksum() {
    local src="$1"
    local checksum_type="$2"
    local checksum_value="$3"

    case "$checksum_type" in
        md5|sha1|sha256|sha384|sha512)
            echo "$checksum_value  $src" | "$checksum_type"sum -c -
            ;;
        *)
            abdie "Unsupported checksum type '$checksum_type'"
            ;;
    esac
}

# $0: source type
# $1: source URL
# $2: destination path
# $3 -> $n: (optional) options to pass to the fetcher
fetch_source() {
    local type="$1"
    local url="$2"
    local dest="$3"
    shift 3

    case "$type" in
        tbl|file)
            _fetch_source_wget "$url" "$dest" "$@"
            ;;
        git)
            _fetch_source_git "$url" "$dest" "$@"
            ;;
        *)
            abdie "Unsupported source type '$type'"
            ;;
    esac
}

_process_source_file() {
    local src="$1"
    local dest="$2"

    cp --reflink=auto -v "$src" "$dest"
}

_process_source_tbl() {
    local src="$1"
    local dest="$2"

    mkdir -p "$dest"
    bsdtar -xf "$src" -C "$dest"
}

_process_source_git() {
    local src="$1"
    local dest="$2"
    local opts=()
    local submodule=0
    local copy_repo=0
    shift 2

    while [ $# -gt 0 ]; do
        case "$1" in
            submodule=*)
                case "$1" in
                    submodule=true) submodule=1 ;;
                    submodule=recursive) opts+=("--recurse-submodules") ;;
                    submodule=off) ;;
                    *)
                        abdie "Unsupported option '$1' for git source processor"
                        ;;
                esac
                shift
                ;;
            commit=*)
                opts+=("${1#*=}")
                shift
                ;;
            copy-repo)
                case "$1" in
                    copy-repo=true) copy_repo=1 ;;
                    copy-repo=false) ;;
                    *)
                        abdie "Unsupported option '$1' for git source processor"
                        ;;
                esac
                shift
                ;;
            *)
                abdie "Unsupported option '$1' for git source processor"
                ;;
        esac
    done

    git --git-dir="$src" --work-tree="$dest" checkout -f "${opts[@]}"

    if [ "$submodule" -eq 1 ]; then
        git --git-dir="$src" --work-tree="$dest" submodule update --init
    fi
    if [ "$copy_repo" -eq 1 ]; then
        cp -a "$src" "$dest/.git"
        sed -i 's|bare = true|bare = false|' "$dest/.git/config"
    fi
}

# $0: source type
# $1: downloaded source path
# $2: destination path (build path)
# $3 -> $n: (optional) options to pass to the processor
process_source() {
    local type="$1"
    local src="$2"
    local dest="$3"
    shift 3

    case "$type" in
        tbl|file|git)
            _process_source_"$type" "$src" "$dest" "$@"
            ;;
        *)
            abdie "Unsupported source type '$type'"
            ;;
    esac
}