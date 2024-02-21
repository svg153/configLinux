# set PATH for Android Studio
ANDROID_STUDIO="/usr/local/android-studio/bin"
if [ -d "$ANDROID_STUDIO" ] ; then
  PATH="$PATH:$ANDROID_STUDIO"
fi

# set PATH for Android SDK
ANDROID_SDK="~/Android/Sdk/tools"
if [ -d $ANDROID_SDK ] ; then
  PATH="$PATH:$ANDROID_SDK"
fi