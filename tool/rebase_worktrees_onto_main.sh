#!/usr/bin/env bash

set -uo pipefail

usage() {
  cat <<'EOF'
Usage: tool/rebase_worktrees_onto_main.sh [base-ref]

Rebase every non-target worktree branch onto the given base ref.
Defaults to origin/main.

Examples:
  tool/rebase_worktrees_onto_main.sh
  tool/rebase_worktrees_onto_main.sh upstream/main
  tool/rebase_worktrees_onto_main.sh main
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if (( $# > 1 )); then
  usage >&2
  exit 2
fi

base_ref="${1:-origin/main}"

if ! repo_root=$(git rev-parse --show-toplevel 2>/dev/null); then
  echo "This script must be run inside a Git worktree." >&2
  exit 1
fi

if [[ -t 1 ]]; then
  bold=$'\033[1m'
  cyan=$'\033[36m'
  green=$'\033[32m'
  orange=$'\033[38;5;214m'
  red=$'\033[31m'
  reset=$'\033[0m'
else
  bold=''
  cyan=''
  green=''
  orange=''
  red=''
  reset=''
fi

log_line() {
  local color="$1"
  local label="$2"
  local message="$3"
  printf '%b%s%b %s\n' "$color" "$label" "$reset" "$message"
}

info() {
  log_line "$cyan" "INFO " "$1"
}

success() {
  log_line "$green" "OK   " "$1"
}

warn() {
  log_line "$orange" "WARN " "$1"
}

error() {
  log_line "$red" "ERR  " "$1"
}

section() {
  printf '\n%b==>%b %s\n' "$bold" "$reset" "$1"
}

stash_ref_for_oid() {
  local worktree_path="$1"
  local stash_oid="$2"

  git -C "$worktree_path" stash list --format='%gd %H' \
    | awk -v oid="$stash_oid" '$2 == oid { print $1; exit }'
}

restore_untracked_stash() {
  local worktree_path="$1"
  local stash_oid="$2"

  [[ -n "$stash_oid" ]] || return 0

  local stash_ref
  stash_ref=$(stash_ref_for_oid "$worktree_path" "$stash_oid")
  if [[ -z "$stash_ref" ]]; then
    warn "Untracked-file stash already disappeared in $worktree_path"
    return 0
  fi

  if git -C "$worktree_path" stash pop "$stash_ref" >/dev/null; then
    success "Reapplied untracked files in $worktree_path"
    return 0
  fi

  error "Could not reapply untracked files in $worktree_path; stash kept as $stash_ref"
  return 1
}

fetch_base_ref() {
  if [[ "$base_ref" == */* && "$base_ref" != refs/* ]]; then
    local remote="${base_ref%%/*}"
    local branch="${base_ref#*/}"
    info "Fetching $remote/$branch"
    git -C "$repo_root" fetch "$remote" "$branch"
    return
  fi

  info "Using local ref $base_ref"
}

target_branch="${base_ref##*/}"

if ! fetch_base_ref; then
  error "Failed to update $base_ref"
  exit 1
fi

mapfile -t worktrees < <(
  git -C "$repo_root" worktree list --porcelain | sed -n 's/^worktree //p'
)

rebased=()
skipped=()
ignored=()

for worktree_path in "${worktrees[@]}"; do
  branch_name=$(git -C "$worktree_path" symbolic-ref --quiet --short HEAD 2>/dev/null) || {
    warn "Skipping detached HEAD worktree: $worktree_path"
    skipped+=("$worktree_path [detached HEAD]")
    continue
  }

  if [[ "$branch_name" == "$target_branch" ]]; then
    info "Leaving target branch alone: $worktree_path [$branch_name]"
    ignored+=("$worktree_path [$branch_name]")
    continue
  fi

  section "$worktree_path [$branch_name]"

  untracked_stash_oid=""
  mapfile -d '' -t untracked_files < <(
    git -C "$worktree_path" ls-files --others --exclude-standard -z
  )

  if (( ${#untracked_files[@]} > 0 )); then
    stash_message="worktree-untracked-pre-rebase:$branch_name:$(date +%s)"
    if git -C "$worktree_path" stash push -u -m "$stash_message" -- "${untracked_files[@]}" >/dev/null; then
      untracked_stash_oid=$(git -C "$worktree_path" rev-parse --verify stash@{0})
      success "Stashed ${#untracked_files[@]} untracked file(s)"
    else
      error "Could not stash untracked files in $worktree_path"
      skipped+=("$worktree_path [$branch_name: untracked stash failed]")
      continue
    fi
  fi

  if git -C "$worktree_path" rebase --autostash "$base_ref"; then
    success "Rebased $branch_name onto $base_ref"
    if restore_untracked_stash "$worktree_path" "$untracked_stash_oid"; then
      rebased+=("$worktree_path [$branch_name]")
    else
      skipped+=("$worktree_path [$branch_name: untracked stash restore failed]")
    fi
    continue
  fi

  error "Rebase failed in $worktree_path; aborting and skipping"
  git -C "$worktree_path" rebase --abort >/dev/null 2>&1 || true
  if ! restore_untracked_stash "$worktree_path" "$untracked_stash_oid"; then
    skipped+=("$worktree_path [$branch_name: conflict and untracked stash restore failed]")
  else
    skipped+=("$worktree_path [$branch_name: rebase conflict]")
  fi
done

printf '\n%bSummary%b\n' "$bold" "$reset"
success "Rebased ${#rebased[@]} worktree(s)"

if (( ${#ignored[@]} > 0 )); then
  info "Ignored ${#ignored[@]} target-branch worktree(s)"
fi

if (( ${#skipped[@]} > 0 )); then
  warn "Skipped ${#skipped[@]} worktree(s):"
  for skipped_entry in "${skipped[@]}"; do
    if [[ "$skipped_entry" == *conflict* || "$skipped_entry" == *failed* ]]; then
      printf '%b - %s%b\n' "$red" "$skipped_entry" "$reset"
    else
      printf '%b - %s%b\n' "$orange" "$skipped_entry" "$reset"
    fi
  done
else
  success "No skipped worktrees"
fi
