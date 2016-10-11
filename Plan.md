# a MicroBiome Annotator

## BackGround

现在的 Microbiome 分析 WGS 数据，是通过组装成 contig ，然后[将其比对到某个基因集上](http://mocat.embl.de/about.html)，从而获得基因功能等注释信息。

![MOCAT2](doc/img/mocat.png)

## Brief

本研究将在前人用 BLAT 做比对注释 的基础上，添加按物种表型划分可能性优先级的功能。

其中，物种分类使用倾向按特征划分的类 ontology 的划分，而非纯粹的 taxonomy，以便将不同功能分开。如：[NCBI Taxonomy](http://www.ncbi.nlm.nih.gov/taxonomy)。

由于人体表微生物包括真菌，计划在[细菌](http://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?mode=Undef&name=Bacteria&lvl=2&srchmode=1&keep=1&unlock)基础上，添加[真菌](http://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=4751)。

## Example Cases

### Type 1, Industrial Flow: Annoate with Given Priority

对肠道微生物组的分析，这些不可能的菌排后面：噬酸、硫细菌、蓝细菌。
对体表微生物的分析，把厌氧的排后面。

### Type 2, _ab initio_ Flow: 相似的生态位包含营养型相似的复数物种，找到一个则期望有一堆

若样品分析结果显著表明其中含有硫细菌，则其中含有其它厌氧生物的概率增加，此时需要把厌氧生物的分值提高。

## Details

* NCBI Taxonomy 的各级节点具有的表型的 tag，可以通过对 PubMed 进行 text mining 得到。相关技术在 IT 领域很常见。
  * 肯定有现成的数据库，寻找之。 
* 每类功能内的比对的 hit，可以参考 BLAST 给出 [Expect (E) value](http://blast.ncbi.nlm.nih.gov/Blast.cgi?CMD=Web&PAGE_TYPE=BlastDocs&DOC_TYPE=FAQ#expect)。

## Flow

````
Ecological Niche => Tag Portions -.
                                  |
Taxonomy nodes => Tag List ---------> Taxonomy Prior Probability ->1
1.Industrial Flow:                                                 |
                                                                   |
Common Path: Sample DNA -> WGS -> contigs -> OTU -> Alignments ------> Refined alignments(output Top 5 or so) -> Annotation (Goal)
                                                        |       |
2.ab initio Flow:                                       |       2<---------------------------------.
                                                        |                                          |
                                           Obvious alignments -> Tag Portions from Taxonomy -> Taxonomy Prior Probability
````

其中，`Alignments`用到的参考序列，需要将 NCBI Genome 中的微生物，做去重复，然后再按`taxid`分类索引。 

## Notes

* NCBI Taxonomy DB 记录在其`taxdump.tar.gz`中，也可以通过[Ensembl API](http://asia.ensembl.org/info/docs/api/api_git.html)或直接用 MySQL 访问[其数据库](http://asia.ensembl.org/info/data/mysql.html)。

* 比对建议用`MOSAIK`, <https://github.com/wanpinglee/MOSAIK>. 参考李波刚发来看的[Genomic variation landscape of the human gut microbiome](http://www.nature.com/nature/journal/v493/n7430/full/nature11711.html).
   * `MOSAIK`提到了一个新出的高速 Smith-Waterman 的包，[mengyao/Complete-Striped-Smith-Waterman-Library](https://github.com/mengyao/Complete-Striped-Smith-Waterman-Library)，记录备案。
   * 若参考序列为蛋白（比如JGI上下载的注释好了的基因） 可以用[DIAMOND](https://github.com/bbuchfink/diamond)来做比对。灵敏度接近BLAST，且比BLAST快很多。

* 使用 NCBI BLAST 的`nt`, `nr`库，提取`taxid`对应的序列，然后以提取结果为新参考序列，建索引来作比对。

* 对比对结果的过滤，可以参考 [CIP](https://www.biostars.org/p/59879/#60037)。

   * In [Salse et al. 2009](http://www.plantcell.org/content/20/1/11.full) they introduced two parameters to allow the identification of the best BLAST alignment - the highest cumulative percentage of identity in the longest cumulative length.

   * The first parameter, cumulative identity percentage (CIP) corresponds to the cumulative percentage of sequence identity obtained for all the HSPs (CIP = [∑ ID by HSP/AL] × 100) where AL is the sum of all hsp lengths.

   * The second parameter, CALP, is the cumulative alignment length percentage which represents the sum of the HSP lengths (AL) for all the HSPs divided by the length of the query sequence (CALP = AL/query).

## Program Design

### 1. Reference Selection

* Use SQLite to store the tag information.
* Use proportion to reveal whether a column(tag) is distinctive.
  * the 2nd larger tag proportion should be at least 10%. (?)
* a CL-UI tool for user to select tags, which output taxids with weights.

### 2. Reference Dedup

------

# 其它

## 关于16S用来区分个体时涉及的统计问题

````
M个不同的元素，共计Q个，分配到N个不同的集合内，Q >> M > N。
分配结果可以测量，但存在测量误差e。通常 M > 5N。认为e约为5%。
现在需要用其中 X种元素的分配结果来区分其中 Y种集合。 X<=M, Y<=N。

需要使 X 尽可能小，Y 尽可能大，同时，“区分”发生错误的概率E足够小。
在给定E的情况下，求X与Y的相互关系。
另外，需要个求给定E、Y下，最小的X。
（为简化书写，集合的名称在不等式中用来代表集合内元素个数）

注：分配结果是元素出现的次数，而非简单的有无。

即：测量N个人的肠道微生物丰度，想的到X种代表性的微生物物种，用来区分这N个人。物种丰度的测量误差为e，区分不同人时犯错误的期望是E。
要求E<1。为了减小E，可以放弃部分人，只区分Y个人，Y<=N。
需要求 E、X、Y的函数关系。
另外，希望有个找到最少的X的方法。
````
