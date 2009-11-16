#!/bin/bash

set -e

. ./test-lib.sh

setup_initsvn
setup_gitsvn

(
  set -e
  cd git-svn
  git config rietveld.server localhost:8080
  git checkout -q -b work
  echo "some work done on a branch" >> test
  git add test; git commit -q -m "branch work"

  # Prevent the editor from coming up when you upload.
  export EDITOR=/bin/true
  test_expect_success "upload succeeds (needs a server running on localhost)" \
    "$GIT_CL upload -m test master... | grep -q 'Issue created'"

  test_expect_failure "git-cl dcommit with argument fails" \
    "$GIT_CL dcommit -f master"
)
SUCCESS=$?

cleanup

if [ $SUCCESS == 0 ]; then
  echo PASS
fi
