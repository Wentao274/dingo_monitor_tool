#!/bin/bash

export python_command=python

echo "****************************************************************"
echo "监控脚本主程序开始执行, 当前时间："
date +'%Y-%m-%d %H:%M:%S'
echo

ROOT_PATH=$(cd `dirname $0`; pwd)
WARN_PATH=${ROOT_PATH}/warn_data

function send_store_warn() {
	if [ -s "${WARN_PATH}/abnormal_store_map.txt" ]; then
		echo "获取到store进程异常，发送store进程告警消息"
		cd ${ROOT_PATH}
		${python_command} send_store_warn.py
	else
		echo "所有store进程状态正常"
	fi
}

function send_region_warn() {
	if [ -f "${WARN_PATH}/warn_all_region.txt" ]; then
		rm -f ${WARN_PATH}/warn_all_region.txt
	fi

	if [ -f "${WARN_PATH}/store_region_abnormal_summary.txt" ] && [ -f "${WARN_PATH}/store_region_abnormal_summary_pre.txt" ]; then
		sort ${WARN_PATH}/store_region_abnormal_summary.txt ${WARN_PATH}/store_region_abnormal_summary_pre.txt | uniq -d > ${WARN_PATH}/warn_store_region.txt
		echo "==============================" > ${WARN_PATH}/warn_all_region.txt
		echo "store异常状态region列表：" >> ${WARN_PATH}/warn_all_region.txt
		cat ${WARN_PATH}/warn_store_region.txt >> ${WARN_PATH}/warn_all_region.txt
		echo  >> ${WARN_PATH}/warn_all_region.txt
	fi
	if [ -f "${WARN_PATH}/index_region_abnormal_summary.txt" ] && [ -f "${WARN_PATH}/index_region_abnormal_summary_pre.txt" ]; then
		sort ${WARN_PATH}/index_region_abnormal_summary.txt ${WARN_PATH}/index_region_abnormal_summary_pre.txt | uniq -d > ${WARN_PATH}/warn_index_region.txt
		echo "==============================" >> ${WARN_PATH}/warn_all_region.txt
		echo "index异常状态region列表：" >> ${WARN_PATH}/warn_all_region.txt
		cat ${WARN_PATH}/warn_index_region.txt >> ${WARN_PATH}/warn_all_region.txt
		echo  >> ${WARN_PATH}/warn_all_region.txt
	fi
	if [ -f "${WARN_PATH}/document_region_abnormal_summary.txt" ] && [ -f "${WARN_PATH}/document_region_abnormal_summary_pre.txt" ]; then
		sort ${WARN_PATH}/document_region_abnormal_summary.txt ${WARN_PATH}/document_region_abnormal_summary_pre.txt | uniq -d > ${WARN_PATH}/warn_document_region.txt
		echo "==============================" >> ${WARN_PATH}/warn_all_region.txt
		echo "document异常状态region列表：" >> ${WARN_PATH}/warn_all_region.txt
		cat ${WARN_PATH}/warn_document_region.txt >> ${WARN_PATH}/warn_all_region.txt
		echo  >> ${WARN_PATH}/warn_all_region.txt
	fi

	if [ -s "${WARN_PATH}/warn_all_region.txt" ]; then 
		if awk 'NR==3 {gsub(/[ \t]+/, ""); if(length>0) exit 0; else exit 1}' ${WARN_PATH}/warn_all_region.txt; then
			echo "获取到region状态异常，发送region状态告警消息"
			cd ${ROOT_PATH}
			${python_command} send_region_warn.py
		fi
	else
		echo "未获取到或仅获取到一次异常region信息，暂不发送告警通知"
	fi
}

function monitor_loop() {
	cd ${ROOT_PATH}
	if [ -f ${WARN_PATH}/store_region_abnormal_summary.txt ]; then
		rm -f ${WARN_PATH}/store_region_abnormal_summary.txt
	fi
	if [ -f ${WARN_PATH}/index_region_abnormal_summary.txt ]; then
		rm -f ${WARN_PATH}/index_region_abnormal_summary.txt
	fi
	if [ -f ${WARN_PATH}/document_region_abnormal_summary.txt ]; then
		rm -f ${WARN_PATH}/document_region_abnormal_summary.txt
	fi

	if [ -f "${WARN_PATH}/abnormal_store_map.txt" ]; then
		rm -f ${WARN_PATH}/abnormal_store_map.txt
	fi

	${python_command} dingodb_region_monitor.py
	send_store_warn
	send_region_warn
	
	cd ${ROOT_PATH}
	if [ -f ${WARN_PATH}/store_region_abnormal_summary.txt ]; then
		mv ${WARN_PATH}/store_region_abnormal_summary.txt ${WARN_PATH}/store_region_abnormal_summary_pre.txt
	fi
	if [ -f ${WARN_PATH}/index_region_abnormal_summary.txt ]; then
		mv ${WARN_PATH}/index_region_abnormal_summary.txt ${WARN_PATH}/index_region_abnormal_summary_pre.txt
	fi
	if [ -f ${WARN_PATH}/document_region_abnormal_summary.txt ]; then
		mv ${WARN_PATH}/document_region_abnormal_summary.txt ${WARN_PATH}/document_region_abnormal_summary_pre.txt
	fi

	cd ${ROOT_PATH}
	#echo "监控后休眠$1秒"
	#sleep $1
	
	#${python_command} dingodb_region_monitor.py
	#send_store_warn
	#send_region_warn
	#echo "第二次监控后休眠$1秒"
	#sleep $1
}

case $# in
1)
	echo "一个参数"
	echo "当前未使用crontab定时执行，指定了程序休眠时长参数，程序循环执行"	
	while true
	do
		echo "================================================================"
		monitor_loop "${1}"
		echo "================================================================"
		echo "本次运行结束, 结束时间为："
		date +'%Y-%m-%d %H:%M:%S'
		echo "监控后休眠${1}秒"
		sleep ${1}
		echo
		echo "****************************************************************"
		exit 1
	done
	;;
2)
	echo "两个参数"
	echo "当前使用crontab定时执行，程序不循环"
	if [[ "${2}" == "true" ]]; then
		echo "================================================================"
		monitor_loop "${1}"
		echo "================================================================"
		echo "本次运行结束, 结束时间为："
		date +'%Y-%m-%d %H:%M:%S'
		echo "监控后休眠${1}秒"
		sleep ${1}
		echo
		echo "****************************************************************"
		exit 1
	else
		echo "参数值错误！！本脚本的第二个参数表示是否使用crontab执行，如果确实使用了crontab，则第二个参数必须是true，请更正参数值！"
		exit 1
	fi
	;;
*)
	echo "当前未使用crontab定时执行，也未指定程序休眠时长参数，程序循环执行，使用默认休眠时间300秒"	
	while true
	do
		echo "================================================================"
		monitor_loop 300
		echo "================================================================"
		echo "本次运行结束, 结束时间为："
		date +'%Y-%m-%d %H:%M:%S'
		echo "监控后休眠300秒"
		sleep 300
		echo
		echo "****************************************************************"
		exit 1
	done
esac

