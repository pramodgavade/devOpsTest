# git commits
echo "GIT_COMMIT = ${GIT_COMMIT}"
echo "GIT_PREVIOUS_SUCCESSFUL_COMMIT = ${GIT_PREVIOUS_SUCCESSFUL_COMMIT}"

currGitCommit=${GIT_COMMIT}
prevGitCommit=${GIT_PREVIOUS_SUCCESSFUL_COMMIT}

if [ -z $2 ]; then
    echo "no commit id override"
else 
    echo "prev commit id override: $2"
    prevGitCommit=$2
fi    

echo "currGitCommit = $currGitCommit"
echo "prevGitCommit = $prevGitCommit"

# if previous commit id is null
if $1 && [ -z $prevGitCommit ]; then
    echo "cannot run incremental deployment with null prevGitCommit"
    exit 1
fi 

# if current and previous git commits are same
if $1 && [[ $currGitCommit == $prevGitCommit ]]; then
    echo "current and previous git cimmits are same, no change to deploy"
    exit 0
fi   

# list of files modifed
echo "***************list of modified files***************"
git diff --name-only $currGitCommit $prevGitCommit

tempDirectory="temp-dir"
changeDetected=false

echo "***************building force-app folder***************"

# loop through list of modified files
git diff -z --name-only $currGitCommit $prevGitCommit|
while read -d $'\0' fileName
do
    echo "current file : $fileName"
    echo "changeDetected = $changeDetected"
        
        # if file modified file is from force-app/main/default
        if [[ $fileName == *"force-app"* ]]; then
            echo "including $fileName"
            
            changeDetected=true           
            
            # First create the target directory, if it doesn't exist
            directoryName=$(dirname "$fileName")
            mkdir -p "$tempDirectory/$directoryName"
            
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
ls

# if incremental deployment
if $1; then
    echo "***************incremental changes***************"
    echo "changeDetected = $changeDetected"
    # if no file changed
    if [ ! -d "$tempDirectory" ]; then
        echo "no change detected, exiting"
        exit 0
    fi    

    # rename force-app folder
    mv force-app force-app-old

    # copy force-app folder from temp directory to workspace
    cp -r $tempDirectory/force-app $WORKSPACE
fi

# convert to Metadata API format using sfdx
echo "***************Salesforce CLI***************"
sfdx --version
sfdx force:source:convert -d deployment

# verify deployment folder, deployment folder is use for ANT deployment
echo "***************Deployment folder***************"
cd deployment
ls