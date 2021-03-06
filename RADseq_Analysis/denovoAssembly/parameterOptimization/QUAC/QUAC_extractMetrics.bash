#!/bin/bash

# Script for extracting 4 metrics from Stacks QUAC de novo assembly output, in order to assess quality of denovo assembly for each specific parameter set
# The while loops over a file which is simply a list of every output directory generated as part of the parameter optimization run. Directory names are combinations of parameter values.

# 6 metrics are pulled from the Stacks output files of each assembly, using stacks-dist-extract. These are cleaned into simple texts files.
# The referenced Rscript reads in these text files and builds a matrix of assembly values. That matrix is saved to an R object, which is read in a separate R script used for plotting.

while IFS=, read -r assembly; do
	echo $assembly
        # Move into assembly folder
	cd ../output/$assembly

        # %%%%%%%%%%%%%%%%%%%%%%%
	# %%% EXTRACT METRICS %%%
	# %%%%%%%%%%%%%%%%%%%%%%%
	# GENERAL COVERAGE (unweighted)
	stacks-dist-extract ./denovo_map.log cov_per_sample | cut -f 2 > metric-depth_of_cov

	# WEIGHTED COVERAGE (adjusted by number of samples present at a locus)
	stacks-dist-extract ./gstacks.log.distribs effective_coverages_per_sample | cut -f 5 > metric-weighted_cov

	# NUMBER OF ASSEMBLED LOCI
	stacks-dist-extract ./pop_R80/populations.log.distribs loci_per_sample | cut -f 2 > metric-assembled_loci

	# NUMBER OF POLYMORPHIC LOCI
	stacks-dist-extract ./pop_R80/populations.log.distribs snps_per_loc_postfilters | tail -n +4 | cut -f 2 > metric-polymorphic_loci

	# NUMBER OF SNPS
	stacks-dist-extract ./pop_R80/populations.log.distribs variant_sites_per_sample | cut -f 2 > metric-number_of_SNPs

	# PCR DUPLICATION RATE
	stacks-dist-extract ./gstacks.log.distribs effective_coverages_per_sample | cut -f 8 > metric-pcr_duplication_rate

	# %%%%%%%%%%%%%%%%%%%%
        # %%% BUILD MATRIX %%%
        # %%%%%%%%%%%%%%%%%%%%
	# Run R script to build a matrix in R containing metrics just extracted for the current assembly. The script will save this matrix to a .Rdata file
	Rscript /home/user/Documents/SSRvSNP/Code/denovoAssembly/parameterOptimization/QUAC/build_QUAC_assemblyMetricsMatrix.R

	# Move back into analysis folder
	cd ../../analysis

done < ../output/QUAC_assemblies
