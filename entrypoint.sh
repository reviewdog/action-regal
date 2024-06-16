#!/bin/sh
set -e

if [ -n "${GITHUB_WORKSPACE}" ] ; then
  cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit 1
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit 1
fi

wget -O /usr/local/bin/regal -q "https://github.com/StyraInc/regal/releases/download/"${INPUT_REGAL_VERSION}"/regal_Linux_x86_64" \
    && chmod +x /usr/local/bin/regal

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

jq_script='
.violations[]
| {
  severity: (.level|ascii_upcase),
  message: "\(.title)\ncategory: \(.category)\n\(.description)",
  location: {
    path: .location.file,
    range: {
      start: {line: .location.row, column: .location.col},
      end: {line: .location.row, column: .location.col}
    },
  },
}
'

regal lint "${INPUT_POLICY_PATH}" "${INPUT_REGAL_FLAGS}" -f json \
  | jq "$jq_script" -c \
  | reviewdog -f="rdjsonl" \
      -name="regal" \
      -reporter="${INPUT_REPORTER:-github-pr-check}" \
      -filter-mode="${INPUT_FILTER_MODE}" \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
      -level="${INPUT_LEVEL}" \
      "${INPUT_REVIEWDOG_FLAGS}"
