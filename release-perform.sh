#!/bin/bash

# UI
BOLD=$(tput bold)
NORM=$(tput sgr0)

# helpers

assert_value ()
{
    if [[ -z "$2" || "${2:0:1}" = "-" ]]; then
        echo "Error: Argument for $1 is missing" >&2
        exit 1
    fi
}

print_error_and_exit ()
{
    echo "${BOLD}${1}${NORM}"
    exit "${2:-1}"
}

usage ()
{
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --no-push                              Don't push to remote repository
  -n, --next-dev-version                 Specify the next development version
  -v, --version                          Show version.
  -h, --help                             Show help.
EOF
}

# Parsing args

VERSION=1.4.0
PUSH=1
NEXT_DEV_VERSION=""

PARAMS=""

while (( "$#" )); do
    case "$1" in
        --no-push)
            PUSH=0
            shift
            ;;
        -n|--next-dev-version)
            assert_value "$1" "$2"
            NEXT_DEV_VERSION=$2
            shift 2
            ;;
        -v|--version)
            echo "$(basename "$0") v$VERSION"
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
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

if [[ ! -e "cl-release.properties" ]]; then
    echo "Please run release-prepare to prepare a release." >&2
    exit 1
fi

# shellcheck source=/dev/null
source "cl-release.properties"

echo "${BOLD}Performing release for $SYSTEM-$RELEASE_VERSION${NORM}"

# only add files that are already tracked. We don't want to commit the
# cl-release.properties.
if [[ -n "$(git status -uno --short)" ]]; then
    git add -u
    if ! git commit -m "Release v$RELEASE_VERSION"; then
        print_error_and_exit "Cannot commit to git."
    fi
fi

echo "${BOLD}Tagging release...${NORM}"
if ! git tag -a "$RELEASE_VERSION" -m "Release v$RELEASE_VERSION"; then
    print_error_and_exit "Cannot create git tag ${RELEASE_VERSION}."
fi

# increment the last segment of the version string and append 0 for
# development
if [[ -z "$NEXT_DEV_VERSION" ]]; then
    IFS='.' read -ra v_parts <<< "$RELEASE_VERSION"
    last_part=${v_parts[${#v_parts[@]}-1]}
    v_parts[${#v_parts[@]}-1]=$(( last_part + 1))
    joined=$(echo "${v_parts[@]}" | tr ' ' '.')
    NEXT_DEV_VERSION="$joined.0"
fi


echo "${BOLD}Set development version to $NEXT_DEV_VERSION...${NORM}"
echo "$NEXT_DEV_VERSION" > version
git add version
if ! git commit -m 'Start next development iteration'; then
    print_error_and_exit "Cannot commit next development iteration."
fi

if [[ "$PUSH" -gt 0 ]]; then
    echo "${BOLD}Pushing repository...${NORM}"
    if ! git push; then
        print_error_and_exit "Git push failed."
    fi
    if ! git push --tags; then
        print_error_and_exit "Git push tags failed."
    fi
fi

rm cl-release.properties
echo "${BOLD}Finished.${NORM}"
