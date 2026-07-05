def main [mode: string, save_script: string] {
  sleep 500ms
  let tmp_file = $"/tmp/wkshot_(random int).png"
  ^hyprshot -m $mode -z --raw | save --raw $tmp_file
  # dispatch the prompt at spawn time so the oneshot rule can't expire during a slow region drag
  let rules = "{ float = true, size = {360, 130}, center = true, stay_focused = true, focus_on_activate = true }"
  ^hyprctl dispatch $"hl.dsp.exec_cmd\('ghostty --title=name-shot -e nu ($save_script) ($tmp_file)', ($rules)\)"
}
