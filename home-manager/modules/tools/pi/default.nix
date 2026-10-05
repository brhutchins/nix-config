{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.local.tools.pi;
  c = config.local.theme."rose-pine-slate".colors;

  # Point ketch (the agentic search CLI behind Pi's MCP tools) at the local
  # search instances. Applied to both the MCP server and the shell so the CLI
  # and the agent agree. KETCH_BACKEND is only exported when a self-hosted
  # instance is actually configured — `auto` then prefers it, and the export
  # overrides ketch's on-disk backend (which may say e.g. `tavily`). Hosts with
  # no search URLs keep whatever backend ketch has on disk.
  ketchEnv =
    (lib.optionalAttrs (cfg.searxngUrl != null) {
      KETCH_SEARXNG_URL = cfg.searxngUrl;
    })
    // (lib.optionalAttrs (cfg.degoogUrl != null) {
      KETCH_DEGOOG_URL = cfg.degoogUrl;
    })
    // (lib.optionalAttrs (cfg.searxngUrl != null || cfg.degoogUrl != null) {
      KETCH_BACKEND = cfg.searchBackend;
    });

  # rose-pine-slate theme, generated from the shared palette so it stays in sync
  # with the rest of the setup. Pi loads user themes from
  # ~/.pi/agent/themes/<name>.json and hot-reloads them on /reload.
  piTheme = {
    "$schema" = "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
    name = "rose-pine-slate";
    appearance = "dark";
    vars = {
      inherit (c)
        base surface overlay text muted subtle iris pine foam rose gold love;
      # Accent tints blended onto base for panel backgrounds.
      pineBg = "#1d2f3a";
      irisBg = "#423b4f";
      loveBg = "#4b2e3a";
      goldBg = "#4e4233";
    };
    colors = {
      accent = "iris";
      border = "overlay";
      borderAccent = "iris";
      borderMuted = "muted";
      success = "foam";
      error = "love";
      warning = "gold";
      muted = "subtle";
      dim = "muted";
      text = "text";
      thinkingText = "subtle";
      selectedBg = "overlay";
      scrollbarTrack = "overlay";
      scrollbarThumb = "subtle";
      searchMatchBg = "goldBg";
      searchMatchText = "text";
      userMessageBg = "surface";
      userMessageText = "text";
      customMessageBg = "irisBg";
      customMessageText = "subtle";
      customMessageLabel = "iris";
      toolPendingBg = "surface";
      toolSuccessBg = "pineBg";
      toolErrorBg = "loveBg";
      toolTitle = "text";
      toolOutput = "subtle";
      mdHeading = "gold";
      mdLink = "pine";
      mdLinkUrl = "subtle";
      mdCode = "rose";
      mdCodeBlock = "foam";
      mdCodeBlockBorder = "muted";
      mdQuote = "subtle";
      mdQuoteBorder = "muted";
      mdHr = "muted";
      mdListBullet = "iris";
      toolDiffAdded = "foam";
      toolDiffRemoved = "love";
      toolDiffContext = "subtle";
      syntaxComment = "muted";
      syntaxKeyword = "pine";
      syntaxFunction = "gold";
      syntaxVariable = "foam";
      syntaxString = "rose";
      syntaxNumber = "foam";
      syntaxType = "iris";
      syntaxOperator = "subtle";
      syntaxPunctuation = "subtle";
      thinkingOff = "muted";
      thinkingMinimal = "pine";
      thinkingLow = "foam";
      thinkingMedium = "iris";
      thinkingHigh = "rose";
      thinkingXhigh = "love";
      thinkingMax = "gold";
      bashMode = "foam";
    };
    export = {
      pageBg = "base";
      cardBg = "surface";
      infoBg = "goldBg";
    };
  };
in
{
  options.local.tools.pi = {
    enable = lib.mkEnableOption "Pi coding agent config (extensions, theme, Plannotator)";

    searxngUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        When set, point ketch at a SearXNG instance via KETCH_SEARXNG_URL for
        both the Pi MCP server and the ketch CLI.
      '';
    };

    degoogUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        When set, point ketch at a DeGoog instance via KETCH_DEGOOG_URL for
        both the Pi MCP server and the ketch CLI.
      '';
    };

    searchBackend = lib.mkOption {
      type = lib.types.enum [ "auto" "searxng" "degoog" ];
      default = "auto";
      description = ''
        KETCH_BACKEND. `auto` prefers the configured self-hosted instances.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Pi itself. It is a per-user agent (talks to ~/.pi, the user's repos and
    # auth), so it lives in the home profile with the rest of the config rather
    # than as a system package. All hosts track the upstream pi-nix flake.
    home.packages = [ inputs.pi-nix.packages.${pkgs.stdenv.hostPlatform.system}.pi ];

    # ketch CLI env; the MCP entry below gets the same values.
    home.sessionVariables = ketchEnv;

    # Vim-style modal editing for the pi prompt editor. Toggle at runtime with /vim.
    # Source lives in github:brhutchins/pi-vim (pinned in flake.lock).
    # The entry file imports the modules in extensions/vim-editor/, so that
    # directory must be linked too (it intentionally has no index.ts, which
    # would make Pi load it as a second extension).
    home.file.".pi/agent/extensions/vim-editor.ts" = {
      source = "${inputs.pi-vim}/extensions/vim-editor.ts";
      force = true;
    };
    home.file.".pi/agent/extensions/vim-editor" = {
      source = "${inputs.pi-vim}/extensions/vim-editor";
      force = true;
    };

    # Research mode: a read-only session mode (/research or --research) that
    # disables write tools, restricts bash to read-only commands, and declares
    # the ketch MCP tools directly to the model while active. Source lives in
    # github:brhutchins/pi-research-mode (pinned in flake.lock); Pi loads the
    # directory because it contains an index.ts entry point.
    home.file.".pi/agent/extensions/research-mode" = {
      source = "${inputs.pi-research-mode}/extensions/research-mode";
      force = true;
    };

    # rose-pine-slate theme for pi, generated from the shared palette (piTheme
    # is defined in the let block above).
    home.file.".pi/agent/themes/rose-pine-slate.json".text =
      builtins.toJSON piTheme + "\n";

    # Plannotator's Pi extension. It is an ordinary npm pi-package with runtime
    # dependencies, so instead of vendoring its dependency tree in the Nix
    # store we declare it in Pi's settings and let Pi install/resolve it.
    # settings.json is owned and mutated by Pi (lastChangelogVersion, /settings),
    # so merge the entry in idempotently rather than taking the file over with
    # home.file (a read-only store symlink Pi could not write to).
    home.activation.plannotatorPiExtension =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        settings="${config.home.homeDirectory}/.pi/agent/settings.json"
        pkg="npm:@plannotator/pi-extension@0.27.25"
        mkdir -p "$(dirname "$settings")"
        [ -f "$settings" ] || printf '{}\n' > "$settings"
        if ! ${pkgs.jq}/bin/jq -e --arg p "$pkg" '(.packages // []) | index($p)' "$settings" >/dev/null; then
          tmp="$(mktemp)"
          ${pkgs.jq}/bin/jq --arg p "$pkg" '.packages = ((.packages // []) + [$p])' "$settings" > "$tmp"
          mv "$tmp" "$settings"
        fi
      '';

    # ketch's MCP server: search / code / docs / scrape / crawl / tag as MCP
    # tools over stdio, on the same config and backends as the CLI. Like
    # settings.json, mcp.json is owned and mutated by Pi (`/mcp`, `pi mcp
    # add`), so merge the entry in idempotently rather than taking the file
    # over with home.file. The command is the Nix store path, so the server
    # does not depend on Pi inheriting a PATH that contains ketch.
    home.activation.ketchMcpServer =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mcp="${config.home.homeDirectory}/.pi/agent/mcp.json"
        cmd="${pkgs.unstable.ketch}/bin/ketch"
        env='${builtins.toJSON ketchEnv}'
        mkdir -p "$(dirname "$mcp")"
        [ -f "$mcp" ] || printf '{"mcpServers":{}}\n' > "$mcp"
        if ! ${pkgs.jq}/bin/jq -e --arg cmd "$cmd" --argjson env "$env" \
              '(.mcpServers.ketch.command == $cmd) and (.mcpServers.ketch.args == ["mcp", "serve"]) and ((.mcpServers.ketch.env // {}) == $env)' \
              "$mcp" >/dev/null 2>&1; then
          tmp="$(mktemp)"
          ${pkgs.jq}/bin/jq --arg cmd "$cmd" --argjson env "$env" \
            '.mcpServers = ((.mcpServers // {}) + { ketch: ({ command: $cmd, args: ["mcp", "serve"] } + (if ($env | length) > 0 then { env: $env } else {} end)) })' \
            "$mcp" > "$tmp" && mv "$tmp" "$mcp"
        fi
      '';
  };
}
