#!/usr/bin/env python3

### Author

# Chris King (@raikiasec) - chris.king@mandiant.com

### Description

# This script exists because I am tired of grepping and awking gnmap scripts. This script
# parses pipped-in data and extracts either all the online hosts or hosts that have specific
# ports open.  See examples for more.
#
# The script also prints simple stats about the number of hosts parsed out. Those stats are
# outputted via stderr, so you can still just redirect the data to a file and have your hosts
# in a file.

### Usage

# I recommend you symlink this script into your /usr/local/bin for ease:
#        ln -s np.py /usr/local/bin/np
# This allows you to just do "cat scan.gnmap | np" instead of directly referencing the file
# each time. For actual usage, see examples section.

### Examples

## Parse all online hosts
# cat scan.gnmap | ./np.py

## Parse all hosts that have port 80 and port 443 open
# cat scan.gnmap | ./np.py -p 80 -p 443

## Parse all hosts that have port 80 or port 443 open
# cat scan.gnmap | ./np.py -p 80 -p 443 -o

## Parse all online hosts and save to a file
# cat scan.gnmap | ./np.py > onlinehosts.txt

## If the DNS hostname exists in the scan, output that instead of the IP
# cat scan.gnmap | ./np.py -d

import argparse
import sys
import os


def parse_args():
    parser = argparse.ArgumentParser(description="Quick gnmap parser. Pipe a gnmap file into this script to parse the online hosts out or give -p to specify a port to look for")
    parser.add_argument("-p", "--port", action="append", help="An open port to search for")
    parser.add_argument("-o", "--or", dest="multi", action="store_true", help="Search for any port instead of all ports")
    parser.add_argument("-d", "--dns", action="store_true", help="Use DNS name if in the output")
    parser.add_argument("-q", "--quiet", action="store_true", help="Dont print any statuses to stderr")
    args = parser.parse_args()
    return args

def print_data(line, args):
    parts = line.split()
    if len(parts) > 3:
        printable = parts[1]
        if (args.dns and parts[2] != '()'):
            printable = parts[2].rstrip(')').lstrip('(')
        print(printable)

def print_status(line, args):
    if not args.quiet:
        print(" [~] {}".format(line), file=sys.stderr)

def main():
    args = parse_args()
    if os.isatty(0):
        print("You should pipe a gnmap file into this script.  Try \"cat file.gnmap | np\" or something")
        sys.exit(1)
    searchFor = ["Status: Up"]
    if args.port is not None:
        searchFor = []
        for port in args.port:
            searchFor.append(" {}/open".format(port))
        modifier = ""
        print_status("Parsing for hosts with {}open ports: {}".format("any " if args.multi else "", ",".join(args.port)), args)
    else:
        print_status("Parsing for online hosts...", args)

    found = 0
    for line in sys.stdin:
        numTerms = 0
        for term in searchFor:
            if term in line:
                numTerms += 1
        if (args.multi and numTerms > 0) or (not args.multi and numTerms == len(searchFor)):
            found += 1
            print_data(line, args)

    print_status("Found {} hosts".format(found), args)









if __name__ == '__main__':
    main()

