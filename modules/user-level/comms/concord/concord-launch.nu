# CONCORD_TOKEN outranks every credential-store mode, so the agenix secret never lands in concord's state dir
def main [] {
  let token = try { open --raw /run/agenix/concord-token | str trim } catch {
    print "concord-token is not decrypted at /run/agenix/concord-token"
    input "-- enter to close --" | ignore
    return
  }
  with-env { CONCORD_TOKEN: $token } { ^concord }
}
