#!/usr/bin/python
# vim: set fileencoding=utf-8 :
import csv
from datetime import datetime
import json
import os
import re
import sys
from tempfile import NamedTemporaryFile

from cli import cli, clip
from webexteamssdk import WebexTeamsAPI
from pytz import timezone
import requests
import xlsxwriter

def do_ping(ips):
    results = []
    for ip in ips:
        results.append(
            cli('ping {}'.format(ip))
        )
    return results

def write_xlsx(fp, ipaddrs):
    workbook = xlsxwriter.Workbook(fp.name)
    worksheet = workbook.add_worksheet()

    # Define some formats to use to highlight cells
    bold = workbook.add_format({'bold': True})
    bgred = workbook.add_format({'bg_color': 'red'})
    worksheet.set_column(0, 4, 15)

    # Write some data headers
    hostname = cli('show run | i hostname')[9:]
    timestamp = datetime.now(timezone('Asia/Tokyo')).strftime('%Y-%m-%d_%H:%M:%S')
    worksheet.write('A1', u'ping 試験結果', bold)
    worksheet.write('B1', hostname, bold)
    worksheet.write('C1', timestamp, bold)

    worksheet.write('A5', u'宛先', bold)
    worksheet.write('B5', u'ping 成功率 (%)', bold)
    worksheet.write('C5', u'RTT 最小 (ms)', bold)
    worksheet.write('D5', u'RTT 平均 (ms)', bold)
    worksheet.write('E5', u'RTT 最大 (ms)', bold)

    row = 6
    col = 0

    for ipaddr in ipaddrs:
        # String operations
        destination = re.search('ICMP Echos to ([0-9.]+),', ipaddr).group(1)
        prct = re.search('Success rate is ([0-9]+)', ipaddr).group(1)
        rtt = re.search('round-trip min/avg/max = ([0-9]+)/([0-9]+)/([0-9]+)', ipaddr)

        worksheet.write(row, col, destination)
        worksheet.write(row, col + 1, prct, (bgred if int(prct) < 10 else None))
        if int(prct) > 0:
            worksheet.write(row, col + 2, rtt.group(1))
            worksheet.write(row, col + 3, rtt.group(2))
            worksheet.write(row, col + 4, rtt.group(3))
        row += 1
    # Zoom!
    worksheet.set_zoom(150)

    workbook.close()

# Main
def main():
    with open("/flash/ping_ip_addr.csv","rb") as f:
        ipaddrs = f.read().splitlines()
    results = do_ping(ipaddrs)

    fileprefix = "{}_".format(datetime.now(timezone('Asia/Tokyo')).strftime('%Y%m%d_%H%M%S'))
    with NamedTemporaryFile(prefix=fileprefix, suffix='.xlsx') as fp:
        filepath = write_xlsx(fp, results)

        spark_api = WebexTeamsAPI(access_token=sys.argv[1])
        spark_api.messages.create(
            roomId=sys.argv[2],
            markdown="## 設定変更作業後の疎通試験が完了しました",
            files=[fp.name]
        )

if __name__ == '__main__':
    main()
