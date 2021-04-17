# Check version and tag name
tagname=$1
[ -z "${tagname}" ] && tagname=$(git tag --points-at HEAD)
[ -z "${tagname}" ] && tagname=$(echo "${GITHUB_REF}" | sed -e 's/refs\/tags\///g')

[ -z "${tagname}" ] && echo "Version is required" && exit 1

version_short_name=$(cat Clipy/Supporting\ Files/Info.plist  | grep '<key>CFBundleShortVersionString</key>' -A 1 | tail -n 1 | sed -r 's/\n*\t*\w*<\/?string>//g')
version_name=$(cat Clipy/Supporting\ Files/Info.plist  | grep '<key>CFBundleVersion</key>' -A 1 | tail -n 1 | sed -r 's/\n*\t*\w*<\/?string>//g')

[ -z "${tagname}" ] && echo "Version is required" && exit 1

sed -e "s/${version_short_name}/${tagname}/g" -e "s/${version_name}/${tagname}/g" Clipy/Supporting\ Files/Info.plist > Clipy/Supporting\ Files/Info.plist.tmp
mv -f Clipy/Supporting\ Files/Info.plist.tmp Clipy/Supporting\ Files/Info.plist
echo "Version changed. ${version_name} -> ${tagname}"