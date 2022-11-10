#!/usr/bin/env bash

set -euo pipefail

BASEDIR=$(dirname "${BASH_SOURCE[0]}")
RFC_DIR=${RFC_DIR:-${BASEDIR}/../docs/rfcs}
ADR_DIR=${ADR_DIR:-${BASEDIR}/../docs/adrs}

function update-toc() {
    MARKER=$1
    DIR=$2
    PATTERN=$3
    FILE=$4
    RELDIR=$5

    CONTENT="<!-- $MARKER -->\n\n"

    for match in "${DIR}"/${PATTERN} ; do
        TITLE=$(grep '^# ' "${match}${FILE}" | head -1)
        TITLE=${TITLE### }
        TITLE=${TITLE%% }
        CONTENT="${CONTENT}- [${TITLE}](${RELDIR}/$(basename "${match}"))\n"
    done

    CONTENT="${CONTENT}\n<!-- /${MARKER} -->"

    sed -i '/^<!-- '"${MARKER}"' -->$/,/^<!-- \/'"${MARKER}"' -->$/c'\\"${CONTENT}" "${BASEDIR}"/../README.md
}

update-toc "RFCS" "${RFC_DIR}" "*/" "/README.md" "docs/rfcs"
update-toc "ADRS" "${ADR_DIR}" "*.md" "" "docs/adrs"
