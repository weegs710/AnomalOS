{
  config,
  pkgs,
  ...
}:
let
  username = config.mySystem.user.name;
  homeDir = config.users.users.${username}.home;
  lyricsDir = "${homeDir}/.local/share/rmpc/lyrics";

  rmpcOpenScript = pkgs.writeTextFile {
    name = "rmpc-open";
    executable = true;
    destination = "/bin/rmpc-open";
    text = ''
      #!${pkgs.nushell}/bin/nu
      def main [...paths: string] {
        $paths | each {|p| rmpc add $p}
        rmpc play
      }
    '';
  };

  lyricsScript = pkgs.writeTextFile {
    name = "rmpc-lyrics";
    executable = true;
    destination = "/bin/rmpc-lyrics";
    text = ''
      #!${pkgs.nushell}/bin/nu
      def main [] {
        let lrc_file = $env.LRC_FILE? | default ""
        if $lrc_file == "" { return }
        if ($lrc_file | path exists) { return }

        let title = $env.TITLE? | default ""
        if $title == "" { return }

        let artist = $env.ARTIST? | default ($env.ALBUMARTIST? | default "")
        let album = $env.ALBUM? | default ""

        let dur_str = $env.DURATION? | default ""
        let dur_secs = if $dur_str == "" {
          0
        } else {
          let parts = $dur_str | split row ":"
          let n = $parts | length
          if $n == 3 {
            ($parts | get 0 | into int) * 3600 + ($parts | get 1 | into int) * 60 + ($parts | get 2 | into int)
          } else if $n == 2 {
            ($parts | get 0 | into int) * 60 + ($parts | get 1 | into int)
          } else {
            0
          }
        }

        let url = $"https://lrclib.net/api/get?track_name=($title | url encode)&artist_name=($artist | url encode)&album_name=($album | url encode)&duration=($dur_secs)"

        let lyrics = try {
          let r = http get $url
          let synced = $r.syncedLyrics? | default ""
          let plain = $r.plainLyrics? | default ""
          if $synced != "" { $synced } else if $plain != "" { $plain } else { null }
        } catch { null }

        if $lyrics == null { return }

        mkdir ($lrc_file | path dirname)
        $lyrics | save $lrc_file
      }
    '';
  };

in
{
  users.users.${username}.packages = [
    pkgs.rmpc
    pkgs.cava
    lyricsScript
    rmpcOpenScript
  ];

  hjem.users.${username} = {
    xdg.data.files."applications/rmpc-open.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=rmpc
      GenericName=Music Player Client
      Comment=Add and play audio files in MPD via rmpc
      Exec=rmpc-open %F
      Terminal=false
      Categories=AudioVideo;Audio;Player;Music;
      MimeType=audio/aac;audio/flac;audio/mpeg;audio/ogg;audio/opus;audio/wav;audio/webm;audio/mp4;audio/mpegurl;audio/x-mpegurl;audio/x-opus+ogg;audio/x-vorbis+ogg;audio/x-m4a;audio/x-wav;audio/x-aiff;audio/aiff;
      NoDisplay=true
    '';

    xdg.config.files."rmpc/config.ron".text = ''
      #![enable(implicit_some)]
      #![enable(unwrap_newtypes)]
      #![enable(unwrap_variant_newtypes)]
      (
          address: "/home/${username}/.config/mpd/socket",
          theme: "eldritch",
          volume_step: 5,
          max_fps: 30,
          scrolloff: 5,
          wrap_navigation: true,
          enable_mouse: true,
          status_update_interval_ms: 1000,
          rewind_to_start_sec: 1,
          center_current_song_on_change: true,
          ignore_leading_the: true,
          lyrics_dir: "${lyricsDir}",
          enable_lyrics_index: true,
          enable_lyrics_hot_reload: true,
          on_song_change: ["${lyricsScript}/bin/rmpc-lyrics"],
          exec_on_song_change_at_start: true,
          browser_song_sort: [Disc, Track, Artist, Title],
          directories_sort: SortFormat(group_by_type: true, reverse: false),
          auto_open_downloads: true,
          duration_format: "%h:%m:%S",
          album_art: (
              method: Kitty,
              max_size_px: (width: 1200, height: 1200),
              disabled_protocols: ["http://", "https://"],
              vertical_align: Center,
              horizontal_align: Center,
              order: EmbeddedFirst,
          ),
          cava: (
              framerate: 60,
              autosens: true,
              sensitivity: 100,
              input: (
                  method: Pipewire,
                  source: "alsa_output.usb-Jieli_Technology_Tylubio_ST200-00.analog-stereo.monitor",
              ),
          ),
          search: (
              case_sensitive: false,
              ignore_diacritics: false,
              mode: Contains,
              search_button: false,
              tags: [
                  (value: "any",         label: "Any Tag"),
                  (value: "artist",      label: "Artist"),
                  (value: "album",       label: "Album"),
                  (value: "albumartist", label: "Album Artist"),
                  (value: "title",       label: "Title"),
                  (value: "filename",    label: "Filename"),
                  (value: "genre",       label: "Genre"),
              ],
          ),
          artists: (
              album_display_mode: NameOnly,
              album_sort_by: Date,
              album_date_tags: [Date],
          ),
          keybinds: (
              global: {
                  "q":       Quit,
                  "?":       ShowHelp,
                  ":":       CommandMode,
                  "oI":      ShowCurrentSongInfo,
                  "oo":      ShowOutputs,
                  "op":      ShowDecoders,
                  "od":      ShowDownloads,
                  "oP":      Partition(),
                  "z":       ToggleRepeat,
                  "x":       ToggleRandom,
                  "c":       ToggleConsume,
                  "v":       ToggleSingle,
                  "p":       TogglePause,
                  "s":       Stop,
                  ">":       NextTrack,
                  "<":       PreviousTrack,
                  "f":       SeekForward,
                  "b":       SeekBack,
                  ".":       VolumeUp,
                  ",":       VolumeDown,
                  "<Tab>":   NextTab,
                  "gt":      NextTab,
                  "<S-Tab>": PreviousTab,
                  "gT":      PreviousTab,
                  "1":       SwitchToTab("Queue"),
                  "2":       SwitchToTab("Artists"),
                  "3":       SwitchToTab("Album Artists"),
                  "4":       SwitchToTab("Albums"),
                  "5":       SwitchToTab("Playlists"),
                  "6":       SwitchToTab("Search"),
                  "u":       Update,
                  "U":       Rescan,
                  "R":       AddRandom,
              },
              navigation: {
                  "<C-c>":      Close,
                  "<Esc>":      Close,
                  "<CR>":       Confirm,
                  "k":          Up,
                  "<Up>":       Up,
                  "j":          Down,
                  "<Down>":     Down,
                  "h":          Left,
                  "<Left>":     Left,
                  "l":          Right,
                  "<Right>":    Right,
                  "<C-w>k":     PaneUp,
                  "<C-Up>":     PaneUp,
                  "<C-w>j":     PaneDown,
                  "<C-Down>":   PaneDown,
                  "<C-w>h":     PaneLeft,
                  "<C-Left>":   PaneLeft,
                  "<C-w>l":     PaneRight,
                  "<C-Right>":  PaneRight,
                  "K":          MoveUp,
                  "J":          MoveDown,
                  "<C-u>":      UpHalf,
                  "<C-d>":      DownHalf,
                  "<C-b>":      PageUp,
                  "<PageUp>":   PageUp,
                  "<C-f>":      PageDown,
                  "<PageDown>": PageDown,
                  "gg":         Top,
                  "G":          Bottom,
                  "<Space>":    Select,
                  "<C-Space>":  InvertSelection,
                  "/":          EnterSearch,
                  "n":          NextResult,
                  "N":          PreviousResult,
                  "a":          Add,
                  "A":          AddAll,
                  "D":          Delete,
                  "<C-r>":      Rename,
                  "i":          FocusInput,
                  "oi":         ShowInfo,
                  "<C-z>":      ContextMenu(),
                  "<C-s>s":     Save(kind: Modal(all: false, duplicates_strategy: Ask)),
                  "<C-s>a":     Save(kind: Modal(all: true, duplicates_strategy: Ask)),
                  "r":          Rate(),
              },
              queue: {
                  "d":   Delete,
                  "D":   DeleteAll,
                  "<CR>": Play,
                  "C":   JumpToCurrent,
                  "X":   Shuffle,
              },
          ),
          tabs: [
              (
                  name: "Queue",
                  pane: Split(
                      direction: Horizontal,
                      panes: [
                          (
                              size: "35%",
                              pane: Split(
                                  direction: Vertical,
                                  panes: [
                                      (
                                          size: "100%",
                                          borders: "LEFT | RIGHT | TOP",
                                          border_symbols: Rounded,
                                          pane: Pane(AlbumArt)
                                      ),
                                      (
                                          size: "12",
                                          borders: "ALL",
                                          border_symbols: Inherited(parent: Rounded, top_left: "├", top_right: "┤", bottom_left: "├", bottom_right: "┤"),
                                          border_title: [(kind: Text(" Lyrics "))],
                                          border_title_alignment: Center,
                                          pane: Pane(Lyrics)
                                      ),
                                      (
                                          size: "6",
                                          borders: "ALL",
                                          border_symbols: Inherited(parent: Rounded, top_left: "├", top_right: "┤"),
                                          pane: Pane(Cava)
                                      ),
                                  ],
                              ),
                          ),
                          (
                              size: "65%",
                              pane: Split(
                                  direction: Vertical,
                                  panes: [
                                      (
                                          size: "3",
                                          borders: "ALL",
                                          border_symbols: Inherited(parent: Rounded, bottom_left: "├", bottom_right: "┤"),
                                          pane: Split(
                                              direction: Horizontal,
                                              panes: [
                                                  (size: "1", pane: Pane(Empty())),
                                                  (size: "100%", pane: Pane(QueueHeader())),
                                              ]
                                          )
                                      ),
                                      (
                                          size: "100%",
                                          borders: "LEFT | RIGHT | BOTTOM",
                                          border_symbols: Rounded,
                                          pane: Split(
                                              direction: Horizontal,
                                              panes: [
                                                  (size: "1", pane: Pane(Empty())),
                                                  (size: "100%", pane: Pane(Queue)),
                                              ]
                                          )
                                      ),
                                  ],
                              )
                          ),
                      ],
                  ),
              ),
              (
                  name: "Artists",
                  borders: "ALL",
                  border_symbols: Rounded,
                  pane: Split(
                      size: "100%",
                      direction: Vertical,
                      panes: [(pane: Pane(Artists), size: "100%", borders: "ALL", border_symbols: Rounded)],
                  )
              ),
              (
                  name: "Album Artists",
                  borders: "ALL",
                  border_symbols: Rounded,
                  pane: Split(
                      size: "100%",
                      direction: Vertical,
                      panes: [(pane: Pane(AlbumArtists), size: "100%", borders: "ALL", border_symbols: Rounded)],
                  )
              ),
              (
                  name: "Albums",
                  borders: "ALL",
                  border_symbols: Rounded,
                  pane: Split(
                      size: "100%",
                      direction: Vertical,
                      panes: [(pane: Pane(Albums), size: "100%", borders: "ALL", border_symbols: Rounded)],
                  )
              ),
              (
                  name: "Playlists",
                  borders: "ALL",
                  border_symbols: Rounded,
                  pane: Split(
                      size: "100%",
                      direction: Vertical,
                      panes: [(pane: Pane(Playlists), size: "100%", borders: "ALL", border_symbols: Rounded)],
                  )
              ),
              (
                  name: "Search",
                  borders: "ALL",
                  border_symbols: Rounded,
                  pane: Split(
                      size: "100%",
                      direction: Vertical,
                      panes: [(pane: Pane(Search), size: "100%", borders: "ALL", border_symbols: Rounded)],
                  )
              ),
          ],
      )
    '';

    xdg.config.files."rmpc/themes/eldritch.ron".text = ''
      #![enable(implicit_some)]
      #![enable(unwrap_newtypes)]
      #![enable(unwrap_variant_newtypes)]
      (
          default_album_art_path: None,
          format_tag_separator: " | ",
          browser_column_widths: [20, 38, 42],
          background_color: "#212337",
          text_color: "#ebfafa",
          header_background_color: None,
          modal_background_color: "#212337",
          modal_backdrop: false,
          preview_label_style: (fg: "#f1fc79", modifiers: "Bold"),
          preview_metadata_group_style: (fg: "#f1fc79", modifiers: "Bold"),
          highlighted_item_style: (fg: "#04d1f9", modifiers: "Bold"),
          current_item_style: (fg: "#212337", bg: "#37f499", modifiers: "Bold"),
          borders_style: (fg: "#606b9d"),
          highlight_border_style: (fg: "#04d1f9"),
          symbols: (
              song: "S",
              dir: "D",
              playlist: "P",
              marker: "M",
              ellipsis: "...",
              song_style: None,
              dir_style: None,
              playlist_style: None,
              marker_style: None,
              song_highlighted_style: None,
              dir_highlighted_style: None,
              playlist_highlighted_style: None,
              marker_highlighted_style: None,
              song_current_style: None,
              dir_current_style: None,
              playlist_current_style: None,
              marker_current_style: None,
          ),
          level_styles: (
              info:  (fg: "#04d1f9", bg: "#212337"),
              warn:  (fg: "#e9f941", bg: "#212337"),
              error: (fg: "#f9515d", bg: "#212337"),
              debug: (fg: "#37f499", bg: "#212337"),
              trace: (fg: "#a48cf2", bg: "#212337"),
          ),
          progress_bar: (
              symbols: ["█", "█", "█", " ", "█"],
              track_style: (fg: "#434b6e"),
              elapsed_style: (fg: "#37f499"),
              thumb_style: (fg: "#04d1f9"),
              use_track_when_empty: true,
          ),
          scrollbar: (
              symbols: ["│", "█", "▲", "▼"],
              track_style: (),
              ends_style: (),
              thumb_style: (fg: "#606b9d"),
          ),
          tab_bar: (
              active_style: (fg: "#212337", bg: "#37f499", modifiers: "Bold"),
              inactive_style: (fg: "#abb4da"),
          ),
          lyrics: (
              timestamp: false
          ),
          cava: (
              bar_color: Gradient({0: "#37f499", 50: "#04d1f9", 100: "#a48cf2"}),
              bar_spacing: 1,
              bar_width: 1,
              orientation: Bottom,
          ),
          browser_song_format: [
              (
                  kind: Group([
                      (kind: Property(Track)),
                      (kind: Text(" ")),
                  ])
              ),
              (
                  kind: Group([
                      (kind: Property(Artist)),
                      (kind: Text(" - ")),
                      (kind: Property(Title)),
                  ]),
                  default: (kind: Property(Filename))
              ),
          ],
          song_table_format: [
              (
                  prop: (kind: Property(Artist), default: (kind: Text("Unknown"))),
                  label_prop: (kind: Text("Artist")),
                  width: "20%",
              ),
              (
                  prop: (kind: Property(Title), default: (kind: Text("Unknown"))),
                  label_prop: (kind: Text("Title")),
                  width: "35%",
              ),
              (
                  prop: (kind: Property(Album), style: (fg: "#abb4da"),
                      default: (kind: Text("Unknown Album"), style: (fg: "#abb4da"))
                  ),
                  label_prop: (kind: Text("Album")),
                  width: "30%",
              ),
              (
                  prop: (kind: Property(Duration), default: (kind: Text("-"))),
                  label_prop: (kind: Text("Time")),
                  width: "15%",
                  alignment: Right,
              ),
          ],
          layout: Split(
              direction: Vertical,
              panes: [
                  (
                      size: "4",
                      pane: Split(
                          direction: Horizontal,
                          panes: [
                              (
                                  size: "35",
                                  borders: "LEFT | TOP | BOTTOM",
                                  border_symbols: Inherited(parent: Rounded, bottom_left: "├"),
                                  pane: Component("header_left")
                              ),
                              (
                                  size: "100%",
                                  borders: "ALL",
                                  border_symbols: Inherited(parent: Rounded, top_left: "┬", top_right: "┬", bottom_left: "┴", bottom_right: "┴"),
                                  pane: Component("header_center")
                              ),
                              (
                                  size: "35",
                                  borders: "RIGHT | TOP | BOTTOM",
                                  border_symbols: Inherited(parent: Rounded, bottom_right: "┤"),
                                  pane: Component("header_right")
                              ),
                          ]
                      )
                  ),
                  (
                      pane: Pane(Tabs),
                      borders: "RIGHT | LEFT | BOTTOM",
                      border_symbols: Rounded,
                      size: "2",
                  ),
                  (
                      pane: Pane(TabContent),
                      size: "100%",
                  ),
                  (
                      size: "3",
                      pane: Split(
                          direction: Horizontal,
                          panes: [
                              (
                                  size: "12",
                                  borders: "ALL",
                                  border_symbols: Inherited(parent: Rounded, top_right: "┬", bottom_right: "┴"),
                                  pane: Component("input_mode")
                              ),
                              (
                                  size: "100%",
                                  borders: "TOP | BOTTOM | RIGHT",
                                  border_symbols: Rounded,
                                  border_title: [(kind: Text(" ")), (kind: Property(Status(QueueLength()))), (kind: Text(" songs / ")), (kind: Property(Status(QueueTimeTotal()))), (kind: Text(" total time "))],
                                  border_title_alignment: Right,
                                  pane: Component("progress_bar"),
                              ),
                          ]
                      ),
                  ),
              ],
          ),
          components: {
              "state": Pane(Property(
                  content: [
                      (kind: Text("["), style: (fg: "#37f499", modifiers: "Bold")),
                      (kind: Property(Status(StateV2())), style: (fg: "#37f499", modifiers: "Bold")),
                      (kind: Text("]"), style: (fg: "#37f499", modifiers: "Bold")),
                  ], align: Left,
              )),
              "title": Pane(Property(
                  content: [
                      (kind: Property(Song(Title)), style: (modifiers: "Bold"),
                          default: (kind: Text("No Song"), style: (modifiers: "Bold"))),
                  ], align: Center, scroll_speed: 1
              )),
              "volume": Split(
                  direction: Horizontal,
                  panes: [
                      (size: "1", pane: Pane(Property(content: [(kind: Text(""))]))),
                      (size: "100%", pane: Pane(Volume(kind: Slider(symbols: (filled: "─", thumb: "●", track: "─"))))),
                      (size: "3", pane: Pane(Property(content: [(kind: Property(Status(Volume)), style: (fg: "#04d1f9"))], align: Right))),
                      (size: "2", pane: Pane(Property(content: [(kind: Text("%"), style: (fg: "#04d1f9"))]))),
                  ]
              ),
              "elapsed_and_bitrate": Pane(Property(
                  content: [
                      (kind: Property(Status(Elapsed))),
                      (kind: Text(" / ")),
                      (kind: Property(Status(Duration))),
                      (kind: Group([
                          (kind: Text(" (")),
                          (kind: Property(Status(Bitrate))),
                          (kind: Text(" kbps)")),
                      ])),
                  ],
                  align: Left,
              )),
              "artist_and_album": Pane(Property(
                  content: [
                      (kind: Property(Song(Artist)), style: (fg: "#f1fc79", modifiers: "Bold"),
                          default: (kind: Text("Unknown"), style: (fg: "#f1fc79", modifiers: "Bold"))),
                      (kind: Text(" - ")),
                      (kind: Property(Song(Album)), default: (kind: Text("Unknown Album"))),
                  ], align: Center, scroll_speed: 1
              )),
              "states": Split(
                  direction: Horizontal,
                  panes: [
                      (
                          size: "1",
                          pane: Pane(Empty())
                      ),
                      (
                          size: "100%",
                          pane: Pane(Property(content: [(kind: Property(Status(InputBuffer())), style: (fg: "#04d1f9"), align: Left)]))
                      ),
                      (
                          size: "6",
                          pane: Pane(Property(content: [
                              (kind: Text("["), style: (fg: "#606b9d", modifiers: "Bold")),
                              (kind: Property(Status(RepeatV2(
                                  on_label: "z",
                                  off_label: "z",
                                  on_style: (fg: "#37f499", modifiers: "Bold"),
                                  off_style: (fg: "#606b9d", modifiers: "Dim"),
                              )))),
                              (kind: Property(Status(RandomV2(
                                  on_label: "x",
                                  off_label: "x",
                                  on_style: (fg: "#37f499", modifiers: "Bold"),
                                  off_style: (fg: "#606b9d", modifiers: "Dim"),
                              )))),
                              (kind: Property(Status(ConsumeV2(
                                  on_label: "c",
                                  off_label: "c",
                                  oneshot_label: "c",
                                  on_style: (fg: "#37f499", modifiers: "Bold"),
                                  off_style: (fg: "#606b9d", modifiers: "Dim"),
                                  oneshot_style: (fg: "#f9515d", modifiers: "Dim"),
                              )))),
                              (kind: Property(Status(SingleV2(
                                  on_label: "v",
                                  off_label: "v",
                                  oneshot_label: "v",
                                  on_style: (fg: "#37f499", modifiers: "Bold"),
                                  off_style: (fg: "#606b9d", modifiers: "Dim"),
                                  oneshot_style: (fg: "#f9515d", modifiers: "Bold"),
                              )))),
                              (kind: Text("]"), style: (fg: "#606b9d", modifiers: "Bold")),
                              ],
                              align: Right
                          ))
                      ),
                  ]
              ),
              "input_mode": Pane(Property(
                  content: [
                      (kind: Transform(Replace(content: (kind: Property(Status(InputMode()))), replacements: [
                          (match: "Normal", replace: (kind: Text(" NORMAL "), style: (fg: "#212337", bg: "#7081d0"))),
                          (match: "Insert", replace: (kind: Text(" INSERT "), style: (fg: "#212337", bg: "#37f499"))),
                      ])))
                  ], align: Center
              )),
              "header_left": Split(
                  direction: Vertical,
                  panes: [
                      (size: "1", pane: Component("state")),
                      (size: "1", pane: Component("elapsed_and_bitrate")),
                  ]
              ),
              "header_center": Split(
                  direction: Vertical,
                  panes: [
                      (size: "1", pane: Component("title")),
                      (size: "1", pane: Component("artist_and_album")),
                  ]
              ),
              "header_right": Split(
                  direction: Vertical,
                  panes: [
                      (size: "1", pane: Component("volume")),
                      (size: "1", pane: Component("states")),
                  ]
              ),
              "progress_bar": Split(
                  direction: Horizontal,
                  panes: [
                      (size: "1", pane: Pane(Empty())),
                      (size: "100%", pane: Pane(ProgressBar)),
                      (size: "1", pane: Pane(Empty())),
                  ]
              )
          },
      )
    '';
  };

  systemd.user.tmpfiles.rules = [
    "d ${lyricsDir} 0755 - - -"
  ];

  environment.persistence."/persist".users.${username}.directories = [
    ".local/share/rmpc"
  ];
}
