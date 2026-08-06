# sbx — run build/dev tooling in a bubblewrap sandbox that cannot read $HOME.
#
# Why: `npm install`, `cargo build` (build.rs), `pip install`, and editor
# extensions all execute arbitrary upstream code with your full user privileges.
# That is the realistic compromise path — no kernel bug required, because
# everything worth stealing is already readable by uid 1000.
#
# Inside sbx that code sees a scratch $HOME, and has no access to ~/.ssh,
# ~/.npmrc, ~/.aws, ~/.config/1Password, the SSH agent socket, the Wayland
# socket, or any other project directory. Only the current directory is bound.
#
# Usage:
#   sbx                     interactive shell, cwd bound read-write
#   sbx <cmd> [args...]     run a single command
#   sbx --offline <cmd>     also cut off the network (unshare-net)
#   sbx --npmrc <cmd>       bind ~/.npmrc read-only -- see warning below
#
# Caches persist in ~/.cache/sbx/home so repeat installs stay fast, but that
# directory is only ever visible from inside the sandbox.
#
# Deliberately NOT available inside: git push/pull over ssh (no agent). Do
# network git operations outside the sandbox; builds don't need them.

usage() {
  cat <<'EOF'
sbx — run build/dev tooling in a sandbox that cannot read $HOME.

  sbx                     interactive shell, project dir bound read-write
  sbx <cmd> [args...]     run a single command
  sbx --offline <cmd>     also cut off the network
  sbx --npmrc <cmd>       bind ~/.npmrc read-only (re-exposes registry tokens)

The "project dir" is the enclosing git repository if there is one, otherwise
just $PWD. The whole repo is bound so monorepo workspace installs resolve,
but nothing outside it is visible. You always start in $PWD.

Locally linked packages (bun link / npm link symlinks in node_modules that
point at sibling repos) are detected and bound read-only, so linked workspaces
keep resolving. Set SBX_DEBUG=1 to print everything that gets bound.

Caches persist in ~/.cache/sbx/home, visible only from inside the sandbox.
EOF
}

sandbox_home="${XDG_CACHE_HOME:-$HOME/.cache}/sbx/home"
offline=0
bind_npmrc=0

while [ $# -gt 0 ]; do
  case "$1" in
    --offline) offline=1; shift ;;
    --npmrc)   bind_npmrc=1; shift ;;
    --help|-h) usage; exit 0 ;;
    --) shift; break ;;
    *) break ;;
  esac
done

if [ "$PWD" = "$HOME" ]; then
  echo "sbx: refusing to run with \$HOME as the project directory" >&2
  echo "sbx: cd into the project you want to build first" >&2
  exit 1
fi

# Bind the whole repository, not just $PWD: JS workspace installs run from a
# package subdirectory but need the root manifest and lockfile. Falls back to
# $PWD outside a repo. Guards against a repo rooted at $HOME (a dotfiles repo
# would otherwise hand the sandbox the entire home directory).
project_root="$PWD"
if git_root="$(git rev-parse --show-toplevel 2>/dev/null)" && [ -n "$git_root" ]; then
  if [ "$git_root" = "$HOME" ]; then
    echo "sbx: git root is \$HOME; binding only $PWD" >&2
  else
    project_root="$git_root"
  fi
fi

# `bun link` / `npm link` / workspace setups leave symlinks in node_modules that
# point at sibling repositories -- e.g. dex-v2's node_modules/@sundaeswap/core
# -> ../../../sundae-sdk/packages/core. Those live outside project_root, so
# without this the linked package silently vanishes inside the sandbox and the
# build fails with "cannot find module".
#
# Each target is resolved to its own enclosing git root rather than the linked
# subdirectory, because monorepo packages reach upward for shared tsconfigs and
# lockfiles. Bound read-only: a postinstall script in this project has no
# business writing to your other repos.
link_roots=()
scan_dirs=("$project_root/node_modules")
if [ "$PWD" != "$project_root" ]; then
  scan_dirs+=("$PWD/node_modules")
fi

for scan in "${scan_dirs[@]}"; do
  [ -d "$scan" ] || continue
  while IFS= read -r -d '' link; do
    target="$(readlink -f -- "$link" 2>/dev/null)" || continue
    [ -n "$target" ] && [ -e "$target" ] || continue

    # Already covered by the project bind.
    case "$target" in "$project_root"/*|"$project_root") continue ;; esac

    # Prefer the target's repository root so shared config resolves.
    root="$target"
    if git_target_root="$(git -C "$target" rev-parse --show-toplevel 2>/dev/null)" \
       && [ -n "$git_target_root" ]; then
      root="$git_target_root"
    fi

    # Never bind $HOME or the project itself; that would defeat the sandbox.
    [ "$root" = "$HOME" ] && continue
    case "$root" in "$project_root"|"$project_root"/*) continue ;; esac

    already=0
    for seen in ${link_roots[@]+"${link_roots[@]}"}; do
      [ "$seen" = "$root" ] && already=1 && break
    done
    [ "$already" -eq 1 ] || link_roots+=("$root")
  done < <(find "$scan" -maxdepth 2 -type l -not -path '*/.bin/*' -print0 2>/dev/null)
done

mkdir -p "$sandbox_home"

# Everything below is bound read-only unless stated. Sources are resolved in
# the host namespace, so binding the scratch home over /home/pi works even
# though /home is tmpfs'd first.
args=(
  --die-with-parent
  --unshare-pid
  --unshare-ipc
  --unshare-uts
  --unshare-cgroup
  --hostname sbx
  --ro-bind /nix /nix
  --ro-bind /etc /etc
  --ro-bind /run/current-system /run/current-system
  # /usr/bin/env and /bin/sh are the two FHS paths NixOS provides, and they are
  # both just symlinks into the store. Without them every `#!/usr/bin/env node`
  # shebang fails with ENOENT from posix_spawn, which breaks all of npm's
  # installed CLIs (vite, tsc, eslint, ...).
  --ro-bind /usr /usr
  --ro-bind /bin /bin
  --proc /proc
  --dev /dev
  --tmpfs /tmp
  --tmpfs /home
  --tmpfs "${XDG_RUNTIME_DIR:-/run/user/1000}"
  --bind "$sandbox_home" "$HOME"
  --bind "$project_root" "$project_root"
  --chdir "$PWD"
)

# Note: no --new-session. It would detach the controlling terminal and break
# interactive use; the TIOCSTI escape it defends against is already disabled
# kernel-wide (dev.tty.legacy_tiocsti=0 by default since 6.2).

for root in ${link_roots[@]+"${link_roots[@]}"}; do
  args+=(--ro-bind "$root" "$root")
done

if [ "$offline" -eq 1 ]; then
  args+=(--unshare-net)
fi

if [ "$bind_npmrc" -eq 1 ]; then
  # WARNING: this hands your registry tokens back to every postinstall script
  # in the dependency tree -- the exact thing sbx exists to prevent. Use it
  # only for projects that genuinely need private packages, and prefer a
  # read-only token scoped to those packages.
  if [ -f "$HOME/.npmrc" ]; then
    args+=(--ro-bind "$HOME/.npmrc" "$HOME/.npmrc")
  else
    echo "sbx: --npmrc given but ~/.npmrc does not exist" >&2
  fi
fi

# The environment is inherited, with credential-shaped variables stripped by
# pattern. An earlier version cleared the environment and re-added an allowlist,
# which was tighter but broke ordinary app development -- `APP_ENV=preview bun
# run dev` silently lost its APP_ENV, and every framework has its own set of
# these. Filesystem isolation is the real protection here; env scrubbing is
# best-effort defence in depth, so favour the version that stays out of the way.
args+=(
  --setenv IN_SBX "1"
  --unsetenv SSH_AUTH_SOCK
  --unsetenv SSH_AGENT_PID
)

while IFS= read -r -d '' entry; do
  var="${entry%%=*}"
  case "$var" in
    *TOKEN*|*SECRET*|*PASSWORD*|*PASSWD*|*APIKEY*|*_KEY|*_KEYS| \
    AWS_*|GITHUB_*|GH_*|CACHIX_*|NPM_*|OP_*|ANTHROPIC_*|CLAUDE_*)
      args+=(--unsetenv "$var")
      ;;
  esac
done < <(env -0)

if [ $# -eq 0 ]; then
  shell="${SHELL:-}"
  if [ -z "$shell" ] || [ ! -x "$shell" ]; then
    shell="$(command -v bash)"
  fi
  set -- "$shell"
fi

if [ -n "${SBX_DEBUG:-}" ]; then
  {
    echo "sbx: project root  $project_root (rw)"
    echo "sbx: cwd           $PWD"
    for root in ${link_roots[@]+"${link_roots[@]}"}; do
      echo "sbx: linked repo   $root (ro)"
    done
    echo "sbx: scratch home  $sandbox_home -> $HOME"
    echo "sbx: network       $([ "$offline" -eq 1 ] && echo off || echo on)"
  } >&2
fi

exec bwrap "${args[@]}" -- "$@"
