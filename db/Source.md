# Phenotypic Data Sources

## Choice

__IMG/M @ JGI__ by _Crawing_.
 
 * List: [IMG/M@JGI -> Find Genomes -> Genome Browser](https://img.jgi.doe.gov/cgi-bin/m/main.cgi?section=TreeFile&page=domain&domain=all) -> `View Alphabetically`.
   * We can `select` the whole "Metadata" table and `join` with "Genus and NCBI Taxon ID" from "Genome Field" table.
   * Item View for human review: [a record example](https://img.jgi.doe.gov/cgi-bin/m/main.cgi?section=TaxonDetail&taxon_oid=637000072).

 * If we want to include genomes other than NCBI Taxon set from [JGI](http://genome.jgi.doe.gov/), we can fetch with sth. like `curl` follow its [API](http://genome.jgi.doe.gov/help/download.jsf). 

````bash
curl 'https://signon.jgi.doe.gov/signon/create' --data-urlencode 'login=USER_NAME' --data-urlencode 'password=USER_PASSWORD' -c cookies > /dev/null
curl 'http://genome.jgi.doe.gov/ext-api/downloads/get-directory?organism=PhytozomeV10' -b cookies > files.xml
curl 'http://genome.jgi.doe.gov/ext-api/downloads/get_tape_file?blocking=true&url=/PhytozomeV10/download/_JAMO/53112a9e49607a1be0055980/Alyrata_107_v1.0.annotation_info.txt' -b cookies > Alyrata_107_v1.0.annotation_info.txt
````

 * Link to [Offical Forum](https://groups.google.com/a/lbl.gov/forum/?hl=en&fromgroups=#!topic/img-user-forum/o4Pjc_GV1js), if helps.

### de-duplicate

 * In [Genomic variation landscape of the human gut microbiome](http://www.nature.com/doifinder/10.1038/nature11711)，WU-BLAST with `B=2000 spoutmax=3 span1` was used to get average nucleotide identity (ANI) between. And an operational of 95% ANI was chosen to cluster the genomes. (by "clustered", the author should mean skipped, comparing to "dominant"/"prevalent"; 95% ANI can be a species delineation standard)
 * In [A metagenome-wide association study of gut microbiota in type 2 diabetes](http://www.nature.com/doifinder/10.1038/nature11450), a gene set is built, using KEGG and EggNOG proteomes.
 * In [mPUMA](https://microbiomejournal.biomedcentral.com/articles/10.1186/2049-2618-1-23), its pipeline align OTUs to both DNA and AA.
   * ![mPUMA workflow](https://static-content.springer.com/image/art%3A10.1186%2F2049-2618-1-23/MediaObjects/40168_2013_Article_23_Fig1_HTML.jpg)
 * .

## Candidate

### IMG/M @ JGI

Example link: <https://img.jgi.doe.gov/cgi-bin/m/main.cgi?section=TaxonDetail&taxon_oid=637000072>

> Study Name (Proposal Name)	| Chlorobium chlorochromatii CaD3
> :-------------- | :---------------
> Organism Name	| Chlorobium chlorochromatii CaD3
> Taxon ID	| 637000072
> NCBI Taxon ID	| 340177
> Project Information	 | 
> Bioproject Accession	| PRJNA13921
> Biosample Accession	| SAMN02598328
> Biotic Relationships	| Symbiotic
> Cell Arrangement	| Chains, Singles
> Cell Shape	| Rod-shaped
> Culture Type	| Isolate
> Cultured	| Yes
> Ecosystem	| Environmental
> Ecosystem Category	| Aquatic
> Ecosystem Subtype	| Lentic
> Ecosystem Type	| Freshwater
> Energy Source	| Phototroph
> GOLD Sequencing Quality	| Level 6: Finished
> GOLD Sequencing Strategy	| Whole Genome Sequencing
> GPTS Proposal Id	| 300071
> Geographic Location	| Freshwater lake, Germany.
> Gram Staining	| Gram-
> Habitat	| Aquatic, Fresh water
> Isolation	| Isolated from a phototrophic consortia obtained from a freshwater lake in Germany.
> Motility	| Motile
> Oxygen Requirement	| Anaerobe
> PMO ID	| 16939
> Phenotype	| Green sulfur
> Relevance	| Biotechnological
> Seq Status	| Complete
> Specific Ecosystem	| Unclassified
> Temperature Range	| Mesophile
> Type Strain	| Unknown
> Phenotypes/Metabolism from Pathway Assertion	|  
> Metabolism	| Auxotroph (L-lysine auxotroph) (IMG_PIPELINE; 2015-10-05)
> Metabolism	| Prototrophic (L-alanine prototroph) (IMG_PIPELINE; 2015-10-05)
> Metabolism	| Auxotroph (L-aspartate auxotroph) (IMG_PIPELINE; 2015-10-05)
> Metabolism	| ...

### Human Oral Microbiome Database

Example link: <http://www.homd.org/index.php?name=HOMD&oraltaxonid=389&view=dynamic>

_Text Mining Required._

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

