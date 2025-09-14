{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.steam.presence;

  # Write a base config that does not include secret values.
  # Secret file values are injected at service start into config.json.
  configBaseFile = pkgs.writeText "steam-presence-config.base.json" (builtins.toJSON {
    STEAM_API_KEY =
      if cfg.steamApiKeyFile != null
      then null
      else cfg.steamApiKey;
    USER_IDS = cfg.userIds;
    DISCORD_APPLICATION_ID = cfg.discordApplicationId;
    FETCH_STEAM_RICH_PRESENCE = cfg.fetchSteamRichPresence;
    FETCH_STEAM_REVIEWS = cfg.fetchSteamReviews;
    ADD_STEAM_STORE_BUTTON = cfg.addSteamStoreButton;
    WEB_SCRAPE = cfg.webScrape;
    COVER_ART = {
      STEAM_GRID_DB = {
        ENABLED = cfg.coverArt.steamGridDB.enable;
        STEAM_GRID_API_KEY =
          if cfg.coverArt.steamGridDB.apiKeyFile != null
          then null
          else cfg.coverArt.steamGridDB.apiKey;
      };
      USE_STEAM_STORE_FALLBACK = cfg.coverArt.useSteamStoreFallback;
    };
    LOCAL_GAMES = {
      ENABLED = cfg.localGames.enable;
      LOCAL_DISCORD_APPLICATION_ID = cfg.localGames.discordApplicationId;
      GAMES = cfg.localGames.games;
    };
    GAME_OVERWRITE = {
      ENABLED = cfg.gameOverwrite.enable;
      NAME = cfg.gameOverwrite.name;
      SECONDS_SINCE_START = cfg.gameOverwrite.secondsSinceStart;
    };
    CUSTOM_ICON = {
      ENABLED = cfg.customIcon.enable;
      URL = cfg.customIcon.url;
      TEXT = cfg.customIcon.text;
    };
    BLACKLIST = cfg.blacklist;
    WHITELIST = cfg.whitelist;
  });
in {
  options.programs.steam.presence = {
    enable = mkEnableOption "steam-presence";

    package = mkOption {
      type = types.package;
      description = "The steam-presence package to use.";
    };

    steamApiKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Your Steam Web API key.";
    };

    steamApiKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to a file containing your Steam Web API key (e.g., agenix secret).";
    };

    userIds = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "A list of Steam user IDs (SteamID64) to track.";
    };

    discordApplicationId = mkOption {
      type = types.str;
      default = "869994714093465680";
      description = "The Discord Application ID to use for the rich presence.";
    };

    fetchSteamRichPresence = mkOption {
      type = types.bool;
      default = true;
      description = "Fetch 'enhanced rich presence' information from Steam.";
    };

    fetchSteamReviews = mkOption {
      type = types.bool;
      default = false;
      description = "Fetch the review scores of Steam games.";
    };

    addSteamStoreButton = mkOption {
      type = types.bool;
      default = false;
      description = "Add a button to the Steam store page in the rich presence.";
    };

    webScrape = mkOption {
      type = types.bool;
      default = false;
      description = "Enable web scraping to detect non-Steam games.";
    };

    coverArt = {
      steamGridDB = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable fetching cover art from SteamGridDB.";
        };

        apiKey = mkOption {
          type = types.str;
          default = "STEAM_GRID_API_KEY";
          description = "Your SteamGridDB API key.";
        };

        apiKeyFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to a file containing your SteamGridDB API key (e.g., agenix secret).";
        };
      };

      useSteamStoreFallback = mkOption {
        type = types.bool;
        default = true;
        description = "Use the Steam store page for cover art as a fallback.";
      };
    };

    localGames = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable detection of locally running games.";
      };

      discordApplicationId = mkOption {
        type = types.str;
        default = "1062648118375616594";
        description = "The Discord Application ID to use for locally detected games.";
      };

      games = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "A list of process names for locally detected games.";
      };
    };

    gameOverwrite = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable overwriting the currently playing game.";
      };

      name = mkOption {
        type = types.str;
        default = "Breath of the wild, now on steam!";
        description = "The name of the game to display when overwriting.";
      };

      secondsSinceStart = mkOption {
        type = types.int;
        default = 0;
        description = "The number of seconds to offset the start time when overwriting.";
      };
    };

    customIcon = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable a custom icon in the rich presence.";
      };

      url = mkOption {
        type = types.str;
        default = "https://raw.githubusercontent.com/JustTemmie/steam-presence/main/readmeimages/defaulticon.png";
        description = "The URL of the custom icon.";
      };

      text = mkOption {
        type = types.str;
        default = "Steam Presence on Discord";
        description = "The text to display when hovering over the custom icon.";
      };
    };

    # Optional auxiliary files expected by upstream in the working directory
    cookiesFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to cookies.txt for non-Steam game detection (web scraping).";
    };

    gamesFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to games.txt mapping process names to display names.";
    };

    iconsFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to icons.txt mapping game names to icon URLs.";
    };

    customGameIDsFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to customGameIDs.json mapping game names to Discord application IDs.";
    };

    blacklist = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "A list of games to blacklist from the rich presence.";
    };

    whitelist = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "A list of games to whitelist for the rich presence.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.steamApiKey != null;
        message = "You must set programs.steam.presence.steamApiKey";
      }
      {
        assertion = cfg.userIds != [];
        message = "You must set programs.steam.presence.userIds";
      }
    ];

    # Place the base config in the runtime dir so it's next to main.py
    home.file.".local/state/steam-presence/config.base.json".source = configBaseFile;

    systemd.user.services.steam-presence = {
      Unit = {
        Description = "Discord rich presence for Steam";
        After = ["network-online.target"];
      };

      Service = {
        Environment =
          [
            "STEAM_PRESENCE_RUNTIME_DIR=%h/.local/state/steam-presence"
          ]
          ++ (optional (cfg.steamApiKeyFile != null) "STEAM_API_KEY_FILE=${toString cfg.steamApiKeyFile}")
          ++ (optional (cfg.coverArt.steamGridDB.apiKeyFile != null) "STEAM_GRID_API_KEY_FILE=${toString cfg.coverArt.steamGridDB.apiKeyFile}");

        WorkingDirectory = "%h/.local/state/steam-presence";

        ExecStartPre =
          [
            "mkdir -p %h/.local/state/steam-presence"
            ''${pkgs.bash}/bin/bash -c '[ -e %h/.local/state/steam-presence/main.py ] || cp -r ${cfg.package}/share/steam-presence/. %h/.local/state/steam-presence/' ''
          ]
          ++ (optional (cfg.cookiesFile != null) ''${pkgs.bash}/bin/bash -c 'cp -Lf ${toString cfg.cookiesFile} %h/.local/state/steam-presence/cookies.txt' '')
          ++ (optional (cfg.gamesFile != null) ''${pkgs.bash}/bin/bash -c 'cp -Lf ${toString cfg.gamesFile} %h/.local/state/steam-presence/games.txt' '')
          ++ (optional (cfg.iconsFile != null) ''${pkgs.bash}/bin/bash -c 'cp -Lf ${toString cfg.iconsFile} %h/.local/state/steam-presence/icons.txt' '')
          ++ (optional (cfg.customGameIDsFile != null) ''${pkgs.bash}/bin/bash -c 'cp -Lf ${toString cfg.customGameIDsFile} %h/.local/state/steam-presence/customGameIDs.json' '')
          ++ [
            # Build config.json from config.base.json and optional secret files, atomically
            ''
              ${pkgs.bash}/bin/bash -c '
              set -euo pipefail
              cd %h/.local/state/steam-presence
              in_base="config.base.json"
              out_tmp="config.json.tmp"
              out_final="config.json"
              ${pkgs.python3}/bin/python - "$in_base" "$out_tmp" <<"PY"
              import json, os, sys
              base_path, out_path = sys.argv[1], sys.argv[2]
              with open(base_path, "r") as f:
                  data = json.load(f)

              def ensure_path(d, keys):
                  cur = d
                  for k in keys:
                      if k not in cur or not isinstance(cur[k], dict):
                          cur[k] = {}
                      cur = cur[k]
                  return cur

              steam_key_file = os.environ.get("STEAM_API_KEY_FILE")
              if steam_key_file and os.path.isfile(steam_key_file):
                  try:
                      with open(steam_key_file, "r") as f:
                          data["STEAM_API_KEY"] = f.read().strip()
                  except Exception:
                      pass

              sgdb_key_file = os.environ.get("STEAM_GRID_API_KEY_FILE")
              if sgdb_key_file and os.path.isfile(sgdb_key_file):
                  try:
                      ensure_path(data, ["COVER_ART", "STEAM_GRID_DB"])
                      with open(sgdb_key_file, "r") as f:
                          data["COVER_ART"]["STEAM_GRID_DB"]["STEAM_GRID_API_KEY"] = f.read().strip()
                  except Exception:
                      pass

              with open(out_path, "w") as f:
                  json.dump(data, f, indent=2)
              PY
              ${pkgs.coreutils}/bin/mv -f "$out_tmp" "$out_final"
            ''
          ];

        ExecStart = "${cfg.package}/bin/steam-presence";

        Restart = "on-failure";
        RestartSec = "10s";
      };

      Install = {
        WantedBy = ["default.target"];
      };
    };
  };
}
