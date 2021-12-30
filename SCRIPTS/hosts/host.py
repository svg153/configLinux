#!/usr/bin/env python

import ipaddress
import socket


with open('hosts.txt', 'w') as f:
    net = ipaddress.ip_network('10.10.16.0/20')

    for ip in net:
        try:
            host = socket.gethostbyaddr(str(ip))
        except socket.herror:
            host = (None, [], [])

        f.write("%s; %s\n" % (str(ip), host[0]))
