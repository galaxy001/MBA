#!/bin/bash
if [ $# -ne 1 ]; then
echo "Usage: bash $0 <id.list>"
exit 1
fi
i=0
list=$1
header='User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36'
for id in $(cat $list); do
	dir="TaxonDetail/${id: -2}"
	mkdir -p $dir
	url="https://img.jgi.doe.gov/cgi-bin/m/main.cgi?section=TaxonDetail&taxon_oid=${id}"
	wget $url --header "$header" -O $dir/$id.html
	let i=i+1
	echo $i $id
done
echo DONE


