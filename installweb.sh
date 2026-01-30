#!/bin/bash
set -e

WEB_URL="$1"
APP_NAME="$2"
ICON_URL="$3"

PKG="com.web2apk.app"
APP_ID="Web2APK"
WORKDIR="/root/web2apk/build_$(date +%s)"

echo "📦 Setup environment..."
apt update -y
apt install -y curl unzip openjdk-17-jdk wget

# Android SDK
export ANDROID_HOME=/root/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

if [ ! -d "$ANDROID_HOME" ]; then
  mkdir -p $ANDROID_HOME
  cd /root
  wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
  unzip commandlinetools-linux-*.zip
  mkdir -p $ANDROID_HOME/cmdline-tools/latest
  mv cmdline-tools/* $ANDROID_HOME/cmdline-tools/latest/
  yes | sdkmanager --licenses
  sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.2"
fi

mkdir -p "$WORKDIR/app/src/main/java/com/web2apk"
mkdir -p "$WORKDIR/app/src/main/res/values"
mkdir -p "$WORKDIR/app/src/main/res/mipmap"

cd "$WORKDIR"

echo "🧩 Generate project..."

# settings.gradle
cat <<EOF > settings.gradle
rootProject.name="$APP_ID"
include(":app")
EOF

# root build.gradle
cat <<EOF > build.gradle
buildscript {
    repositories { google(); mavenCentral() }
    dependencies { classpath("com.android.tools.build:gradle:8.1.0") }
}
allprojects { repositories { google(); mavenCentral() } }
EOF

# app build.gradle
cat <<EOF > app/build.gradle
plugins { id 'com.android.application' }

android {
    namespace "$PKG"
    compileSdk 33

    defaultConfig {
        applicationId "$PKG"
        minSdk 21
        targetSdk 33
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        release {
            minifyEnabled false
        }
    }
}

dependencies {}
EOF

# AndroidManifest
cat <<EOF > app/src/main/AndroidManifest.xml
<manifest package="$PKG">
 <application android:label="@string/app_name">
  <activity android:name=".MainActivity">
   <intent-filter>
    <action android:name="android.intent.action.MAIN"/>
    <category android:name="android.intent.category.LAUNCHER"/>
   </intent-filter>
  </activity>
 </application>
</manifest>
EOF

# strings.xml
cat <<EOF > app/src/main/res/values/strings.xml
<resources>
 <string name="app_name">$APP_NAME</string>
</resources>
EOF

# MainActivity
cat <<EOF > app/src/main/java/com/web2apk/MainActivity.java
package com.web2apk.app;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class MainActivity extends Activity {
 @Override
 protected void onCreate(Bundle b) {
  super.onCreate(b);
  WebView w = new WebView(this);
  w.getSettings().setJavaScriptEnabled(true);
  w.setWebViewClient(new WebViewClient());
  w.loadUrl("$WEB_URL");
  setContentView(w);
 }
}
EOF

# Icon
if [ "$ICON_URL" = "no" ]; then
  curl -s https://www.google.com/s2/favicons?domain=$WEB_URL -o app/src/main/res/mipmap/ic_launcher.png
else
  curl -s "$ICON_URL" -o app/src/main/res/mipmap/ic_launcher.png
fi

echo "🚀 Build APK..."

chmod +x gradlew || true
gradle wrapper
./gradlew assembleRelease

APK=$(find app/build/outputs/apk -name "*.apk" | head -n 1)
echo "APK_PATH=$APK"
