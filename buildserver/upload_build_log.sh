#! /bin/bash
#
# A function to upload build logs
# If a branch is known it will upload to
# build-logs/branch/yyyy-mm/logfile
# otherwise it will upload to
# build-logs/logfile

log_file=$1
host=$2
log_dir=$3
remote_branch_dir=$4
base_dir=$(pwd) # A dummy base directory used in rsync

# This function will create a remote directory
# It will only run if $host is configured.
# Note it assumes the parent directory exists and it won't
# create intermediate subdirectories if that is not the case
function create_remote_dir()
{
    if [[ -n "$host" ]]
    then
        # For this hack $base_dir is just an arbitrary existing directory
        # It doesn't matter which one
        # No files will be copied from it anyway because of the exclude parameter
        rsync -e ssh -a --exclude='*' "$base_dir"/ "$1"
    fi
}

if [[ -n "$host" ]]
then
    echo "Uploading log file '$(basename $log_file)'"
    create_remote_dir "$host"/build-logs
    if [[ -z "$remote_branch_dir" ]]
    then
        # We don't know the build type yet, so we can't determine
        # the final remote directory to store it
        # So let's just store it in the top-level so we have a trace
        # of the build start or very early failures
        rsync -e ssh -a "$log_file" "$host"/build-logs
    else
        # Now the subdirectory to store the log file is is known
        # In addition group per month to simplify navigation even more
        month_part=$(date +%Y-%m)

        create_remote_dir "$host"/build-logs/$remote_branch_dir
        create_remote_dir "$host"/build-logs/$remote_branch_dir/$month_part

        rsync -e ssh -a "$log_file" "$host"/build-logs/$remote_branch_dir/$month_part

        # Finally remove the initially start build log uploaded earlier
        # Disable fatal error handling though to prevent the complete script from exiting
        # if no early build log exists
        echo "Removing initial startup build log uploaded earlier"
        set +ex
        rsync -e ssh -rv --delete --include="$(basename $log_file)" --exclude='*' "$base_dir"/ "$host"/build-logs/
        set -ex
    fi
fi
