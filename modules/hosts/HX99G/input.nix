{ ... }:
{
  # Umbriel rejects bare mouse binds and names only 5 buttons, so the ball's extra buttons are remapped below evdev.
  services.keyd = {
    enable = true;
    keyboards.trackball = {
      ids = [ "056e:011c" ];
      settings.main = {
        mouse1 = "f13";
        mouse2 = "f14";
        mouseforward = "f15";
        mouseback = "f16";
        f18 = "f17";
        # Tilts stay real pointer buttons so the focused app gets browser back/forward, not a compositor action.
        scrollleft = "mouse1";
        scrollright = "mouse2";
      };
    };
  };
}
