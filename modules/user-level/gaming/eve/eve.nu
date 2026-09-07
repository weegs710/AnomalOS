const ESI = "https://esi.evetech.net/latest"

export def "eve id" [name: string]: nothing -> int {
    # `default` evaluates its argument eagerly, so an error branch there fires on success too
    let hit = (
        http post --content-type application/json $"($ESI)/universe/ids/" [$name]
        | get -o systems.0.id
    )
    if $hit == null { error make { msg: $"no solar system named ($name)" } }
    $hit
}

export def "eve region-id" [name: string]: nothing -> int {
    let hit = (
        http post --content-type application/json $"($ESI)/universe/ids/" [$name]
        | get -o regions.0.id
    )
    if $hit == null { error make { msg: $"no region named ($name)" } }
    $hit
}

export def "eve kills" []: nothing -> record {
    http get $"($ESI)/universe/system_kills/"
    | reduce --fold {} {|r, acc| $acc | insert ($r.system_id | into string) $r }
}

export def "eve jumps" []: nothing -> record {
    http get $"($ESI)/universe/system_jumps/"
    | reduce --fold {} {|r, acc| $acc | insert ($r.system_id | into string) $r }
}

export def "eve band" [sec: float]: nothing -> string {
    if $sec >= 0.45 { "HIGH" } else if $sec > 0.0 { "LOW" } else { "NULL" }
}

# snapshots are passed in so a route costs two cluster-wide calls, not two per hop
export def "eve sysrow" [id: int, k: record, j: record]: nothing -> record {
    let s = (http get $"($ESI)/universe/systems/($id)/")
    let key = ($id | into string)
    let kk = ($k | get -o $key | default { ship_kills: 0, pod_kills: 0, npc_kills: 0 })
    let jj = ($j | get -o $key | default { ship_jumps: 0 })
    {
        system: $s.name
        sec: ($s.security_status | math round --precision 1)
        band: (eve band $s.security_status)
        ships: $kk.ship_kills
        pods: $kk.pod_kills
        npcs: $kk.npc_kills
        jumps: $jj.ship_jumps
    }
}

export def "eve sys" [name: string] {
    eve sysrow (eve id $name) (eve kills) (eve jumps)
}

# --safest is ESI's `secure` flag, which avoids lowsec but still routes through Uedama
export def "eve route" [from: string, to: string, --safest, --insecure] {
    let flag = if $safest { "secure" } else if $insecure { "insecure" } else { "shortest" }
    let path = (http get $"($ESI)/route/(eve id $from)/(eve id $to)/?flag=($flag)")
    let k = (eve kills)
    let j = (eve jumps)
    # `each` streams, so without collect this renders one table per row
    $path | each {|id| eve sysrow $id $k $j } | collect
}

export def "eve hotspots" [--limit: int = 12] {
    let k = (eve kills)
    let j = (eve jumps)
    $k
    | values
    | where ship_kills > 0
    | sort-by ship_kills --reverse
    | first 40
    | each {|r| eve sysrow $r.system_id $k $j }
    | where band == "HIGH"
    | first $limit
    | collect
}

export def "eve names" [ids: list<int>]: nothing -> record {
    # ESI rejects a resolve batch over 1000 ids
    $ids
    | chunks 900
    | each {|c| http post --content-type application/json $"($ESI)/universe/names/" $c }
    | flatten
    | reduce --fold {} {|r, acc| $acc | insert ($r.id | into string) $r.name }
}

# sorted so the top of the list is the least contested and least hunted, not the safest on paper
export def "eve quiet" [region: string, --band: string = "HIGH", --limit: int = 20] {
    let r = (http get $"($ESI)/universe/regions/(eve region-id $region)/")
    let ids = (
        $r.constellations
        | each {|c| http get $"($ESI)/universe/constellations/($c)/" | get systems }
        | flatten
    )
    let k = (eve kills)
    let j = (eve jumps)
    $ids
    | each {|id| eve sysrow $id $k $j }
    | where band == $band
    | sort-by jumps ships
    | first $limit
    | collect
}

export def "eve fw" [] {
    # ESI returns faction ids only, and there is no endpoint that names militia factions
    let f = {
        "500001": Caldari
        "500002": Minmatar
        "500003": Amarr
        "500004": Gallente
        "500010": Guristas
        "500011": Angel
    }
    let raw = (http get $"($ESI)/fw/systems/")
    let nm = (eve names ($raw | get solar_system_id))
    $raw
    | each {|r| {
        system: ($nm | get ($r.solar_system_id | into string))
        owner: ($f | get -o ($r.owner_faction_id | into string) | default "?")
        occupier: ($f | get -o ($r.occupier_faction_id | into string) | default "?")
        state: $r.contested
        vp: $r.victory_points
        vp_max: $r.victory_points_threshold
        pct: (
            if $r.victory_points_threshold > 0 {
                ($r.victory_points * 100 / $r.victory_points_threshold | math round)
            } else { 0 }
        )
    }}
    | collect
}
