package funkin.mobile;

import flixel.FlxG;
import flixel.input.FlxInput;
import flixel.input.FlxInput.FlxInputState;

/**
 * The buttons of the on-screen menu pad.
 */
enum abstract VirtualButton(Int) from Int to Int
{
  var UP = 0;
  var DOWN = 1;
  var LEFT = 2;
  var RIGHT = 3;
  var ACCEPT = 4;
  var BACK = 5;
  var PAUSE = 6;

  public static inline final COUNT:Int = 7;
}

/**
 * Holds the state of the on-screen menu buttons, using the same state machine as a keyboard key.
 * `funkin.input.Controls` reads this through `FlxActionInputDigitalVirtual`, so every menu that
 * reacts to keyboard or gamepad also reacts to the touch pad without any changes.
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
