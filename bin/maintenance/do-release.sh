#!/bin/bash

_get_version () {

	local year=`date +%Y`;
	local month=`date +%m`;
	local version="";

	if [ $month -gt "09" ]; then
		version="$year-Q4";
	elif [ $month -gt "06" ]; then
		version="$year-Q3";
	elif [ $month -gt "03" ]; then
		version="$year-Q2";
	else
		version="$year-Q1";
	fi;

	echo $version;

}


OLD_FOLDER=$(cd "$(dirname "$0")/../../"; pwd);
NEW_FOLDER="/tmp/lycheejs";
LYCHEEJS_FERTILIZER="$NEW_FOLDER/libraries/fertilizer/bin/fertilizer.sh";
OLD_VERSION=$(cd $OLD_FOLDER && cat ./libraries/lychee/source/core/lychee.js | grep VERSION | cut -d\" -f2);
NEW_VERSION=$(_get_version);

GITHUB_TOKEN=$(cat /opt/lycheejs/.github/TOKEN);
NPM_BIN=`which npm`;


if [ "$GITHUB_TOKEN" == "" ]; then

	echo -e "\e[41m\e[97m";
	echo " (E) No GitHub Token found.                                      ";
	echo "     Use \"echo YOUR-GITHUB-TOKEN > /opt/lycheejs/.github/TOKEN\". ";
	echo -e "\e[0m";

	exit 1;

fi;


if [ "$NPM_BIN" == "" ]; then

	echo -e "\e[41m\e[97m";
	echo " (E) No NPM found.                                ";
	echo "     Please install NPM with the package manager. ";
	echo -e "\e[0m";

	exit 1;

fi;


if [ "$OLD_VERSION" != "$NEW_VERSION" ]; then

	echo " (L) ";
	echo -e "\e[42m\e[97m (I) lychee.js Release Tool \e[0m";
	echo " (L) ";
	echo " (L) All your data are belong to us.                     ";
	echo " (L) This tool creates a new lychee.js release.          ";
	echo " (L) ";
	echo " (L) You need to be member of the Artificial-Engineering ";
	echo " (L) organization and you will be questioned again when  ";
	echo " (L) the release is ready to publish it.                 ";
	echo " (L) ";
	echo " (L) Old lychee.js Folder:  $OLD_FOLDER";
	echo " (L) Old lychee.js Version: $OLD_VERSION";
	echo " (L) ";
	echo " (L) New lychee.js Folder:  $NEW_FOLDER";
	echo " (L) New lychee.js Version: $NEW_VERSION";
	echo " (L) ";
	echo " (L) ";

	read -p " (L) Continue (y/n)? " -r

	if [[ $REPLY =~ ^[Nn]$ ]]; then
		echo -e "\e[41m\e[97m (E) ABORTED \e[0m";
		exit 0;
	elif ! [[ $REPLY =~ ^[Yy]$ ]]; then
		echo -e "\e[41m\e[97m (E) INVALID SELECTION \e[0m";
		exit 1;
	fi;



	#
	# INIT lycheejs
	#

	if [ -d $NEW_FOLDER ]; then
		rm -rf $NEW_FOLDER;
	fi;

	mkdir $NEW_FOLDER;
	git clone git@github.com:Artificial-Engineering/lycheejs.git $NEW_FOLDER;


	DOWNLOAD_URL=$(curl -s https://api.github.com/repos/Artificial-Engineering/lycheejs-runtime/releases/latest | grep browser_download_url | grep lycheejs-runtime | head -n 1 | cut -d'"' -f4);

	if [ "$DOWNLOAD_URL" != "" ]; then

		cd $NEW_FOLDER/bin;
		curl -sSL $DOWNLOAD_URL > $NEW_FOLDER/bin/runtime.zip;

		mkdir $NEW_FOLDER/bin/runtime;
		git clone --single-branch --branch master --depth 1 git@github.com:Artificial-Engineering/lycheejs-runtime.git $NEW_FOLDER/bin/runtime;

		cd $NEW_FOLDER/bin/runtime;
		unzip -nq ../runtime.zip;

		chmod +x $NEW_FOLDER/bin/runtime/bin/*.sh;
		chmod +x $NEW_FOLDER/bin/runtime/*/update.sh;
		chmod +x $NEW_FOLDER/bin/runtime/*/package.sh;

		rm $NEW_FOLDER/bin/runtime.zip;

	fi;


	cd $NEW_FOLDER;
	git checkout development;

	sed -i 's|2[0-9][0-9][0-9]-Q[1-4]|'$NEW_VERSION'|g' ./README.md;
	sed -i 's|2[0-9][0-9][0-9]-Q[1-4]|'$NEW_VERSION'|g' ./libraries/lychee/source/core/lychee.js;

	git add ./README.md;
	git add ./libraries/lychee/source/core/lychee.js;
	git commit -m "lychee.js $NEW_VERSION release";


	cd $NEW_FOLDER;
	$NEW_FOLDER/bin/configure.sh --sandbox;



	#
	# BUILD AND UPDATE lycheejs-runtime
	#

	cd $NEW_FOLDER/bin/runtime;
	./bin/do-update.sh;

	# XXX: lycheejs-bundle requires new runtimes
	# cd $NEW_FOLDER/bin/runtime;
	# ./bin/do-release.sh;



	#
	# BUILD AND PACKAGE lycheejs-harvester
	#

	cd $NEW_FOLDER;
	export LYCHEEJS_ROOT="$NEW_FOLDER";
	git clone --single-branch --branch master git@github.com:Artificial-Engineering/lycheejs-harvester.git $NEW_FOLDER/projects/lycheejs-harvester;
	$LYCHEEJS_FERTILIZER node/main /projects/lycheejs-harvester;



	#
	# BUILD AND PACKAGE lycheejs-library
	#

	cd $NEW_FOLDER;
	export LYCHEEJS_ROOT="$NEW_FOLDER";
	git clone --single-branch --branch master git@github.com:Artificial-Engineering/lycheejs-library.git $NEW_FOLDER/projects/lycheejs-library;
	$LYCHEEJS_FERTILIZER auto /projects/lycheejs-library;



	#
	# BUILD AND PACKAGE lycheejs-bundle
	#

	cd $NEW_FOLDER;
	export LYCHEEJS_ROOT="$NEW_FOLDER";
	git clone --single-branch --branch master git@github.com:Artificial-Engineering/lycheejs-bundle.git $NEW_FOLDER/projects/lycheejs-bundle;
	$LYCHEEJS_FERTILIZER auto /projects/lycheejs-bundle;



	echo " (L) ";
	echo " (L) Somebody set us up the bomb.                    ";
	echo " (L) ";
	echo " (L) If no error occured, you can publish the new    ";
	echo " (L) lychee.js release to GitHub and the peer cloud. ";
	echo " (L) ";
	echo -e "\e[43m\e[97m";
	echo " (W) WARNING: The publish process is irreversible.   ";
	echo "     It is wise to manually check /tmp/lycheejs now. ";
	echo -e "\e[0m";
	echo " (L) ";
	echo " (L) ";

	read -p " (L) Continue (y/n)? " -r

	if [[ $REPLY =~ ^[Nn]$ ]]; then
		echo -e "\e[41m\e[97m (E) ABORTED \e[0m";
		exit 0;
	elif ! [[ $REPLY =~ ^[Yy]$ ]]; then
		echo -e "\e[41m\e[97m (E) INVALID SELECTION \e[0m";
		exit 1;
	fi;



	#
	# PUBLISH lycheejs
	#

	cd $NEW_FOLDER;
	git push origin development;
	git checkout master;
	git merge --squash --no-commit development;
	git commit -m "lychee.js $NEW_VERSION release";
	git push origin master;



	#
	# PUBLISH lycheejs-runtime
	#

	cd $NEW_FOLDER/bin/runtime;
	./bin/do-release.sh;



	#
	# PUBLISH lycheejs-harvester
	#

	cd $NEW_FOLDER/projects/lycheejs-harvester;
	./bin/publish.sh;



	#
	# PUBLISH lycheejs-library
	#

	cd $NEW_FOLDER/projects/lycheejs-library;
	./bin/publish.sh;



	echo " (L) ";
	echo -e "\e[42m\e[97m (I) SUCCESS \e[0m";
	echo " (L) ";
	echo " (L) Remaining manual steps:                                       ";
	echo " (L) ";
	echo " (L) - Create $NEW_VERSION release of lycheejs-bundle repository.  ";
	echo " (L) - Create $NEW_VERSION release of lycheejs-website repository. ";
	echo " (L) ";

	exit 0;

else

	echo " (L) ";
	echo -e "\e[42m\e[97m (I) lychee.js Release Tool \e[0m";
	echo " (L) ";
	echo -e "\e[42m\e[97m (I) lychee.js $NEW_VERSION release already done. \e[0m";
	echo " (L) ";
	exit 0;

fi;
