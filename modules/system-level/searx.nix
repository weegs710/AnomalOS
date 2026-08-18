{ config, pkgs, only, ... }:
let
  orderedTabs = pkgs.writeText "searx-categories-as-tabs.yml" ''
    categories_as_tabs:
      general: {}
      images: {}
      videos: {}
      shopping: {}
      books: {}
      files: {}
      map: {}
      news: {}
      "social media": {}
      translate: {}
  '';
in
only.gate { tags = [ "server" ]; }
{
  services.searx = {
    enable = true;
    # the built-in server logs every query
    configureUwsgi = true;
    environmentFile = config.age.secrets.searx-secret-key.path;

    # firewall trusts only tailscale0, so binding wide stays tailnet-only
    uwsgiConfig = {
      http = ":8888";
      disable-logging = true;
    };

    settings = {
      server = {
        secret_key = "$SEARX_SECRET_KEY";
        port = 8888;
        base_url = "https://hx99g.tailc3ec2d.ts.net/";
        # single-user instance
        limiter = false;
        public_instance = false;
        # so upstream engines never see the browser fetch thumbnails
        image_proxy = true;
      };

      search = {
        safe_search = 0;
        autocomplete = "duckduckgo";
        favicon_resolver = "duckduckgo";
        default_lang = "en";
        formats = [ "html" "json" ];
      };

      default_doi_resolver = "sci-hub.st";

      ui = {
        center_alignment = true;
        theme_args.simple_style = "black";
      };

      preferences.lock = [
        "simple_style"
        "center_alignment"
        "favicon_resolver"
        "doi_resolver"
        "autocomplete"
        "image_proxy"
        "safesearch"
      ];

      engines = [
        { name = "bing"; disabled = false; }

        # captcha-fingerprints searxng's scraper
        { name = "startpage"; disabled = true; }

        # brave rate-limits this IP
        { name = "brave"; disabled = true; }
        { name = "brave.images"; disabled = true; }
        { name = "brave.videos"; disabled = true; }
        { name = "brave.news"; disabled = true; }

        { name = "lingva"; categories = [ "translate" ]; }
        { name = "dictzone"; categories = [ "translate" ]; }
        { name = "mymemory translated"; categories = [ "translate" ]; }

        { name = "openlibrary"; disabled = false; categories = [ "books" ]; }
        { name = "annas archive"; disabled = false; categories = [ "books" ]; }
      ];

      # a plugins block replaces the defaults, not merges
      plugins = {
        "searx.plugins.calculator.SXNGPlugin".active = true;
        "searx.plugins.hash_plugin.SXNGPlugin".active = true;
        "searx.plugins.self_info.SXNGPlugin".active = true;
        "searx.plugins.unit_converter.SXNGPlugin".active = true;
        "searx.plugins.ahmia_filter.SXNGPlugin".active = true;
        "searx.plugins.hostnames.SXNGPlugin".active = true;
        "searx.plugins.time_zone.SXNGPlugin".active = true;
        "searx.plugins.tracker_url_remover.SXNGPlugin".active = true;
        "searx.plugins.oa_doi_rewrite.SXNGPlugin".active = true;
        "searx.plugins.tor_check.SXNGPlugin".active = false;
        "searx.plugins.infinite_scroll.SXNGPlugin".active = true;
      };
    };
  };

  # nix alphabetizes attrset keys -- tab order can't come from the settings map
  systemd.services.searx-init.serviceConfig.ExecStartPost =
    "${pkgs.bash}/bin/bash -c 'cat ${orderedTabs} >> /run/searx/settings.yml'";
}
