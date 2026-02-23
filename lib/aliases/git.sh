#!/usr/bin/env bash
# Oh My Zsh-inspired git aliases for bash.

if [[ -n "${WAKI_GIT_ALIASES_LOADED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
WAKI_GIT_ALIASES_LOADED=1

# Core branch helpers
git_current_branch() {
  local ref
  ref=$(git symbolic-ref --quiet HEAD 2>/dev/null) || ref=$(git rev-parse --short HEAD 2>/dev/null) || return
  echo "${ref#refs/heads/}"
}

git_develop_branch() {
  git rev-parse --git-dir >/dev/null 2>&1 || return
  local branch
  for branch in dev devel develop development; do
    if git show-ref -q --verify "refs/heads/$branch"; then
      echo "$branch"
      return 0
    fi
  done
  echo "develop"
  return 1
}

git_main_branch() {
  git rev-parse --git-dir >/dev/null 2>&1 || return
  local remote ref
  for ref in \
    refs/heads/main \
    refs/heads/trunk \
    refs/heads/mainline \
    refs/heads/default \
    refs/heads/stable \
    refs/heads/master \
    refs/remotes/origin/main \
    refs/remotes/origin/trunk \
    refs/remotes/origin/mainline \
    refs/remotes/origin/default \
    refs/remotes/origin/stable \
    refs/remotes/origin/master \
    refs/remotes/upstream/main \
    refs/remotes/upstream/trunk \
    refs/remotes/upstream/mainline \
    refs/remotes/upstream/default \
    refs/remotes/upstream/stable \
    refs/remotes/upstream/master; do
    if git show-ref -q --verify "$ref"; then
      echo "${ref##*/}"
      return 0
    fi
  done

  for remote in origin upstream; do
    ref=$(git rev-parse --abbrev-ref "$remote/HEAD" 2>/dev/null || true)
    if [[ "$ref" == "$remote/"* ]]; then
      echo "${ref#"$remote/"}"
      return 0
    fi
  done

  echo "master"
  return 1
}

grename() {
  if [[ -z "${1:-}" || -z "${2:-}" ]]; then
    echo "Usage: grename <old_branch> <new_branch>"
    return 1
  fi

  git branch -m "$1" "$2" || return 1
  if git push origin ":$1"; then
    git push --set-upstream origin "$2"
  fi
}

# Work-in-progress helpers
gunwipall() {
  local commit
  commit=$(git log --grep='--wip--' --invert-grep --max-count=1 --format='%H')
  if [[ -n "$commit" && "$commit" != "$(git rev-parse HEAD 2>/dev/null)" ]]; then
    git reset "$commit"
  fi
}

work_in_progress() {
  git -c log.showSignature=false log -n 1 2>/dev/null | command grep -q -- '--wip--' && echo 'WIP!!'
}

# Utility wrappers
ggpnp() {
  if [[ $# -eq 0 ]]; then
    ggl && ggp
  else
    ggl "$@" && ggp "$@"
  fi
}

gbda() {
  local main develop
  main=$(git_main_branch)
  develop=$(git_develop_branch)
  git branch --no-color --merged \
    | command grep -vE "^([+*]|\s*(${main}|${develop})\s*$)" \
    | command xargs -r git branch --delete 2>/dev/null
}

gbds() {
  local default_branch
  default_branch=$(git_main_branch) || default_branch=$(git_develop_branch)

  git for-each-ref refs/heads/ --format='%(refname:short)' \
    | while read -r branch; do
      [[ "$branch" == "$default_branch" ]] && continue
      local merge_base
      merge_base=$(git merge-base "$default_branch" "$branch" 2>/dev/null) || continue
      if [[ "$(git cherry "$default_branch" "$(git commit-tree "$(git rev-parse "${branch}^{tree}")" -p "$merge_base" -m _)" 2>/dev/null)" == -* ]]; then
        git branch -D "$branch"
      fi
    done
}

gccd() {
  command git clone --recurse-submodules "$@" || return 1

  local maybe_dir="${@: -1}"
  if [[ -d "$maybe_dir" ]]; then
    cd "$maybe_dir" || return 1
    return 0
  fi

  local repo_name
  repo_name="${maybe_dir##*/}"
  repo_name="${repo_name%.git}"
  [[ -d "$repo_name" ]] && cd "$repo_name"
}

gdv() {
  git diff -w "$@" | ${PAGER:-less}
}

gdnolock() {
  git diff "$@" ':(exclude)package-lock.json' ':(exclude)*.lock'
}

_git_log_prettily() {
  [[ -n "${1:-}" ]] && git log --pretty="$1"
}

ggu() {
  local branch
  if [[ $# -eq 1 ]]; then
    branch="$1"
  else
    branch=$(git_current_branch)
  fi
  git pull --rebase origin "$branch"
}

ggl() {
  if [[ $# -gt 1 ]]; then
    git pull origin "$*"
    return
  fi

  local branch
  if [[ $# -eq 1 ]]; then
    branch="$1"
  else
    branch=$(git_current_branch)
  fi
  git pull origin "$branch"
}

ggf() {
  local branch
  if [[ $# -eq 1 ]]; then
    branch="$1"
  else
    branch=$(git_current_branch)
  fi
  git push --force origin "$branch"
}

ggfl() {
  local branch
  if [[ $# -eq 1 ]]; then
    branch="$1"
  else
    branch=$(git_current_branch)
  fi
  git push --force-with-lease origin "$branch"
}

ggp() {
  if [[ $# -gt 1 ]]; then
    git push origin "$*"
    return
  fi

  local branch
  if [[ $# -eq 1 ]]; then
    branch="$1"
  else
    branch=$(git_current_branch)
  fi
  git push origin "$branch"
}

gtl() {
  git tag --sort=-v:refname -n --list "${1}*"
}

# Aliases
alias grt='cd "$(git rev-parse --show-toplevel || echo .)"'

alias ggpur='ggu'
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gapa='git add --patch'
alias gau='git add --update'
alias gav='git add --verbose'
alias gwip='git add -A; git rm $(git ls-files --deleted) 2>/dev/null; git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"'
alias gam='git am'
alias gama='git am --abort'
alias gamc='git am --continue'
alias gamscp='git am --show-current-patch'
alias gams='git am --skip'
alias gap='git apply'
alias gapt='git apply --3way'
alias gbs='git bisect'
alias gbsb='git bisect bad'
alias gbsg='git bisect good'
alias gbsn='git bisect new'
alias gbso='git bisect old'
alias gbsr='git bisect reset'
alias gbss='git bisect start'
alias gbl='git blame -w'
alias gb='git branch'
alias gba='git branch --all'
alias gbd='git branch --delete'
alias gbD='git branch --delete --force'
alias gbgd='LANG=C git branch --no-color -vv | grep ": gone\]" | cut -c 3- | awk '\''{print $1}'\'' | xargs git branch -d'
alias gbgD='LANG=C git branch --no-color -vv | grep ": gone\]" | cut -c 3- | awk '\''{print $1}'\'' | xargs git branch -D'
alias gbm='git branch --move'
alias gbnm='git branch --no-merged'
alias gbr='git branch --remote'
alias ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'
alias gbg='LANG=C git branch -vv | grep ": gone\]"'
alias gco='git checkout'
alias gcor='git checkout --recurse-submodules'
alias gcb='git checkout -b'
alias gcB='git checkout -B'
alias gcd='git checkout $(git_develop_branch)'
alias gcm='git checkout $(git_main_branch)'
alias gcp='git cherry-pick'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'
alias gclean='git clean --interactive -d'
alias gcl='git clone --recurse-submodules'
alias gclf='git clone --recursive --shallow-submodules --filter=blob:none --also-filter-submodules'

alias gcam='git commit --all --message'
alias gcas='git commit --all --signoff'
alias gcasm='git commit --all --signoff --message'
alias gcs='git commit --gpg-sign'
alias gcss='git commit --gpg-sign --signoff'
alias gcssm='git commit --gpg-sign --signoff --message'
alias gcmsg='git commit --message'
alias gcsm='git commit --signoff --message'
alias gc='git commit --verbose'
alias gca='git commit --verbose --all'
alias "gca!"='git commit --verbose --all --amend'
alias "gcan!"='git commit --verbose --all --no-edit --amend'
alias "gcans!"='git commit --verbose --all --signoff --no-edit --amend'
alias "gcann!"='git commit --verbose --all --date=now --no-edit --amend'
alias "gc!"='git commit --verbose --amend'
alias gcn='git commit --verbose --no-edit'
alias "gcn!"='git commit --verbose --no-edit --amend'

# Bash-friendly alternatives for aliases ending with '!'.
alias gcaam='git commit --verbose --all --amend'
alias gcanam='git commit --verbose --all --no-edit --amend'
alias gcansam='git commit --verbose --all --signoff --no-edit --amend'
alias gcannam='git commit --verbose --all --date=now --no-edit --amend'
alias gcamend='git commit --verbose --amend'
alias gcnam='git commit --verbose --no-edit --amend'

alias gcf='git config --list'
alias gcfu='git commit --fixup'
alias gdct='git describe --tags $(git rev-list --tags --max-count=1)'
alias gd='git diff'
alias gdca='git diff --cached'
alias gdcw='git diff --cached --word-diff'
alias gds='git diff --staged'
alias gdw='git diff --word-diff'
alias gdup='git diff @{upstream}'
alias gdt='git diff-tree --no-commit-id --name-only -r'
alias gf='git fetch'
alias gfa='git fetch --all --tags --prune'
alias gfo='git fetch origin'
alias gg='git gui citool'
alias gga='git gui citool --amend'
alias ghh='git help'
alias glgg='git log --graph'
alias glgga='git log --graph --decorate --all'
alias glgm='git log --graph --max-count=10'
alias glods='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset" --date=short'
alias glod='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset"'
alias glola='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all'
alias glols='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --stat'
alias glol='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
alias glo='git log --oneline --decorate'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias glp='_git_log_prettily'
alias glg='git log --stat'
alias glgp='git log --stat --patch'
alias gignored='git ls-files -v | grep "^[[:lower:]]"'
alias gfg='git ls-files | grep'
alias gm='git merge'
alias gma='git merge --abort'
alias gmc='git merge --continue'
alias gms='git merge --squash'
alias gmff='git merge --ff-only'
alias gmom='git merge origin/$(git_main_branch)'
alias gmum='git merge upstream/$(git_main_branch)'
alias gmtl='git mergetool --no-prompt'
alias gmtlvim='git mergetool --no-prompt --tool=vimdiff'

alias gl='git pull'
alias gpr='git pull --rebase'
alias gprv='git pull --rebase -v'
alias gpra='git pull --rebase --autostash'
alias gprav='git pull --rebase --autostash -v'
alias gprom='git pull --rebase origin $(git_main_branch)'
alias gpromi='git pull --rebase=interactive origin $(git_main_branch)'
alias gprum='git pull --rebase upstream $(git_main_branch)'
alias gprumi='git pull --rebase=interactive upstream $(git_main_branch)'
alias ggpull='git pull origin "$(git_current_branch)"'
alias gluc='git pull upstream $(git_current_branch)'
alias glum='git pull upstream $(git_main_branch)'
alias gp='git push'
alias gpd='git push --dry-run'
alias "gpf!"='git push --force'
alias gpf='git push --force-with-lease'
alias gpff='git push --force'
alias gpsup='git push --set-upstream origin $(git_current_branch)'
alias gpsupf='git push --set-upstream origin $(git_current_branch) --force-with-lease'
alias gpv='git push --verbose'
alias gpoat='git push origin --all && git push origin --tags'
alias gpod='git push origin --delete'
alias ggpush='git push origin "$(git_current_branch)"'
alias gpu='git push upstream'
alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbi='git rebase --interactive'
alias grbo='git rebase --onto'
alias grbs='git rebase --skip'
alias grbd='git rebase $(git_develop_branch)'
alias grbm='git rebase $(git_main_branch)'
alias grbom='git rebase origin/$(git_main_branch)'
alias grbum='git rebase upstream/$(git_main_branch)'
alias grf='git reflog'
alias gr='git remote'
alias grv='git remote --verbose'
alias gra='git remote add'
alias grrm='git remote remove'
alias grmv='git remote rename'
alias grset='git remote set-url'
alias grup='git remote update'
alias grh='git reset'
alias gru='git reset --'
alias grhh='git reset --hard'
alias grhk='git reset --keep'
alias grhs='git reset --soft'
alias gpristine='git reset --hard && git clean --force -dfx'
alias gwipe='git reset --hard && git clean --force -df'
alias groh='git reset origin/$(git_current_branch) --hard'
alias grs='git restore'
alias grss='git restore --source'
alias grst='git restore --staged'
alias gunwip='git rev-list --max-count=1 --format="%s" HEAD | grep -q "--wip--" && git reset HEAD~1'
alias grev='git revert'
alias greva='git revert --abort'
alias grevc='git revert --continue'
alias grm='git rm'
alias grmc='git rm --cached'
alias gcount='git shortlog --summary --numbered'
alias gsh='git show'
alias gsps='git show --pretty=short --show-signature'
alias gstall='git stash --all'
alias gstaa='git stash apply'
alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gsta='git stash push'
alias gsts='git stash show --patch'
alias gst='git status'
alias gss='git status --short'
alias gsb='git status --short --branch'
alias gsi='git submodule init'
alias gsu='git submodule update'
alias gsw='git switch'
alias gswc='git switch --create'
alias gswd='git switch $(git_develop_branch)'
alias gswm='git switch $(git_main_branch)'
alias gta='git tag --annotate'
alias gts='git tag --sign'
alias gtv='git tag | sort -V'
alias gignore='git update-index --assume-unchanged'
alias gunignore='git update-index --no-assume-unchanged'
alias gwch='git log --patch --abbrev-commit --pretty=medium --raw'
alias gwt='git worktree'
alias gwta='git worktree add'
alias gwtls='git worktree list'
alias gwtmv='git worktree move'
alias gwtrm='git worktree remove'
alias gstu='gsta --include-untracked'
alias gk='gitk --all --branches >/dev/null 2>&1 &'
alias gke='gitk --all $(git log --walk-reflogs --pretty=%h) >/dev/null 2>&1 &'
