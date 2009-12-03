#!/bin/bash

set -e

. ./test-lib.sh

setup_initgit
setup_gitgit

(
  set -e
  cd git-git
  git checkout -q --track -b work origin
  echo "some work done on a branch" >> test
  git add test; git commit -q -m "branch work"
  echo "some other work done on a branch" >> test
  git add test; git commit -q -m "branch work"

  test_expect_success "git-cl upload wants a server" \
    "$GIT_CL upload 2>&1 | grep -q 'You must configure'"

  git config rietveld.server localhost:8080

  test_expect_success "git-cl status has no issue" \
    "$GIT_CL status | grep -q 'no issue'"

  # Prevent the editor from coming up when you upload.
  export EDITOR=$(which true)
  test_expect_success "upload succeeds (needs a server running on localhost)" \
    "$GIT_CL upload -m test master... | grep -q 'Issue created'"

  test_expect_success "git-cl status now knows the issue" \
    "$GIT_CL status | grep -q 'Issue number'"

  # Push a description to this URL.
  URL=$($GIT_CL status | sed -ne '/Issue number/s/[^(]*(\(.*\))/\1/p')
  curl --cookie dev_appserver_login="test@example.com:False" \
       --data-urlencode subject="test" \
       --data-urlencode description="foo-quux" \
       $URL/edit

  test_expect_success "git-cl push ok" \
    "$GIT_CL push -f"

  git checkout -q master > /dev/null 2>&1
  git pull -q > /dev/null 2>&1

  test_expect_success "committed code has proper description" \
      "git show | grep -q 'foo-quux'"

  test_expect_success "issue no longer has a branch" \
      "git cl status | grep -q 'work: None'"

  test_expect_success "upstream svn has our commit" \
      "svn log $REPO_URL 2>/dev/null | grep -q 'foo-quux'"
)
SUCCESS=$?

cleanup

if [ $SUCCESS == 0 ]; then
  echo PASS
fi
