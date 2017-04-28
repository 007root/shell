#!/usr/bin/env python
# -*- coding=utf-8 -*-

import smtplib
from email.mime.text import MIMEText
from email.header import Header
import sys

def send_mail(title,content):
        msg = MIMEText(content, 'plain', 'utf-8')
        to_list = ['admin@admin.com']
        msg['from'] = 'root@root.com'
        msg['subject'] = title

        try:
                server = smtplib.SMTP()
                server.connect('smtp.sina.com')
                server.login('root@root.com', 'rootpassword')
                server.sendmail(msg['from'], to_list, msg.as_string())
                server.quit()
        except Exception, e:
                print str(e)

if __name__ == '__main__':
        send_mail(sys.argv[1],' '.join(sys.argv[2:]))
