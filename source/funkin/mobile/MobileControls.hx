package funkin.mobile;

import flixel.FlxG;
import funkin.input.PreciseInputManager;
import funkin.mobile.VirtualPad.VirtualButton;
import funkin.play.PlayState;
import funkin.play.notes.NoteDirection;
import openfl.display.CapsStyle;
import openfl.display.Graphics;
import openfl.display.JointStyle;
import openfl.display.LineScaleMode;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.TouchEvent;
import openfl.geom.Rectangle;
import openfl.ui.Multitouch;
import openfl.ui.MultitouchInputMode;

/**
 * On-screen touch controls, drawn above the game.
 *
 * - While playing a song, the screen is split into four full-height lanes (LEFT, DOWN, UP, RIGHT)
 *   that feed `PreciseInputManager`, exactly like the note keys do, plus a pause button.
 * - Everywhere else, a d-pad and accept/back buttons feed `VirtualPad`, which `Controls` reads,
 *   so every menu works without needing its own touch code.
 *
 * It only draws with OpenFL vector graphics and needs no assets or storage access.
 */
class MobileControls extends Sprite
{
  static var instance:Null<MobileControls>;

  /**
   * Adds the touch controls on top of the given display object. Safe to call more than once.
   */
  public static function initialize(parent:Sprite):Void
  {
    if (instance != null) return;

    instance = new MobileControls();
    parent.addChild(instance);
  }

  static final ALPHA_IDLE:Float = 0.22;
  static final ALPHA_HELD:Float = 0.6;

  var mode:ControlsMode = HIDDEN;
  var zones:Array<Zone> = [];

  /**
   * The zone each finger (touch point) is currently holding.
   */
  final touches:Map<Int, Zone> = [];

  function new()
  {
    super();

    // Touches are read from the stage, so this layer never blocks anything underneath it.
    mouseEnabled = false;
    mouseChildren = false;
    visible = false;

    addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
  }

  function onAddedToStage(_:Event):Void
  {
    removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);

    Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;

    stage.addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
    stage.addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
    stage.addEventListener(TouchEvent.TOUCH_END, onTouchEnd);
    stage.addEventListener(Event.RESIZE, onResize);
    stage.addEventListener(Event.DEACTIVATE, onDeactivate);
    addEventListener(Event.ENTER_FRAME, onEnterFrame);
  }

  function onEnterFrame(_:Event):Void
  {
    var newMode:ControlsMode = computeMode();
    if (newMode != mode) setMode(newMode);
  }

  function onResize(_:Event):Void
  {
    layout();
    redraw();
  }

  function onDeactivate(_:Event):Void
  {
    // The app went to the background, so we will never get the touch end events.
    releaseAll();
    redraw();
  }

  /**
   * Decides which controls fit what is on screen right now.
   */
  function computeMode():ControlsMode
  {
    if (FlxG.state == null) return HIDDEN;

    var play:Null<PlayState> = PlayState.instance;
    if (play != null && play.subState == null && !play.isInCutscene)
    {
      return GAMEPLAY;
    }

    // Menus, the pause menu, the game over screen and cutscenes all use the menu pad.
    return MENU;
  }

  function setMode(newMode:ControlsMode):Void
  {
    releaseAll();

    mode = newMode;
    visible = mode != HIDDEN;

    layout();
    redraw();
  }

  /**
   * Lets go of everything that is held, so nothing stays stuck when the layout changes.
   */
  function releaseAll():Void
  {
    touches.clear();

    for (zone in zones)
    {
      if (zone.touchCount > 0)
      {
        zone.touchCount = 0;
        activate(zone, false);
      }
    }
  }

  function layout():Void
  {
    zones = [];
    if (stage == null) return;

    var w:Float = stage.stageWidth;
    var h:Float = stage.stageHeight;

    switch (mode)
    {
      case GAMEPLAY:
        layoutGameplay(w, h);
      case MENU:
        layoutMenu(w, h);
      case HIDDEN:
    }
  }

  function layoutGameplay(w:Float, h:Float):Void
  {
    var unit:Float = Math.min(w, h) * 0.14;

    // The pause button comes first so it wins over the lane underneath it.
    var pauseSize:Float = unit * 0.8;
    var pauseHit:Rectangle = new Rectangle(w - unit * 1.6, 0, unit * 1.6, unit * 1.6);
    var pauseArt:Rectangle = new Rectangle(w - pauseSize - unit * 0.4, unit * 0.4, pauseSize, pauseSize);
    zones.push(new Zone(-1, VirtualButton.PAUSE, Pause, 0xFFFFFF, pauseHit, pauseArt, false));

    // Four lanes that fill the whole screen, so a tap never misses.
    var laneWidth:Float = w / 4;
    var artSize:Float = Math.min(laneWidth * 0.8, h * 0.28);
    var directions:Array<NoteDirection> = [NoteDirection.LEFT, NoteDirection.DOWN, NoteDirection.UP, NoteDirection.RIGHT];
    var glyphs:Array<Glyph> = [Arrow(3), Arrow(2), Arrow(0), Arrow(1)];

    for (i in 0...4)
    {
      var hit:Rectangle = new Rectangle(i * laneWidth, 0, laneWidth, h);
      var art:Rectangle = new Rectangle(i * laneWidth + (laneWidth - artSize) / 2, h - artSize - unit * 0.3, artSize, artSize);
      var color:Int = directions[i].color;
      zones.push(new Zone(directions[i], -1, glyphs[i], color, hit, art, true));
    }
  }

  function layoutMenu(w:Float, h:Float):Void
  {
    var unit:Float = Math.min(w, h) * 0.14;
    var margin:Float = unit * 0.5;
    var reach:Float = unit * 0.12;

    // D-pad, bottom left.
    var padX:Float = margin + unit * 1.5;
    var padY:Float = h - margin - unit * 1.5;
    zones.push(menuZone(VirtualButton.UP, Arrow(0), padX, padY - unit * 1.05, unit, reach));
    zones.push(menuZone(VirtualButton.DOWN, Arrow(2), padX, padY + unit * 1.05, unit, reach));
    zones.push(menuZone(VirtualButton.LEFT, Arrow(3), padX - unit * 1.05, padY, unit, reach));
    zones.push(menuZone(VirtualButton.RIGHT, Arrow(1), padX + unit * 1.05, padY, unit, reach));

    // Back and accept, bottom right.
    zones.push(menuZone(VirtualButton.BACK, Cross, w - margin - unit * 2.65, h - margin - unit * 0.8, unit * 1.1, reach));
    zones.push(menuZone(VirtualButton.ACCEPT, Check, w - margin - unit * 0.75, h - margin - unit * 1.6, unit * 1.1, reach));
  }

  function menuZone(button:VirtualButton, glyph:Glyph, centerX:Float, centerY:Float, size:Float, reach:Float):Zone
  {
    var art:Rectangle = new Rectangle(centerX - size / 2, centerY - size / 2, size, size);
    // The touchable area is a little bigger than what is drawn, since thumbs are imprecise.
    var hit:Rectangle = new Rectangle(art.x - reach, art.y - reach, art.width + reach * 2, art.height + reach * 2);
    return new Zone(-1, button, glyph, 0xFFFFFF, hit, art, false);
  }

  function zoneAt(x:Float, y:Float):Null<Zone>
  {
    for (zone in zones)
    {
      if (zone.hit.contains(x, y)) return zone;
    }
    return null;
  }

  function onTouchBegin(event:TouchEvent):Void
  {
    var zone:Null<Zone> = zoneAt(event.stageX, event.stageY);
    if (zone == null) return;

    touches.set(event.touchPointID, zone);
    press(zone);
  }

  function onTouchMove(event:TouchEvent):Void
  {
    var current:Null<Zone> = touches.get(event.touchPointID);
    if (current == null || current.sticky) return;

    // Menu buttons follow the finger, so sliding across the d-pad works.
    var target:Null<Zone> = zoneAt(event.stageX, event.stageY);
    if (target == current) return;

    release(current);
    if (target != null)
    {
      touches.set(event.touchPointID, target);
      press(target);
    }
    else
    {
      touches.remove(event.touchPointID);
    }
  }

  function onTouchEnd(event:TouchEvent):Void
  {
    var zone:Null<Zone> = touches.get(event.touchPointID);
    if (zone == null) return;

    touches.remove(event.touchPointID);
    release(zone);
  }

  function press(zone:Zone):Void
  {
    zone.touchCount++;
    if (zone.touchCount == 1)
    {
      activate(zone, true);
      redraw();
    }
  }

  function release(zone:Zone):Void
  {
    if (zone.touchCount <= 0) return;

    zone.touchCount--;
    if (zone.touchCount == 0)
    {
      activate(zone, false);
      redraw();
    }
  }

  /**
   * Sends the press or release of a zone to whatever listens for it.
   */
  function activate(zone:Zone, held:Bool):Void
  {
    if (zone.lane >= 0)
    {
      if (held)
      {
        PreciseInputManager.instance.handleTouchPress(zone.lane);
      }
      else
      {
        PreciseInputManager.instance.handleTouchRelease(zone.lane);
      }
    }
    else
    {
      VirtualPad.instance.setHeld(zone.button, held);
    }
  }

  function redraw():Void
  {
    graphics.clear();

    for (zone in zones)
    {
      drawZone(graphics, zone);
    }
  }

  function drawZone(g:Graphics, zone:Zone):Void
  {
    var held:Bool = zone.touchCount > 0;
    var art:Rectangle = zone.art;
    var color:Int = zone.color & 0xFFFFFF;

    // In gameplay the whole lane lights up while it is held, which gives feedback across the screen.
    if (zone.sticky && held)
    {
      g.beginFill(color, 0.12);
      g.drawRect(zone.hit.x, zone.hit.y, zone.hit.width, zone.hit.height);
      g.endFill();
    }

    g.lineStyle(Math.max(2, art.width * 0.03), color, held ? 0.9 : 0.45, false, LineScaleMode.NORMAL, CapsStyle.ROUND, JointStyle.ROUND);
    g.beginFill(color, held ? ALPHA_HELD : ALPHA_IDLE);
    g.drawRoundRect(art.x, art.y, art.width, art.height, art.width * 0.28, art.height * 0.28);
    g.endFill();

    drawGlyph(g, zone.glyph, art.x + art.width / 2, art.y + art.height / 2, art.width * 0.5, held ? 1.0 : 0.75);
  }

  function drawGlyph(g:Graphics, glyph:Glyph, cx:Float, cy:Float, size:Float, alpha:Float):Void
  {
    switch (glyph)
    {
      case Arrow(quarterTurns):
        // An arrow pointing up, rotated by a number of quarter turns clockwise.
        var angle:Float = quarterTurns * Math.PI / 2;
        var cos:Float = Math.cos(angle);
        var sin:Float = Math.sin(angle);
        var outline:Array<Array<Float>> = [
          [0, -0.5], [0.5, 0.05], [0.2, 0.05], [0.2, 0.5], [-0.2, 0.5], [-0.2, 0.05], [-0.5, 0.05]
        ];

        g.lineStyle();
        g.beginFill(0xFFFFFF, alpha);
        for (i in 0...outline.length)
        {
          var px:Float = outline[i][0] * size;
          var py:Float = outline[i][1] * size;
          var x:Float = cx + px * cos - py * sin;
          var y:Float = cy + px * sin + py * cos;
          if (i == 0)
          {
            g.moveTo(x, y);
          }
          else
          {
            g.lineTo(x, y);
          }
        }
        g.endFill();
      case Check:
        g.lineStyle(size * 0.22, 0xFFFFFF, alpha, false, LineScaleMode.NORMAL, CapsStyle.ROUND, JointStyle.ROUND);
        g.moveTo(cx - size * 0.4, cy + size * 0.02);
        g.lineTo(cx - size * 0.1, cy + size * 0.32);
        g.lineTo(cx + size * 0.42, cy - size * 0.3);
      case Cross:
        g.lineStyle(size * 0.22, 0xFFFFFF, alpha, false, LineScaleMode.NORMAL, CapsStyle.ROUND, JointStyle.ROUND);
        g.moveTo(cx - size * 0.3, cy - size * 0.3);
        g.lineTo(cx + size * 0.3, cy + size * 0.3);
        g.moveTo(cx + size * 0.3, cy - size * 0.3);
        g.lineTo(cx - size * 0.3, cy + size * 0.3);
      case Pause:
        g.lineStyle();
        g.beginFill(0xFFFFFF, alpha);
        g.drawRect(cx - size * 0.32, cy - size * 0.38, size * 0.24, size * 0.76);
        g.drawRect(cx + size * 0.08, cy - size * 0.38, size * 0.24, size * 0.76);
        g.endFill();
    }

    g.lineStyle();
  }
}

private enum ControlsMode
{
  HIDDEN;
  GAMEPLAY;
  MENU;
}

private enum Glyph
{
  /**
   * An arrow pointing up, turned clockwise by this many quarter turns.
   */
  Arrow(quarterTurns:Int);
  Check;
  Cross;
  Pause;
}

/**
 * One touchable area, and how it is drawn.
 */
private class Zone
{
  /**
   * The note lane this zone plays, or -1 if it is a menu button.
   */
  public final lane:Int;

  /**
   * The menu button this zone presses. Only meaningful when `lane` is -1.
   */
  public final button:VirtualButton;

  public final glyph:Glyph;
  public final color:Int;

  /**
   * The area that reacts to touches.
   */
  public final hit:Rectangle;

  /**
   * The area that is drawn.
   */
  public final art:Rectangle;

  /**
   * Whether a finger stays with this zone until it is lifted, instead of following the finger to other zones.
   */
  public final sticky:Bool;

  /**
   * How many fingers are on this zone.
   */
  public var touchCount:Int = 0;

  public function new(lane:Int, button:VirtualButton, glyph:Glyph, color:Int, hit:Rectangle, art:Rectangle, sticky:Bool)
  {
    this.lane = lane;
    this.button = button;
    this.glyph = glyph;
    this.color = color;
    this.hit = hit;
    this.art = art;
    this.sticky = sticky;
  }
}
