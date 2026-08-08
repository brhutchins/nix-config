{ config, lib, pkgs, system, ... }:

with lib;
with pkgs;

let
  cfg = config.local.core;
  rosePineSlate = config.local.theme."rose-pine-slate";
  c = rosePineSlate.colors;
  data = import ../../../modules/data;
  isLinux = lib.strings.hasSuffix "linux" system;
  isDarwin = lib.strings.hasSuffix "darwin" system;
  gui-packages = {
    firefox = if isLinux then firefox-wayland else firefox;
    kitty = ../terminals/kitty;
  };
  p = {
    utils = [
      bat
      btop
      devbox
      fd
      fzf
      git
      git-filter-repo
      gnupg
      htop
      httpie
      jq
      nh
      nodejs_24
      pandoc
      procps
      ripgrep
      slides
      tailscale
      tldr
      unzip
      xh
      zoxide
    ];
    languages = [
      agda
    ];
    languageServers = [
      nil
      nixd
    ];
    nixSpecific = [
      nix-prefetch-scripts
    ];
    fonts = [
      nerd-fonts.symbols-only
      hasklig
      ibm-plex
      inter
      emacs-all-the-icons-fonts
    ];
    gui = with gui-packages; [
      anki-bin
    ];
  };
  mkGui = lists.optionals cfg.gui.enable;
  # On Darwin with Zscaler, point SSL tooling at the combined CA bundle built
  # by the nix-darwin activation script (includes the Zscaler root CA).
  # This is controlled by config instead of `builtins.pathExists`, since flake
  # evaluation is pure and would incorrectly treat this host path as missing.
  zscalerBundle = "/etc/ssl/certs/ca-bundle-with-zscaler.crt";
  gitEmail = if cfg.work.enable then data.email.work else data.email.personal;
  gitUserName = if cfg.work.enable then data.git.userName.work else data.git.userName.personal;
  signingKeyName = if cfg.work.enable then data.git.signingKey.work else data.git.signingKey.personal;
  gitSigningKeyPath = config.home.homeDirectory + "/.ssh/" + signingKeyName + ".pub";

  # Fetch zjstatus at build time via nix so zellij never needs to download it
  # at runtime (which fails because zellij's rustls doesn't trust Zscaler's CA).
  zjstatus = pkgs.fetchurl {
    url = "https://github.com/dj95/zjstatus/releases/download/v0.22.0/zjstatus.wasm";
    hash = "sha256-TeQm0gscv4YScuknrutbSdksF/Diu50XP4W/fwFU3VM=";
  };
in
{
  imports = [
    ./rose-pine-slate.nix
    ../darwin/core
    ../editors/helix
    ../editors/nvim
    ../terminals/kitty
    ../terminals/wezterm
    ../tools/tuicr
    ../tools/gh-dash
    ../linux/gui
  ];

  options.local.core = {
    gui.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether we're installing core gui apps (e.g., Firefox)";
    };

    work.enable = mkOption {
      type = types.bool;
      default = false;
      description = "If this is a work setup, we'll, e.g., use work email for Git.";
    };

    zscaler.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to point SSL tooling at the Darwin Zscaler CA bundle.";
    };
  };

  config = {

    # nixpkgs.allowUnfree = true;

    home.packages =
         p.utils
      ++ p.languages
      ++ p.languageServers
      ++ p.nixSpecific
      ++ mkGui p.fonts
      ++ mkGui p.gui;

    home.shellAliases = {
      vim = "nvim";
    };

    #####
    #
    # Nix

    programs.nix-index.enable = true;


    #####
    #
    # zsh

    programs.zsh = {
      enable = true;
      autocd = true;
      dotDir = config.home.homeDirectory + "/.config/zsh";
      autosuggestion.enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      shellAliases = {
        kill_bg = "kill $(jobs -l | sed -r 's/\[([0-9]+)\].+/%\1/')";
      };

      initContent = ''
      # disable syntax highlighting on paste, to avoid speed issues
      zle_highlight+=(paste:none)

      # Not deterministic, but the Nix option doesn't seem to work.
      export EDITOR=nvim

      # zoxide
      eval "$(zoxide init zsh)"

      ### Fix slowness of pastes with zsh-syntax-highlighting.zsh
      pasteinit() {
        OLD_SELF_INSERT=''${''${(s.:.)widgets[self-insert]}[2,3]}
        zle -N self-insert url-quote-magic
      }

      pastefinish() {
        zle -N self-insert $OLD_SELF_INSERT
      }
      zstyle :bracketed-paste-magic paste-init pasteinit
      zstyle :bracketed-paste-magic paste-finish pastefinish
      ### Fix slowness of pastes

      # functions
      gch () {
        if [[ -z $1 ]]; then
          SEARCH=("fzf")
        else
          SEARCH=("fzf" "--query" "$1")
        fi
        git checkout "$(git branch --all | {$SEARCH[@]} | tr -d ' ')"
      }
      '';
    };

    programs.zsh.oh-my-zsh = {
      enable = true;
      plugins = [
        "vi-mode"
      ];
    };


    #####
    #
    # bash

    programs.bash = {
      enable = true;
      enableCompletion = true;
      bashrcExtra = ''
      set -o vi
      '';
    };


    #####
    #
    # prompt

    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      settings = {
        palette = "rose_pine";
        palettes.rose_pine = {
          inherit (c)
            base
            surface
            overlay
            text
            subtle
            iris
            pine
            foam
            rose
            gold
            love;
        };

        character = {
          success_symbol = "[❯](foam)";
          error_symbol = "[❯](love)";
          vicmd_symbol = "[❮](iris)";
        };

        directory.style = "foam";
        git_branch.style = "pine";
        git_status.style = "rose";
        cmd_duration.style = "gold";
        username.style_user = "subtle";
        username.style_root = "love";
        hostname.style = "subtle";
        nix_shell.style = "iris";
      };
    };


    #####
    #
    # Environments

    home.sessionVariables = mkMerge [
      {
        EDITOR = "nvim";
      }
      (mkIf isLinux {
        MOZ_ENABLE_WAYLAND = 1;
        XDG_CURRENT_DESKTOP = "sway";
      })
      (mkIf (isDarwin && cfg.zscaler.enable) {
        CARGO_HTTP_CAINFO = zscalerBundle;
        NIX_SSL_CERT_FILE = zscalerBundle;
        SSL_CERT_FILE = zscalerBundle;
      })
    ];

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };


    #####
    #
    # CLI utilities

    programs.eza = {
      enable = true;
    };

    programs.nnn = {
      enable = true;
      package = pkgs.nnn.override ({ withNerdIcons = true; });
      bookmarks = {
        h = "~";
        d = "~/Development";
      };
    };

    programs.tmux = {
      enable = true;
      terminal = "tmux-256color";
      prefix = "C-a";
      sensibleOnTop = false;
      historyLimit = 100000;
      extraConfig = ''
        set -g extended-keys on
        set -g extended-keys-format csi-u
        set -ga terminal-overrides ",*:Tc"
        set -g base-index 1
        set -g pane-base-index 1
        set -g renumber-windows on
        setw -g mode-keys vi

        set -g mouse on

        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"

        bind -r C-h select-window -t :-
        bind -r C-l select-window -t :+

        bind -r h select-pane -L
        bind -r j select-pane -D
        bind -r k select-pane -U
        bind -r l select-pane -R

        bind b set-option -g status

        set -g status-position top
        set -g status-interval 5
        set -g status-left-length 100
        set -g status-right-length 100
        set -g status-left ""
        set -g status-right " #S "

        set -g status-style "bg=${c.base},fg=${c.text}"
        set -g window-status-style "bg=${c.surface},fg=${c.subtle}"
        set -g window-status-current-style "bg=${c.overlay},fg=${c.text},bold"
        set -g pane-border-style "fg=${c.overlay}"
        set -g pane-active-border-style "fg=${c.foam}"
        set -g message-style "bg=${c.overlay},fg=${c.text}"
        set -g message-command-style "bg=${c.overlay},fg=${c.text}"

        set -g allow-rename off
        set -g automatic-rename off
      '';
      plugins = with pkgs; [
        tmuxPlugins.sensible
        tmuxPlugins.resurrect
        {
          plugin = tmuxPlugins.continuum;
          extraConfig = ''
            set -g @continuum-boot 'on'
            set -g @continuum-restore 'on'
          '';
        }
        (tmuxPlugins.tmux-floax.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            substituteInPlace scripts/utils.sh \
              --replace-fail 'tmux bind -n c-M-b' 'tmux bind -n C-M-b'
          '';
        }))
        tmuxPlugins.yank
      ];
    };

    #####
    # herdr

    xdg.configFile."herdr/config.toml".text = ''
      # Show first-run notification setup on startup.
      # Missing also shows onboarding; set false after you've chosen.
      # onboarding = true

      [theme]
      # Built-in themes: catppuccin, terminal, tokyo-night, dracula, nord,
      #                  gruvbox, one-dark, solarized, kanagawa, rose-pine,
      #                  vesper
      name = "rose-pine"

      # Follow host terminal light/dark appearance and switch Herdr UI themes.
      # Existing manual behavior is unchanged unless this is true.
      # auto_switch = false
      # dark_name = "catppuccin"
      # light_name = "catppuccin-latte"

      # Override individual color tokens on top of the base theme.
      # Accepts: hex (#rrggbb), named colors, rgb(r,g,b), or panel_bg = "reset"
      # [theme.custom]
      # panel_bg = "reset"
      # accent = "#f5c2e7"
      # red = "#ff6188"
      # green = "#a6e3a1"

      [terminal]
      # Executable used for new interactive panes.
      # Empty means $SHELL, then /bin/sh.
      # default_shell = ""

      # Startup mode for new interactive pane shells: "auto", "login", or "non_login".
      # "auto" uses login shells on macOS and keeps the current behavior elsewhere.
      # shell_mode = "auto"

      # CWD policy for new panes, tabs, and workspaces when no explicit --cwd is provided.
      # Use "follow" to inherit the source pane/workspace, "home" for $HOME,
      # "current" for Herdr's process directory, or a fixed path such as "~/Projects".
      # new_cwd = "follow"

      [update]
      # Update channel used by background version checks and `herdr update`.
      # Use "stable" for normal releases or "preview" for opt-in preview builds.
      # channel = "stable"

      # Check herdr.dev for new Herdr versions in the background.
      # version_check = true

      # Check herdr.dev for remote agent-detection manifest updates in the background.
      # manifest_check = true

      [keys]
      # Prefix key to enter prefix mode (default: "ctrl+b")
      # Examples: "ctrl+b", "f12", "esc", "-"
      # Action bindings use explicit syntax: "prefix+n" requires the prefix;
      # "ctrl+alt+n" is a direct terminal-mode shortcut.
      # Accepted key syntax: plain keys, ctrl/shift/alt/cmd/super modifiers, and special keys like enter/tab/esc/left/right/up/down.
      # Named punctuation such as minus, comma, ampersand, plus, and backtick is also accepted.
      # Most reliable direct bindings are ctrl+letter, function keys, and explicit modified chords.
      # alt+..., cmd/super, and punctuation-with-modifiers may depend on your terminal/tmux setup.
      prefix = "ctrl+space"

      # Prefix-mode actions
      # help = "prefix+?"
      # settings = "prefix+s"
      # detach = "prefix+q"
      # reload_config = "prefix+shift+r"
      # open_notification_target = "prefix+o"
      # workspace_picker = "prefix+w"
      # goto = "prefix+g"
      # new_workspace = "prefix+shift+n"
      # new_worktree = "prefix+shift+g"
      # open_worktree = ""    # optional, unset by default
      # remove_worktree = ""  # optional, unset by default; opens confirmation
      # rename_workspace = "prefix+shift+w"
      # close_workspace = "prefix+shift+d"
      # previous_workspace = "" # optional, unset by default
      # next_workspace = ""     # optional, unset by default
      # previous_agent = ""     # optional, unset by default
      # next_agent = ""         # optional, unset by default
      # focus_agent = ""        # optional indexed binding, e.g. "prefix+alt+1..9"
      # remote_image_paste = "ctrl+v" # only active in herdr --remote; empty disables raw-key image paste
      # new_tab = "prefix+c"
      # rename_tab = "prefix+shift+t"
      # previous_tab = "prefix+p"
      # next_tab = "prefix+n"
      # switch_tab = "prefix+1..9"
      # switch_workspace = ""   # optional indexed binding, e.g. "prefix+shift+1..9"
      # close_tab = "prefix+shift+x"
      # rename_pane = "prefix+shift+p"
      # edit_scrollback = "prefix+e"
      # focus_pane_left = "prefix+h"
      # focus_pane_down = "prefix+j"
      # focus_pane_up = "prefix+k"
      # focus_pane_right = "prefix+l"
      # cycle_pane_next = "prefix+tab"
      # cycle_pane_previous = "prefix+shift+tab"
      last_pane = "prefix+tab"          # optional, unset by default; bind e.g. "prefix+tab" for global back-and-forth
      # split_vertical = "prefix+v"
      # split_horizontal = "prefix+minus"
      # close_pane = "prefix+x"
      # zoom = "prefix+z"
      # resize_mode = "prefix+r"
      # toggle_sidebar = "prefix+b"

      # Navigate-mode movement. These local shortcuts win while navigate mode is open.
      # They are independent from focus_pane_*. Do not include prefix+, esc, enter, tab, or 1..9 here.
      # navigate_workspace_up = "up"
      # navigate_workspace_down = "down"
      # navigate_pane_left = "h"      # left arrow always focuses the pane to the left
      # navigate_pane_down = "j"
      # navigate_pane_up = "k"
      # navigate_pane_right = "l"     # right arrow always focuses the pane to the right

      # Custom commands use the same binding syntax.
      # type = "shell" runs detached in the background.
      # type = "pane" opens a temporary pane and closes it when the command exits.
      [[keys.command]]
      key = "prefix+alt+g"
      type = "pane"
      command = "gitu"
      description = "open gitu"

      [[keys.command]]
      key = "prefix+alt+d"
      type = "pane"
      command = "tuicr"
      description = "open tuicr"

      [[keys.command]]
      key = "prefix+alt+shift+g"
      type = "pane"
      command = "gh-dash"
      description = "open gh-dash"

      # [worktrees]
      # directory = "~/.herdr/worktrees"

      [ui]
      # Sidebar width (auto-scaled based on workspace names, this sets the default)
      # sidebar_width = 26

      # Minimum sidebar width when expanded (columns)
      # sidebar_min_width = 18

      # Maximum sidebar width when expanded (columns)
      # sidebar_max_width = 36

      # Collapsed sidebar presentation: "compact" keeps the narrow status rail, "hidden" uses zero width.
      # sidebar_collapsed_mode = "compact"

      # Terminal width at or below which Herdr uses the mobile single-column layout.
      # Increase this for foldables, tablets, or wide phone terminals.
      # mobile_width_threshold = 64

      # Capture mouse input for Herdr's mouse UI.
      # Set false to let the terminal handle normal clicks, such as Cmd-clicking URLs.
      # Pane apps like lazygit and btop can still receive mouse when they request it.
      # mouse_capture = true

      # Host cursor policy: "auto", "native", or "drawn".
      # "auto" draws Herdr's own cursor on Windows to avoid ConPTY cursor flicker, and uses the native terminal cursor elsewhere.
      # "native" always uses the outer terminal cursor. "drawn" always draws Herdr's cursor as terminal cell content.
      # host_cursor = "auto"

      # Optional modifier that forwards right-click hold/drag gestures to pane apps instead of opening Herdr's pane menu.
      # Empty/off disables this. Shift is intentionally unsupported because terminals commonly reserve Shift+mouse.
      # right_click_passthrough_modifier = ""

      # Force a full redraw when the outer terminal regains focus.
      # Set false to reduce visible flashing when switching back to Herdr.
      # Trade-off: rare host terminal surface corruption may persist until the next full redraw.
      # redraw_on_focus_gained = true

      # Pane scrollback lines to scroll per mouse wheel notch.
      # mouse_scroll_lines = 3

      # Ask for confirmation before closing a workspace
      # confirm_close = true

      # Ask for a tab name before creating a new tab.
      # Set false to create tabs immediately with generated names.
      # prompt_new_tab_name = true

      # Draw borders around split panes.
      pane_borders = false

      # Keep split panes visually separated instead of sharing divider borders.
      # pane_gaps = true

      # Show detected/reported agent labels in split pane borders when no manual pane name is set.
      # show_agent_labels_on_pane_borders = false

      # Hide the tab row when a workspace has exactly one tab.
      # New tabs can still be created with the configured keybinding.
      # hide_tab_bar_when_single_tab = false

      # Agent panel ordering: "spaces" (grouped by space) or "priority" (attention queue).
      # "workspaces" is accepted as an alias for "spaces".
      # agent_panel_sort = "spaces"

      # Accent color for highlights, borders, and navigation UI.
      # Accepts: hex (#89b4fa), named colors (cyan, blue, magenta), or rgb(r,g,b)
      # accent = "cyan"

      # Background notification popup delivery
      [ui.toast]
      # off = disable pop-up notifications
      # herdr = show in-app toasts
      # terminal = ask the outer terminal to show a desktop notification
      # system = ask the OS notification service directly
      delivery = "herdr"
      # delay_seconds = 1

      [ui.toast.herdr]
      position = "top-right"

      [ui.toast.clipboard]
      # enabled = true
      # position = "bottom-center"

      # Play sounds when agents change state in background workspaces
      [ui.sound]
      # enabled = true
      # Optional custom mp3 sound files. Relative paths are resolved from this config file's directory.
      # path = "sounds/notification.mp3"   # one mp3 file for all sound notifications
      # done_path = "sounds/done.mp3"      # overrides only finished notifications
      # request_path = "sounds/request.mp3" # overrides only needs-attention notifications

      # Per-agent overrides: default | on | off
      # By default, droid is muted.
      # [ui.sound.agents]
      # droid = "off"

      [session]
      # Resume supported AI-agent panes into their native conversation sessions after
      # a Herdr server restart. Requires official integrations that report session refs.
      # resume_agents_on_restore = true

      [remote]
      # Whether herdr manages the ssh config used for `herdr --remote`.
      # When true (default), herdr runs remote ssh through a generated config that
      # includes your ~/.ssh/config first and adds ServerAliveInterval/
      # ServerAliveCountMax as fallbacks (so any keepalive values you set yourself
      # still win) to survive idle network/NAT timeouts. Herdr also uses a private
      # per-attach OpenSSH control socket to reuse the first authenticated connection.
      # Set false to run plain ssh against your ssh config unchanged — this does not
      # force keepalive or multiplexing off, it only stops herdr from adding its own.
      # manage_ssh_config = true

      [experimental]
      # Allow launching herdr from inside a herdr-managed pane.
      # allow_nested = false
      # Experimental local Kitty graphics rendering for attached clients.
      # Requires a Kitty graphics-compatible outer terminal.
      kitty_graphics = true
      # Save recent pane screen history across full server restarts.
      pane_history = true
      # While prefix mode is active, temporarily switch the macOS host input
      # source to an ASCII-capable keyboard layout so prefix commands register
      # even when a CJK IME is active, then restore the previous input source
      # when prefix mode exits. macOS only; best-effort. Default: false.
      # switch_ascii_input_source_in_prefix = false
      # Expose the focused pane's cursor to the outer terminal so macOS input
      # methods keep tracking the candidate window when TUIs paint their own
      # cursor (Claude Code, pi, codex). Trade-off: extra cursor visible for
      # apps that hide it without painting a replacement (vim normal mode, etc.).
      # reveal_hidden_cursor_for_cjk_ime = false
      # Optional allow-list: only reveal for focused panes whose detected agent
      # matches one of these names. Empty means apply to any focused pane.
      # If the list contains no valid names, the reveal does not apply.
      # Accepted: pi, claude, codex, gemini, cursor, devin, cline, opencode,
      # copilot, kimi, kiro, droid, amp, grok, hermes, kilo, qodercli, qoder.
      # cjk_ime_agents = []
      # Cursor shape rendered when reveal_hidden_cursor_for_cjk_ime is true.
      # Values: block, steady_block (default), underline, steady_underline, bar, steady_bar.
      # cjk_ime_cursor_shape = "steady_block"

      [advanced]
      # Maximum scrollback buffer size in bytes retained per pane terminal.
      # Matches Ghostty's default scrollback-limit behavior.
      # scrollback_limit_bytes = 10000000

    '';

    #####

    programs.zellij = {
      enable = true;
      settings = {
        pane_frames = false;
        simplified_ui = true;
        hide_frame_for_single_pane = true;
        theme = "oxocarbon";
        copy_on_select = true;
        scrollback = 10000;
        mouse_mode = true;
        auto_layout = true;
        attach_existing_session = true;
        default_layout = "compact";
        plugins = {
          zjstatus = {
            location = "file:${zjstatus}";
          };
        };
      };
      enableBashIntegration = false;
      enableZshIntegration = false;
      extraConfig = ''
        themes {
          oxocarbon {
            // base00 = #161616, base01 = ~#262626, base02 = ~#393939, base03 = ~#525252
            // base04 = ~#dde1e7, base09 = #78a9ff, base11 = #33b1ff
            // base12 = #ff7eb6, base13 = #42be65, base14 = #be95ff, base15 = #82cfff
            text_unselected {
              base 221 225 231
              background 22 22 22
              emphasis_0 255 126 182
              emphasis_1 130 207 255
              emphasis_2 66 190 101
              emphasis_3 190 149 255
            }
            text_selected {
              base 221 225 231
              background 57 57 57
              emphasis_0 255 126 182
              emphasis_1 130 207 255
              emphasis_2 66 190 101
              emphasis_3 190 149 255
            }
            ribbon_unselected {
              base 22 22 22
              background 82 82 82
              emphasis_0 255 126 182
              emphasis_1 221 225 231
              emphasis_2 120 169 255
              emphasis_3 190 149 255
            }
            ribbon_selected {
              base 22 22 22
              background 120 169 255
              emphasis_0 255 126 182
              emphasis_1 130 207 255
              emphasis_2 190 149 255
              emphasis_3 66 190 101
            }
            table_title {
              base 66 190 101
              background 0
              emphasis_0 255 126 182
              emphasis_1 130 207 255
              emphasis_2 66 190 101
              emphasis_3 190 149 255
            }
            table_cell_unselected {
              base 221 225 231
              background 22 22 22
              emphasis_0 255 126 182
              emphasis_1 130 207 255
              emphasis_2 66 190 101
              emphasis_3 190 149 255
            }
            table_cell_selected {
              base 221 225 231
              background 57 57 57
              emphasis_0 255 126 182
              emphasis_1 130 207 255
              emphasis_2 66 190 101
              emphasis_3 190 149 255
            }
            list_unselected {
              base 221 225 231
              background 22 22 22
              emphasis_0 255 126 182
              emphasis_1 130 207 255
              emphasis_2 66 190 101
              emphasis_3 190 149 255
            }
            list_selected {
              base 221 225 231
              background 57 57 57
              emphasis_0 255 126 182
              emphasis_1 130 207 255
              emphasis_2 66 190 101
              emphasis_3 190 149 255
            }
            // frame_unselected: base = divider line color (~base01), bg = terminal bg
            // Using base01 (~#262626) as the line color gives a subtle separator
            frame_unselected {
              base 38 38 38
              background 22 22 22
              emphasis_0 82 82 82
              emphasis_1 57 57 57
              emphasis_2 57 57 57
              emphasis_3 57 57 57
            }
            frame_selected {
              base 120 169 255
              background 0
              emphasis_0 255 126 182
              emphasis_1 130 207 255
              emphasis_2 190 149 255
              emphasis_3 0
            }
            frame_highlight {
              base 255 126 182
              background 0
              emphasis_0 190 149 255
              emphasis_1 255 126 182
              emphasis_2 255 126 182
              emphasis_3 255 126 182
            }
            exit_code_success {
              base 66 190 101
              background 0
              emphasis_0 51 177 255
              emphasis_1 22 22 22
              emphasis_2 190 149 255
              emphasis_3 120 169 255
            }
            exit_code_error {
              base 255 126 182
              background 0
              emphasis_0 130 207 255
              emphasis_1 0
              emphasis_2 0
              emphasis_3 0
            }
          }
        }
      '';
      layouts = {
        compact = ''
          layout {
              default_tab_template {
                  children
                  pane size=1 borderless=true {
                      plugin location="file:${zjstatus}" {
                          format_left   "{mode} #[fg=#78a9ff,bold]{session}"
                          format_center "{tabs}"
                          format_right  "{command_git_branch} {datetime}"
                          format_space  ""

                          hide_frame_for_single_pane "true"

                          mode_normal  "#[bg=#78a9ff] "
                          mode_tmux    "#[bg=#ff7eb6] "

                          tab_normal   "#[fg=#525252] {name} "
                          tab_active   "#[fg=#dde1e7,bold,italic] {name} "

                          command_git_branch_command     "git rev-parse --abbrev-ref HEAD"
                          command_git_branch_format      "#[fg=#78a9ff] {stdout} "
                          command_git_branch_interval    "10"
                          command_git_branch_rendermode  "static"

                          datetime        "#[fg=#525252,bold] {format} "
                          datetime_format "%A, %d %b %Y %H:%M"
                          datetime_timezone "Europe/Berlin"
                      }
                  }
              }

              // Floating layout: small centered pane (~60% width, ~70% height)
              swap_floating_layout name="centered" {
                  floating_panes {
                      pane { x "20%"; y "15%"; width "60%"; height "70%"; }
                  }
              }

              // Floating layout: near-fullscreen (~90% width, ~90% height)
              swap_floating_layout name="fullscreen" {
                  floating_panes {
                      pane { x "5%"; y "5%"; width "90%"; height "90%"; }
                  }
              }
          }
        '';
      };
    };

    home.file.".config/ghostty/config.ghostty".text = ''
      font-family = Hasklig
      font-size = 12
      font-thicken = true
      macos-option-as-alt = left
      macos-titlebar-style = hidden
      mouse-hide-while-typing = true
      keybind = shift+enter=text:\n

      window-padding-x = 10
      window-padding-y = 10

      theme = Rose Pine

      # Keep Rose Pine accents, but use the less-purple neutral base.
      background = ${c.base}
      foreground = ${c.text}
      cursor-color = ${c.foam}
      selection-background = ${c.overlay}
      selection-foreground = ${c.text}
      palette = 0=${c.base}
      palette = 8=${c.muted}
    '';

    #####
    #
    # Version control

    programs.git = {
      enable = true;
      settings = mkMerge [
        {
          user = {
            name = gitUserName;
            email = gitEmail;
          };
          init.defaultBranch = "main";
          core.editor = "nvim";
          commit.gpgsign = true;
        }
        (mkIf cfg.work.enable {
          user.signingkey = gitSigningKeyPath;
          gpg.format = "ssh";
          gpg.ssh.allowedSignersFile = config.home.homeDirectory + "/.config/git/allowed_signers";
        })
        (mkIf (!cfg.work.enable) {
          user.signingkey = "178AD48BC452AEB5";
          gpg.format = "openpgp";
        })
        (mkIf cfg.work.enable {
          "url \"ssh://git@github.com/prlb-gts/\"".insteadOf = "https://github.com/prlb-gts/";
        })
      ];
    };

    programs.diff-so-fancy = {
      enable = true;
      enableGitIntegration = true;
    };

    programs.gh = {
      enable = true;
      settings.gitProtocol = "ssh";
      extensions = [
        pkgs.unstable.gh-enhance
        pkgs.unstable.gh-dash
      ];
    };

    home.file.".config/git/allowed_signers" = mkIf cfg.work.enable {
      text = "${gitEmail} ${builtins.readFile gitSigningKeyPath}";
    };


    #####
    #
    # Editors
    local.editors = {
      nvim.enable = true;
      helix.enable = true;
    };


    #####
    #
    # Tools
    local.tools.tuicr.enable = true;
    local.tools.gh-dash.enable = true;


    #####
    #
    # Fonts

    fonts.fontconfig.enable = mkIf cfg.gui.enable true;


    #####
    #
    # GUI

    programs.firefox = mkIf (cfg.gui.enable && isLinux) {
      enable = true;
    };

    local.terminals.kitty.enable = mkIf cfg.gui.enable true;
    local.terminals.wezterm.enable = mkIf cfg.gui.enable true;


    #####
    #
    # Darwin
    local.darwin.core.enable = stdenv.isDarwin;

  };
}
