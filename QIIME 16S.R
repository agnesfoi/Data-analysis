
#################################
########## Preparation ##########
#################################


######## install macqiime ########
source /macqiime/configs/bash_profile.txt #*working* terminal with MacQIIME 

install.packages('vegan')
install.packages('klaR',type='binary')
install.packages("biom",type='binary')
source("http://bioconductor.org/biocLite.R")
biocLite("metagenomeSeq")
biocLite("DESeq2")

# Backing up old MacQIIME 1.9.0 installation
sudo mv /macqiime /macqiime-1.9.0-backup 
# Reverting back to your old install of MacQIIME 1.9.0 for some reason
sudo mv /macqiime /macqiime-1.9.1-backup # Move the new macqiime 1.9.1 out of the way
sudo mv /macqiime-1.9.0-backup /macqiime # Rename your old backup of macqiime 1.9.0 to /macqiime

# use macqiime
macqiime



######## use qiime in conda environement #######
conda create -n qiime1 python=2.7 qiime matplotlib=1.4.3 mock nose -c bioconda # creat an environement

source activate qiime1
# print_qiime_config.py -t
source deactivate

conda remove --name qiime1 --all # remove qiime1 environement 


####################################
########## QIIME tutorial ##########
####################################

# formats required in 16S analysis
FASTA file .fna
https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh



#################################
########## 16S Analysis #########
#################################

########## 1.conda ##########
## add channels
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/bioconda
conda config --add channels conda-forge
conda config --add channels r
conda config --add channels bioconda
conda config --add channels biocore 
conda config --add channels hcc


########## 2. quality checking with fastqc ##########
download from:http://www.bioinformatics.babraham.ac.uk/projects/download.html#fastqc


########## 3.data preprocessing with fastp ##########
conda create -n fastp
source activate fastp
conda install fastp

fastp -i 20180904-065-232-938_S97_L001_R1_001.fastq.gz \
-I 20180904-065-232-938_S97_L001_R2_001.fastq.gz \
-z 4 -q 20 -u 30 -n 10 -w 8 -t 15 -T 15 \
-h 065-232-938.html -j 065-232-938.json \
-o 20181017-065-232-938_S97_L001_R1_001.fastq.gz \
-O 20181017-065-232-938_S97_L001_R2_001.fastq.gz


########## 4.qiime ##########
source activate qiime1
conda install ea-utils  #if ea-utils not exist


## For Illumina MiSeq, joint multiple paired end reads in a folder
multiple_join_paired_ends.py -i raw -o join


## split library in qiime
split_libraries_fastq.py -o slout/ --barcode_type not-barcoded -i 015-006-108.fastq,015-014-082.fastq --sample_ids 015-006-108,015-014-082 -m mapping.txt 


## OTU picking
######## greengene
## closed-reference OTU picking
pick_closed_reference_otus.py -a -O 4 -i slout/seqs.fna -o otus 

######## silva
## closed-reference OTU picking
pick_closed_reference_otus.py -i slout/seqs.fna -o otus_silva -r 97_otus_16S.fasta -t taxonomy_7_levels.txt 


## summarize OTU table
biom summarize-table -i otus/otu_table.biom -o otus/otu_count.txt
biom summarize-table -i otus_silva/otu_table.biom -o otus_silva/otu_count.txt


## convert biom file to txt OTU table
biom convert -i otus/otu_table.biom -o otus/table_from_biom_taxonomy.txt --to-tsv --header-key taxonomy
biom convert -i otus/table_from_biom_taxonomy.txt -o otus/otu_table_json.biom --table-type="OTU table" --to-json

biom convert -i otus_silva/otu_table.biom -o otus_silva/table_from_biom_taxonomy.txt --to-tsv --header-key taxonomy
biom convert -i otus_silva/table_from_biom_taxonomy.txt -o otus_silva/otu_table_json.biom --table-type="OTU table" --to-json


## diversity analysis
core_diversity_analyses.py -o cdout/ -i otus/otu_table.biom -m mapping.txt -t otus/97_otus.tree -e 10000 

core_diversity_analyses.py -o cdout_silva -i otus_silva/otu_table.biom -m mapping.txt --nonphylogenetic_diversity -e 10000 


#### UniFrac weighted and unweighted PCoA 2D plots
make_2d_plots.py -i cdout/bdiv_even10000/weighted_unifrac_pc.txt -m mapping.txt -o cdout/bdiv_even10000/weighted_unifrac_2d -k white
make_2d_plots.py -i cdout/bdiv_even15000/unweighted_unifrac_pc.txt -m mapping.txt -o cdout/bdiv_even10000/unweighted_unifrac_2d -k white


#### Bray curtis PCoA 2D plots
make_2d_plots.py -i cdout_silva/bdiv_even10000/bray_curtis_pc.txt -m mapping.txt -o cdout_silva/bdiv_even10000/bray_curtis_2d -k white


##Convert to relative abundances
summarize_taxa.py -i otus/otu_table.biom -o otus/summarize_taxa_L7 -L 2,3,4,5,6,7 -m mapping.txt --delimiter '|'
summarize_taxa.py -i otus_silva/otu_table.biom -o otus_silva/summarize_taxa_L7 -L 2,3,4,5,6,7 -m mapping.txt --delimiter '|'



########## 5.qiime2 ##########
##Installing QIIME 2 
conda install wget
wget https://data.qiime2.org/distro/core/qiime2-2018.11-py35-linux-conda.yml
conda env create -n qiime2-2018.11 --file qiime2-2018.11-py35-linux-conda.yml
rm qiime2-2018.11-py35-linux-conda.yml


##run QIIME 2
source activate qiime2-2018.11

##import these sequence data files into a QIIME 2 artifact
#manifest 文件的格式要求非常严格，表头的名字必须是 sample-id,absolute-filepath,direction.表中不要有空格，都是用逗号隔开
qiime tools import \
--type 'SampleData[PairedEndSequencesWithQuality]' \
--input-path manifest.csv \
--output-path demux.qza \
--input-format PairedEndFastqManifestPhred33

# generate summary and export in .qzv file
qiime demux summarize \ 
--i-data demux.qza \
--o-visualization demux.qzv

qiime tools view demux.qzv


##Sequence quality control
#a.Dada2
qiime dada2 denoise-paired \
--i-demultiplexed-seqs demux.qza \
--p-trim-left-f 5 \
--p-trim-left-r 5 \
--p-trunc-len-f 250 \
--p-trunc-len-r 250 \
--o-representative-sequences rep-seqs-dada2.qza \
--o-table table-dada2.qza \
--o-denoising-stats stats-dada2.qza

qiime metadata tabulate \
--m-input-file stats-dada2.qza \
--o-visualization stats-dada2.qzv

qiime tools view stats-dada2.qzv


#b.Deblur (very slow)
qiime quality-filter q-score \
--i-demux demux.qza \
--o-filtered-sequences demux-filtered.qza \
--o-filter-stats demux-filter-stats.qza

qiime deblur denoise-16S \
--i-demultiplexed-seqs demux-filtered.qza \
--p-trim-length -1 \
--o-representative-sequences rep-seqs-deblur.qza \
--o-table table-deblur.qza \
--p-sample-stats \
--o-stats deblur-stats.qza 
#--verbose


qiime metadata tabulate \
--m-input-file demux-filter-stats.qza \
--o-visualization demux-filter-stats.qzv

qiime deblur visualize-stats \
--i-deblur-stats deblur-stats.qza \
--o-visualization deblur-stats.qzv


qiime tools view demux-filter-stats.qzv
qiime tools view deblur-stats.qzv


## FeatureTable and FeatureData summaries
qiime feature-table summarize \
--i-table table-deblur.qza \
--o-visualization table-deblur.qzv \
--m-sample-metadata-file sample-metadata.tsv

qiime feature-table tabulate-seqs \
--i-data rep-seqs-deblur.qza \
--o-visualization rep-seqs-deblur.qzv


## Generate a tree for phylogenetic diversity analyses
qiime phylogeny align-to-tree-mafft-fasttree \
--i-sequences rep-seqs-deblur.qza \
--o-alignment aligned-rep-seqs-deblur.qza \
--o-masked-alignment masked-aligned-rep-seqs-deblur.qza \
--o-tree unrooted-tree-dada2.qza \
--o-rooted-tree rooted-tree-deblur.qza


## Alpha and beta diversity analysis
qiime diversity core-metrics-phylogenetic \
--i-phylogeny rooted-tree-deblur.qza \
--i-table table-deblur.qza \
--p-sampling-depth 10000 \
--m-metadata-file sample-metadata.tsv \
--output-dir core-metrics-results-deblur


qiime tools view core-metrics-results-deblur/jaccard_emperor.qzv
qiime tools view core-metrics-results-deblur/bray_curtis_emperor.qzv
qiime tools view core-metrics-results-deblur/unweighted_unifrac_emperor.qzv
qiime tools view core-metrics-results-deblur/weighted_unifrac_emperor.qzv


## Taxonomic analysis
qiime feature-classifier classify-sklearn \
--i-classifier gg-13-8-99-515-806-nb-classifier.qza \
--i-reads rep-seqs-deblur.qza \
--o-classification taxonomy-deblur.qza

qiime metadata tabulate \
--m-input-file taxonomy-deblur.qza \
--o-visualization taxonomy-deblur.qzv

qiime taxa barplot \
--i-table table-deblur.qza \
--i-taxonomy taxonomy-deblur.qza \
--m-metadata-file sample-metadata.tsv \
--o-visualization taxa-bar-plots-deblur.qzv


## Differential abundance testing with ANCOM
qiime feature-table filter-samples \
--i-table table-deblur.qza \
--m-metadata-file sample-metadata.tsv \
--p-where "BodySite='gut'" \
--o-filtered-table gut-table-deblur.qza

qiime composition add-pseudocount \
--i-table table-deblur.qza \
--o-composition-table comp-table-deblur.qza

qiime composition ancom \
--i-table comp-table-deblur.qza \
--m-metadata-file sample-metadata.tsv \
--m-metadata-column Subject \
--o-visualization ancom-Subject-deblur.qzv

qiime tools view ancom-Subject-deblur.qzv


qiime taxa collapse \
--i-table gut-table-deblur.qza \
--i-taxonomy taxonomy-deblur.qza \
--p-level 6 \
--o-collapsed-table gut-table-l6-deblur.qza

qiime composition add-pseudocount \
--i-table gut-table-l6-deblur.qza \
--o-composition-table comp-gut-table-l6-deblur.qza

qiime composition ancom \
--i-table comp-gut-table-l6-deblur.qza \
--m-metadata-file sample-metadata.tsv \
--m-metadata-column Subject \
--o-visualization l6-ancom-Subject-deblur.qzv

qiime tools view l6-ancom-Subject-deblur.qzv



########## 6.picrust ##########
http://picrust.github.io/picrust/install.html#install

source activate picrust
##must use otu_table.biom from greengene
## Step 1: Normalize OTU Table
normalize_by_copy_number.py -i otus/otu_table.biom  -o picrust/normalized_otus.biom

## Step 2: Predict Functions For Metagenome
predict_metagenomes.py -i picrust/normalized_otus.biom -o picrust/metagenome_predictions.biom

## Step 3: Categorize KEGG pathways
categorize_by_function.py -f -i picrust/metagenome_predictions.biom -c KEGG_Pathways -l 1 -o picrust/predicted_metagenomes.L1.txt
categorize_by_function.py -f -i picrust/metagenome_predictions.biom -c KEGG_Pathways -l 2 -o picrust/predicted_metagenomes.L2.txt
categorize_by_function.py -f -i picrust/metagenome_predictions.biom -c KEGG_Pathways -l 3 -o picrust/predicted_metagenomes.L3.txt


##the output(after biom Convert to spf) is the input of STAMP
categorize_by_function.py -i picrust/metagenome_predictions.biom -c KEGG_Pathways -l 1 -o picrust/predicted_metagenomes.L1.biom
categorize_by_function.py -i picrust/metagenome_predictions.biom -c KEGG_Pathways -l 2 -o picrust/predicted_metagenomes.L2.biom
categorize_by_function.py -i picrust/metagenome_predictions.biom -c KEGG_Pathways -l 3 -o picrust/predicted_metagenomes.L3.biom



########## 7.stamp ##########
conda create -n stamp python=2.7 matplotlib=1.4.3 pyqt=4.11.4
source activate stamp
pip install stamp
conda update libpng
pip install stamp --upgrade
#you can also input "STAMP" to lunch STAMP

##convert the otus.biom file into a plain text file for use in STAMP
python biom_to_stamp.py -m taxonomy otus/otu_table.biom > otus/otu_table.spf
python biom_to_stamp.py -m KEGG_Pathways picrust/predicted_metagenomes.L3.biom > picrust/predicted_metagenomes_L3.spf






