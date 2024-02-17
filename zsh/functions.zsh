# Thanks to https://github.com/ardubev16

function pathPrepend() {
    # Only adds to the path if it's not already there
    if ! echo "$PATH" | grep -E -q "(^|:)$1($|:)"; then
        PATH=$1:$PATH
    fi
}

function pathAppend() {
    # Only adds to the path if it's not already there
    if ! echo "$PATH" | grep -E -q "(^|:)$1($|:)"; then
        PATH=$PATH:$1
    fi
}
