#!/bin/sh

#  version.sh
#  Velocity Coaster Chaser
#
#  Created by Michael Kacos on 6/16/2026..
#  


#!/bin/bash
# This script is designed to increment the build number consistently across all
# targets.


# https://medium.com/@mateuszsiatrak/automating-build-number-increments-in-xcode-with-custom-format-a-practical-guide-bcc90a19f716

cd "$SRCROOT"

# Get the current date in the format "YYYYMMDD".
current_date=$(date "+%Y%m%d")
year="${current_date:2:2}"
month="${current_date:4:2}"
day="${current_date:6:2}"

new_version_number="$year.$month.$day"
#echo "$new_version_number"

#
# Use 'sed' command to replace the previous build number with the new build
# number in the 'Config.xcconfig' file.
sed -i -e "/VERSION =/ s/= .*/= $new_version_number/" Config.xcconfig

# Remove the backup file created by 'sed' command.
rm -f Config.xcconfig-e
