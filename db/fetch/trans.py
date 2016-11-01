#!/usr/bin/env python3
import csv
import sys
from BioUtil import xzopen

infile,outfile  = sys.argv[1:]
input = xzopen(infile)
reader = csv.reader(input)
output = xzopen(outfile,'w')
writer = csv.writer(output, quoting=csv.QUOTE_ALL)
for row in reader:
    writer.writerow([i.replace("\n"," ") for i in row])
input.close()
output.close()
