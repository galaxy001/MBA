# Data Sources

## Human Oral Microbiome Database

[Downloadable Data in HOMD](http://www.homd.org/index.php?name=Download)

````bash
curl 'http://www.homd.org/index.php?name=Download&file=download&table=tt&format=text' -o HOMD_Taxon.tsv
curl 'http://www.homd.org/index.php?name=Download&file=download&table=meta&format=text' -o HOMD_Meta.tsv
````

`Oral Taxon ID` is_a `HOT_ID`.

Detailed [Database Structure](http://www.homd.org/index.php?name=Article&sid=25&cat=12&toc=1):
![HOMD Schema](http://www.homd.org/modules/Article/article_images/taxon_database.jpg)

See also <ftp://ftp.homd.org/taxonomy/daily_mysql_dump/>.

