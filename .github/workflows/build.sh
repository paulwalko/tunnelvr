#!/bin/bash

set -e

export GODOT_VERSION=3.4
export GODOT_RELEASE=stable

export ANDROID_HOME=$HOME/tmp-android-sdk
export ANDROID_INSTALLER=$HOME/tmp-android-sdk-installer/cmdline-tools
export EDITOR_DATA=$PWD/editor_data

#wget -O godot.zip https://downloads.tuxfamily.org/godotengine/$GODOT_VERSION/Godot_v$GODOT_VERSION-stable_linux_headless.64.zip
#unzip godot.zip
#mv Godot_v$GODOT_VERSION-stable_linux_headless.64 godot
#mkdir -p $EDITOR_DATA
#rm Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_linux_headless.64.zip

#wget https://downloads.tuxfamily.org/godotengine/${GODOT_VERSION}/Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_export_templates.tpz
#unzip Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_export_templates.tpz
#mkdir -p $EDITOR_DATA/templates/${GODOT_VERSION}.${GODOT_RELEASE}/
#mv templates/* $EDITOR_DATA/templates/${GODOT_VERSION}.${GODOT_RELEASE}/
#rm Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_export_templates.tpz

#wget -O godot_oculus.tar.gz https://github.com/GodotVR/godot-oculus-mobile-asset/archive/refs/tags/v3.0.1.tar.gz
#tar xf godot_oculus.tar.gz
#mv godot-oculus-mobile-asset-3.0.1/addons/ .
#rm -r godot-oculus-mobile-asset-3.0.1 godot_oculus.tar.gz

#mkdir -p $ANDROID_INSTALLER
#pushd $ANDROID_INSTALLER &>/dev/null
#curl -fsSLO "https://dl.google.com/android/repository/commandlinetools-linux-6858069_latest.zip"
#unzip -q commandlinetools-linux-*.zip
#rm commandlinetools-linux-*.zip
#mv cmdline-tools latest
#popd &>/dev/null

#mkdir -p $HOME/.android
#echo "count=0" > $HOME/.android/repositories.cfg
#yes | $ANDROID_INSTALLER/latest/bin/sdkmanager --licenses
#yes | $ANDROID_INSTALLER/latest/bin/sdkmanager --sdk_root=$ANDROID_HOME \
#  "platform-tools" "build-tools;30.0.3" "platforms;android-29" "cmdline-tools;latest" \
#  "cmake;3.10.2.4988404" "ndk;21.4.7075529"
keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android \
  -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999
mv debug.keystore $ANDROID_HOME/debug.keystore

#./godot -e -v -q
#echo "export/android/debug_keystore = \"$ANDROID_HOME/debug.keystore\"" >> ./editor_data/editor_settings-3.tres
#echo 'export/android/debug_keystore_user = "androiddebugkey"' >> ./editor_data/editor_settings-3.tres
#echo 'export/android/debug_keystore_pass = "android"' >> ./editor_data/editor_settings-3.tres
#echo "export/android/android_sdk_path = \"$ANDROID_HOME\"" >> ./editor_data/editor_settings-3.tres
#echo "projects/$(echo $PWD | sed 's/\//::/g') = \"$PWD\"" >> ./editor_data/editor_settings-3.tres

./godot --export "Quest"
