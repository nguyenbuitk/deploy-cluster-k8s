#!/bin/bash
# Get list arguments
declare -a arrArguments
i=1;
for arg in "$@" 
do
    arrArguments+=("$arg")
    i=$((i + 1));
done

# Setup variable
cluster_name=${arrArguments[$(($#-1))]}
number_of_nodes=$(($# / 2 ))
number_of_master=$(($number_of_nodes - 1))
echo "cluster name: $cluster_name"
echo "number of nodes: $number_of_nodes"
echo "number of master: $number_of_master"

# Setup on each node
for(( i=1; i<=$number_of_nodes; i++ ))
do
double_i=$(($i*2))                  # i = i*2
arg_ip=$(($double_i-1))             # arg_ip = i-1
arg_dns=$(($double_i))              # arg_dn = i

public_ip=${arrArguments[$(($arg_ip-1))]}
domain_name=${arrArguments[$(($arg_dns-1))]}
scp -i /home/ubuntu/ovng_poc -r -P 22 /home/ubuntu/dns ubuntu@$public_ip:/home/ubuntu
sudo ssh -i /home/ubuntu/ovng_poc ubuntu@$public_ip <<EOF
sudo apt-get update
sudo apt-get install python -y
curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
sudo python get-pip.py

sudo touch /etc/rc.local
sudo chmod 666 /etc/rc.local
cat <<EOT >> /etc/rc.local
#!/bin/bash
pip install requests
python /home/ubuntu/dns/update_dns.py dev $domain_name
EOT

sudo touch /etc/systemd/system/rc-local.service
sudo chmod +666 /etc/systemd/system/rc-local.service
cat <<EOT >> /etc/systemd/system/rc-local.service
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
EOT

sudo chmod -v +x /etc/rc.local
sudo systemctl enable rc-local.service
sudo systemctl restart rc-local.service
sudo systemctl status rc-local.service
EOF
done

# Create hosts.yml file
cat > /home/ubuntu/ovng-wip/hosts.yml <<EOF
${cluster_name}_cluster:
    vars:
        ale_name: $cluster_name
        ansible_user: ubuntu
        ansible_ssh_private_key_file: /home/ubuntu/ovng_poc
        hostname: ${arrArguments[1]}
    hosts:
        ${cluster_name}_lead:
            ale_hostname: ${arrArguments[1]}
            ansible_host: ${arrArguments[1]}
EOF

# Ddd master node
for(( i=1; i<=$number_of_master; i++ ))
do
double_i=$(($i*2))                    # double_i = i*2
index_host=$(($double_i + 1))         # index_host = i + 1 

cat <<EOT >> /home/ubuntu/ovng-wip/hosts.yml
        ${cluster_name}_master_${i}:
            ale_hostname: ${arrArguments[index_host]}
            ansible_host: ${arrArguments[index_host]}
EOT
done

cd /home/ubuntu/ovng-wip/
python3 /home/ubuntu/ovng-wip/ovng/ovng.py cluster create $cluster_name