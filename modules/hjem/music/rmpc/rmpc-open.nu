#!@NUSHELL@/bin/nu
def main [...paths: string] {
    $paths | each {|p| rmpc add $p}
    rmpc play
}
