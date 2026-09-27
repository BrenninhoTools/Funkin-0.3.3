package funkin.mobile;

import flixel.FlxG;
import flixel.input.touch.FlxTouch;

/**
 * Recognizes simple touch gestures anywhere on screen - a vertical swipe, a one-finger tap, and a
 * two-finger tap - and turns each into a one-frame pulse that `Controls` reads to drive menu
 * navigation (see `Controls.bindMobile`). This is what replaced the on-screen d-pad: menus like
 * the main menu, story mode, freeplay and options are navigated by swiping and confirmed by
 * tapping, instead of drawing buttons to tap on.
 *
 * There is exactly one recognizer for the whole game, not one per bound action, since a gesture
 * only ever happens once and every listener (e.g. the PRESSED/JUST_PRESSED/JUST_RELEASED inputs
 * `forEachBound` adds for a single control) must see the same pulse rather than re-detecting it.
 */
class MenuGestures
{
  public static var instance(get, null):MenuGestures;

  static function get_instance():MenuGestures
  {
    return instance ?? (instance = new MenuGestures());
  }

  /**
   * Total finger movement, in pixels, below which a release counts as a tap rather than a swipe.
   */
  static final TAP_MAX_DISTANCE:Float = 32;

  /**
   * Total finger movement, in pixels, a swipe needs before it counts, so small jitters don't
   * register as navigation.
   */
  static final SWIPE_MIN_DISTANCE:Float = 60;

  /**
   * True for one frame when the finger swiped upward.
   */
  public var swipedUp(default, null):Bool = false;

  /**
   * True for one frame when the finger swiped downward.
   */
  public var swipedDown(default, null):Bool = false;

  /**
   * True for one frame when a single finger tapped (touched down and released again without
   * moving far), anywhere on screen.
   */
  public var tapped(default, null):Bool = false;

  /**
   * True for one frame when a second finger tapped down and up while the first one was down too.
   */
  public var twoFingerTapped(default, null):Bool = false;

  var startX:Float = 0;
  var startY:Float = 0;

  /**
   * Whether the current touch already fired a swipe, so it doesn't also fire a tap on release.
   */
  var resolved:Bool = false;

  var hadSecondFinger:Bool = false;

  function new()
  {
    // Runs before FlxG.touches updates justPressed/justReleased for the frame's states, matching
    // how the rest of the input layer (e.g. VirtualPad) hooks into the frame.
    FlxG.signals.preUpdate.add(update);
  }

  function update():Void
  {
    swipedUp = false;
    swipedDown = false;
    tapped = false;
    twoFingerTapped = false;

    var touch:Null<FlxTouch> = FlxG.touches.getFirst();
    if (touch == null)
    {
      resolved = false;
      hadSecondFinger = false;
      return;
    }

    if (touch.justPressed)
    {
      startX = touch.screenX;
      startY = touch.screenY;
      resolved = false;
    }

    if (FlxG.touches.list.length >= 2) hadSecondFinger = true;

    var dx:Float = touch.screenX - startX;
    var dy:Float = touch.screenY - startY;

    if (!resolved && Math.abs(dy) > Math.abs(dx))
    {
      if (dy <= -SWIPE_MIN_DISTANCE)
      {
        swipedUp = true;
        resolved = true;
      }
      else if (dy >= SWIPE_MIN_DISTANCE)
      {
        swipedDown = true;
        resolved = true;
      }
    }

    if (touch.justReleased)
    {
      if (!resolved && Math.abs(dx) <= TAP_MAX_DISTANCE && Math.abs(dy) <= TAP_MAX_DISTANCE)
      {
        if (hadSecondFinger) twoFingerTapped = true;
        else
          tapped = true;
      }

      resolved = false;
      hadSecondFinger = false;
    }
  }
}
