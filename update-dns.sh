#!/bin/bash
number_of_nodes=$(($# / 2 ))

domain_name=$1
sudo apt-get update
sudo apt-get install python -y
curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
sudo python get-pip.py

cat > /etc/rc.local <<EOF
#!/bin/bash
pip install requests
python /home/ubuntu/dns/update_dns.py dev $domain_name
EOF

cat > /etc/systemd/system/rc-local.service <<EOF
[Unit]
    Description=/etc/rc.local Compatibility
    ConditionPathExists=/etc/rc.local

[Service]
    Type=forking
    ExecStart=/etc/rc.local start
    TimeoutSec=0
    StandardOutput=tty
    RemainAfterExit=yes
    SysVStartPriority=99

[Install]
    WantedBy=multi-user.target
EOF

sudo chmod -v +x /etc/rc.local
sudo systemctl enable rc-local.service
sudo systemctl restart rc-local.service
sudo systemctl status rc-local.service