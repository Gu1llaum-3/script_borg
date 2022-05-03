#!/bin/bash

###########################################################
# Description : Script for borg backup                    #
# According to Tontonjoe's script,                        #
# himself modified from the official script.              #
# Join him on Youtube: https://www.youtube.com/c/tontonjo #
# Auteur......: Guillaume                                 #
# Date........: 01/05/2022                                #
# Version.....: 1.0                                       #
###########################################################


# USAGE
# Install borg Backup for your distribution
# Initialize your backup target: borg init -e authenticated /path/to/repo
# Backup the passphase and datastore key as suggested
# Copy this script on your server
# Uncomment/comment local or remote target and edit BORG_REPO to your datastore
# Edit BORG_PASSPHRASE to the one you choose when you inited the repository
# Edit Path to save, leave blank save2 if not used
# Edit compression to choose the desired method (none/lz4/zstd/zlib/lzma/auto)
# Edit exclusion if needed (ex: '/var/tmp/*' /, none if don't use)
# Edit retention
# Edit Path to logs
# Run script with bash borg.sh

## Path to repo & Password ##
# local target:
# export BORG_REPO=/path/to/repo
# remote target:
export BORG_REPO=ssh://username@example.com:2022/path/to/remote_repo
export BORG_PASSPHRASE='your_password'

#Path to save
save1=
save2=

# Customization backup
compression=none
exclusion1=none
exclusion2=none

# Retention (By default, keep the last 7 days, the last 4 weeks, the last 6 months and 1 per year):
hourly=0
daily=7
weekly=4
monthly=6
yearly=1

# Path to logs:
logs=/path/to/logs/borg.log

# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$( date )" "$*" >&2; }
trap 'echo $( date ) Backup interrupted >&2; exit 2' INT TERM

info "Starting backup"

# Backup the most important directories into an archive named after
# the machine this script is currently running on:
borg create                         \
    --progress                      \
    --stats                         \
    --show-rc                       \
    --compression      $compression \
    --exclude-caches                \
    --exclude          $exclusion1  \
    --exclude          $exclusion2  \
    ::'{hostname}-{now}'            \
    $save1                          \
    $save2                          \
    2>&1 | tee $logs


backup_exit=$?

info "Pruning repository"

# Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
# archives of THIS machine. The '{hostname}-' prefix is very important to
# limit prune's operation to this machine's archives and not apply to
# other machines' archives also:

borg prune                          \
    --list                          \
    --stats                         \
    --prefix '{hostname}-'          \
    --show-rc                       \
    --keep-hourly   $hourly         \
    --keep-daily    $daily          \
    --keep-weekly   $weekly         \
    --keep-monthly  $monthly        \
    --keep-yearly   $yearly         \
    2>&1 | tee -a $logs
prune_exit=$?

# use highest exit code as global exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))

if [ ${global_exit} -eq 0 ]; then
    info "Backup and Prune finished successfully"
elif [ ${global_exit} -eq 1 ]; then
    info "Backup and/or Prune finished with warnings"
else
    info "Backup and/or Prune finished with errors"
fi


exit ${global_exit}
