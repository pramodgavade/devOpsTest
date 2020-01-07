# git commits
currGitCommit=${GIT_COMMIT}
prevGitCommit=${GIT_PREVIOUS_SUCCESSFUL_COMMIT}
if [ -z $2]; then
    echo "empty commit id"
else 
    echo "commit id: $2"
fi    


echo "GIT_COMMIT = ${GIT_COMMIT}"
echo "GIT_PREVIOUS_SUCCESSFUL_COMMIT = ${GIT_PREVIOUS_SUCCESSFUL_COMMIT}"

# list of files modifed
echo "***************list of modified files***************"
git diff --name-only ${GIT_COMMIT} ${GIT_PREVIOUS_SUCCESSFUL_COMMIT}

tempDirectory = "temp-dir"

echo "***************building force-app folder***************"

# loop through list of modified files
for fileName in $(git diff --name-only ${GIT_COMMIT} ${GIT_PREVIOUS_SUCCESSFUL_COMMIT})
    do
        echo "current file : $fileName"
        
        # if file modified file is from force-app/main/default
        if [[ $fileName == *"force-app"* ]]; then
            echo "including $fileName"
            
            # First create the target directory, if it doesn't exist
            mkdir -p "$tempDirectory/$(dirname $fileName)"
            
            # Then copy over the file
            cp -rf "$fileName" "$tempDirectory/$fileName"
            
            # Then copy over the meta data file if it exists
            metaFileName="$fileName-meta.xml"
            if [ -f "$metaFileName" ]; then
                echo "including $metaFileName"
                cp -rf "$metaFileName" "$tempDirectory/$metaFileName"
            fi    
        else 
            echo "skipped $fileName"
        fi
        
    done
    
# navigate to workspace
cd $WORKSPACE

# rename force-app folder
mv force-app force-app-old

# copy force-app folder from temp directory to workspace
cp -r $tempDirectory/force-app $WORKSPACE

# convert to Metadata API format using sfdx
echo "***************Salesforce CLI***************"
sfdx --version
sfdx force:source:convert -d deployment

# verify deployment folder, deployment folder is use for ANT deployment
echo "***************Deployment folder***************"
cd deployment
ls