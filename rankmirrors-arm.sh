#!/bin/bash
#   rankmirrors-arm : rank archlinuxarm mirrors using rankmirrors utility
#
#   Copyright (c) 2018 Martin Födinger <martin@foedinger.ml>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

declare -r myname='rankmirrors-arm'
declare -r myver='1.0'

pacmirrorlist=${PACMIRRORLIST:-/etc/pacman.d/mirrorlist}

declare -i USE_PACMAN=0 USE_GET=0 USE_FILE=0 OUTPUTONLY=0

usage() {
  cat <<EOF
${myname} v${myver}
Rank archlinuxarm mirrors using rankmirrors utility.

Usage: $myname [-p | -g | -f MIRRORLIST] [-n | -m] [-o]
General Options:
  -o/--output          do not overwrite pacman mirrorlist, only show generated mirrorlist

Source Options:        select one (default: --pacman)
  -p/--pacman          use the current pacman mirrorlist
  -g/--get             get the current mirrorlist from archlinuxarm's pacman-mirrorlist sources
  -f/--file            use the specified MIRRORFILE

Rankmirrors Options:   passed on to rankmirrors tool
  -n NUM               number of servers to output, 0 for all
  -m/--max-time NUM    specify a ranking operation timeout, can be decimal number

Environment Variables:
  PACMIRRORLIST        override pacman mirrorlist path (default: /etc/pacman.d/mirrorlist)

Example: $myname --pacman -n 6 --output
Example: PACMIRRORLIST="/etc/pacman.d/local_mirrorlist" $myname
EOF
}

version() {
  printf "%s %s\n" "$myname" "$myver"
  echo 'Copyright (C) 2018 Martin Födinger <martin@foedinger.ml>'
  echo
  echo "This is free software; see the source for copying conditions."
  echo "There is NO WARRANTY, to the extent permitted by law."
}

msg() {
	(( QUIET )) && return
	local mesg=$1; shift
	printf "${GREEN}==>${ALL_OFF}${BOLD} ${mesg}${ALL_OFF}\n" "$@" >&1
}

error() {
  local mesg=$1; shift
	printf "${RED}==> $(gettext "ERROR:")${ALL_OFF}${BOLD} ${mesg}${ALL_OFF}\n" "$@" >&2
}

strip_content() {
  (( OUTPUTONLY )) || msg "Stripping unneeded content from mirrorlist"
  #delete blank lines, uncomment all Servers, remove every line not starting with Server =
  sed '/^\s*$/d; s/^# Server/Server/; /^Server = /!d' $1 > /tmp/mirrorlist.tmp
}

# prefer terminal safe colored and bold text when tput is supported
if tput setaf 0 &>/dev/null; then
  ALL_OFF="$(tput sgr0)"
	BOLD="$(tput bold)"
	BLUE="${BOLD}$(tput setaf 4)"
	GREEN="${BOLD}$(tput setaf 2)"
	RED="${BOLD}$(tput setaf 1)"
	YELLOW="${BOLD}$(tput setaf 3)"
else
	ALL_OFF="\e[1;0m"
	BOLD="\e[1;1m"
	BLUE="${BOLD}\e[1;34m"
	GREEN="${BOLD}\e[1;32m"
	RED="${BOLD}\e[1;31m"
	YELLOW="${BOLD}\e[1;33m"
fi
readonly ALL_OFF BOLD BLUE GREEN RED YELLOW

#argument passing
while [[ -n "$1" ]]; do
  case "$1" in
    -p|--pacman)
      USE_PACMAN=1;;
    -g|--get)
      USE_GET=1;;
    -f|--file)
      USE_FILE=1;
      [[ $2 ]] || error "Must specify Mirrorlist when using -f/--file";
      MIRRORFILE="$2"; shift;;
    -o|--output)
      OUTPUTONLY=1;;
    -n)
      RM_MAXSERVERS="-n $2"; shift;;
    -m|--max-time)
      RM_MAXTIME="-m $2"; shift;;
    -V|--version)
      version; exit 0;;
    -h|--help)
      usage; exit 0;;
    *)
      usage; exit 1;;
  esac
  shift
done

case $(( USE_PACMAN + USE_GET + USE_FILE )) in
  0) USE_PACMAN=1;; #set default source option
  [^1]) error "Only one source option may be used at a time."
    usage; exit 1;;
esac

(( OUTPUTONLY )) || msg "Retrieving source mirrorlist"
#write mirrors to /tmp/mirrorlist.tmp using strip_content
if (( USE_PACMAN )); then
  strip_content $pacmirrorlist
elif (( USE_GET )); then
  if wget https://raw.githubusercontent.com/archlinuxarm/PKGBUILDs/master/core/pacman-mirrorlist/mirrorlist -O /tmp/mirrorlist.inet.tmp; then
    strip_content /tmp/mirrorlist.inet.tmp
  else
    error "wget command failed!"
  fi
elif (( USE_FILE )); then
  strip_content $MIRRORFILE
fi

if (( OUTPUTONLY )); then
  rankmirrors $RM_MAXSERVERS $RM_MAXTIME /tmp/mirrorlist.tmp
else
  cp $pacmirrorlist $pacmirrorlist.bckp
  rankmirrors $RM_MAXSERVERS $RM_MAXTIME /tmp/mirrorlist.tmp > $pacmirrorlist
  msg "Replaced Pacman's mirrorlist with new one!"
fi
