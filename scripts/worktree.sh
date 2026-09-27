#!/usr/bin/env bash
# scripts/worktree.sh
# Helper utility to manage Git Worktrees for parallel development in Pedro.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
PRIMARY_ROOT="$(git worktree list 2>/dev/null | head -n 1 | awk '{print $1}')"
REPO_ROOT="${PRIMARY_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
WORKTREES_DIR="${REPO_ROOT}/.worktrees"
DEFAULT_USER="kroikie"

# Resolve github username (fall back to DEFAULT_USER)
get_github_user() {
  if command -v gh &>/dev/null; then
    gh api user -q .login 2>/dev/null || echo "$DEFAULT_USER"
  else
    echo "$DEFAULT_USER"
  fi
}

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [arguments]

Commands:
  create <name> [base]   Create a new worktree from origin/master (or base branch).
                         Automatically prefixes branch with GitHub username (e.g. kroikie/<name>).
  clean  <name>          Remove the worktree and delete the associated local branch.
  list                   List all active git worktrees.
  prune                  Prune stale worktree administrative metadata.
  sync   [branch]        Safely fast-forward local master (or branch) to origin in the root workspace.

Examples:
  ./scripts/worktree.sh create score-board
  ./scripts/worktree.sh clean score-board
  ./scripts/worktree.sh sync
  ./scripts/worktree.sh list
EOF
  exit 1
}

cmd_create() {
  local raw_name="${1:-}"
  local base_ref="${2:-master}"

  if [[ -z "$raw_name" ]]; then
    echo "Error: Worktree/task name is required." >&2
    usage
  fi

  local gh_user
  gh_user="$(get_github_user)"

  # Strip user prefix if already included by caller
  local slug="${raw_name#"${gh_user}/"}"
  local branch="${gh_user}/${slug}"
  local target_dir="${WORKTREES_DIR}/${slug}"

  if [[ -d "$target_dir" ]]; then
    echo "Error: Worktree directory already exists at: $target_dir" >&2
    exit 1
  fi

  echo "==> Fetching latest origin/${base_ref}..."
  git fetch origin "$base_ref" 2>/dev/null || echo "Notice: Could not fetch origin/${base_ref}, creating worktree from existing ref."

  echo "==> Creating worktree at: $target_dir (branch: $branch)..."
  mkdir -p "$WORKTREES_DIR"

  # If branch already exists locally, check it out; otherwise create new branch
  if git show-ref --verify --quiet "refs/heads/${branch}"; then
    git worktree add "$target_dir" "$branch"
  else
    git worktree add -b "$branch" "$target_dir" "origin/${base_ref}"
  fi

  echo "==> Worktree ready!"
  echo "    Path:   $target_dir"
  echo "    Branch: $branch"
  echo "    To enter: cd $target_dir"
}

cmd_clean() {
  local raw_name="${1:-}"

  if [[ -z "$raw_name" ]]; then
    echo "Error: Worktree/task name is required to clean." >&2
    usage
  fi

  local gh_user
  gh_user="$(get_github_user)"
  local slug="${raw_name#"${gh_user}/"}"
  local branch="${gh_user}/${slug}"
  local target_dir="${WORKTREES_DIR}/${slug}"

  if [[ -d "$target_dir" ]]; then
    echo "==> Removing worktree at $target_dir..."
    git worktree remove "$target_dir" --force || rm -rf "$target_dir"
  else
    echo "Notice: Worktree directory $target_dir does not exist."
  fi

  echo "==> Pruning git worktree metadata..."
  git worktree prune

  if git show-ref --verify --quiet "refs/heads/${branch}"; then
    echo "==> Deleting local branch $branch..."
    git branch -D "$branch" || true
  fi

  echo "==> Cleaned up $slug successfully."
}

cmd_list() {
  echo "==> Active Git Worktrees:"
  git worktree list
}

cmd_prune() {
  echo "==> Pruning git worktree metadata..."
  git worktree prune -v
}

cmd_sync() {
  local target_branch="${1:-master}"

  echo "==> Synchronizing root workspace with origin/${target_branch}..."

  # Move to the primary root repo directory
  cd "$REPO_ROOT"

  local current_branch
  current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"

  if [[ "$current_branch" != "$target_branch" ]]; then
    echo "Switching from '$current_branch' to '$target_branch'..."
    git checkout "$target_branch"
  fi

  # Safety check: ensure working directory is clean
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "Warning: You have uncommitted changes in your root workspace." >&2
    echo "Please commit or stash your changes before syncing." >&2
    git status -s
    exit 1
  fi

  echo "==> Fetching latest origin/${target_branch}..."
  git fetch origin "$target_branch"

  echo "==> Pulling latest changes into '${target_branch}'..."
  git pull --ff-only origin "$target_branch"

  echo "==> Local '${target_branch}' is up to date:"
  git log -n 1 --oneline
}

# Entrypoint dispatch
main() {
  if [[ $# -eq 0 ]]; then
    usage
  fi

  local cmd="$1"
  shift

  case "$cmd" in
    create)
      cmd_create "$@"
      ;;
    clean|remove|rm)
      cmd_clean "$@"
      ;;
    list|ls)
      cmd_list
      ;;
    prune)
      cmd_prune
      ;;
    sync|pull)
      cmd_sync "$@"
      ;;
    *)
      echo "Unknown command: $cmd" >&2
      usage
      ;;
  esac
}

main "$@"
