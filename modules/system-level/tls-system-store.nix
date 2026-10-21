_:
let
  systemStore = "/etc/ssl/certs/ca-certificates.crt";
in
{
  # These clients ship their own root list and so ignore the eMudhra distrust in the system store.
  # See: https://emudhra.we-have-a-problem.com/
  environment.sessionVariables = {
    UV_SYSTEM_CERTS = "1";
    DENO_TLS_CA_STORE = "system";
    DPRINT_TLS_CA_STORE = "system";
    PIP_CERT = systemStore;
    PIP_USE_DEPRECATED = "legacy-certs";
  };

  systemd.services.bazarr.environment.REQUESTS_CA_BUNDLE = systemStore;
}
