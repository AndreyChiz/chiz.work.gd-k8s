/etc/systemd/system/reverse-tunnel.service

```sh
[Unit]
Description=Persistent reverse SSH tunnel to VPS
After=network.target

[Service]
User=achi
Environment="AUTOSSH_GATETIME=0"
ExecStart=/usr/bin/autossh -M 0 -N \
  -o "ServerAliveInterval=30" \
  -o "ServerAliveCountMax=1000" \
  -R 8080:localhost:80 \
  -R 8443:localhost:443 \
  -R 2228:localhost:228 \
  -R 8000:localhost:8001 \
  -R 8088:localhost:8088 \
  -R 5000:localhost:5000 \
  achi@91.132.162.205
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```