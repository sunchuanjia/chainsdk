#!/bin/bash
# version v0.1
#
# This is used to keep genesis data update on all machines automatically.
#
#

SN_SERVER_IP=""
SN_UDP_PORT=
SN_TCP_PORT=

# Machine
MACHINE_NUM=2

INSTALL_DIR="project/bucky/ruffChain"
GENESIS_DIR="demo/dpos/chain"
GENESIS_DIR_DEST="demo/dpos"

# Master machine
MACHINE_0=eoshost1

# Slave machine
MACHINE_1=nanchao
MACHINE_1_IP=""
MACHINE_1_SECRET=""

MACHINE_2=yangjun
MACHINE_2_IP=""
MACHINE_2_SECRET=""


# Node Number
NODE_NUM=5
NODE_NAME="ruffchain_node"
NODE_PEERID="ruff_miner"

NODE_1="${NODE_NAME}1"
NODE_1_MINER_SECRET="64d8284297f40dc7475b4e53eb72bc052b41bef62fecbd3d12c5e99b623cfc11"
NODE_1_PEERID="${NODE_PEERID}1"
NODE_1_MACHINE=0
NODE_1_RPC=" --rpchost  0.0.0.0 --rpcport 18089 "
NODE_1_DIR="/home/${MACHINE_0}/project/bucky/ruffChain"
NODE_1_PORT="'13010|13000'"

NODE_2="${NODE_NAME}2"
NODE_2_MINER_SECRET="c07ad83d2c5627acece18312362271e22d7aeffb6e2a6e0ffe1107371514fdc2"
NODE_2_PEERID="${NODE_PEERID}2"
NODE_2_MACHINE=1
NODE_2_RPC=" --rpchost  0.0.0.0 --rpcport 18089 "
NODE_2_DIR="/home/${MACHINE_1}/project/bucky/ruffChain"
NODE_2_PORT="'13010|13000'"

NODE_3="${NODE_NAME}3"
NODE_3_MINER_SECRET="9b55dea11fc216e768bf436d0efe9e734ec7bc9e575a935ae6203e5e99dae5ac"
NODE_3_PEERID="${NODE_PEERID}3"
NODE_3_MACHINE=2
NODE_3_RPC=" --rpchost  0.0.0.0 --rpcport 18089 "
NODE_3_DIR="/home/${MACHINE_2}/project/bucky/ruffChain"
NODE_3_PORT="'13010|13000'"

NODE_4="${NODE_NAME}4"
NODE_4_MINER_SECRET="e109b61f011c9939ac51808fac542b66fcb358f69bf710f5d11eb5d1f3e82bc3"
NODE_4_PEERID="${NODE_PEERID}4"
NODE_4_MACHINE=1
NODE_4_RPC=""
NODE_4_DIR="/home/${MACHINE_1}/project/bucky/ruffChain2"
NODE_4_PORT="'13200|13300'"

NODE_5="${NODE_NAME}5"
NODE_5_MINER_SECRET="054898c1a167977bc42790a3064821a2a35a8aa53455b9b3659fb2e9562010f7"
NODE_5_PEERID="${NODE_PEERID}5"
NODE_5_MACHINE=1
NODE_5_RPC=" "
NODE_5_DIR=""
NODE_5_PORT="'13400|13500'"

NODE_6="${NODE_NAME}6"
NODE_6_MINER_SECRET="bb368892d16df7e99d2f08e84423ec416a8e4e8542871e2f02115e4915a1c098"
NODE_6_PEERID="${NODE_PEERID}6"
NODE_6_MACHINE=0
NODE_6_RPC=" "
NODE_6_DIR=""
NODE_6_PORT="'13200|13300'"

NODE_7="${NODE_NAME}7"
NODE_7_MINER_SECRET="67091033899af84c918dd8394b4954cd79fc4da1e238c545479b7cccfbeccf0c"
NODE_7_PEERID="${NODE_PEERID}7"
NODE_7_MACHINE=0
NODE_7_RPC=" "
NODE_7_DIR=""
NODE_7_PORT="'13400|13500'"

NODE_8="${NODE_NAME}8"
NODE_8_MINER_SECRET="e4f3b5ff5c5725a16acd334edf4802a9c4fed7b5fd76a2845cc737418df6e5ae"
NODE_8_PEERID="${NODE_PEERID}8"
NODE_8_MACHINE=2
NODE_8_RPC=" "
NODE_8_DIR=""
NODE_8_PORT="'13400|13500'"


# filename
# hostname
# ip
# dest_filename
copy_file_to_remote()
{
    echo -e "\ncopy file to remote"
    local filename=$1
    local hostname=$2
    local ip=$3
    local dest_filename=$4
    local secret=$5

    echo "#!/usr/bin/expect -f" > ./tmp.sh
    chmod u+x ./tmp.sh

    echo "set timeout 10" >> ./tmp.sh
    echo "spawn scp ${filename} ${hostname}@${ip}:${dest_filename}">> ./tmp.sh
    echo 'expect "*password:"' >> ./tmp.sh
    echo "send \"${secret}\r\"" >> ./tmp.sh
    echo 'interact' >> ./tmp.sh
    echo 'exit 0' >> ./tmp.sh

    echo -e "\n"
    cat ./tmp.sh

    ( expect ./tmp.sh )

    wait
    
    if [ $? -gt 0 ]
    then
	echo "expect execution error"
	exit 1
    fi
    
}
# src_dir
# dst_dir
# hostname
# ip
# secret
copy_dir_to_remote()
{
    echo -e "\ncopy dir to remote"
    local src_dir=$1
    local dst_dir=$2
    local hostname=$3
    local ip=$4
    local secret=$5

    echo -e "\nCopy ${src_dir}/ to ${ip} ${dst_dir}"

    echo "#!/usr/bin/expect -f" > ./tmp.sh
    chmod u+x ./tmp.sh

    echo "set timeout 10" >> ./tmp.sh
    echo "spawn scp -r ${src_dir}/ ${hostname}@${ip}:${dst_dir}/" >> ./tmp.sh
    echo 'expect "*password:"' >> ./tmp.sh
    echo "send \"${secret}\r\"" >> ./tmp.sh
    echo 'interact' >> ./tmp.sh
    echo 'exit 0' >> ./tmp.sh

    echo "------------------------------------"
    
    cat ./tmp.sh

    echo "------------------------------------"

    ( expect ./tmp.sh )

    wait
    
    if [ $? -gt 0 ]
    then
	echo "expect execution error"
	exit 1
    fi
}
copy_chain_info()
{
    # Create expect script
    local num=$1
    local name="MACHINE_${num}"
    local ip="${name}_IP"
    local ipaddr="${!ip}"
    local sec="${name}_SECRET"
    local secret="${!sec}"

    echo -e  "\n\nCopy chain/ files to ==> ${ipaddr}"
 
    echo "#!/usr/bin/expect -f" > ./tmp.sh
    chmod u+x ./tmp.sh

    echo "set timeout 10" >> ./tmp.sh
    echo "spawn scp -r ${GENESIS_DIR}/ ${!name}@${ipaddr}:/home/${!name}/${INSTALL_DIR}/${GENESIS_DIR_DEST}/" >> ./tmp.sh
    echo 'expect "*password:"' >> ./tmp.sh
    echo "send \"${secret}\r\"" >> ./tmp.sh
    echo 'interact' >> ./tmp.sh
    echo 'exit 0' >> ./tmp.sh
    
    ( expect ./tmp.sh )

    if [ $? -gt 0 ]
    then
	echo "expect execute failure"
	exit 1
    fi
    # rm -rf ./tmp.sh
}
# to every node
# every node should have a unique port udp/tcp
copy_genesis()
{
    echo -e "copy genesisi file"

}
# copy genesis file to every node
copy_chain_genesis()
{
    local i=1

    while [ ${i} -le ${MACHINE_NUM}  ]
    do  
	#copy_genesis ${i}
	copy_chain_info ${i}
	let "i=i+1"
    done
}
generate_script_file()
{
    local num=$1
    local filename="miner${num}.sh"
    local pm2_name="NODE_${num}"
    local secret="NODE_${num}_MINER_SECRET"
    local peerid="NODE_${num}_PEERID"
    local rpc="NODE_${num}_RPC"
    local port="NODE_${num}_PORT"
    
    local PM2_NAME="${!pm2_name}"
    local SECRET="${!secret}"
    local PEERID="${!peerid}"
    local RPC="${!rpc}"
    local PORT="${!port}"
    
    local CMD_OPTION=""

    if [ ${num} -eq 1 ]
    then
	CMD_OPTION=" --minOutbound 0 "
    fi
    
    local CMD_HEADER="pm2 start ./dist/blockchain-sdk/src/tool/host.js --name ${PM2_NAME} "
    local CMD_ARG1="-- miner --genesis './data/dpos/genesis' --dataDir './data/dpos/miner${num}' --loggerConsole --loggerLevel debug --minerSecret ${SECRET} "
    local CMD_ARG2=" ${RPC} ${CMD_OPTION} --feelimit 10 --net bdt --host 0.0.0.0 --port ${PORT} --peerid  ${PEERID} "
    local CMD_ARG3="--sn SN_RUFF_TEST@42.159.86.15@10000@10001 --bdt_log_level info --ignoreBan --executor inprocess --forceClean "

    rm -rf ${filename}
    touch ${filename}
    chmod u+x ${filename}

    echo "${CMD_HEADER} ${CMD_ARG1} ${CMD_ARG2} ${CMD_ARG3}" > ${filename}

    cat ${filename}
}

copy_script_file()
{
    local num=$1
    local filename="miner${num}.sh"
    local nodename="NODE_${num}_MACHINE"
    local machinename="${!nodename}"
    local tempname="MACHINE_${machinename}"
    local name="${!tempname}"
    
    local ip="MACHINE_${machinename}_IP"
    local ipaddr="${!ip}"
    local sec="MACHINE_${machinename}_SECRET"
    local secret="${!sec}"    

    if [ ${machinename}  -eq 0   ]
    then
	echo -e "\nMachine 1 dont need to copy scirpt: ${machinename}"
	return 0
    else
	echo -e "\nCopy scirpt to: ${machinename}"
    fi
       
    
    if [ ! -f ${!filename} ]
    then
	echo "Script ${filename} not exist"
	exit 1
    fi

    echo "#!/usr/bin/expect -f" > ./tmp.sh
    chmod u+x ./tmp.sh

    echo "set timeout 10" >> ./tmp.sh
    echo "spawn scp  ${filename} ${name}@${ipaddr}:/home/${name}/${INSTALL_DIR}/" >> ./tmp.sh
    echo 'expect "*password:"' >> ./tmp.sh
    echo "send \"${secret}\r\"" >> ./tmp.sh
    echo 'interact' >> ./tmp.sh
    echo 'exit 0' >> ./tmp.sh
    
    ( expect ./tmp.sh )

    echo -e "\n[["
    cat ./tmp.sh
    echo -e "\n]]"

    if [ $? -gt 0 ]
    then
	echo "expect execute failure"
	exit 1
    fi

}
generate_script()
{
    local i=1

    while [ ${i} -le ${NODE_NUM}  ]
    do
	echo -e "\n\nGenerate ${i} script"
	generate_script_file ${i}
	copy_script_file ${i}
	let "i=i+1"
    done
}

# This is to overwrite the data file
copy_data_file()
{
    local num=$1
    local name="MACHINE_${num}"
    local IP="${name}_IP"
    local sec="${name}_SECRET"

    echo -e "\n\n${num}"

    local src_dir="data"
    local dst_dir="/home/${!name}/${INSTALL_DIR}"
    local hostname="${!name}"
    local ip="${!IP}"
    local secret="${!sec}"
    
    copy_dir_to_remote ${src_dir} ${dst_dir} ${hostname} ${ip} ${secret}
    
    cat ./data/dpos/genesis/config.json | sed -e 's/eoshost1/'"${!name}"'/g' > ./config.json
    # replace MACHINE_0 with name
    echo -e "Modified config.json"
    cat ./config.json
    echo -e "\n"

    local dst_filename="${dst_dir}/data/dpos/genesis/"
    copy_file_to_remote ./config.json ${hostname} ${ip} ${dst_filename} ${secret}
}

copy_data()
{
    local i=1

    # run ./demo/dpos/create.sh
    
    while [ ${i} -le ${MACHINE_NUM}  ]
    do  
	# do_with ${i}
	copy_data_file ${i}
	let "i=i+1"
    done
    
}
help()
{
    echo -e "***********************************************"
    echo -e "m_config.sh arg1"
    echo -e ""
    echo -e "arg1:"
    echo -e "    copy   - copy genesis file to all machines"
    echo -e "    script - generate scripts for all nodes"
    echo -e "    data   - copy data file to all machines"
    echo -e "***********************************************"    
}
# ############### main() #############
which expect

if [ $? -gt 0 ]
then
    echo "You must install expect"
    exit 1
fi



if [ -z $1 ]
then
    echo -e "Empty arguments"
    exit 0
fi

case $1 in
    "help")
	help
    ;;
    
    "copy")
	echo "copy"
	copy_chain_genesis
    ;;
    "script")
	echo "script"
	generate_script
    ;;
    "data")
	echo "data"
	copy_data
    ;;
    *)
	echo "none args"
	help
    ;;
esac

echo -e "\nFinished\n\n"


