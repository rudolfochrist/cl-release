#!/bin/sh
#set -xve

# UI
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
BOLD=$(tput bold)
NORM=$(tput sgr0)

# helpers

assert_value ()
{
    if [ -z "$2" ] || [ "${2:0:1}" = "-" ]; then
        echo "Error: Argument for $1 is missing" >&2
        exit 1
    fi
}

usage ()
{
    cat <<EOF
Usage: $(basename $0) [options] SYSTEM VERSION

Options:
  -cl, --lisp-implementation            Specify the lisp implemntation. Defaults
                                        to $LISP.
  -f, --force                           Force running the script, regardless if a release is active.
  -v, --version                         Show version.
  -h, --help                            Show help.
EOF
}

# Parsing args

VERSION=0.1.0
LISP="sbcl --non-interactive"
FORCE=0

PARAMS=""

while (( "$#" )); do
    case "$1" in
        -cl|--lisp-implementation)
            assert_value "$1" "$2"
            LISP=$2
            shift 2
            ;;
        -f | --force)
            FORCE=1
            shift
            ;;
        -v|--version)
            echo "$(basename $0) v$VERSION"
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*|--*)
            echo "Error: Unsupported flag $1" >&2
            exit 1
            ;;
        *)
            PARAMS+="$1 "
            shift
            ;;
    esac
done
# set positional arguments in their proper place
eval set -- "$PARAMS"

assert_value "SYSTEM" "$1"
assert_value "VERSION" "$2"

SYSTEM=$1
RELEASE_VERSION=$2

# Program

# check if system available
if [ ! -e "$SYSTEM.asd" ]; then
    echo "Can't find system $SYSTEM." >&2
    exit 1
fi

# check if clean
if [ "$FORCE" = 0 ] && [ -e "release-prepare" ]; then
    echo "Release in progress. Please run release-perform or distclean the project." >&2
    exit 1
fi

echo "${BOLD}Preparing release $SYSTEM v$RELEASE_VERSION${NORM}"

cat > release-prepare <<EOF
SYSTEM=$SYSTEM
RELEASE_VERSION=$RELEASE_VERSION
EOF

echo "${BOLD}Loading system and running tests${NORM}"

SHELLP=1 $LISP --eval "(require 'asdf)" \
      --eval "(push *default-pathname-defaults* asdf:*central-registry*)" \
      --eval "(asdf:load-system \"$SYSTEM\")" \
      --eval "(asdf:test-system \"$SYSTEM\")"

if [ $? -ne 0 ]; then
    echo "${BOLD}${RED}ERROR.${NC}${NORM}"
else
    echo "${BOLD}${GREEN}FINISHED${NC}${NORM}"
fi
