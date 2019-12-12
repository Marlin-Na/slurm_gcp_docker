# this should not be run as a standalone, but rather only sourced from external
# scripts.

#
# parse arguments

SIZE=$1
shift
DISKTYPE=$1

case "$DISKTYPE" in
	pd-standard)
		;;
	pd-ssd)
		;;
	*)
		DISKTYPE="pd-standard"
		;;
esac

#
# get zone of instance
ZONE=$(gcloud compute instances list --filter="name=${HOSTNAME}" \
  --format='csv[no-heading](zone)')

#
# create and attach NFS disk (if it does not already exist)
echo -e "Creating NFS disk ...\n"

gcloud compute disks list --filter="name=${HOSTNAME}-nfs" --format='csv[no-heading](type)' | \
  grep -q $DISKTYPE || \
  gcloud compute disks create ${HOSTNAME}-nfs --size ${SIZE}GB --type $DISKTYPE --zone $ZONE
[ -b /dev/disk/by-id/google-${HOSTNAME}-nfs ] || \
  { gcloud compute instances attach-disk $HOSTNAME --disk ${HOSTNAME}-nfs --zone $ZONE \
      --device-name ${HOSTNAME}-nfs && \
    gcloud compute instances set-disk-auto-delete $HOSTNAME --disk ${HOSTNAME}-nfs \
      --zone $ZONE; }

#
# format NFS disk (if it's not already mounted)
mountpoint -q /mnt/nfs || {
echo -e "\nFormatting disk ...\n"

# XXX: we assume that this will always be /dev/sdb. In the future, if we are
#      attaching multiple disks, this might not be the case.
sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb

#
# mount NFS disk
echo -e "\nMounting disk ...\n"

# this should already be present, but let's do this just in case
[ ! -d /mnt/nfs ] && sudo mkdir -p /mnt/nfs
sudo mount -o discard,defaults /dev/sdb /mnt/nfs;
}