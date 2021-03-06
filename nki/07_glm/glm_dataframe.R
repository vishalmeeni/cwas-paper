#!/usr/bin/env Rscript

### Command-Line:
## usage: glm_dataframe.R mdmr-pvals-file glm-summary-file output-directory
## arguments:
# mdmr p-value descriptor file
# glm summary rda file
# output directory

library(niftir)


# An empty function for Comments
Comment <- function(`@Comments`) {invisible()}

Comment("
This script will combine the GLM summary data with MDMR results
into a nice data frame that can be used for visualization.

Story:
    Vicki has her bags full.
")


## Read in user arguments

args = commandArgs(trailingOnly = TRUE)

if (length(args) < 4)
    stop("must have at least 4 arguments: mask-file mdmr-zstat-file glm-summary-files outdir")

mask.file <- args[1]
mdmr.zstat.file <- args[2]
glm.summary.files <- args[-c(1,2,length(args))]
outdir <- args[length(args)]



### Combine data together!

library(connectir)

## Read

# 1. Load MDMR Results
mask        <- read.mask(mask.file)
mdmr.zvals  <- as.matrix(read.nifti.image(mdmr.zstat.file)[mask])
#mdmr.pvals <- attach.big.matrix(mdmr.pvals.file)[,,drop=FALSE]
#mdmr.log.pvals <- -log10(mdmr.pvals)
#mdmr.fdr.pvals <- p.adjust(mdmr.pvals, "fdr")
#mdmr.fdr.pvals <- matrix(mdmr.fdr.pvals, nrow(mdmr.pvals), ncol(mdmr.pvals))
#mdmr.fdr.log.pvals <- -log10(mdmr.fdr.pvals)


# 2. Load GLM Summary

# Get names of regressors
fns <- basename(glm.summary.files)
names <- sub("both_", "", fns)
names <- sub(".rda", "", names)

# Load the data
glm.wt.zvals <- matrix(0, nrow(mdmr.zvals), ncol(mdmr.zvals))
glm.uwt.zvals <- matrix(0, nrow(mdmr.zvals), ncol(mdmr.zvals))
for (i in 1:length(glm.summary.files)) {
    load(glm.summary.files[i])
    glm.wt.zvals[,i] <- wt$zvals
    glm.uwt.zvals[,i] <- uwt$zvals
}


###
# Combine
###

nrois <- nrow(mdmr.zvals)
nvoxs <- sum(mask)
df <- data.frame(
    factor = rep(names, each=nrois), 
    roi = rep(1:nrois, length(glm.summary.files)), 
    mdmr = as.vector(mdmr.zvals), 
    glm.wt = as.vector(glm.wt.zvals), 
    glm.uwt = (as.vector(glm.uwt.zvals)/nvoxs)*100
)

write.csv(df, file=file.path(outdir, "dataframe_glm+mdmr.csv"))
