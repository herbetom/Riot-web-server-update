#!/bin/bash

# Authors: @MTRNord:matrix.ffslfl.net @grigruss:matrix.org

# Specify the path to the web server directory
WWW="/var/www/element/"

# Get the content to determine the latest version.
content=$(curl -s https://api.github.com/repos/vector-im/element-web/releases/latest)
package_id=$(jq -r '.id' <<<"$content")

# If it is started for the first time, it creates a file in which the latest version number will be saved.
[ -f ./element_version-id ] || touch element_version-id

# Ensure existens of the WWW directory
if [ ! -d $WWW ]
then
    echo "create the direcotry for element first"
    exit 1
fi

# If the versions are different, we begin the update
if [ "$package_id" != "$(cat ./element_version-id)" ]
then
    download_url=$(jq -r '.assets[] | select((.content_type == "application/x-gzip") or (.content_type == "application/octet-stream")) | .browser_download_url | select(contains("asc") | not)' <<<"$content")
    if [ "$download_url" != "" ]
    then
        # If there is no element directory, it will be created.
        if [ ! -d ./element ]
        then
            mkdir element
        fi

        echo "New Version found starting download"
        curl -Ls "$download_url" | tar xz --strip-components=1 -C ./element/
        echo "$package_id" > ./element_version-id
        echo "The new version is downloaded. Copying to the web server directory begins."

        # Uncomment for save your logos
        # rm -rf ./element/img/logos
        
        # Owner anpassen
        chown -R www-data: ./element
        
        # Copy the new version of Element to the web server directory
        cp -r ./element/* $WWW
        
        # Delete the new version from the Element buffer directory
        rm -rf ./element
        
        echo "Copying to the web server directory finished. Exiting..."
        exit 0
    else
        echo "New version doesn't conatin needed archive. Aborting..."
        exit 1
    fi
fi
