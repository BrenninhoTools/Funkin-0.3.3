# Compiling Friday Night Funkin'

0. Setup
    - Download Haxe from [Haxe.org](https://haxe.org)
1. Cloning the Repository: Make sure when you clone, you clone the submodules to get the assets repo:
    - `git clone --recurse-submodules https://github.com/FunkinCrew/funkin.git`
    - If you accidentally cloned without the `assets` submodule (aka didn't follow the step above), you can run `git submodule update --init --recursive` to get the assets in a foolproof way.
2. Install `hmm` (run `haxelib --global install hmm` and then `haxelib --global run hmm setup`)
3. Install all haxelibs of the current branch by running `hmm install`
4. Setup lime: `haxelib run lime setup`
5. Platform setup
   - For Windows, download the [Visual Studio Build Tools](https://aka.ms/vs/17/release/vs_BuildTools.exe)
        - When prompted, select "Individual Components" and make sure to download the following:
        - MSVC v143 VS 2022 C++ x64/x86 build tools
        - Windows 10/11 SDK
    - Mac: [`lime setup mac` Documentation](https://lime.openfl.org/docs/advanced-setup/macos/)
    - Linux: [`lime setup linux` Documentation](https://lime.openfl.org/docs/advanced-setup/linux/)
    - HTML5: Compiles without any extra setup
6. If you are targeting for native, you may need to run `lime rebuild PLATFORM` and `lime rebuild PLATFORM -debug`
7. `lime test PLATFORM` ! Add `-debug` to enable several debug features such as time travel (`PgUp`/`PgDn` in Play State).

## Mobile (Android and iOS)

The game is packaged as `FNF: 0.3.3` with the package name `com.funkin.fnf033`.

- Build it with `lime build android -arm64 -release` or `lime build ios -arm64 -release -nosign` (iOS needs macOS and Xcode).
- The `build.yml` GitHub workflow does both and uploads the APK and the unsigned IPA as artifacts.
- No storage permission is needed. The save file, mods folder (`mods`) and crash logs (`logs`) live in the app's private storage.
  The Android job fails if `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE` or similar ever ends up in the manifest, so don't add them to `Project.xml`.
- Touch controls are drawn by `funkin.mobile.MobileControls`. During a song the screen is split into four lanes plus a pause button,
  everywhere else there is a d-pad with accept and back buttons. The Android back button also works.
- Video cutscenes are skipped on mobile, since there is no video backend for it yet.
- To keep updates installable on Android, add your keystore as the repository secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
  `ANDROID_KEY_ALIAS` and optionally `ANDROID_KEY_PASSWORD`. Without them the APK is signed with a throwaway key.
