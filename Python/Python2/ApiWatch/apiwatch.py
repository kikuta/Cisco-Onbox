::cisco::eem::event_register_none

import json
import requests
import sys
import cli
import eem

url = "http://10.71.154.116:3000/contractlist"
cmds = ["interface GigabitEthernet0/1/0", "end"]


def get_service(url):
    headers = {"content-type": "application/json"}
    r = requests.get(url, headers=headers)
    data = r.json()
    
    service = data[0]["service"]
    speed = data[0]["speed"]

    return service, speed


def listcmds(service, speed):    
    changediscr = "description" + " " + service
    changespeed = "speed" + " " + speed
    
    addcmds = [changediscr.encode('utf-8'), changespeed.encode('utf-8')]
    cmds[1:1] = addcmds
    eem.action_syslog(cmds)

    return cmds


def main():
    result = get_service(url)
    eem.action_syslog(result)
    changeclis = listcmds(*result)
    cli.configurep(changeclis)


if __name__ == '__main__':
    main()
