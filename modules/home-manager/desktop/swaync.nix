{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
with lib; {
  config = mkIf osConfig.mySystem.features.desktop {
    services.swaync = {
      enable = true;
      settings = {
        positionX = "right";
        positionY = "top";
        control-center-margin-top = 10;
        control-center-margin-bottom = 10;
        control-center-margin-right = 10;
        control-center-margin-left = 10;
        timeout = 5;
        timeout-low = 3;
        timeout-critical = 0;
        fit-to-screen = false;
        keyboard-shortcuts = true;
        image-visibility = "when-available";
        transition-time = 200;
      };
    };

    stylix.targets.swaync.enable = true;

    services.swaync.style = ''
      * {
        font-size: 11pt;
      }

      .notification-row {
        margin: 8px;
      }

      .notification {
        background: @base00;
        border: 2px solid @base0D;
        border-radius: 12px;
        padding: 12px;
        margin: 8px;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
      }

      .notification.low {
        border: 2px solid @base03;
      }

      .notification.critical {
        border: 2px solid @base08;
        box-shadow: 0 4px 12px rgba(255, 0, 102, 0.3);
      }

      .notification-content {
        background: transparent;
        padding: 8px;
        border: none;
      }

      .summary {
        color: @base05;
        font-weight: bold;
        font-size: 12pt;
        margin-bottom: 4px;
      }

      .body {
        color: @base06;
        font-size: 10pt;
        margin-top: 4px;
      }

      .time {
        color: @base04;
        font-size: 9pt;
        margin-top: 4px;
      }

      .close-button {
        background: @base08;
        color: @base00;
        border-radius: 8px;
        padding: 4px;
        margin: 4px;
        border: none;
      }

      .close-button:hover {
        background: lighter(@base08);
      }

      .notification-action {
        background: @base01;
        color: @base05;
        border: 1px solid @base0D;
        border-radius: 8px;
        padding: 8px;
        margin: 4px;
      }

      .notification-action:hover {
        background: @base02;
      }

      .notification-action:active {
        background: @base0F;
      }

      .control-center {
        background: @base00;
        border: 2px solid @base0D;
        border-radius: 12px;
        padding: 12px;
        margin: 10px;
        box-shadow: 0 4px 16px rgba(0, 0, 0, 0.6);
      }

      .widget-title {
        color: @base05;
        font-size: 14pt;
        font-weight: bold;
        margin: 8px;
      }

      .widget-title > button {
        background: @base01;
        border: 1px solid @base0D;
        border-radius: 8px;
        color: @base05;
        padding: 6px 12px;
      }

      .widget-title > button:hover {
        background: @base02;
      }

      .widget-dnd {
        margin: 8px;
      }

      .widget-dnd > switch {
        background: @base01;
        border: 1px solid @base0D;
        border-radius: 16px;
      }

      .widget-dnd > switch:checked {
        background: @base0B;
      }

      .widget-dnd > switch slider {
        background: @base06;
        border-radius: 12px;
      }
    '';
  };
}
