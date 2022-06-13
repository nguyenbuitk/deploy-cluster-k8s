#!/bin/bash
i=1;
for arg in "$@" 
do
    arr+=("$arg")
    i=$((i + 1));
done

number_of_nodes=$(($# / 2 ))
for(( i=1; i<=$number_of_nodes; i++ ))
do
double_i=$(($i*2))                  # i = i*2
arg_ip=$(($double_i-1))             # arg_ip = i-1
arg_dns=$(($double_i))              # arg_dn = i

# echo "ip node $i: ${arr[$(($arg_ip-1))]}"
# echo "dns node $i: ${arr[$((arg_dns-1))]}"

public_ip=${arr[$(($arg_ip-1))]}
domain_name=${arr[$(($arg_dns-1))]}
echo $public_ip
echo $domain_name

done