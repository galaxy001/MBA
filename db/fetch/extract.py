#!/usr/bin/env python3
"""extract overview information from jgi data
Usage: python3 <script> <data_dir> <taxon_id.list> <result.csv>
"""
from bs4 import BeautifulSoup
import sys
import os.path
import csv
from BioUtil import xzopen
import logging
logging.basicConfig(level=logging.INFO)
logger=logging.getLogger()

def main():
    if len(sys.argv) -1 != 3:
        sys.exit(__doc__)
    datadir, id_list, outfile = sys.argv[1:]
    out = xzopen(outfile, 'w')
    writer = csv.writer(out, quoting=csv.QUOTE_ALL)
    count = 0
    for line in open(id_list):
        taxon_oid = line.strip()
        filename = os.path.join(datadir, taxon_oid[-2:], taxon_oid + ".html")
        try:
            result = parse_file(filename)
        except Exception as e:
            logger.warning("%s: %s" % (taxon_oid, e))
            continue
        for line in result:
            writer.writerow([taxon_oid,] + line)
        count+=1
        if count % 1000 == 0:
            logger.info("%d record proceeded" % count)
    out.close()
    logger.info("DONE")

def parse_file(filename):
    "get the content of the first table of the html doc"
    # source: http://stackoverflow.com/questions/11790535/extracting-data-from-html-table
    soup = BeautifulSoup(open(filename).read(), "lxml")
    table = soup.find("table") # get the first table
    result = list()
    for row in table.findChildren("tr", recursive=False):
        try:
            # line = [th.get_text().strip() for th in row.findChildren("th")] + [ td.get_text().strip() for td in row.findChildren("td")]
            # line = [th.get_text().strip() for th in row.findChildren("th", recursive=False)] + [ td.get_text().strip() for td in row.findChildren("td", recursive=False)]
            line = [elt.get_text().strip() for i in ("th", "td") for elt in row.findChildren(i, recursive=False)]
        except Exception as e:
            print(filename, row)
            raise e
        result.append(line)
    return result

if __name__ == '__main__':
    main()
