#!/bin/bash
i=1;
for arg in "$@" 
do
    arrArguments+=("$arg")
    i=$((i + 1));
done

cluster_name=${arrArguments[$(($#-1))]}
number_of_nodes=$(($# / 2 ))
number_of_master=$(($number_of_nodes - 1))
echo "cluster name: $cluster_name"
echo "number of nodes: $number_of_nodes"
echo "number of master: $number_of_master"
# ip1 host1 ip2 host2 ip3 host3 name-cluster
# $1  $2    $3  $4    $5  $6    $7
# 0   1     2   3     4   5     6

# add lead node
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

# add master node
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

python3 /home/ubuntu/ovng-wip/ovng/ovng.py cluster create $cluster_name