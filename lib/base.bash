#!/bin/bash

set -e

# Output formatters.
abwarn() { echo -e "[\e[33mWARN\e[0m] : \e[1m$*\e[0m"; }
aberr()  { echo -e "[\e[31mERROR\e[0m]: \e[1m$*\e[0m"; IGNITE_ERROR=1; }
abinfo() { echo -e "[\e[96mINFO\e[0m] : \e[1m$*\e[0m"; }

# see if the given string evaluates into true.
bool() {
	local v="$1"
	[ -z "$v" ] && return 1
	[[ "${v,,}" =~ y|yes|1|true ]]
}

# If the terminal allows, set a title.
set_title() {
	if [ "${TERM//@(xterm|tmux|ghostty|kitty)/}" == "$TERM" ] ; then
		return
	fi
	echo -ne "\e]0;ignite: $*\007\r"
}

abdie() {
	echo -e "[\e[31mERROR\e[0m]: \e[1m$*\e[0m"
	set_title "Failed at $PKGNAME"
	exit 1
}

set_trap() {
	set -e
	trap 'abdie "Failed to build ‘$PKGNAME-$PKGVER’"' ERR
}