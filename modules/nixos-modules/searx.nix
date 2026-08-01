{ config, ... }:
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
        # single-user instance
        limiter = false;
        public_instance = false;
        # so upstream engines never see the browser fetch thumbnails
        image_proxy = true;
      };

      search = {
        safe_search = 0;
        autocomplete = "duckduckgo";
        default_lang = "en";
        formats = [ "html" "json" ];
      };

      ui = {
        center_alignment = true;
        theme_args.simple_style = "black";
      };

      engines = [
        # rate-limits this IP and self-suspends
        { name = "brave"; disabled = true; }
        # google's index is the priority
        { name = "google cse"; weight = 3; }
        { name = "startpage"; weight = 3; }
        { name = "bing"; disabled = false; }
      ];

      # a plugins block replaces the defaults, so the whole active set is restated
      plugins = {
        "searx.plugins.calculator.SXNGPlugin".active = true;
        "searx.plugins.hash_plugin.SXNGPlugin".active = true;
        "searx.plugins.self_info.SXNGPlugin".active = true;
        "searx.plugins.unit_converter.SXNGPlugin".active = true;
        "searx.plugins.ahmia_filter.SXNGPlugin".active = true;
        "searx.plugins.hostnames.SXNGPlugin".active = true;
        "searx.plugins.time_zone.SXNGPlugin".active = true;
        "searx.plugins.tracker_url_remover.SXNGPlugin".active = true;
        "searx.plugins.oa_doi_rewrite.SXNGPlugin".active = false;
        "searx.plugins.tor_check.SXNGPlugin".active = false;
        "searx.plugins.infinite_scroll.SXNGPlugin".active = true;
      };
    };
  };
}
