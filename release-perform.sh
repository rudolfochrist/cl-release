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

verify_exit ()
{
    if [ "$?" -gt 0 ] ;then
        echo "${BOLD}${RED}Error.${NC}${NORM}"
        exit 1
    fi
}

usage ()
{
    cat <<EOF
Usage: $(basename $0) [options]

Options:
  --no-push                              Don't push to remote repository
  --skip-readme                          Don't run make's README.txt target
  -n, --next-dev-version                 Specify the next development version
  -v, --version                          Show version.
  -h, --help                             Show help.
EOF
}

# Parsing args

VERSION=0.7.0
PUSH=1
NEXT_DEV_VERSION=""

PARAMS=""

while (( "$#" )); do
    case "$1" in
        --no-push)
            PUSH=0
            shift
            ;;
        --skip-readme)
            skip_readme="t"
            shift
            ;;
        -n|--next-dev-version)
            assert_value "$1" "$2"
            NEXT_DEV_VERSION=$2
            shift 2
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

# check for uncommited changes
if [ -n "$(git diff --name-only)" ] || [ -n "$(git diff --name-only --cached)" ]; then
    echo "There are uncommited changes." >&2
    exit 1
fi

if [ ! -e "cl-release.properties" ]; then
    echo "Please run release-prepare to prepare a release." >&2
    exit 1
fi
source "cl-release.properties"

echo "${BOLD}Performing release for $SYSTEM-$RELEASE_VERSION${NORM}"
echo "$RELEASE_VERSION" > version

if [ "$skip_readme" != "t" ]; then
    echo "${BOLD}Make README...${NORM}"
    make README.txt
    verify_exit
fi 

git add version
git commit -m "Release v$RELEASE_VERSION"
verify_exit

echo "${BOLD}Tagging release...${NORM}"
git tag -a "$RELEASE_VERSION" -m "Release v$RELEASE_VERSION"
verify_exit

# increment the last segment of the version string and append 0 for development
if [ -n "$NEXT_DEV_VERSION"]; then
    IFS='.' read -ra v_parts <<< "$RELEASE_VERSION"
    last_part=${v_parts[${#v_parts[@]}-1]}
    v_parts[${#v_parts[@]}-1]=$(( $last_part + 1))
    joined=$(echo "${v_parts[@]}" | tr ' ' '.')
    NEXT_DEV_VERSION="$joined.0"
fi


echo "${BOLD}Set development version to $NEXT_DEV_VERSION...${NORM}"
echo "$NEXT_DEV_VERSION" > version
git add version
git commit -m 'Start next development iteration'
verify_exit

if [ "$PUSH" -gt 0 ]; then
    echo "${BOLD}Pushing repository...${NORM}"
    git push
    verify_exit
    git push --tags
    verify_exit
fi

rm cl-release.properties
verify_exit
echo "${BOLD}${GREEN}Finished.${NC}${NORM}"
