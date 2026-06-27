{
  config,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;
in
{
  users.users.${username}.packages = [
    pkgs.zed-editor
    # zed resolves servers/formatters from PATH (which() lookup); css/html/ts servers come from dev.nix, nu LSP is nushell itself, marksman self-downloads via its extension
    pkgs.nixd
    pkgs.nufmt
    pkgs.prettier
  ];

  # copy-type so zed can rewrite it at runtime; gui edits get pulled back with `zed-s`
  hjem.users.${username}.xdg.config.files."zed/settings.json" = {
    source = ./settings.json;
    type = "copy";
  };

  # grammar/adapter wasm + the marksman binary are fetched once into .local/share/zed; persist so the tmpfs reboot doesn't re-download every boot
  preservation.preserveAt."/persist".users.${username}.directories = [
    ".config/zed"
    ".local/share/zed"
  ];
}
