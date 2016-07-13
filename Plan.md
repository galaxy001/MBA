# a MicroBiome Annotator

## BackGround

现在的 Microbiome 分析 WGS 数据，是通过组装成 contig ，然后[将其比对到某个基因集上](http://mocat.embl.de/about.html)，从而获得基因功能等注释信息。

![MOCAT2](doc/img/mocat.png)

## Brief

本研究将在前人用 BLAT 做比对注释 的基础上，添加按物种表型划分可能性优先级的功能。

其中，物种分类使用倾向按特征划分的类 ontology 的划分，而非纯粹的 taxonomy，以便将不同功能分开。如：[NCBI Taxonomy](http://www.ncbi.nlm.nih.gov/taxonomy)。

## Details

* 每类功能内的比对的 hit，可以参考 BLAST 给出 [Expect (E) value](http://blast.ncbi.nlm.nih.gov/Blast.cgi?CMD=Web&PAGE_TYPE=BlastDocs&DOC_TYPE=FAQ#expect)。

