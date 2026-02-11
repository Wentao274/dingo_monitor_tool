#!/bin/bash

echo "开始执行region_statistics脚本"
ROOT_PATH=$(cd `dirname $0`; pwd)
echo "${ROOT_PATH}"
MON_PATH=${ROOT_PATH}/region_info

if [ -d "${MON_PATH}" ]; then
	rm -rf ${MON_PATH}
fi
mkdir -p ${MON_PATH}/region_map_data
mkdir -p ${MON_PATH}/store_map_data

cd ${ROOT_PATH}

function getRegionMap() {
	cd ${ROOT_PATH}
	if [ -f ${MON_PATH}/region_map_data/all_region_map.txt ]; then
		rm -f ${MON_PATH}/region_map_data/all_region_map.txt
	fi
	
	./dingodb_cli GetRegionMap > ${MON_PATH}/region_map_data/all_region_map.txt
	
	if [ $? -eq 0 ] && [ -s "${MON_PATH}/region_map_data/all_region_map.txt" ]; then
		echo "获取regionMap成功"
	else
		echo "获取regionMap失败，退出"
		exit 1
	fi
}

function getAllRegionIds() {
	cd ${ROOT_PATH}
	if [ -f ${MON_PATH}/region_map_data/all_region_ids.txt ]; then
		rm -f ${MON_PATH}/region_map_data/all_region_ids.txt
	fi
	
	grep '^id=' ${MON_PATH}/region_map_data/all_region_map.txt | cut -d' ' -f1 | awk -F "=" '{print $2}' > ${MON_PATH}/region_map_data/all_region_ids.txt
	
	if [ $? -eq 0 ] && [ -s "${MON_PATH}/region_map_data/all_region_ids.txt" ]; then
		echo "提取region id列表完成"
	else
		echo "提取region id列表失败, 退出"
		exit 1
	fi
}

function splitRegionType() {
	cd ${ROOT_PATH}
	#./dingodb_cli QueryRegion --id $1 | sed -n '5p' | awk -F ' ' '{print $3}' | awk -F '_' '{print $1}' > storetype.txt
	#type_flag=`cat storetype.txt`
	type_flag=$(./dingodb_cli QueryRegion --id "$1" | sed -n '5p' | awk '{print $3}' | awk -F '_' '{print $1}')
	case ${type_flag} in
	*STO*)
		echo "${1}" >> ${MON_PATH}/region_map_data/store_region_ids.txt
		;;
	*IND*)
		echo "${1}" >> ${MON_PATH}/region_map_data/index_region_ids.txt
		;;
	*DOC*)
		echo "${1}" >> ${MON_PATH}/region_map_data/document_region_ids.txt
		;;
	*)
		echo "${1}" >> ${MON_PATH}/region_map_data/unknown_region_ids.txt
		;;
	esac

	#rm -f storetype.txt
}

function getStoreMap() {
	cd ${ROOT_PATH}
	if [ -f ${MON_PATH}/store_map_data/all_store_map.txt ]; then
		rm -f ${MON_PATH}/store_map_data/all_store_map.txt
	fi

	./dingodb_cli GetStoreMap > ${MON_PATH}/store_map_data/all_store_map.txt
	
	if [ $? -eq 0 ] && [ -s ${MON_PATH}/store_map_data/all_store_map.txt ]; then
		echo "获取storeMap完成"
	else
		echo "获取storeMap失败，退出"
		exit 1
	fi
}

function splitStoreType() {
	cd ${ROOT_PATH}
	if [ -f ${MON_PATH}/store_map_data/all_nodes.txt ]; then
		rm -f ${MON_PATH}/store_map_data/all_nodes.txt
	fi

	awk '/Summary/{exit} NR>4' ${MON_PATH}/store_map_data/all_store_map.txt | head -n -2 | awk -F "|" '{print $2,$3,$4,$5}' | awk ' {$1=$1;print}' > ${MON_PATH}/store_map_data/all_nodes.txt
	mapfile -t all_nodes_array < ${MON_PATH}/store_map_data/all_nodes.txt

	if [ -f ${MON_PATH}/store_map_data/store_node.txt ]; then
		rm -f ${MON_PATH}/store_map_data/store_node.txt
	fi
	if [ -f ${MON_PATH}/store_map_data/index_node.txt ]; then
		rm -f ${MON_PATH}/store_map_data/index_node.txt
	fi
	if [ -f ${MON_PATH}/store_map_data/document_node.txt ]; then
		rm -f ${MON_PATH}/store_map_data/document_node.txt
	fi
	
	cat ${MON_PATH}/store_map_data/all_nodes.txt | while read line; do
		if [[ "$line" =~ "NODE_TYPE_STORE" ]]; then
			echo "$line" >> ${MON_PATH}/store_map_data/store_node.txt
		fi
		if [[ "$line" =~ "NODE_TYPE_INDEX" ]]; then
			echo "$line" >> ${MON_PATH}/store_map_data/index_node.txt
		fi
		if [[ "$line" =~ "NODE_TYPE_DOCUMENT" ]]; then
			echo "$line" >> ${MON_PATH}/store_map_data/document_node.txt
		fi	
	done
}


echo "获取RegionMap"
getRegionMap

echo "获取所有region的id列表"
getAllRegionIds

mapfile -t all_region_array < ${MON_PATH}/region_map_data/all_region_ids.txt

cd ${ROOT_PATH}
echo "将region id分组"
for reg in ${all_region_array[@]};
do
	splitRegionType "${reg}"
done

echo "获取StoreMap"
getStoreMap

echo "将storeMap分组"
splitStoreType

function getStoreRegionStatus() {
	cd ${ROOT_PATH}
	if [ -f ${MON_PATH}/store_region_status_summary.txt ]; then
		rm -f ${MON_PATH}/store_region_status_summary.txt
	fi

	mapfile -t store_region_array < ${MON_PATH}/region_map_data/store_region_ids.txt

	for region in ${store_region_array[@]};
	do
		cat ${MON_PATH}/store_map_data/store_node.txt | while read line; do
			store_id=`echo ${line} | awk -F " " '{print $1}'` 
			store_ip=`echo ${line} | awk -F " " '{print $3}' | awk -F ":" '{print $1}'` 
			store_port=`echo ${line} | awk -F " " '{print $3}' | awk -F ":" '{print $2}'`
			store_state=`echo ${line} | awk -F " " '{print $4}'`
			
			#echo ${store_ip}
			#echo ${store_port}
			#echo ${store_state}

			if [[ "${store_state}" == "STORE_NORMAL" ]]; then
				if ./dingodb_cli QueryRegionStatus --store_addrs ${store_ip}:${store_port} --region_ids ${region} | awk '/not exist/' | awk 'NR==1 {gsub(/[ \t]+/, ""); if(length>0) exit 1; else exit 0}'; then
					echo "${region} ${store_ip} "`./dingodb_cli QueryRegionStatus --store_addrs ${store_ip}:${store_port} --region_ids ${region} | awk '/state:/'` >> ${MON_PATH}/store_region_status_summary.txt
				fi
			fi
		done
	done
}

function getIndexRegionStatus() {
	cd ${ROOT_PATH}
	if [ -f ${MON_PATH}/index_region_status_summary.txt ]; then
		rm -f ${MON_PATH}/index_region_status_summary.txt
	fi

	mapfile -t index_region_array < ${MON_PATH}/region_map_data/index_region_ids.txt

	for region in ${index_region_array[@]};
	do
		cat ${MON_PATH}/store_map_data/index_node.txt | while read line; do
			index_id=`echo ${line} | awk -F " " '{print $1}'` 
			index_ip=`echo ${line} | awk -F " " '{print $3}' | awk -F ":" '{print $1}'` 
			index_port=`echo ${line} | awk -F " " '{print $3}' | awk -F ":" '{print $2}'`
			index_state=`echo ${line} | awk -F " " '{print $4}'`

			if [[ "${index_state}" == "STORE_NORMAL" ]]; then
				if ./dingodb_cli QueryRegionStatus --store_addrs ${index_ip}:${index_port} --region_ids ${region} | awk '/not exist/' | awk 'NR==1 {gsub(/[ \t]+/, ""); if(length>0) exit 1; else exit 0}'; then
					echo "${region} ${index_ip} "`./dingodb_cli QueryRegionStatus --store_addrs ${index_ip}:${index_port} --region_ids ${region} | awk '/state:/'` >> ${MON_PATH}/index_region_status_summary.txt
				fi
			fi
		done
	done
}

function getDocumentRegionStatus() {
	cd ${ROOT_PATH}
	if [ -f ${MON_PATH}/document_region_status_summary.txt ]; then
		rm -f ${MON_PATH}/document_region_status_summary.txt
	fi

	mapfile -t document_region_array < ${MON_PATH}/region_map_data/document_region_ids.txt

	for region in ${document_region_array[@]};
	do
		cat ${MON_PATH}/store_map_data/document_node.txt | while read line; do
			document_id=`echo ${line} | awk -F " " '{print $1}'` 
			document_ip=`echo ${line} | awk -F " " '{print $3}' | awk -F ":" '{print $1}'` 
			document_port=`echo ${line} | awk -F " " '{print $3}' | awk -F ":" '{print $2}'`
			document_state=`echo ${line} | awk -F " " '{print $4}'`

			if [[ "${document_state}" == "STORE_NORMAL" ]]; then
				if ./dingodb_cli QueryRegionStatus --store_addrs ${document_ip}:${document_port} --region_ids ${region} | awk '/not exist/' | awk 'NR==1 {gsub(/[ \t]+/, ""); if(length>0) exit 1; else exit 0}'; then
					echo "${region} ${document_ip} "`./dingodb_cli QueryRegionStatus --store_addrs ${document_ip}:${document_port} --region_ids ${region} | awk '/state:/'` >> ${MON_PATH}/document_region_status_summary.txt
				fi
			fi
		done
	done
}

if [ -s "${MON_PATH}/region_map_data/store_region_ids.txt" ]; then
	echo "遍历每个store节点上的各region状态,并输出到文件"
	getStoreRegionStatus
else
	echo "没有store region列表文件或文件为空"
fi

if [ -s "${MON_PATH}/region_map_data/index_region_ids.txt" ]; then
	echo "遍历每个index节点上的各region状态,并输出到文件"
	getIndexRegionStatus
else
	echo "没有index region列表文件或文件为空"
fi

if [ -s "${MON_PATH}/region_map_data/document_region_ids.txt" ]; then
	echo "遍历每个document节点上的各region状态,并输出到文件"
	getDocumentRegionStatus
else
	echo "没有document region列表文件或文件为空"
fi

