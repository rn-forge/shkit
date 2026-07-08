# git.sh

Git workflow helpers.

## Overview

Common git operations: branch management, commits, merge, and squash.
All functions log on error and return 1 on failure — callers decide whether to exit.

Notes:
- git_switch uses git checkout internally for compatibility with git < 2.23.
- git_merge and git_squash delete the source branch after merging by default;
pass --keep-branch to suppress deletion.
- git_squash uses -D (force-delete) because squash merges do not mark the
source branch as fully merged in git's view.

Dependencies: log.sh
Safe to source multiple times (guarded by _RNF_GIT_LOADED).

## Index

* [git_current_branch](#git_current_branch)
* [git_branch_list](#git_branch_list)
* [git_checkout](#git_checkout)
* [git_switch](#git_switch)
* [git_commit](#git_commit)
* [git_merge](#git_merge)
* [git_squash](#git_squash)

### git_current_branch

Print the name of the current branch.

#### Exit codes

* **0**: Success.
* **1**: Not in a git repository or HEAD is detached.

### git_branch_list

List local branches, or remote-tracking branches when called with 'remote'.

#### Arguments

* **$1** (string): Optional: pass 'remote' to list remote branches (strips the origin/ prefix).

#### Exit codes

* **0**: Always.

### git_checkout

Create and check out a new branch. Fails if the branch already exists.

#### Arguments

* **$1** (string): Branch name.

#### Exit codes

* **0**: Branch created and checked out.
* **1**: Branch name missing or branch already exists.

### git_switch

Switch to a branch, creating it if it does not exist.
Uses git checkout for compatibility with git < 2.23 (no git switch).

#### Arguments

* **$1** (string): Branch name.

#### Exit codes

* **0**: Switched to or created the branch.
* **1**: Branch name missing.

### git_commit

Stage all changes and commit with the given message.
A no-op (logged at NOTICE) if the working tree is already clean.

#### Arguments

* **$1** (string): Commit message.

#### Exit codes

* **0**: Committed, or nothing to commit.
* **1**: Message missing or commit failed.

### git_merge

Merge the current branch into TARGET with a merge commit, then delete the source branch.
Pass --keep-branch to skip deletion.

#### Options

* **--keep-branch**

  Skip deleting the source branch after merge.

#### Arguments

* **$1** (string): Merge commit message.
* **$2** (string): Target branch. Default: main.

#### Exit codes

* **0**: Merge completed.
* **1**: Message missing or merge failed.

### git_squash

Squash-merge the current branch into TARGET as a single commit, then delete the source branch.
Uses -D (force-delete) since squash merges do not mark the source as fully merged.
Pass --keep-branch to skip deletion.

#### Options

* **--keep-branch**

  Skip deleting the source branch after merge.

#### Arguments

* **$1** (string): Commit message.
* **$2** (string): Target branch. Default: main.

#### Exit codes

* **0**: Squash completed.
* **1**: Message missing or merge failed.

