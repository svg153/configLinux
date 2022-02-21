#!/bin/bash

set -e
set -u

INPUT_MD_FILE=$1
OUT_ADOC_FILE=${INPUT_MD_FILE}.adoc 
OUT_TMP_PDF_FILE=${INPUT_MD_FILE}.tmp.pdf
OUT_PDF_FILE=${INPUT_MD_FILE}.pdf

function clear() {
    # echo "Clear temporary files (if exist)"
    rm -f "${OUT_ADOC_FILE}" "${OUT_TMP_PDF_FILE}" || true
}

clear

# Convert Markdown to Asciidoctor
docker run --rm -v "$(pwd)":/data pandoc/core  -f markdown -t asciidoc -i "${INPUT_MD_FILE}" -o "${OUT_ADOC_FILE}"

# Convert Asciidoctor to PDF
docker run --rm -v "$(pwd)":/documents/ asciidoctor/docker-asciidoctor asciidoctor-pdf "${OUT_ADOC_FILE}"

echo "${OUT_PDF_FILE}"

clear