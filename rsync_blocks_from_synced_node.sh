#!/bin/bash
set -x

USER=root
REMOTE_HOST=host.withsyncedblocks.org
REMOTE_PATH=$user@$REMOTE_HOST:/home/zend/.zen/
LOCAL_PATH=/mnt/blocks/
DRY_RUN="--dry-run"
#DRY_RUN=""

# make sure zend is stopped on remote
ssh $USER@$REMOTE_HOST "sudo systemctl stop zend"

# pull blocks
rsync -av $DRY_RUN -e ssh --progress $REMOTE_PATH/blocks $LOCAL_PATH

# pull chainstate
rsync -av $DRY_RUN -e ssh --progress $REMOTE_PATH/chainstate $LOCAL_PATH

