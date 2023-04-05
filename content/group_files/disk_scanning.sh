#/bin/bash
#Rescan all SCSI/SATA Hosts
echo "Re-Scanning iSCSI"
for SHOST in /sys/class/scsi_host/host*; do
    echo -n "Scanning ${SHOST##*/}..."
    echo "- - -" > ${SHOST}/scan
    echo Done
done

echo "Re-scanning drive sizes"
for SDRIVE in /sys/block/sd*; do
    echo -n "Scanning ${SDRIVE##*/}..."
    echo 1 > ${SDRIVE}/device/rescan
    echo Done
done 