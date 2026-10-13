# function that isolates the cwd as root for a shell
# intented to run ai agents in isolated enviroments, so they can do less potential harm
isolate() {
  emulate -L zsh
 
  local root=${PWD:A}
  local dns=9.9.9.9
  local -a targets args created
  local d top ret
 
  # What dynamically linked binaries need to actually run (libraries,
  # the dynamic loader, terminfo for line editing). Only existing dirs are used.
  for d in /lib /lib32 /lib64 /usr/lib /usr/lib32 /usr/lib64 /usr/libexec \
           /usr/share/terminfo /etc/terminfo /nix/store; do
    [[ -d $d ]] && targets+=($d)
  done
 
  # Every absolute, existing directory in $PATH
  for d in $path; do
    [[ $d == /* && -d $d ]] || continue      # skip relative or missing entries
    [[ ${d:A}/ == $root/* ]] && continue      # already visible inside the new root
    targets+=($d)
  done

  local zshrc=$HOME/.zshrc
  zshrc=${zshrc:A}                 # resolve the symlink to the real file
  [[ ${zshrc:h} != ${HOME:A} ]] && targets+=(${zshrc:h})

  targets=(${(u)targets})
 
  # bwrap has to create mount points inside $root. Remember which
  # top-level names don't exist yet so we can remove them afterwards.
  for d in $targets /proc /dev /tmp /etc; do
    top=${${d#/}%%/*}
    [[ -e $root/$top || -L $root/$top ]] || created+=($top)
  done
  created=(${(u)created})
 
  for d in $targets; do
    args+=(--ro-bind $d $d)
  done
 
  (( $# )) || set -- zsh

  local state=~/.local/state/isolate/${root//\//%}
  if [[ ! -d $state ]]; then
    mkdir -p $state
    [[ -d ~/.claude ]]      && cp -a ~/.claude $state/
    [[ -f ~/.claude.json ]] && cp -a ~/.claude.json $state/
  fi
 
  # pasta: own network namespace with NAT to the internet, no access to host
  # localhost or abstract sockets. Inside it, nft blocks private/LAN ranges,
  # then bwrap starts with a generated resolv.conf passed in on fd 3.
  pasta --config-net -t none -u none -T none -U none --no-map-gw -- \
  sh -c '
dns=$1; shift
nft -f - <<EOF || exit 1
table inet isolate {
  chain out {
    type filter hook output priority 0; policy accept;
    ip daddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 169.254.0.0/16, 100.64.0.0/10 } drop
    ip6 daddr { fc00::/7, fe80::/10 } drop
  }
}
EOF
exec "$@" 3<<EOF
nameserver $dns
EOF
' isolate-net $dns \
  bwrap \
    --bind $root / \
    $args \
    --proc /proc \
    --dev /dev \
    --tmpfs /tmp \
    --symlink $zshrc /tmp/.zshrc \
    --setenv ZDOTDIR /tmp \
    --ro-bind-data 3 /etc/resolv.conf \
    --ro-bind /etc/hosts /etc/hosts \
    --ro-bind /etc/ssl /etc/ssl \
    --ro-bind /etc/passwd /etc/passwd \
    --bind $state /tmp/home \
    --setenv HOME /tmp/home \
    --unshare-all \
    --uid $UID \
    --gid $GID \
    --cap-drop ALL \
    --share-net \
    --die-with-parent \
    --chdir / \
    -- "$@"
  ret=$?
 
  # Clean up the empty mount-point directories bwrap left behind
  # (only directories that are still empty; nothing you created is deleted).
  for d in $created; do
    [[ -d $root/$d && ! -L $root/$d ]] && find $root/$d -depth \( -type d -o -type f \) -empty -delete
  done
 
  return ret
}
