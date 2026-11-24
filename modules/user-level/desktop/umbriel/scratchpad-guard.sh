# umbriel restores scratchpad windows against the barless output on a reconnect, so the bar's later remap pushes them down
sock="$XDG_RUNTIME_DIR/umbriel-$WAYLAND_DISPLAY.sock"
settle=3

declare -A goodX=() goodY=() curX=() curY=()
detached=0
pending=0
deadline=0
moved=0
last=""

coproc STREAM {
  # sleep holds stdin open so socat keeps the subscription instead of closing after the request
  { printf '{"cmd":"subscribe","events":["windows"]}\n'; exec sleep infinity; } \
    | socat - "UNIX-CONNECT:$sock" \
    | jq --unbuffered -r 'select(.event == "windows") | [.data[] | select(.scratchpad != "") | "\(.id) \(if .output == "" then "-" else .output end) \(.x) \(.y)"] | join(";")'
}

restore() {
  local id dx dy
  moved=0
  for id in "${!goodX[@]}"; do
    [[ -n ${curX[$id]-} ]] || continue
    dx=$((goodX[$id] - curX[$id]))
    dy=$((goodY[$id] - curY[$id]))
    if ((dx != 0 || dy != 0)); then
      moved=1
      jq -cn --arg w "$id" --argjson dx "$dx" --argjson dy "$dy" \
        '{cmd: "action", action: "window-move-by", dx: $dx, dy: $dy, window: $w}' \
        | socat -t2 - "UNIX-CONNECT:$sock" >/dev/null || true
    fi
  done
}

track() {
  local entry id out x y any=0
  local -a entries=()
  declare -A seen=()
  IFS=';' read -r -a entries <<<"$1"
  for entry in "${entries[@]}"; do
    read -r id out x y <<<"$entry"
    seen[$id]=1
    # a pad with no output is mid-reconnect, and its last good position is what gets restored
    if [[ $out == - ]]; then
      any=1
      continue
    fi
    curX[$id]=$x
    curY[$id]=$y
    if [[ -z ${goodX[$id]-} ]] || ((!pending)); then
      goodX[$id]=$x
      goodY[$id]=$y
    fi
  done
  for id in "${!goodX[@]}"; do
    if [[ -z ${seen[$id]-} ]]; then
      unset "goodX[$id]" "goodY[$id]" "curX[$id]" "curY[$id]"
    fi
  done
  if ((any)); then
    detached=1
    pending=1
  elif ((detached)); then
    detached=0
  fi
}

while true; do
  # pending only clears after a quiet pass with nothing left to move, so a late bar remap still gets undone
  if ((pending && !detached && SECONDS >= deadline)); then
    restore
    ((moved)) || pending=0
    deadline=$((SECONDS + settle))
  fi
  rc=0
  IFS= read -r -t 1 line <&"${STREAM[0]}" || rc=$?
  if ((rc > 128)); then
    continue
  elif ((rc != 0)); then
    exit 1
  fi
  # title and focus churn repeats the same geometry, and must not keep pushing the settle deadline out
  [[ $line == "$last" ]] && continue
  last=$line
  track "$line"
  deadline=$((SECONDS + settle))
done
