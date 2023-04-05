#!/bin/bash
##########################################################
##                                                      ##
##          UNCLASSIFIED//FOR OFFICIAL USE ONLY         ##
##                                                      ##
##########################################################

##########################################################
##                                                      ##
##                         Team                         ##
##             ACAS Scanner DNS Lookup-ifier            ##
##                      Version 1.0                     ##
##                                                      ##
##########################################################

HEADERLINE=`head -n1 acas_scanners.csv`                                         # Grabs top line from OG list, sets variable 

sed -e '1d' acas_scanners.csv | cut -d, -f1 > acas_scanners_hostnames.csv       # Remove top line from OG list

sed -e '1d' acas_scanners.csv | cut -d, -f3-20 > cut_info.csv                   # Remove top line from OG list, removes first two columns

for h in `cat acas_scanners_hostnames.csv`; do                                  #
        printf "$h,$(dig +short "$h".domain),\n"                         # For each hostname, do a dig lookup and concatenate the two values in a new file
done > acas_scanners_hostnames_ips.csv                                          #

paste -d "" acas_scanners_hostnames_ips.csv cut_info.csv > combined.csv         # Paste list of hostnames & IPs with the old info into one CSV

sed -i "1i${HEADERLINE}" combined.csv                                           # Prepends header line to top of CSV

##########################################################
##                                                      ##
##          UNCLASSIFIED//FOR OFFICIAL USE ONLY         ##
##                                                      ##
##########################################################