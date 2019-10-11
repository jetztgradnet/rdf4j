#!/bin/bash

echo "This script will stop if an unhandled error occurs";
echo "Do not change any files in this directory while the script is running!"
set -e -o pipefail


read -p "Start the release process (y/n)?" choice
case "${choice}" in
  y|Y ) echo "";;
  n|N ) exit;;
  * ) echo "unknown response, exiting"; exit;;
esac


if  !  mvn -v | grep -q "Java version: 1.8."; then
  echo "";
  echo "You need to use Java 8!";
  echo "mvn -v";
  echo "";
  exit 1;
fi


# check that we are on master
if  ! git status --porcelain --branch | grep -q "## master...origin/master"; then
  echo""
  echo "You need to be on master!";
  echo "git checkout master";
  echo "";
  exit 1;
fi

echo "Running git pull to make sure we are up to date"
git pull


# check that we are not ahead or behind
if  ! [[ $(git status --porcelain -u no  --branch) == "## master...origin/master" ]]; then
    echo "";
    echo "There is something wrong with your git. It seems you are not up to date with master. Run git status";
    exit 1;
fi

# check that there are no uncomitted or untracked files
if  ! [[ `git status --porcelain` == "" ]]; then
    echo "";
    echo "There are uncomitted or untracked files! Commit, delete or unstage files. Run git status for more info.";
    exit 1;
fi

# set maven version, user will be prompted
mvn versions:set

# find the maven version of the project from the root pom.xml
MVN_VERSION_RELEASE=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='version']/text()" pom.xml)

echo "";
echo "Your maven version is: ${MVN_VERSION_RELEASE}"
read -n 1 -s -r -p "Press any key to continue (ctrl+c to cancel)"; printf "\n\n";

#Remove backup files. Finally, commit the version number changes:
mvn versions:commit


BRANCH="releases/${MVN_VERSION_RELEASE}"

# delete old release branch if it exits
if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  git branch --delete --force "${BRANCH}" &>/dev/null
fi

# checkout branch for release, commit this maven version and tag commit
git checkout -b ${BRANCH}
git commit -s -a -m "release ${MVN_VERSION_RELEASE}"
git tag "${MVN_VERSION_RELEASE}"

echo "";
read -p "Push tag (y/n)?" choice
case "${choice}" in
  y|Y ) echo "";;
  n|N ) exit;;
  * ) echo "unknown response, exiting"; exit;;
esac

# push tag (only tag, not branch)
git push origin "${MVN_VERSION_RELEASE}"

echo "";
echo "One-jar build takes several minutes"
read -n 1 -s -r -p "Press any key to continue to one-jar build (ctrl+c to cancel)"; printf "\n\n";

# build one jar
mvn -Passembly clean install -DskipTests

# todo upload to SFTP (also check sftp credentials at beginning of this script)

echo "";
read -n 1 -s -r -p "Press any key to continue (ctrl+c to cancel)"; printf "\n\n";

# Cleanup
git checkout master
mvn clean
git branch --delete --force "${BRANCH}" &>/dev/null


# Set a new SNAPSHOT version
echo "";
echo "You will now be prompted to set the new maven SNAPSHOT version. If you set a version of say 3.2.4 then the next version should be 3.2.5-SNAPSHOT. If it was 5.0.0 then the next should be 5.0.1-SNAPSHOT."
echo "You released: ${MVN_VERSION_RELEASE}"
echo "Type in the next version number followed by '-SNAPSHOT' when prompted."
read -n 1 -s -r -p "Press any key to continue (ctrl+c to cancel)"; printf "\n\n";


# set maven version, user will be prompted
mvn versions:set

# find the maven version of the project from the root pom.xml
MVN_VERSION_NEW_SNAPSHOT=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='version']/text()" pom.xml)

echo "";
echo "Your maven version is: ${MVN_VERSION_NEW_SNAPSHOT}"
read -n 1 -s -r -p "Press any key to continue (ctrl+c to cancel)"; printf "\n\n";

#Remove backup files. Finally, commit the version number changes:
mvn versions:commit

echo "";
echo "Committing the new version to git"
git commit -s -a -m "next development iteration: ${MVN_VERSION_NEW_SNAPSHOT}"
echo "Pushing the new version to github"
git push

echo "";
echo "Preparing a merge branch to merge into develop"
read -n 1 -s -r -p "Press any key to continue (ctrl+c to cancel)"; printf "\n\n";


git checkout develop
git pull

MVN_VERSION_DEVELOP=$(xmllint --xpath "//*[local-name()='project']/*[local-name()='version']/text()" pom.xml)

git checkout master

git checkout -b "merge_master_into_develop_after_release_${MVN_VERSION_RELEASE}"
mvn versions:set -DnewVersion=${MVN_VERSION_DEVELOP}
mvn versions:commit
git commit -s -a -m "set correct version"
git push --set-upstream origin "merge_master_into_develop_after_release_${MVN_VERSION_RELEASE}"

git checkout master

mvn clean install -DskipTests

echo "";
echo "Go to github and create a new PR to merge merge_master_into_develop_after_release_${MVN_VERSION_RELEASE} into develop";
read -n 1 -s -r -p "Press any key to continue (ctrl+c to cancel)"; printf "\n\n";






