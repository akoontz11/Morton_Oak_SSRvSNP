# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# %%% RESAMPLING WITH SUBSET MICROSATELLITES %%%
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# This script generates Resampling arrays, and plots their results, 
# for Quercus acerifolia (QUAC; optimized Stacks de novo assembly, m 7, M/n 4, gt-alpha 0.01) 
# and Quercus boyntonii (QUBO; GSNAP4 alignment with Quercus robur reference) NextRAD samples

# In addition to processing SNP datasets, this script reads in the QUAC and QUBO microsatellite (MSAT)
# genind files as well, to compare results between marker types. Both SNP and MSAT files are then subset
# to contain only samples share between the two datasets, and resampling analyses are conducted with this
# shared sample set.

library(adegenet)
library(RColorBrewer)
library(scales)

# %%%% FUNCTIONS %%%% ----
# Function for reporting capture rates, using a sample matrix and a vector of allele frequencies
get.allele.cat.NEW <- function(freq.vector, sample.mat){
  # Total alleles
  # Determine how many alleles in the sample (i.e. greater than 0) are found in the frequency vector 
  total <- length(which(names(which(freq.vector > 0)) %in% names(which(colSums(sample.mat, na.rm = TRUE) > 0))))/length(which(freq.vector > 0))*100
  # Very common alleles (greater than 10%)
  v_com <- length(which(names(which(freq.vector > 10)) %in% names(which(colSums(sample.mat, na.rm = TRUE) > 0))))/length(which(freq.vector > 10))*100
  # Common alleles (greater than 5%)
  com <- length(which(names(which(freq.vector > 5)) %in% names(which(colSums(sample.mat, na.rm = TRUE) > 0))))/length(which(freq.vector > 5))*100
  # Low frequency alleles (between 1% and 10%)
  low_freq <- length(which(names(which(freq.vector < 10 & freq.vector > 1)) %in% names(which(colSums(sample.mat, na.rm = TRUE) > 0))))/length(which(freq.vector < 10 & freq.vector > 1))*100
  # Rare alleles (less than 1%)
  rare <- length(which(names(which(freq.vector < 1 & freq.vector > 0)) %in% names(which(colSums(sample.mat, na.rm = TRUE) > 0))))/length(which(freq.vector < 1 & freq.vector > 0))*100
  # Concatenate values to a vector, and return
  return(c(total,v_com,com,low_freq,rare))
}

# %%%% QUAC %%%% ----
# ---- PROCESS MSATS ----
# Read in genind file (GCC_QUAC_ZAIN repo; QUAC_wK_garden_wild_clean.gen)
genpop.filePath <- 
  "~/Documents/peripheralProjects/GCC_QUAC_ZAIN/Data_Files/Adegenet_Files/Garden_Wild/"
setwd(genpop.filePath)
QUAC.MSAT.genind <- read.genepop("QUAC_wK_garden_wild_clean.gen", quiet = TRUE, ncode = 3)
# Correct popNames: pop1 is Garden, pop2 is Wild
pop(QUAC.MSAT.genind) <- gsub("pop1", "garden", pop(QUAC.MSAT.genind))
pop(QUAC.MSAT.genind) <- gsub("pop2", "wild", pop(QUAC.MSAT.genind))
# Correct sample names: read in tissue database names from GCC_QUAC_ZAIN repository, and rename genind object rows
QUAC.MSAT.sampleNames_filepath <- "~/Documents/peripheralProjects/GCC_QUAC_ZAIN/Data_Files/Data_Frames/QUAC_allpop_clean_df.csv"
QUAC.MSAT.sampleNames <- unlist(read.csv2(QUAC.MSAT.sampleNames_filepath, header = TRUE, sep=",")[1])
rownames(QUAC.MSAT.genind@tab) <- QUAC.MSAT.sampleNames
# Create a matrix of strictly wild samples
QUAC.MSAT.wildMat <- QUAC.MSAT.genind@tab[which(pop(QUAC.MSAT.genind) == "wild"),]

# ---- PROCESS SNPS ----
# Read in genind file (QUAC DNFA; R0, min-maf=0; 1 SNP/locus; 2 populations, garden and wild)
genpop.filePath <- 
  "/RAID1/IMLS_GCCO/Analysis/Stacks/denovo_finalAssemblies/QUAC/output/populations_R0_NOMAF_TwoPops/"
setwd(genpop.filePath)
QUAC.R0_NOMAF.genind <- read.genepop(paste0(genpop.filePath,"populations.snps.gen"), quiet = TRUE)
# Correct popNames
pop(QUAC.R0_NOMAF.genind) <- factor(read.table("QUAC_popmap_GardenWild", header=FALSE)[,2])
# Create a matrix of strictly wild samples
QUAC.SNP.wildMat <- QUAC.R0_NOMAF.genind@tab[which(pop(QUAC.R0_NOMAF.genind) == "wild"),]
# Get QUAC SNP wild sample names, and rename wild SNP matrix
QUAC.SNP.sampleNames_filepath <- "~/Documents/SSRvSNP/Code/exSituCapture/QUAC_TissueDatabaseNames.csv"
QUAC.SNP.sampleNames <- unlist(read.csv2(QUAC.SNP.sampleNames_filepath, header = TRUE, sep = ",")[3])
rownames(QUAC.SNP.wildMat) <- QUAC.SNP.sampleNames

# ---- GENERATE SHARE SAMPLE DATASET ----
# Subset SNP sample names by those that are also seen within the MSAT samples (all of them, for QUAC)
QUAC_sharedSamples <- sort(QUAC.SNP.sampleNames[which(QUAC.SNP.sampleNames %in% QUAC.MSAT.sampleNames)])
# Demonstrating that which can be used regardless of the names vector that comes first
# QUAC_sharedSamples_TEST <- sort(QUAC.MSAT.sampleNames[which(QUAC.MSAT.sampleNames %in% QUAC.SNP.sampleNames)])
# identical(unname(QUAC_sharedSamples), unname(QUAC_sharedSamples_TEST))
# Subset MSAT and SNP wild matrix objects to strictly shared samples
QUAC.SNP.wildMat <- QUAC.SNP.wildMat[QUAC_sharedSamples,]
QUAC.MSAT.wildMat <- QUAC.MSAT.wildMat[QUAC_sharedSamples,]
# Generate allele frequency vectors for each dataset
QUAC.MSAT_wildFreqs <- colSums(QUAC.MSAT.wildMat, na.rm = TRUE)/(nrow(QUAC.MSAT.wildMat)*2)*100
QUAC.SNP_wildFreqs <- colSums(QUAC.SNP.wildMat, na.rm = TRUE)/(nrow(QUAC.SNP.wildMat)*2)*100

# ---- BUILD SAMPLING RESULTS ARRAYS ----
# TO DO: build a single (4D? 5D?) array that contains both MSAT and SNP values
# MSAT Sampling Results array
num_reps <- 25
list_allele_cat <- c("tot","v_com","com","low_freq","rare")
samplingResults_QUAC.MSAT <- array(dim=c(nrow(QUAC.MSAT.wildMat)-1,length(list_allele_cat),num_reps))
colnames(samplingResults_QUAC.MSAT) <- list_allele_cat
# For each replicate (which is the third dimension, in the samplingResults array)...
for(i in 1:num_reps){
  # loop through sampling from 2 to the maximum number of wild individuals
  for(j in 2:nrow(QUAC.MSAT.wildMat)){
    # Create a sample of the wild allele matrix, of "j" size
    samp <- QUAC.MSAT.wildMat[sample(nrow(QUAC.MSAT.wildMat), size=j, replace = FALSE),]
    # Calculate how many alleles of each category that sample captures,
    # and place those percentages into the row of the samplingResults array
    samplingResults_QUAC.MSAT[j-1,,i] <- get.allele.cat.NEW(QUAC.MSAT_wildFreqs,samp)
  }
}
str(samplingResults_QUAC.MSAT)

# SNP Sampling Results array
num_reps <- 25
list_allele_cat <- c("tot","v_com","com","low_freq","rare")
samplingResults_QUAC.SNP <- array(dim=c(nrow(QUAC.SNP.wildMat)-1,length(list_allele_cat),num_reps))
colnames(samplingResults_QUAC.SNP) <- list_allele_cat
# For each replicate (which is the third dimension, in the samplingResults array)...
for(i in 1:num_reps){
  # loop through sampling from 2 to the maximum number of wild individuals
  for(j in 2:nrow(QUAC.SNP.wildMat)){
    # Create a sample of the wild allele matrix, of "j" size
    samp <- QUAC.SNP.wildMat[sample(nrow(QUAC.SNP.wildMat), size=j, replace = FALSE),]
    # Calculate how many alleles of each category that sample captures,
    # and place those percentages into the row of the samplingResults array
    samplingResults_QUAC.SNP[j-1,,i] <- get.allele.cat.NEW(QUAC.SNP_wildFreqs,samp)
  }
}
str(samplingResults_QUAC.SNP)

# ---- CALCULATE MEANS AND PLOT ----
# Set plotting window to stack 2 graphs vertically
par(mfcol=c(2,1), oma=rep(0.05,4))
# Average results across replicates (slices) of the sampling array, to determine
# the minimum number of samples required to capture 95% wild genetic diversity
# (We average samplingResults[,1,], since this column contains the total genetic diversity)
min_95_QUAC.MSAT <- min(which(apply(samplingResults_QUAC.MSAT[,1,],1,mean) > 95)); min_95_QUAC.MSAT
min_95_QUAC.SNP <- min(which(apply(samplingResults_QUAC.SNP[,1,],1,mean) > 95)); min_95_QUAC.SNP

# Calculate means and standard deviations, for each capture rate category
QUAC.MSAT.total_means <- apply(samplingResults_QUAC.MSAT[,1,], 1, mean)
QUAC.SNP.total_means <- apply(samplingResults_QUAC.SNP[,1,], 1, mean)

# QUAC.MSAT.v.com_means <- apply(samplingResults_QUAC.MSAT[,2,], 1, mean)
# QUAC.SNP.v.com_means <- apply(samplingResults_QUAC.SNP[,2,], 1, mean)
# 
# QUAC.MSAT.com_means <- apply(samplingResults_QUAC.MSAT[,3,], 1, mean)
# QUAC.SNP.com_means <- apply(samplingResults_QUAC.SNP[,3,], 1, mean)
# 
# QUAC.MSAT.lowfr_means <- apply(samplingResults_QUAC.MSAT[,4,], 1, mean)
# QUAC.SNP.lowfr_means <- apply(samplingResults_QUAC.SNP[,4,], 1, mean)
# 
# QUAC.MSAT.rare_means <- apply(samplingResults_QUAC.MSAT[,5,], 1, mean)
# QUAC.SNP.rare_means <- apply(samplingResults_QUAC.SNP[,5,], 1, mean)

# Plots Total, for microsatellites and SNPs
plotColors <- alpha(c("purple","olivedrab4"),0.9)
plot(QUAC.MSAT.total_means, ylim=c(0,110), col=plotColors[1], pch=16, 
     xlab="Number of Individuals", ylab="Percent Diversity Capture",
     main="QUAC")
points(QUAC.SNP.total_means, col=plotColors[2], pch=17)
legend(x=30, y=40, inset = 0.05, legend = ("Microsatellites"),
       col=plotColors[1], pch = 16, cex=1, pt.cex = 2, bty="n", y.intersp = 0.5)
legend(x=30, y=40, inset = 0.05, legend = c("Microsatellites","SNPs"),
       col=plotColors, pch = c(16,17), cex=1, pt.cex = 2, bty="n", y.intersp = 0.5)
# Lines for 95% threshold
abline(h=95, col="grey1", lty=2)
abline(v=min_95_QUAC.MSAT, col=plotColors[1])
abline(v=min_95_QUAC.SNP, col=plotColors[2])
mtext(text=c("MSAT: 62 samples"), side=1, line=-3, at=67, cex=1)
mtext(text=c("MSAT: 62 samples","SNP: 81 samples"), side=1, line=-3, at=c(67,86), cex=1)

# %%%% QUBO %%%% ----
# ---- PROCESS MSATS ----
# Read in genind file (Southeast Oaks repo; genetic_data/Qb_total.gen file)
genpop.filePath <- 
  "~/Documents/peripheralProjects/SE_oaks_genetics/genetic_data/"
setwd(genpop.filePath)
QUBO.MSAT.genind <- read.genepop(paste0(genpop.filePath,"Qb_total.gen"), quiet = TRUE, ncode=3)
# Correct popNames: last population (IMLS4_MP1_IMLS336_C05) is Garden; rest are Wild
pop(QUBO.MSAT.genind) <- gsub("IMLS4_MP1_IMLS336_C05", "garden", pop(QUBO.MSAT.genind))
# Create a matrix of strictly wild samples
QUBO.MSAT.wildMat <- QUBO.MSAT.genind@tab[which(pop(QUBO.MSAT.genind) != "garden"),]

# Get QUBO MSAT wild sample names
QUBO.MSAT.sampleNames <- row.names(QUBO.MSAT.wildMat)
# Split sample names on underscore, then return the 3rd element of the names. Rename the sample matrix with these names
QUBO.MSAT.sampleNames <- unlist(lapply(QUBO.MSAT.sampleNames, function(x) strsplit(x, "_")[[1]][3]))
rownames(QUBO.MSAT.wildMat) <- QUBO.MSAT.sampleNames

# ---- PROCESS SNPS ----
# Read in genind file (QUBO GSNAP4 alignment; R0, min-maf=0; 1 SNP/locus; 2 populations, garden and wild)
genpop.filePath <- 
  "/RAID1/IMLS_GCCO/Analysis/Stacks/reference_filteredReads/QUBO/GSNAP4/output/populations_R0_NOMAF_TwoPops/"
setwd(genpop.filePath)
QUBO.R0_NOMAF.genind <- read.genepop(paste0(genpop.filePath,"populations.snps.gen"), quiet = TRUE)
# Correct popNames
pop(QUBO.R0_NOMAF.genind) <- factor(read.table("QUBO_popmap_GardenWild", header=FALSE)[,2])

# Make a vector corresponding to wild individuals in the genind file (to extract them)
# (Wild individuals are those that don't have a population named "garden")
QUBO.SNP.sampleNumbers <- seq(from=length(which(pop(QUBO.R0_NOMAF.genind)=="garden"))+1, to=nInd(QUBO.R0_NOMAF.genind))
# Create a matrix of strictly wild samples.
QUBO.SNP.wildMat <- QUBO.R0_NOMAF.genind@tab[QUBO.SNP.sampleNumbers,]

# Get QUBO SNP wild sample names
QUBO.SNP.sampleNames <- row.names(QUBO.R0_NOMAF.genind@tab)[QUBO.SNP.sampleNumbers]
# Remove QUBO_W_ headers from sample names
QUBO.SNP.sampleNames <- gsub("QUBO_W_",replacement = "", QUBO.SNP.sampleNames)
# Replace SH-Q names in SNP list with IMLS names
QUBO.SNP.sampleNames <- gsub("SH_Q2178",replacement = "IMLS312", QUBO.SNP.sampleNames)
QUBO.SNP.sampleNames <- gsub("SH_Q2179",replacement = "IMLS062", QUBO.SNP.sampleNames)
QUBO.SNP.sampleNames <- gsub("SH_Q2180",replacement = "IMLS051", QUBO.SNP.sampleNames)
QUBO.SNP.sampleNames <- gsub("SH_Q2181",replacement = "IMLS011", QUBO.SNP.sampleNames)
QUBO.SNP.sampleNames <- gsub("SH_Q2182",replacement = "IMLS144", QUBO.SNP.sampleNames)
QUBO.SNP.sampleNames <- gsub("SH_Q2183",replacement = "IMLS170", QUBO.SNP.sampleNames)
QUBO.SNP.sampleNames <- gsub("SH_Q2184",replacement = "IMLS005", QUBO.SNP.sampleNames)
QUBO.SNP.sampleNames <- gsub("SH_Q2186",replacement = "IMLS017", QUBO.SNP.sampleNames)
# Rename sample matrix
rownames(QUBO.SNP.wildMat) <- QUBO.SNP.sampleNames

# ---- GENERATE SHARED SAMPLE DATASET ----
# Subset SNP sample names by those that are also seen within the MSAT samples
QUBO_sharedSamples <- sort(QUBO.SNP.sampleNames[which(QUBO.SNP.sampleNames %in% QUBO.MSAT.sampleNames)])
# Demonstrating that which can be used regardless of the names vector that comes first
# QUBO_sharedSamples_TEST <- sort(QUBO.MSAT.sampleNames[which(QUBO.MSAT.sampleNames %in% QUBO.SNP.sampleNames)])
# identical(QUBO_sharedSamples, QUBO_sharedSamples_TEST)
# Subset MSAT and SNP wild matrix objects to strictly shared samples
QUBO.SNP.wildMat <- QUBO.SNP.wildMat[QUBO_sharedSamples,]
QUBO.MSAT.wildMat <- QUBO.MSAT.wildMat[QUBO_sharedSamples,]
# Generate allele frequency vectors for each dataset
QUBO.MSAT_wildFreqs <- colSums(QUBO.MSAT.wildMat, na.rm = TRUE)/(nrow(QUBO.MSAT.wildMat)*2)*100
QUBO.SNP_wildFreqs <- colSums(QUBO.SNP.wildMat, na.rm = TRUE)/(nrow(QUBO.SNP.wildMat)*2)*100

# ---- BUILD SAMPLING RESULTS ARRAYS ----
# TO DO: build a single (4D? 5D?) array that contains both MSAT and SNP values
# MSAT Sampling Results array
num_reps <- 25
list_allele_cat <- c("tot","v_com","com","low_freq","rare")
samplingResults_QUBO.MSAT <- array(dim=c(nrow(QUBO.MSAT.wildMat)-1,length(list_allele_cat),num_reps))
colnames(samplingResults_QUBO.MSAT) <- list_allele_cat
# For each replicate (which is the third dimension, in the samplingResults array)...
for(i in 1:num_reps){
  # loop through sampling from 2 to the maximum number of wild individuals
  for(j in 2:nrow(QUBO.MSAT.wildMat)){
    # Create a sample of the wild allele matrix, of "j" size
    samp <- QUBO.MSAT.wildMat[sample(nrow(QUBO.MSAT.wildMat), size=j, replace = FALSE),]
    # Calculate how many alleles of each category that sample captures,
    # and place those percentages into the row of the samplingResults array
    samplingResults_QUBO.MSAT[j-1,,i] <- get.allele.cat.NEW(QUBO.MSAT_wildFreqs,samp)
  }
}
str(samplingResults_QUBO.MSAT)

# SNP Sampling Results array
num_reps <- 25
list_allele_cat <- c("tot","v_com","com","low_freq","rare")
samplingResults_QUBO.SNP <- array(dim=c(nrow(QUBO.SNP.wildMat)-1,length(list_allele_cat),num_reps))
colnames(samplingResults_QUBO.SNP) <- list_allele_cat
# For each replicate (which is the third dimension, in the samplingResults array)...
for(i in 1:num_reps){
  # loop through sampling from 2 to the maximum number of wild individuals
  for(j in 2:nrow(QUBO.SNP.wildMat)){
    # Create a sample of the wild allele matrix, of "j" size
    samp <- QUBO.SNP.wildMat[sample(nrow(QUBO.SNP.wildMat), size=j, replace = FALSE),]
    # Calculate how many alleles of each category that sample captures,
    # and place those percentages into the row of the samplingResults array
    samplingResults_QUBO.SNP[j-1,,i] <- get.allele.cat.NEW(QUBO.SNP_wildFreqs,samp)
  }
}
str(samplingResults_QUBO.SNP)

# ---- CALCULATE MEANS AND PLOT ----
# Average results across replicates (slices) of the sampling array, to determine
# the minimum number of samples required to capture 95% wild genetic diversity
# (We average samplingResults[,1,], since this column contains the total genetic diversity)
min_95_QUBO.MSAT <- min(which(apply(samplingResults_QUBO.MSAT[,1,],1,mean) > 95)); min_95_QUBO.MSAT
min_95_QUBO.SNP <- min(which(apply(samplingResults_QUBO.SNP[,1,],1,mean) > 95)); min_95_QUBO.SNP

# Calculate means and standard deviations, for each capture rate category
QUBO.MSAT.total_means <- apply(samplingResults_QUBO.MSAT[,1,], 1, mean)
QUBO.SNP.total_means <- apply(samplingResults_QUBO.SNP[,1,], 1, mean)

# QUBO.MSAT.v.com_means <- apply(samplingResults_QUBO.MSAT[,2,], 1, mean)
# QUBO.SNP.v.com_means <- apply(samplingResults_QUBO.SNP[,2,], 1, mean)
# 
# QUBO.MSAT.com_means <- apply(samplingResults_QUBO.MSAT[,3,], 1, mean)
# QUBO.SNP.com_means <- apply(samplingResults_QUBO.SNP[,3,], 1, mean)
# 
# QUBO.MSAT.lowfr_means <- apply(samplingResults_QUBO.MSAT[,4,], 1, mean)
# QUBO.SNP.lowfr_means <- apply(samplingResults_QUBO.SNP[,4,], 1, mean)
# 
# QUBO.MSAT.rare_means <- apply(samplingResults_QUBO.MSAT[,5,], 1, mean)
# QUBO.SNP.rare_means <- apply(samplingResults_QUBO.SNP[,5,], 1, mean)

# Plots Total, for microsatellites and SNPs
plotColors <- alpha(c("purple","olivedrab4"),0.9)
plot(QUBO.MSAT.total_means, ylim=c(0,110), col=plotColors[1], pch=16, 
     xlab="Number of Individuals", ylab="Percent Diversity Capture",
     main="QUBO")
points(QUBO.SNP.total_means, col=plotColors[2], pch=17)
legend(x=30, y=40, inset = 0.05, legend = "Microsatellites",
       col=plotColors[1], pch = 16, cex=1, pt.cex = 2, bty="n", y.intersp = 0.5)
legend(x=30, y=40, inset = 0.05, legend = c("Microsatellites","SNPs"),
       col=plotColors, pch = c(16,17), cex=1, pt.cex = 2, bty="n", y.intersp = 0.5)
# Lines for 95% threshold
abline(h=95, col="grey1", lty=2)
abline(v=min_95_QUBO.MSAT, col=plotColors[1])
abline(v=min_95_QUBO.SNP, col=plotColors[2])
mtext(text=c("MSAT: 76 samples"), side=1, line=-4, at=82, cex=1)
mtext(text=c("MSAT: 76 samples","SNP: 73 samples"), side=1, line=-4, at=c(82,68), cex=1)
