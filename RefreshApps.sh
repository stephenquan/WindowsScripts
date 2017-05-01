#!/bin/bash

ScriptsDir=$(cd $(dirname $0) ; pwd)

[ -f ~/.HockeyApp ] && . ~/.HockeyApp

HockInstall=$ScriptsDir/HockInstall.sh

$HockInstall -name AppStudioPlayer -appId $AppStudioPlayer_Alpha_x64
$HockInstall -name AppStudio -appId $AppStudio_Alpha_x64
$HockInstall -name Survey123forArcGIS -appId $Survey123_x86
$HockInstall -name AuGeo -appId $AuGeo_x86
$HockInstall -name Trek2There -appId $Trek2There_x86
# $HockInstall -name TilePackageKreator -appId $TilePackageKreator_x86

exit 0

