# wg-dnsupdate

A WireGuard DNS Update script that monitors domain name changes and updates WireGuard peer endpoints accordingly.

## Description

The `wg-dnsupdate` script is designed to monitor domain names used as endpoints in WireGuard peers. It periodically checks if the IP address associated with these domains changes and updates the WireGuard configuration to reflect the new IP address. This ensures that connections remain active even when the peer's IP changes due to dynamic DNS updates.

Imagine having a small server outside your home trying to reach your home servers via wireguard. It will work great at first, but then suddenly drop out and be gone after your home ISP decided to change your IP address.
This script solves this exact issue.

## Features

- **Dynamic DNS Handling**: Automatically updates WireGuard peer endpoints when their DNS-resolved IP changes.
- **No DNS Spamming**: Sleeps for the time specified by the domain's TTL to avoid unnecessary checks.
- **Service Integration**: Runs as a systemd service for continuous operation.
- **wg-easy Integration**: Uses the configuration at `/etc/wireguard/X.conf`, resulting in basically no additional configuration

## Prerequisites

- **`dig` utility**: Required for DNS queries. Install with `sudo apt install dnsutils` on Ubuntu/Debian.
- **wg-quick**: Ensure the WireGuard interface and peers are configured.

## Installation

1. **Clone the Repository**: 
   ```bash
   git clone https://github.com/Papierkorb/wg-dnsupdate.git
   ```
2. **Run the Installer**: 
   ```bash
   sudo ./install.sh
   ```
3. **Enable the Service**: 
   ```bash
   sudo systemctl enable --now wg-dnsupdate@<Interface>.service
   ```
   Replace `<Interface>` with your WireGuard interface name (e.g., wg0).

## DNS Configuration

By default the script uses the Cloudflare DNS service `1.1.1.1`. This is to circumvent issues if your default DNS is set via wireguard to use a DNS server behind the VPN.
As this VPN may not be accessible when the IP of the endpoint changes, we can't rely on it.

To change this behaviour:

1. Execute `systemctl edit wg-dnsupdate@.service` as root
2. In the editor in the blank space, write `[Service]` first
3. In a line below write `Environment=DNS=DNS_IP_ADDRESS`
4. To rely on the systems DNS write `Environment=DNS=` instead to unset `DNS`.
5. Save the file and restart the service, like `systemctl restart wg-dnsupdate@wg0`

## Manual Usage

If you don't use systemd, you can also just run the script directly.
Make sure to run it as `root` user, or any other user that has permissions to use the `wg` tool to modify interfaces.

```bash
./wg-dnsupdate.sh <Interface> <DNS>
```
Replace `<Interface>` with your WireGuard interface name (e.g., `wg0`).
Replace `<DNS>` with the DNS that shall be used - Omit to use the systems default DNS.

Example: 
```bash
sudo ./wg-dnsupdate.sh wg0 1.1.1.1
```

## Contributing

Contributions are welcome. For major changes, discuss them in a GitHub issue first. Thank you!

## License

This project is licensed under the MIT License.
