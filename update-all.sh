if which git>/dev/null; then
    git remote update
    UPSTREAM=${1:-'@{u}'}
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse "$UPSTREAM")
    BASE=$(git merge-base @ "$UPSTREAM")

    if [ $LOCAL = $REMOTE ]; then
        echo "update-all up-to-date"
    elif [ $LOCAL = $BASE ]; then
        git pull
        bash -x ./update-all.sh
    elif [ $REMOTE = $BASE ]; then
        echo "Need to push update-all, but we will not do that automatically"
    else
        echo "Diverged from upstream. Skipping update"
    fi
fi

./update-apt.sh

./update-npm.sh &

./update-pip.sh &

./update-R.sh &

./update-snap.sh &

./update-conda.sh

./update-julia.sh

./update-waterfox.sh

./update-calibre.sh



wait
