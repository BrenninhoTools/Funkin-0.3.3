package funkin.mobile;

import flixel.FlxG;
import flixel.input.FlxInput;
import flixel.input.FlxInput.FlxInputState;

/**
 * The buttons of the on-screen touch pad. Menus are navigated by swiping and tapping instead (see
 * `MenuGestures`), so pause - shown only during gameplay - is the only on-screen button left.
 */
enum abstract VirtualButton(Int) from Int to Int
{
  var PAUSE = 0;

  public static inline final COUNT:Int = 1;
}

/**
 * Holds the state of the on-screen pause button, using the same state machine as a keyboard key.
 * `funkin.input.Controls` reads this through `FlxActionInputDigitalVirtual`, so it reacts to a tap
 * exactly like a keyboard or gamepad press would.
 */
class VirtualPad
{
  public static var instance(get, null):VirtualPad;

  static function get_instance():VirtualPad
  {
    // Created on first use, since it needs `FlxG` to be initialized.
    return instance ?? (instance = new VirtualPad());
  }

  final inputs:Array<FlxInput<Int>>;

  function new()
  {
    inputs = [for (i in 0...VirtualButton.COUNT) new FlxInput<Int>(i)];

    // Advance the states once per game step, before anything reads them.
    FlxG.signals.preUpdate.add(update);
  }

  /**
   * Sets whether a button is being held down.
   */
  public function setHeld(button:VirtualButton, held:Bool):Void
  {
    var input:FlxInput<Int> = inputs[button];
    if (held)
    {
      input.press();
    }
    else
    {
      input.release();
    }
  }

  /**
   * Checks a button against a trigger state (`JUST_PRESSED`, `PRESSED`, `JUST_RELEASED`, `RELEASED`).
   */
  public function check(button:VirtualButton, state:FlxInputState):Bool
  {
    return inputs[button].hasState(state);
  }

  /**
   * Lets go of every button.
   */
  public function releaseAll():Void
  {
    for (input in inputs)
    {
      input.release();
    }
  }

  function update():Void
  {
    for (input in inputs)
    {
      input.update();
    }
  }
}
