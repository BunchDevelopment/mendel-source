#!/bin/bash -e

function usage {
    echo "Usage: checkout-release.sh <release-file> <release-branch-name>"
    echo
    echo "Where <release-file> contains a simple list of project path"
    echo "to SHA-1 commit ID."
    echo
    exit 1
}

release_file="$1"
release_branch_name="$2"

[[ ! -e $release_file ]] && usage
[[ -z $release_branch_name ]] && usage

(
    while read project commit; do
        pushd $project
        git checkout $commit
        git checkout -b $release_branch_name
        popd
    done
) < $release_file

echo
echo "**********************************************************************"
echo "Everything look sane? If so, type YES to push the branches upstream."
read yes

if [[ "$yes" != "YES" ]]; then
    echo "You didn't say YES. Cowardly refusing to continue."
    echo "**********************************************************************"
    echo
    exit 1
fi

(
    while read project commit; do
        pushd $project
        git push aiy $release_branch_name:refs/heads/$release_branch_name
        popd
    done
) < $release_file

echo "Push completed."
echo "**********************************************************************"
echo
