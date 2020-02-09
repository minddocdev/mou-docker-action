#!/bin/bash
binary="$0"
parameters="$*"
echo "${binary} ${parameters}" >> mockCalledWith

function mockShouldFail() {
  [ "${MOCK_RETURNS[${binary}]}" = "_${parameters}" ]
}

# shellcheck disable=SC1091
source mockReturns
if [ -n "${MOCK_RETURNS[${binary}]}" ]; then
  if mockShouldFail ; then
    exit 1
  fi
  echo "${MOCK_RETURNS[${binary}]}"
fi

exit 0
