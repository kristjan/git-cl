#!/bin/bash

# Abort on error.
set -e

PWD=`pwd`
REPO_URL=file://$PWD/svnrepo
GITREPO_URL=file://$PWD/gitrepo
GIT_CL=$PWD/../git-cl

# Set up an SVN repo that has a few commits to trunk.
setup_initsvn() {
  echo "Setting up test SVN repo..."
  rm -rf svnrepo
  svnadmin create svnrepo

  rm -rf svn
  svn co -q $REPO_URL svn
  (
    cd svn
    echo "test" > test
    svn add -q test
    svn commit -q -m "initial commit"
    echo "test2" >> test
    svn commit -q -m "second commit"
  )
}

# Set up a git-svn checkout of the repo.
setup_gitsvn() {
  echo "Setting up test git-svn repo..."
  rm -rf git-svn
  # There appears to be no way to make git-svn completely shut up, so we
  # redirect its output.
  git svn -q clone $REPO_URL git-svn >/dev/null 2>&1
}

# Set up a git repo that has a few commits to master.
setup_initgit() {
  echo "Setting up test upstream git repo..."
  rm -rf gitrepo
  mkdir gitrepo

  (
    cd gitrepo
    git init -q
    echo "test" > test
    git add test
    git commit -qam "initial commit"
    echo "test2" >> test
    git commit -qam "second commit"
    # Hack: make sure master is not the current branch
    #       otherwise push will give a warning
    git checkout -q -b foo
  )
}

# Set up a git checkout of the repo.
setup_gitgit() {
  echo "Setting up test git repo..."
  rm -rf git-git
  git clone -q $GITREPO_URL git-git
}

cleanup() {
  rm -rf gitrepo svnrepo svn git-git git-svn
}

# Usage: test_expect_success "description of test" "test code".
test_expect_success() {
  echo "TESTING: $1"
  exit_code=0
  sh -c "$2" || exit_code=$?
  if [ $exit_code != 0 ]; then
    echo "FAILURE: $1"
    return $exit_code
  fi
}

# Usage: test_expect_failure "description of test" "test code".
test_expect_failure() {
  echo "TESTING: $1"
  exit_code=0
  sh -c "$2" || exit_code=$?
  if [ $exit_code = 0 ]; then
    echo "SUCCESS, BUT EXPECTED FAILURE: $1"
    return $exit_code
  fi
}
