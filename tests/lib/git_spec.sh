#!/bin/bash
# shellcheck shell=bash

Describe 'git.sh'
Include src/lib/console.sh
Include src/lib/log.sh
Include src/lib/git.sh

# Create a fresh isolated git repo before each example.
setup() {
  REPO_DIR="$(mktemp -d)"
  export REPO_DIR
  git -C "$REPO_DIR" init -q
  git -C "$REPO_DIR" config user.email "test@test.com"
  git -C "$REPO_DIR" config user.name "Test User"
  printf 'hello\n' >"$REPO_DIR/file.txt"
  git -C "$REPO_DIR" add .
  git -C "$REPO_DIR" commit -qm "initial commit"
  # Detect the default branch name (master on older git, main on newer).
  REPO_MAIN_BRANCH="$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD)"
  export REPO_MAIN_BRANCH
  cd "$REPO_DIR"
}

teardown() {
  cd /tmp
  rm -rf "$REPO_DIR"
}

Before 'setup'
After 'teardown'

Describe 'git_current_branch'
It 'returns the name of the current branch'
When call git_current_branch
The output should not equal ''
The status should equal 0
End

It 'reflects the branch after a checkout'
git checkout -qb feature-x
When call git_current_branch
The output should equal 'feature-x'
End
End

Describe 'git_branch_list'
It 'lists local branches'
When call git_branch_list
The output should not equal ''
End

It 'includes a manually created branch'
git checkout -qb my-branch
git checkout -q "$REPO_MAIN_BRANCH"
When call git_branch_list
The output should include 'my-branch'
End
End

Describe 'git_checkout'
It 'creates a new branch and checks it out'
When call git_checkout 'new-feature'
The status should equal 0
The error should include 'new-feature'
End

It 'fails if the branch already exists'
git checkout -qb existing-branch
git checkout -q "$REPO_MAIN_BRANCH"
When run git_checkout 'existing-branch'
The status should not equal 0
The error should include 'existing-branch'
End

It 'requires a branch name'
When run git_checkout ''
The status should equal 1
The error should include 'branch name is required'
End
End

Describe 'git_switch'
It 'switches to an existing branch'
git checkout -qb target-branch
git checkout -q "$REPO_MAIN_BRANCH"
When call git_switch 'target-branch'
The status should equal 0
The error should include 'target-branch'
End

It 'creates the branch if it does not exist'
When call git_switch 'brand-new-branch'
The status should equal 0
The error should include 'brand-new-branch'
End

It 'requires a branch name'
When run git_switch ''
The status should equal 1
The error should include 'branch name is required'
End
End

Describe 'git_commit'
It 'commits all changes with the given message'
printf 'change\n' >>"$REPO_DIR/file.txt"
When call git_commit 'my commit message'
The status should equal 0
The error should include 'Committing'
The output should include 'my commit message'
End

It 'is a no-op when the working tree is clean'
When call git_commit 'nothing to commit'
The status should equal 0
The error should include 'Nothing to commit'
End

It 'stages and commits untracked files'
printf 'new\n' >"$REPO_DIR/new_file.txt"
When call git_commit 'add new file'
The status should equal 0
The error should include 'add new file'
The output should include 'add new file'
End

It 'requires a commit message'
When run git_commit ''
The status should equal 1
The error should include 'commit message is required'
End
End

Describe 'git_merge'
# Set up a feature branch with commits, stay on it so git_merge can detect it.
setup_merge() {
  git checkout -qb feature-branch
  printf 'feature work\n' >>"$REPO_DIR/file.txt"
  git add .
  git commit -qm "feature commit"
}

Before 'setup_merge'

It 'merges the feature branch into the target'
When call git_merge 'Merge feature' "$REPO_MAIN_BRANCH"
The status should equal 0
The error should include 'Merging'
The output should include 'file changed'
End

It 'deletes the source branch by default'
git_merge 'Merge feature' "$REPO_MAIN_BRANCH" >/dev/null 2>&1
When call git_branch_list
The output should not include 'feature-branch'
End

It 'keeps the source branch with --keep-branch'
git_merge 'Merge feature' "$REPO_MAIN_BRANCH" --keep-branch >/dev/null 2>&1
When call git_branch_list
The output should include 'feature-branch'
End

It 'requires a commit message'
When run git_merge ''
The status should equal 1
The error should include 'commit message is required'
End

It 'fails when source and target are the same branch'
git checkout -q "$REPO_MAIN_BRANCH"
When call git_merge 'msg' "$REPO_MAIN_BRANCH"
The status should equal 1
The error should include 'same'
End

It 'fails from a detached HEAD'
git checkout -q --detach HEAD
When call git_merge 'msg' "$REPO_MAIN_BRANCH"
The status should equal 1
The error should not equal ''
End
End

Describe 'git_squash'
# Set up a feature branch with commits, stay on it so git_squash can detect it.
setup_squash() {
  git checkout -qb squash-branch
  printf 'squash work\n' >>"$REPO_DIR/file.txt"
  git add .
  git commit -qm "squash commit"
}

Before 'setup_squash'

It 'squash-merges the branch into the target'
When call git_squash 'Squash feature' "$REPO_MAIN_BRANCH"
The status should equal 0
The error should include 'Squashing'
The output should include 'Squash feature'
End

It 'force-deletes the source branch by default'
git_squash 'Squash feature' "$REPO_MAIN_BRANCH" >/dev/null 2>&1
When call git_branch_list
The output should not include 'squash-branch'
End

It 'keeps the source branch with --keep-branch'
git_squash 'Squash feature' "$REPO_MAIN_BRANCH" --keep-branch >/dev/null 2>&1
When call git_branch_list
The output should include 'squash-branch'
End

It 'requires a commit message'
When run git_squash ''
The status should equal 1
The error should include 'commit message is required'
End

It 'fails when source and target are the same branch'
git checkout -q "$REPO_MAIN_BRANCH"
When call git_squash 'msg' "$REPO_MAIN_BRANCH"
The status should equal 1
The error should include 'same'
End

It 'fails from a detached HEAD'
git checkout -q --detach HEAD
When call git_squash 'msg' "$REPO_MAIN_BRANCH"
The status should equal 1
The error should not equal ''
End
End
End
