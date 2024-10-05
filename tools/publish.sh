#!/usr/bin/env bash

# This script will push all changes to github

CURRENT_DATE=$(date '+%Y%m%d')
echo "Published to GitHub on $CURRENT_DATE"

git add --all
git commit -n -m "published on $CURRENT_DATE"
git push
