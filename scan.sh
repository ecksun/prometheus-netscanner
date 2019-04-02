#!/bin/bash

set -euo pipefail

all_hosts="${STATE_DIRECTORY:-/var/lib/promscan}/all"
inventory_file="${STATE_DIRECTORY:-/var/lib/promscan}/inventory.json"
HOST_FILTER="${HOST_FILTER:-:}"

scan() {
    scanlog="/tmp/$(date --iso-8601=s).scanlog"

    sudo arp-scan --quiet --plain --localnet --interface "$(get_interface)" | sort | uniq | ts '%FT%TZ' | grep "$HOST_FILTER" | sort > "$scanlog"

    touch "$all_hosts"

    awk '{ print $3 }' "$scanlog" |\
        while IFS='' read -r line || [[ -n "$line" ]]; do
            sed -i "/$line/d" "$all_hosts"
        done

    cat "$scanlog" "$all_hosts" | sponge "$all_hosts"
    rm "$scanlog"
}

update_inventory() {
    tr --truncate-set1 '[:alnum:]-:. ' '' < "$all_hosts" | awk '{ printf("%s:4000,%s,%s\n", $2, $2, $3) }' | jq --raw-input --null-input '[inputs | split(",") |
{
    targets: [.[0]],
    labels: {
        ip: .[1],
        instance: .[2],
    }
}]' > /tmp/inventory-tmp.json
    mv /tmp/inventory-tmp.json "$inventory_file"
}

get_interface() {
    first_iface=$(ip -o link show up | grep 'link/ether' | awk 'BEGIN { FS=": " } { print $2 }' | head -n 1)
    if [ -z "$first_iface" ]; then
        echo >&2 "Could not find any interface to scan"
        exit 3
    fi
    echo "$first_iface"
}

scan
echo >&2 "Inventory contains $(wc -l < "$all_hosts") hosts"
update_inventory
