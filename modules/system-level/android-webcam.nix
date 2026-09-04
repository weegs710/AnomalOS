{
  config,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;

  phoneIp = "192.168.1.151";
  # Pinned by `adb tcpip`, which does not survive a phone reboot -- `phone-adb` re-pins it.
  phonePort = "5555";
  phone = "${phoneIp}:${phonePort}";

  phoneMdnsPort = pkgs.writeText "phone-mdns-port.py" ''
    import socket
    import struct
    import sys
    import time

    SERVICES = ["_adb._tcp.local", "_adb-tls-connect._tcp.local"]


    def encode(name):
        out = b""
        for label in name.split("."):
            if label:
                out += bytes([len(label)]) + label.encode()
        return out + b"\x00"


    def read_name(buf, i):
        parts = []
        while True:
            length = buf[i]
            if length == 0:
                return ".".join(parts), i + 1
            if length & 0xC0 == 0xC0:
                ptr = struct.unpack("!H", buf[i:i + 2])[0] & 0x3FFF
                sub, _ = read_name(buf, ptr)
                parts.append(sub)
                return ".".join(parts), i + 2
            i += 1
            parts.append(buf[i:i + length].decode("utf-8", "replace"))
            i += length


    def query(ip, timeout=3.0):
        # QU bit, so the reply is unicast and returns through conntrack rather than needing 5353 open
        header = struct.pack("!HHHHHH", 0, 0, len(SERVICES), 0, 0, 0)
        body = b"".join(encode(s) + struct.pack("!HH", 255, 0x8001) for s in SERVICES)
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.settimeout(0.5)
        sock.sendto(header + body, (ip, 5353))

        found = {}
        deadline = time.time() + timeout
        while time.time() < deadline:
            try:
                data, _ = sock.recvfrom(9000)
            except socket.timeout:
                continue
            except OSError:
                break
            qd, an, ns, ar = struct.unpack("!HHHH", data[4:12])
            i = 12
            for _ in range(qd):
                _, i = read_name(data, i)
                i += 4
            for _ in range(an + ns + ar):
                name, i = read_name(data, i)
                rtype, _, _, dlen = struct.unpack("!HHIH", data[i:i + 10])
                i += 10
                if rtype == 33:
                    found[name] = struct.unpack("!H", data[i + 4:i + 6])[0]
                i += dlen
            if found:
                break
        return found


    def main():
        if len(sys.argv) < 2:
            print("usage: phone-mdns-port <ip>", file=sys.stderr)
            return 2
        found = query(sys.argv[1])
        if not found:
            print("no mdns reply", file=sys.stderr)
            return 1
        # plain _adb._tcp needs no pairing, so it is offered ahead of the tls port
        for service in SERVICES:
            for name, port in found.items():
                if name.endswith(service):
                    print(port)
        return 0


    if __name__ == "__main__":
        sys.exit(main())
  '';

  # The debug port is random again after a phone reboot, and adbd publishes the new one over mDNS.
  phoneAdb = pkgs.writeShellApplication {
    name = "phone-adb";
    runtimeInputs = with pkgs; [
      android-tools
      netcat
      coreutils
      findutils
      python3
      systemd
    ];
    text = ''
      IP=${phoneIp}
      PIN=${phonePort}
      say() { printf '%s\n' "$*" >&2; }

      if adb -s "$IP:$PIN" shell true >/dev/null 2>&1; then
        say "already on $IP:$PIN, nothing to do"
        exit 0
      fi

      if [ "$#" -ge 2 ]; then
        say "pairing on $IP:$1"
        adb pair "$IP:$1" "$2" || exit 1
        shift 2
      fi

      if [ "$#" -ge 1 ]; then
        ports=$1
        say "using the port given: $ports"
      else
        ports=$(python3 ${phoneMdnsPort} "$IP" 2>/dev/null || true)
        if [ -n "$ports" ]; then
          say "mdns: $(echo "$ports" | tr '\n' ' ')"
        else
          # a 28k-port sweep returns false negatives against this device, so it is the last resort
          say "no mdns reply, falling back to a port scan of $IP:32768-60999"
          # xargs exits 123 when any probe fails, which is every closed port, so swallow it
          ports=$(seq 32768 60999 | xargs -P 100 -I{} sh -c "nc -z -w2 $IP {} 2>/dev/null && echo {}" || true)
          if [ -z "$ports" ]; then
            say "nothing found. is wireless debugging on? read the port off the phone and pass it in"
            exit 1
          fi
          say "open: $(echo "$ports" | tr '\n' ' ')"
        fi
      fi

      for p in $ports; do
        adb connect "$IP:$p" >/dev/null 2>&1 || true
        if adb -s "$IP:$p" shell true >/dev/null 2>&1; then
          say "adb answered on $p, pinning to $PIN"
          adb -s "$IP:$p" tcpip "$PIN" || exit 1
          sleep 4
          adb disconnect "$IP:$p" >/dev/null 2>&1 || true
          ok=""
          for _ in 1 2 3; do
            # a stale transport makes adb connect report success without re-establishing anything
            adb disconnect "$IP:$PIN" >/dev/null 2>&1 || true
            adb connect "$IP:$PIN" >/dev/null 2>&1 || true
            if adb -s "$IP:$PIN" shell true >/dev/null 2>&1; then ok=1; break; fi
            sleep 2
          done
          [ -n "$ok" ] || { say "reconnect on $PIN failed"; exit 1; }
          systemctl --user restart phone-mic.service >/dev/null 2>&1 || true
          say "done. adb is on $IP:$PIN"
          exit 0
        fi
        adb disconnect "$IP:$p" >/dev/null 2>&1 || true
      done
      say "candidates found but none answered adb: $(echo "$ports" | tr '\n' ' ')"
      exit 1
    '';
  };

  # Attenuation limit 10 is the highest setting that suppresses noise without gating speech.
  phoneMicConf = pkgs.writeText "phone-mic.conf" ''
    context.properties = {
        log.level = 0
    }
    context.spa-libs = {
        audio.convert.* = audioconvert/libspa-audioconvert
        support.*       = support/libspa-support
    }
    context.modules = [
        { name = libpipewire-module-rt
            args = { }
            flags = [ ifexists nofail ]
        }
        { name = libpipewire-module-protocol-native }
        { name = libpipewire-module-client-node }
        { name = libpipewire-module-adapter }
        { name = libpipewire-module-filter-chain
            args = {
                node.description = "Phone Mic (DeepFilter)"
                media.name       = "Phone Mic (DeepFilter)"
                filter.graph = {
                    nodes = [
                        { type = builtin  name = mix  label = mixer
                          control = { "Gain 1" = 0.5  "Gain 2" = 0.5 } }
                        { type = ladspa   name = df   label = deep_filter_mono
                          plugin = "libdeep_filter_ladspa"
                          control = {
                              "Attenuation Limit (dB)"            = 10.0
                              "Min processing threshold (dB)"     = -15.0
                              "Max ERB processing threshold (dB)" = 35.0
                              "Max DF processing threshold (dB)"  = 35.0
                              "Min Processing Buffer (frames)"    = 0
                              "Post Filter Beta"                  = 0.0
                          } }
                        # Sized so a node volume of 100% is the intended ceiling, which noctalia cannot exceed.
                        { type = builtin  name = gain label = mixer
                          control = { "Gain 1" = 2.06626 } }
                    ]
                    links = [
                        { output = "mix:Out"      input = "df:Audio In" }
                        { output = "df:Audio Out" input = "gain:In 1"   }
                    ]
                    inputs  = [ "mix:In 1" "mix:In 2" ]
                    outputs = [ "gain:Out" ]
                }
                capture.props = {
                    node.name      = "phone_mic_sink"
                    node.nick      = "Phone Mic Input"
                    media.class    = "Audio/Sink"
                    audio.position = [ FL FR ]
                }
                playback.props = {
                    node.name      = "phone_mic_source"
                    node.nick      = "Phone Mic"
                    media.class    = "Audio/Source"
                    audio.position = [ MONO ]
                }
            }
        }
    ]
  '';

  # Its own app_id, so an umbriel rule can place the preview without catching every other mpv window.
  phoneCamPreview = pkgs.writeShellScriptBin "phone-cam-preview" ''
    exec ${pkgs.mpv}/bin/mpv --wayland-app-id=phone-cam --title="Phone Cam" \
      --profile=low-latency --untimed --no-osc --no-input-default-bindings \
      --geometry=480x270 av://v4l2:/dev/video9
  '';

  phoneCamList = pkgs.writeShellScriptBin "phone-cam-list" ''
    ${pkgs.android-tools}/bin/adb connect ${phone} >/dev/null 2>&1 || true
    exec ${pkgs.scrcpy}/bin/scrcpy -s ${phone} --list-cameras
  '';
in
{
  boot = {
    kernelModules = [ "v4l2loopback" ];
    extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=9 card_label="Android Camera" exclusive_caps=1
    '';
  };

  users.users.${username}.extraGroups = [ "adbusers" ];

  environment.systemPackages = with pkgs; [
    adbfs-rootless
    scrcpy
    android-tools
    deepfilternet
    phoneAdb
    phoneCamPreview
    phoneCamList
  ];

  environment.shellAliases = {
    cam-on = "systemctl --user start phone-cam";
    cam-off = "systemctl --user stop phone-cam";
    cam-view = "phone-cam-preview";
    cam-list = "phone-cam-list";
  };

  # filter-chain resolves ladspa plugins by bare name against LADSPA_PATH, never by absolute path
  systemd.user.services.phone-mic-filter = {
    description = "Phone mic DeepFilter chain";
    wantedBy = [ "default.target" ];
    after = [ "pipewire.service" ];
    environment.LADSPA_PATH = "${pkgs.deepfilternet}/lib/ladspa";
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.pipewire}/bin/pipewire -c ${phoneMicConf}";
      Restart = "always";
      RestartSec = 2;
    };
  };

  systemd.user.services.phone-mic = {
    description = "Phone microphone over scrcpy";
    wantedBy = [ "default.target" ];
    after = [ "phone-mic-filter.service" ];
    requires = [ "phone-mic-filter.service" ];
    # A filter restart orphans the scrcpy stream onto the default sink, so drag the stream with it.
    partOf = [ "phone-mic-filter.service" ];
    # No spaces or quotes, so systemd's Environment= unquoting cannot mangle it.
    environment.PIPEWIRE_PROPS = "{target.object=phone_mic_sink}";
    serviceConfig = {
      Type = "simple";
      ExecStartPre = "${pkgs.android-tools}/bin/adb connect ${phone}";
      # Every audio encoder on this device is software, and raw costs ~44% less phone CPU on a LAN.
      ExecStart = "${pkgs.scrcpy}/bin/scrcpy -s ${phone} --no-video --no-window --audio-source=mic-camcorder --audio-codec=raw";
      Restart = "always";
      RestartSec = 5;
    };
  };

  # The camera sensor stays closed until it is explicitly asked for.
  systemd.user.services.phone-cam = {
    description = "Phone camera to /dev/video9";
    serviceConfig = {
      Type = "simple";
      ExecStartPre = "${pkgs.android-tools}/bin/adb connect ${phone}";
      ExecStart = "${pkgs.scrcpy}/bin/scrcpy -s ${phone} --video-source=camera --camera-id=0 --camera-size=1920x1080 --camera-fps=60 --capture-orientation=180 --no-audio --no-window --v4l2-sink=/dev/video9";
      Restart = "no";
    };
  };

  systemd.user.services.phone-cam-view = {
    description = "Phone camera preview window";
    after = [ "phone-cam.service" ];
    partOf = [ "phone-cam.service" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${phoneCamPreview}/bin/phone-cam-preview";
      # mpv exits 4 when it is told to quit, which is a normal stop rather than a failure.
      SuccessExitStatus = 4;
      Restart = "no";
    };
  };
}
