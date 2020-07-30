import requests
import json

url = "http://10.71.154.116:3000/contractlist"

headers = {"content-type": "application/json"}
r = requests.get(url, headers=headers)

data = r.json()
print json.dumps(data, indent=4)

service = data[0]["service"]
print service
