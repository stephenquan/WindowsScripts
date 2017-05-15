#!/bin/bash

currentDir="$(pwd)"
scriptsDir="$(cd $(dirname $0); pwd)"
datestamp=$(date +%Y%m%d)

function showUsage {
  cat <<+
HockInstall.sh -name  Name of app
               -appId HockeyApp App Id
+
}

while [ "$1" != "" ]; do
  case "$1" in
  -name)
    shift
    appName="$1"
    ;;
  -appId)
    shift
    appId="$1"
    ;;
  -h)
    showUsage
    exit 0
    ;;
  *)
    echo "Skipping $1"
    ;;
  esac
  shift
done

if [ "$HOCKEY_APP_TOKEN" == "" ]; then
  echo No HOCKEY_APP_TOKEN
  exit 1
fi

if [ "$appName" == "" ]; then
  echo appName not set
  showUsage
  exit 1
fi

if [ "$appId" == "" ]; then
  echo appId not set
  showUsage
  exit 1
fi

appDir=~/Applications/ArcGIS/$appName

tmpDir=/tmp/hock
tmpFile=$tmpDir/$appName-$datestamp.tmp

newDir=$tmpDir/$appName/new
newSetup=$newDir/$appName-Setup.exe
newJson=$newDir/$appName.json

goodDir=$tmpDir/$appName/good
goodSetup=$goodDir/$appName-Setup.exe
goodJson=$goodDir/$appName.json

hockRestApi=https://rink.hockeyapp.net/api/2

echo "Checking $appName"

function jsonPrint {
  python -m json.tool
}

function jsonGet {
  python -c 'import json,sys
o=json.load(sys.stdin)
for a in "'$1'".split("."):
  if isinstance(o, dict):
    o=o[a] if a in o else ""
  elif isinstance(o, list):
    if a == "length":
      o=str(len(o))
    elif a == "join":
      o=",".join(o)
    else:
      o=o[int(a)]
  else:
    o=""
if isinstance(o, str) or isinstance(o, unicode):
  print o
else:
  print json.dumps(o)
'
}

function jsonGetValues {
  for i in $*
  do
    n="${i//./_}"
    v="$(jsonGet $i < $tmpFile)"
    echo "$n=$v"
    eval "$n=\"$v\""
  done
}

function mkFileDir {
  fileDir=$(dirname "$1")

  if [ "$fileDir" == "" ]; then
    return
  fi

  if [ -d "$fileDir" ]; then
    return
  fi

  echo mkdir -p "$fileDir"
  mkdir -p "$fileDir"
}

function hockApi {
  args=(-H "X-HockeyAppToken: $HOCKEY_APP_TOKEN")
  for i in $*
  do
    args+=("$i")
  done

  mkFileDir "$tmpFile"

  echo curl "${args[@]}"
  curl "${args[@]}" > $tmpFile
}

function hockAppVersions {
  hockApi -s $hockRestApi/apps/$appId/app_versions?include_build_urls=true
}

function checkApp {
  if [ -f "$appDir/$appName.exe" ]; then
    echo 1
    return
  fi

  if [ -f "$appDir/bin/$appName.exe" ]; then
    echo 1
    return
  fi

  return 0
}

function uninstallApp {
  if ! [ -d "$appDir" ]; then
    return
  fi

  tool=""
  for f in "$(find "$appDir" -type f -name 'Un*.exe' -print)"
  do
    tool="$f"
  done

  if [ "$tool" == "" ]; then
    echo rm -rf "$appDir"
    rm -rf "$appDir"
    return
  fi

  case "$(uname -s)" in
  MINGW*)
    echo "$tool" --script $scriptsDir/silent-uninstall-controller.qs
    "$tool" --script $scriptsDir/silent-uninstall-controller.qs
    ;;
  esac

  sleep 5
}

function cleanUpNewDir {
  if [ -d "$newDir" ]; then
    echo rm -rf "$newDir"
    rm -rf "$newDir"
  fi
}

function downloadJson {
  hockAppVersions

  mkFileDir "$1"

  jsonGet app_versions.0 < "$tmpFile" | jsonPrint > "$1"

  rm "$tmpFile"
}

function downloadSetup {
  jsonFile="$2"
  echo jsonGet timestamp "$jsonFile"
  build_url=$(jsonGet build_url < "$jsonFile")
  if [ "$build_url" == "" ]; then
    jsonPrint < "$jsonFile"
    echo "No valid setup detected"
    exit 1
  fi

  mkFileDir "$1"

  echo curl -L "$build_url" -o "$1.zip"
  curl -L "$build_url" -o "$1.zip"
  cd "$(dirname $1)"
  echo unzip "$1.zip"
  unzip "$1.zip"
  for f in *.exe; do
    echo mv "$f" "$1"
    mv "$f" "$1"
  done
  echo rm "$1.zip"
  rm "$1.zip"
  cd "$currentDir"
}

function installApp {
  case "$(uname -s)" in
  MINGW*)
    echo "$1" --script $scriptsDir/silent-install-controller.qs
    timeout -sHUP 5m "$1" --script $scriptsDir/silent-install-controller.qs
    ;;
  esac
}

function checkTimestamps {
  if ! [ -f "$newJson" ]; then
    echo 0
    return
  fi

  if ! [ -f "$goodJson" ]; then
    echo 1
    return
  fi

  newTimestamp=$(jsonGet timestamp < $newJson)
  goodTimestamp=$(jsonGet timestamp < $goodJson)

  if [ "$newTimestamp" == "$goodTimestamp" ]; then
    echo 0
    return
  fi

  echo 1
}

function saveSetup {
  if [ -d "$goodDir" ]; then
    echo rm -rf "$goodDir"
    rm -rf "$goodDir"
  fi

  mkFileDir "$goodJson"
  echo cp "$newJson" "$goodJson"
  cp "$newJson" "$goodJson"
  echo mv "$newSetup" "$goodSetup"
  mv "$newSetup" "$goodSetup"
}

function isQtCreatorRunning {
  c=$(ps -W | grep qtcreator.exe | wc -l)
  if [ "$c" -gt 0 ]; then
    echo 1
    return
  fi
  echo 0
}

function isAppRunning {
  c=$(ps -W | grep ${appName}.exe | wc -l)
  if [ "$c" -gt 0 ]; then
    echo 1
    return
  fi
  echo 0
}

function updateApp {
  # cleanUpNewDir

  if [ -f "$newJson" ]; then
    downloadJson "$newJson.tmp"
    newTimestamp=$(jsonGet timestamp < $newJson)
    tmpTimestamp=$(jsonGet timestamp < $newJson.tmp)
    if [ "$tmpTimestamp" == "$newTimestamp" ]; then
      rm "$newJson.tmp"
    else
      rm "$newJson"
      if [ -f "$newSetup" ]; then
        echo rm "$newSetup"
        rm "$newSetup"
      fi
      mv "$newJson.tmp" "$newJson"
    fi
  fi

  if ! [ -f "$newJson" ]; then
    downloadJson "$newJson"
  fi

  if [ -f "$goodJson" ]; then
    newTimestamp=$(jsonGet timestamp < $newJson)
    goodTimestamp=$(jsonGet timestamp < $goodJson)
    if [ "$newTimestamp" == "$goodTimestamp" ]; then
      return
    fi
  fi

  if ! [ -f "$newSetup" ]; then
    downloadSetup "$newSetup" "$newJson"
  fi

  if [ "$(isQtCreatorRunning)" != 0 ]; then
    echo "Skipping install since QtCreator is running"
    return
  fi

  if [ "$(isAppRunning)" != 0 ]; then
    echo "Skipping install since $appName is running"
    return
  fi

  uninstallApp
  installApp "$newSetup"

  if [ "$(checkApp)" == "1" ]; then
    echo SAVE SETUP
    saveSetup
  fi

  if [ "$(checkApp)" == "1" ]; then
    return
  fi

  if [ -f "$goodSetup" ]; then
    installApp "$goodSetup"
  fi
}

updateApp

