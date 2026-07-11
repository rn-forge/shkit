#!/bin/bash
# @file git.sh
# @brief Git workflow helpers.
# @description
#   Common git operations: branch management, commits, merge, and squash.
#   All functions log on error and return 1 on failure — callers decide whether to exit.
#
#   Notes:
#   - git_switch uses git checkout internally for compatibility with git < 2.23.
#   - git_merge and git_squash delete the source branch after merging by default;
#     pass --keep-branch to suppress deletion.
#   - git_squash uses -D (force-delete) because squash merges do not mark the
#     source branch as fully merged in git's view.
#
#   Dependencies: log.sh
#   Safe to source multiple times (guarded by _RNF_GIT_LOADED).

# shellcheck shell=bash

[ "${_RNF_GIT_LOADED:-}" = "1" ] && return 0
_RNF_GIT_LOADED=1

# @description Print the name of the current branch.
# @exitcode 0 Success.
# @exitcode 1 Not in a git repository or HEAD is detached.
git_current_branch() {
  local branch
  branch="$(git rev-parse --abbrev-ref HEAD)" || return 1
  if [ "$branch" = "HEAD" ]; then
    log_error "git_current_branch: HEAD is detached"
    return 1
  fi
  printf '%s\n' "$branch"
}

# @description List local branches, or remote-tracking branches when called with 'remote'.
# @arg $1 string Optional: pass 'remote' to list remote branches (strips the origin/ prefix).
# @exitcode 0 Always.
git_branch_list() {
  if [ "${1:-}" = "remote" ]; then
    git for-each-ref --format="%(refname:short)" refs/remotes/ |
      grep -vx "origin" | sed 's|origin/||'
    return
  fi
  git for-each-ref --format="%(refname:short)" refs/heads/
}

# @description Create and check out a new branch. Fails if the branch already exists.
# @arg $1 string Branch name.
# @exitcode 0 Branch created and checked out.
# @exitcode 1 Branch name missing or branch already exists.
git_branch_create() {
  local branch="$1"
  if [ -z "$branch" ]; then
    log_error "git_branch_create: branch name is required"
    return 1
  fi
  log_info "Creating branch: ${branch}"
  git checkout -b "$branch"
}

# @description Switch to a branch, creating it if it does not exist.
#   Uses git checkout for compatibility with git < 2.23 (no git switch).
# @arg $1 string Branch name.
# @exitcode 0 Switched to or created the branch.
# @exitcode 1 Branch name missing.
git_switch() {
  local branch="$1"
  if [ -z "$branch" ]; then
    log_error "git_switch: branch name is required"
    return 1
  fi
  log_info "Switching to branch: ${branch}"
  git checkout "$branch" 2>/dev/null || git checkout -b "$branch"
}

# @description Stage all changes and commit with the given message.
#   A no-op (logged at NOTICE) if the working tree is already clean.
# @arg $1 string Commit message.
# @exitcode 0 Committed, or nothing to commit.
# @exitcode 1 Message missing or commit failed.
git_commit() {
  local message="$1"
  if [ -z "$message" ]; then
    log_error "git_commit: commit message is required"
    return 1
  fi
  if [ -z "$(git status --porcelain)" ]; then
    log_notice "Nothing to commit: ${message}"
    return 0
  fi
  log_info "Committing: ${message}"
  git add -A && git commit -m "$message"
}

# @description Merge the current branch into TARGET with a merge commit, then delete the source branch.
#   Pass --keep-branch to skip deletion.
#
# @arg $1 string  Merge commit message.
# @arg $2 string  Target branch. Default: main.
# @option --keep-branch Skip deleting the source branch after merge.
#
# @exitcode 0 Merge completed.
# @exitcode 1 Message missing or merge failed.
git_merge() {
  local message="" target="main" keep_branch=0 arg
  for arg in "$@"; do
    case "$arg" in
    --keep-branch) keep_branch=1 ;;
    *) if [ -z "$message" ]; then message="$arg"; else target="$arg"; fi ;;
    esac
  done
  if [ -z "$message" ]; then
    log_error "git_merge: commit message is required"
    return 1
  fi
  local source
  source="$(git_current_branch)" || return 1
  if [ "$source" = "$target" ]; then
    log_error "git_merge: source and target branch are the same ('${source}')"
    return 1
  fi
  log_warning "Merging ${source} into ${target}: ${message}"
  git checkout "$target" && git merge --commit --no-ff -m "$message" "$source" || return 1
  if [ "$keep_branch" = "0" ]; then
    git branch -d "$source" || return 1
  fi
  return 0
}

# @description Squash-merge the current branch into TARGET as a single commit, then delete the source branch.
#   Uses -D (force-delete) since squash merges do not mark the source as fully merged.
#   Pass --keep-branch to skip deletion.
#
# @arg $1 string  Commit message.
# @arg $2 string  Target branch. Default: main.
# @option --keep-branch Skip deleting the source branch after merge.
#
# @exitcode 0 Squash completed.
# @exitcode 1 Message missing or merge failed.
git_squash() {
  local message="" target="main" keep_branch=0 arg
  for arg in "$@"; do
    case "$arg" in
    --keep-branch) keep_branch=1 ;;
    *) if [ -z "$message" ]; then message="$arg"; else target="$arg"; fi ;;
    esac
  done
  if [ -z "$message" ]; then
    log_error "git_squash: commit message is required"
    return 1
  fi
  local source
  source="$(git_current_branch)" || return 1
  if [ "$source" = "$target" ]; then
    log_error "git_squash: source and target branch are the same ('${source}')"
    return 1
  fi
  log_warning "Squashing ${source} into ${target}: ${message}"
  git checkout "$target" && git merge --squash "$source" || return 1
  git commit -m "$message" || return 1
  if [ "$keep_branch" = "0" ]; then
    git branch -D "$source" || return 1
  fi
  return 0
}
