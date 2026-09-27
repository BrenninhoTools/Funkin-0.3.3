package funkin.util;

/**
 * Utility functions related to specific platforms.
 */
class PlatformUtil
{
  /**
   * Returns true if the current platform is MacOS.
   *
   * NOTE: Only use this for choosing modifier keys for shortcut hints.
   * @return Whether the current platform is MacOS, or HTML5 running on MacOS.
   */
  public static function isMacOS():Bool
  {
    #if mac
    return true;
    #elseif html5
    return js.Browser.window.navigator.platform.startsWith('Mac')
      || js.Browser.window.navigator.platform.startsWith('iPad')
      || js.Browser.window.navigator.platform.startsWith('iPhone');
    #else
    return false;
    #end
  }

  /**
   * Returns true if the game is running on a phone or tablet (Android or iOS).
   */
  public static inline function isMobile():Bool
  {
    #if FUNKIN_MOBILE
    return true;
    #else
    return false;
    #end
  }

  /**
   * Resolves a path for data the game WRITES at runtime (mods folder, logs, and so on).
   *
   * On mobile this points into the app's private storage, which needs no storage permission.
   * The working directory is read-only there, so relative paths would fail.
   * On every other platform the path is returned unchanged, relative to the executable.
   *
   * @param relativePath A path relative to the game's data directory.
   * @return The path to use with `sys.io.File` and `sys.FileSystem`.
   */
  public static function getDataPath(relativePath:String):String
  {
    #if FUNKIN_MOBILE
    return haxe.io.Path.join([lime.system.System.applicationStorageDirectory, relativePath]);
    #else
    return relativePath;
    #end
  }

  /**
   * Detects and returns the current host platform.
   * Always returns `HTML5` on web, regardless of the computer running that browser.
   * @return The host platform, or `null` if the platform could not be detected.
   */
  public static function detectHostPlatform():Null<HostPlatform>
  {
    #if html5
    return HTML5;
    #else
    switch (Sys.systemName())
    {
      case ~/window/i.match(_) => true:
        return WINDOWS;
      case ~/linux/i.match(_) => true:
        return LINUX;
      case ~/mac/i.match(_) => true:
        return MAC;
      default:
        return null;
    }
    #end
  }
}

/**
 * Represents a host platform.
 */
enum HostPlatform
{
  WINDOWS;
  LINUX;
  MAC;
  HTML5;
}
