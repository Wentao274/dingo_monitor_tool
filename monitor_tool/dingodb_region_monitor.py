# -*- coding: utf-8 -*-

import os
import subprocess
import time


def get_region_store_data(shell_path):
    if os.path.exists(shell_path):
        subprocess.run([shell_path])
        time.sleep(3)
    else:
        print(f"文件 ‘{shell_path}’ 不存在")


def find_region_in_list(abnormal_list, region_str):
    indexes = [index for index, item in enumerate(abnormal_list) if region_str in item]
    if indexes:
        return indexes[0]
    else:
        return None


def write_region_list(region_abnormal_file, abnormal_list):
    with open(region_abnormal_file, encoding='utf-8', mode='a') as f:
        for item in abnormal_list:
            f.write(item + "\n")
            print(f"写文件{region_abnormal_file}完成")


def collect_abnormal_regions(region_status_file, region_abnormal_file, check_flag):
    if os.path.exists(region_status_file):
        if os.path.exists(region_abnormal_file):
            os.remove(region_abnormal_file)
        region_list = []
        abnormal_list = []
        with open(region_status_file, 'r') as file:
            for line in file:
                if check_flag not in line.strip():
                    region_str = line.strip().split(" ")[0]
                    if (region_str not in region_list):
                        abnormal_list.append(line.strip())
                        region_list.append(region_str)
                    elif (region_str in region_list):
                        find_region_index = find_region_in_list(abnormal_list, region_str)
                        if find_region_index is not None:
                            abnormal_list[int(find_region_index)] += ", " + " ".join(line.strip().split(" ")[1:])
        if len(abnormal_list) > 0:
            write_region_list(region_abnormal_file, abnormal_list)
    else:
        print(f"store region状态文件'{region_status_file}'不存在")


def store_map_contains_offline(file_path, warn_path):
    try:
        with open(file_path, 'r') as file:
            for line in file:
                if "OFFLINE" in line:
                    os.system(f"cp {file_path} {warn_path}")
    except FileNotFoundError:
        print(f"文件 {file_path} 未找到")


if __name__ == '__main__':

    print("执行monitor py文件")
    current_path = os.path.dirname(os.path.abspath(__file__))
    shell_path = current_path + "/region_statistics.sh"
    region_data_path = current_path + "/region_info"
    abnormal_data_path = current_path + "/warn_data"
    store_region_status_file = region_data_path + "/store_region_status_summary.txt"
    index_region_status_file = region_data_path + "/index_region_status_summary.txt"
    document_region_status_file = region_data_path + "/document_region_status_summary.txt"
    store_region_abnormal_file = abnormal_data_path + "/store_region_abnormal_summary.txt"
    index_region_abnormal_file = abnormal_data_path + "/index_region_abnormal_summary.txt"
    document_region_abnormal_file = abnormal_data_path + "/document_region_abnormal_summary.txt"
    store_map_data_file = region_data_path + "/store_map_data/all_store_map.txt"
    abnormal_store_map_data_file = abnormal_data_path + "/abnormal_store_map.txt"
    
    if not os.path.exists(abnormal_data_path):
        os.makedirs(abnormal_data_path)
    if os.path.exists(abnormal_store_map_data_file):
        os.remove(abnormal_store_map_data_file)

    get_region_store_data(shell_path)
    
    store_map_contains_offline(store_map_data_file, abnormal_store_map_data_file)

    check_flag = "NORMAL"
    storeTypeList = ["store", "index", "document"]
    for stype in storeTypeList:
        if stype == "store":
            if os.path.exists(store_region_status_file):
                collect_abnormal_regions(store_region_status_file, store_region_abnormal_file, check_flag)
            else:
                print("没有store region状态文件，不收集store的异常region状态信息")
        if stype == "index":
            if os.path.exists(index_region_status_file):
                collect_abnormal_regions(index_region_status_file, index_region_abnormal_file, check_flag)
            else:
                print("没有index region状态文件，不收集index的异常region状态信息")
        if stype == "document":
            if os.path.exists(document_region_status_file):
                collect_abnormal_regions(document_region_status_file, document_region_abnormal_file, check_flag)
            else:
                print("没有document region状态文件，不收集document的异常region状态信息")



