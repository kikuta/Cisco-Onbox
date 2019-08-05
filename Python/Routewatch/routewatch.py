::cisco::eem::event_register_routing network 10.2.2.0/24 type all ge 24

import requests
import sys
import eem

ACCESS_TOKEN = "<yourtoken>"
ROOM_ID = "<your-roomid>"

def setHeaders():
    accessToken_hdr = 'Bearer ' + ACCESS_TOKEN
    spark_header = {'Authorization': accessToken_hdr, 'Content-Type': 'application/json; charset=utf-8'}
    return spark_header

def postMsg(the_header,roomId,message):
    message = '{"roomId":"' + roomId + '","text":"' + message +'"}'
    uri = 'https://api.ciscospark.com/v1/messages'
    resp = requests.post(uri, data=message, headers=the_header)
    print resp

event = eem.event_reqinfo()
message = '!!! RoutingTable Change Detected by EEM: !!! -> ' + event['network'] + '-' + event['type'] + '-BY-' + event['protocol']
          
header=setHeaders()
postMsg(header,ROOM_ID,message)
