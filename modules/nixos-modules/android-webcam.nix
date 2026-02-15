{
  flake.nixosModules.android-webcam = {
    config,
    lib,
    pkgs,
    ...
  }: let
      startAndroidCam = pkgs.writers.writePython3Bin "andcam-start" {} ''
        import subprocess
        import sys

        ADB = "${pkgs.android-tools}/bin/adb"  # noqa: E501
        SCRCPY = "${pkgs.scrcpy}/bin/scrcpy"  # noqa: E501


        class Colors:
            GREEN = '\033[0;32m'
            BLUE = '\033[0;34m'
            RED = '\033[0;31m'
            YELLOW = '\033[1;33m'
            END = '\033[0m'


        def print_color(color, message):
            print(f"{color}{message}{Colors.END}")


        def main():
            print_color(Colors.BLUE, "Starting ADB server...")
            subprocess.run([ADB, "start-server"], check=True)

            print_color(Colors.BLUE, "Checking connected devices...")
            result = subprocess.run(
                [ADB, "devices"],
                capture_output=True,
                text=True
            )

            if "\tdevice" not in result.stdout:
                print_color(
                    Colors.RED,
                    "Error: No Android device connected"
                )
                print_color(Colors.YELLOW, "Make sure:")
                print("  1. USB debugging is enabled on your phone")
                print("  2. Phone is connected via USB")
                print("  3. You've authorized this computer")
                sys.exit(1)

            print_color(Colors.GREEN, "Device connected!")
            print_color(
                Colors.BLUE,
                "Starting camera stream to /dev/video9..."
            )
            print_color(
                Colors.YELLOW,
                "Using: back camera, no audio, 1024px width"
            )

            subprocess.run([
                SCRCPY,
                "--video-source=camera",
                "--camera-facing=back",
                "--no-audio",
                "--v4l2-sink=/dev/video9",
                "-m1024"
            ])


        if __name__ == "__main__":
            main()
      '';

      listCameras = pkgs.writers.writePython3Bin "andcam-list" {} ''
        import subprocess
        import sys

        ADB = "${pkgs.android-tools}/bin/adb"  # noqa: E501
        SCRCPY = "${pkgs.scrcpy}/bin/scrcpy"  # noqa: E501


        class Colors:
            GREEN = '\033[0;32m'
            BLUE = '\033[0;34m'
            RED = '\033[0;31m'
            END = '\033[0m'


        def print_color(color, message):
            print(f"{color}{message}{Colors.END}")


        def main():
            print_color(Colors.BLUE, "Starting ADB server...")
            subprocess.run([ADB, "start-server"], check=True)

            print_color(
                Colors.BLUE,
                "Listing available cameras on device..."
            )
            result = subprocess.run(
                [ADB, "devices"],
                capture_output=True,
                text=True
            )

            if "\tdevice" not in result.stdout:
                print_color(
                    Colors.RED,
                    "Error: No Android device connected"
                )
                sys.exit(1)

            print_color(Colors.GREEN, "Available cameras:")
            subprocess.run([SCRCPY, "--list-cameras"])


        if __name__ == "__main__":
            main()
      '';

      daemonAndroidCam = pkgs.writers.writePython3Bin "andcam-daemon" {} ''
        import subprocess
        import sys

        ADB = "${pkgs.android-tools}/bin/adb"  # noqa: E501
        SCRCPY = "${pkgs.scrcpy}/bin/scrcpy"  # noqa: E501


        class Colors:
            GREEN = '\033[0;32m'
            BLUE = '\033[0;34m'
            RED = '\033[0;31m'
            YELLOW = '\033[1;33m'
            END = '\033[0m'


        def print_color(color, message):
            print(f"{color}{message}{Colors.END}")


        def main():
            print_color(Colors.BLUE, "Starting ADB server...")
            subprocess.run([ADB, "start-server"], check=True)

            print_color(Colors.BLUE, "Checking connected devices...")
            result = subprocess.run(
                [ADB, "devices"],
                capture_output=True,
                text=True
            )

            if "\tdevice" not in result.stdout:
                print_color(
                    Colors.RED,
                    "Error: No Android device connected"
                )
                print_color(Colors.YELLOW, "Make sure:")
                print("  1. USB debugging is enabled on your phone")
                print("  2. Phone is connected via USB")
                print("  3. You've authorized this computer")
                sys.exit(1)

            print_color(Colors.GREEN, "Device connected!")
            print_color(
                Colors.BLUE,
                "Starting background camera stream to /dev/video9..."
            )
            print_color(
                Colors.YELLOW,
                "Using: back camera, no audio, no preview window"
            )
            print_color(
                Colors.YELLOW,
                "Camera will run in background. Use 'pkill scrcpy' to stop."
            )

            subprocess.run([
                SCRCPY,
                "--video-source=camera",
                "--camera-facing=back",
                "--no-audio",
                "--no-video-playback",
                "--v4l2-sink=/dev/video9",
                "-m1024"
            ])


        if __name__ == "__main__":
            main()
      '';

      customCamera = pkgs.writers.writePython3Bin "andcam-custom" {} ''
        import subprocess
        import sys

        ADB = "${pkgs.android-tools}/bin/adb"  # noqa: E501
        SCRCPY = "${pkgs.scrcpy}/bin/scrcpy"  # noqa: E501


        class Colors:
            GREEN = '\033[0;32m'
            BLUE = '\033[0;34m'
            YELLOW = '\033[1;33m'
            END = '\033[0m'


        def print_color(color, message):
            print(f"{color}{message}{Colors.END}")


        def main():
            if len(sys.argv) < 2:
                msg = "Usage: andcam-custom <camera-id> [options]"
                print_color(Colors.YELLOW, msg)
                print("Example: andcam-custom 0")
                print("Example: andcam-custom 0 --show-touches")
                print("Example: andcam-custom 0 --no-audio")
                print()
                print("Run 'andcam-list' to see available IDs")
                sys.exit(1)

            camera_id = sys.argv[1]
            extra_args = sys.argv[2:]

            print_color(Colors.BLUE, "Starting ADB server...")
            subprocess.run([ADB, "start-server"], check=True)

            msg = f"Starting camera {camera_id} to /dev/video9..."
            print_color(Colors.BLUE, msg)

            cmd = [
                SCRCPY,
                "--video-source=camera",
                f"--camera-id={camera_id}",
                "--v4l2-sink=/dev/video9",
                "-m1024"
            ]
            cmd.extend(extra_args)

            subprocess.run(cmd)


        if __name__ == "__main__":
            main()
      '';
  in {
    config = lib.mkIf config.mySystem.features.androidWebcam {
        boot = {
          kernelModules = ["v4l2loopback"];
          extraModulePackages = [config.boot.kernelPackages.v4l2loopback];
          extraModprobeConfig = ''
            options v4l2loopback devices=1 video_nr=9 card_label="Android Camera" exclusive_caps=1
          '';
        };

        users.users.${config.mySystem.user.name}.extraGroups = ["adbusers"];

        environment.systemPackages = with pkgs; [
          scrcpy
          android-tools
          startAndroidCam
          listCameras
          customCamera
          daemonAndroidCam
        ];

        environment.shellAliases = {
          cam-on = "andcam-start";
          cam-list = "andcam-list";
          cam-cust = "andcam-custom";
          cam-d = "andcam-daemon";
          cam-off = "pkill scrcpy";
        };
      };
    };
}
