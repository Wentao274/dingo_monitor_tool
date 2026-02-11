# -*- coding: utf-8 -*-

import os
import requests
import json


def send_text_message(webhook_url, content, mentioned_list=None, mentioned_mobile_list=None):
    """
    发送文本消息到企业微信群

    Args:
        webhook_url (str): 群机器人的Webhook地址
        content (str): 消息内容
        mentioned_list (list, optional): @的成员UserID列表。 Defaults to None.
        mentioned_mobile_list (list, optional): @的成员手机号列表。 Defaults to None.
    """
    headers = {
        "Content-Type": "application/json",
        "Charset": "UTF-8"
    }
    data = {
        "msgtype": "text",
        "text": {
            "content": content,
            "mentioned_list": mentioned_list,
            "mentioned_mobile_list": mentioned_mobile_list
        }
    }

    response = requests.post(url=webhook_url, data=json.dumps(data), headers=headers)
    result = response.json()

    if result.get('errcode') == 0:
        print("region监控告警消息发送成功")
    else:
        print(f"region监控告警消息发送失败: {result.get('errmsg')}")


def warn_file_to_content(send_file):
    if os.path.exists(send_file):
        with open(send_file, 'r', encoding='utf-8') as file:
            content = file.read()
        return content
    else:
        print("找不到存放异常状态region信息的文件")


if __name__ == '__main__':
    WEBHOOK_URL = "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=8404d7a6-b557-40c8-8045-aca4797c6723"
    current_path = os.path.dirname(os.path.abspath(__file__))
    send_file = current_path + "/warn_data/warn_all_region.txt"
    send_prefix = "DingoDB监控Region状态告警\n"
    file_content = warn_file_to_content(send_file)
    if file_content is not None:
        send_content = send_prefix + warn_file_to_content(send_file)
        #print(send_content)
        send_text_message(WEBHOOK_URL, send_content, mentioned_list=["@all"])
