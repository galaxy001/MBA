# Phenotypic Data Sources

## Human Oral Microbiome Database

Example link: <http://www.homd.org/index.php?name=HOMD&oraltaxonid=389&view=dynamic>

> #### Cultivability:
> Requires 10 mg/l pyrixoxal hydrochloride or 100 mg/l L-cysteine for growth [1]
> #### Phenotypic Characteristics:
> Gram-positive cocci.  Nonmotile, nonsporulating, catalase negative, and oxidase negative.  Facultatively anaerobic with complex growth requirements.  Grows as satellite colonies adjacent to Staphylococcus epidermidis [1]. 
> #### Prevalence and Source:
> Abiotrophia defectiva is a common member of the human oral cavity, pharynx, intestine and urogenital tracts.  In a study examining the normal microflora of the oral cavity it was recovered from buccal, hard palate, tooth surface and subgingival sites [3].  
> #### Disease Associations:
> In a study of microbial risk indicators of early childhood caries, Abiotrophia defectiva was significantly more abundant in caries free vs caries active subjects [4].  The organism has also been associated with bacterial endocarditis [2,5]

[Downloadable Data in HOMD](http://www.homd.org/index.php?name=Download)

````bash
curl 'http://www.homd.org/index.php?name=Download&file=download&table=tt&format=text' -o HOMD_Taxon.tsv
curl 'http://www.homd.org/index.php?name=Download&file=download&table=meta&format=text' -o HOMD_Meta.tsv
````

`Oral Taxon ID` is_a `HOT_ID`.

Detailed [Database Structure](http://www.homd.org/index.php?name=Article&sid=25&cat=12&toc=1):
![HOMD Schema](http://www.homd.org/modules/Article/article_images/taxon_database.jpg)

See also <ftp://ftp.homd.org/taxonomy/daily_mysql_dump/>.

