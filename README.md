# WireGuard-Notify
🔹 Receive WireGuard connection notifications on a webhook endpoint (Home Assistant, and more...).

WireGuard is a fast, simple, and secure VPN protocol. It uses modern cryptography, is lightweight, using very few lines of code, making it very promising against these competitors.
However, a VPN that gives access to a hole area network (or a single device) needs to be secured and monitored to avoid serious cyber-attack. That's why this project was born.
The main goal here is to have some sort of notification when a new connection to the VPN is made.
<br>The notification have the public IP address of the client that's connecting (with a link to [ipinfo.io](https://ipinfo.io) to quicly check where this IP is located), and the name of the WireGuard configuration.

# Installation
Download the script from this repo on your WireGuard server
```bash
wget https://raw.githubusercontent.com/Baptiste-mrch/wireguard-notify/refs/heads/main/wireguard-notify.sh
```
You need to customize the first variables of the script :
```bash
# URL du webhook Home Assistant
WEBHOOK_URL="http://homeassistant.local:8123/api/webhook/WEBHOOKID"
# Fichier contenant les noms des clients et leurs cles publiques
CLIENTS_FILE="/etc/wireguard/configs/clients.txt"
# Delai de verification
DELAY=5
```
Make it executable
```bash
chmod +x wireguard-notify.sh
```
You can test the script by launching it manually
```bash
./wireguard-notify.sh
```

# Configuration as a systemd service
Create a new `.service` file
```bash
sudo nano /etc/systemd/system/wireguard-notify.service
```
Add the following content to the file :
<br>&nbsp;&nbsp;⚠️ On my case I use the root folder and so the script must be run as root. This may differ depending on your configuration.
```bash
[Unit]
Description=WireGuard VPN Notification Service
After=network.target

[Service]
ExecStart=/root/wireguard-notify.sh
Restart=always
User=root
WorkingDirectory=/root

[Install]
WantedBy=multi-user.target

```
Reload the systemd daemon
```bash
sudo systemctl daemon-reload
```
Enable and start the service so it will run when your server starts
```bash
sudo systemctl enable wireguard-notify.service
sudo systemctl start wireguard-notify.service
```

# Home Assistant configuration
On my case, I choose to receive the notification with Home Assistant. For this purpose, I created a new automation, and choose "Webhook" as the trigger. From there a webhook id is generated.
<br> <br> ![image](https://github.com/user-attachments/assets/2afe9128-d3b7-46f4-8377-207d5c04cdc6)<br>
You need to paste this id after your home assistant url : `http://homeassistant.local:8123/api/webhook/**WEBHOOKID**`
<br>
You will gets the notification values with the following template
```yaml
{{ trigger.json.client_ip }}
{{ trigger.json.client_ipinfo }}
{{ trigger.json.client_name }}
```

## Automation example
```yaml
alias: WireGuard Notification de connexion
description: ""
triggers:
  - trigger: webhook
    allowed_methods:
      - POST
    local_only: true
    webhook_id: "**WEBHOOKID**"
conditions: []
actions:
  - action: notify.mobile_app_**YOUR_PHONE**
    metadata: {}
    data:
      message: |
        Nouvelle connexion WireGuard !
        🔹 IP : {{ trigger.json.client_ip }}
        🔹 Conf : {{ trigger.json.client_name }}
      data:
        priority: high
        push:
          sound:
            name: alarm.caf
            critical: 1
            volume: 0.25
        url: "{{ trigger.json.client_ipinfo }}"
        clickAction: "{{ trigger.json.client_ipinfo }}"
        actions:
          - action: URI
            title: Open
            uri: "{{ trigger.json.client_ipinfo }}"
mode: single

```
With this notify action, I can open the ipinfo website with the IP address that has just been connected by pressing on it or by opening the action menu of the notification (long press on iPhone)
