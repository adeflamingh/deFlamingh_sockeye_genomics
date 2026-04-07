#ANGSD analysis

This directory contains scripts associated with ANGSD and genotype likelihood estimation. It follows the same general approach as used by Kelsey Witt's pipeline on Github: kelsey-witt/macaque-lowcvg-pipeline 

Yao, Lu, et al. "Population genetics of wild Macaca fascicularis with low‐coverage shotgun sequencing of museum specimens." American journal of physical anthropology 173.1 (2020): 21-33.

##Input file filters:
Only samples that had a breadth of coverage above 50% of the genome were included in GL estimation. We used alignment statistics calculated during the alignment step to ensure that this threshold was met. Further, 
