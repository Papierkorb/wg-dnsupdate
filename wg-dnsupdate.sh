#!/bin/bash

# wg-dnsupdate.sh: Service script to keep wg endpoints configured as domains in sync after a IP address change.

# Requires the 'dig' utility.
# On ubuntu: sudo apt install dnsutils

Interface="$1"
DNS="$2"
MinimumWait=180
MaximumWait=1800

#
if [ -z "$Interface" ]; then
  echo "Error: Missing interface argument" >&2
  echo "Usage: $0 <Wireguard Interface>" >&2
  echo "  The script expects a wg-quick configuration file at /etc/wireguard/INTERFACE.conf" >&2
  exit 1
fi

if ! ip link show "$Interface" > /dev/null 2>&1; then
  echo "Error: Interface $Interface does not exist." >&2
  echo "       This script expects that the initial set up has already been done." >&2
  echo "       If it's restarted by systemd and then proceeds you don't have to worry." >&2
  exit 1
fi

if [ -n "$DNS" ]; then
  echo "Using DNS server $DNS to resolve IP addresses."
  DNS="@$DNS" # Fix argument for dig
fi

#

declare -A DomainPorts
declare -A DomainPeers
declare -A DomainAddresses
Domains=()

# Parse the wg-quick configuration
PublicKey=""
Endpoint=""
Port=""
while read line; do
  if [ "$line" = "[Peer]" ]; then
    PublicKey=""
    Endpoint=""
    Port=""
  else
    IFS=' ' read -r Key Value <<< "$(echo "$line" | sed 's!=! !')"

    if [ "$Key" = "PublicKey" ]; then
      PublicKey="$Value"
    elif [ "$Key" = "Endpoint" ]; then
      DomainAndPort=(${Value//:/ })
      Endpoint="${DomainAndPort[0]}"
      Port="${DomainAndPort[1]}"
    fi

    if [ -n "$PublicKey" -a -n "$Endpoint" ]; then
      echo "Watching domain $Endpoint (port $Port) for peer $PublicKey"
      DomainPeers[$Endpoint]="$PublicKey"
      DomainPorts[$Endpoint]="$Port"
      Domains+=("$Endpoint")
    fi
  fi
done <<<$(cat "/etc/wireguard/${Interface}.conf" | grep -E '^(\[Peer\]$|PublicKey\b|Endpoint\s*=\s*([^:]+)(:[0-9]+)?)' | sed 's!\s!!g')

# Program loop
FirstRun=1
while true; do
  WaitTime=$MaximumWait

  for i in "${Domains[@]}"; do
    Answer="$(dig "$i" +noquestion $DNS | grep "$i\." | grep -E '\bA(AAA)?\b' | head -1)"

    if [ -z "$Answer" ]; then
      echo "Error: Failed to resolve domain $i" >&2
    else
      Ttl="$(echo $Answer | sed -E 's!.+\. ([0-9]+)\b.+!\1!')"
      Ip="$(echo $Answer | sed -E 's!.+\s([^\s]+)$!\1!')"

      if [ "$Ip" != "${DomainAddresses[$i]}" ]; then
        if [ $FirstRun = 1 ]; then
          echo "Initial IP of domain $i is $Ip (TTL of this domain is $Ttl seconds)"
        else
          echo "Domain $i has changed IP from ${DomainAddresses[$i]} to $Ip"
          wg set "$Interface" peer "${DomainPeers[$i]}" endpoint "${Ip}:${DomainPorts[$i]}"
        fi

        DomainAddresses[$i]="$Ip"
      fi

      if [ "$Ttl" -lt "$WaitTime" -a "$Ttl" -gt "$MinimumWait" ]; then
        WaitTime="$Ttl"
      fi
    fi
  done

  sleep $WaitTime
done
