/**
 * @author Tyler Spaulding
 * @author Glenn Ko	(ported over to Haxe for Flash/Fp10 AS3)
 * 
 * Test-bed for any new features...
 * 
 *  Compiler directives include:
 * 
-D occlude				To test occlusion culling/clipping
-D occludeEarlyOut		Whether to skip further raycast jumps if a wall covers the entire height of a screen
-D clippedBottoms		Whether to clip the bottom edges of walls during occlusion. (instead of drawing it's entire height)
-D noMaxHeight			If enabled, uses a map with no building height limits. 
-D testPosition			To start at a recorded starting position/angle based on code ( see Start() );
-D debugView			To turn on debug view at the beginning ( see Start() ) which allows one to view surfaces transparently.

 * See SetupToggles() for a list of available key toggles at the moment.
 */

package ;
import flash.display.GraphicsPath;
import flash.display.GraphicsPathCommand;
import flash.display.GraphicsSolidFill;
import flash.display.GraphicsStroke;
import flash.display.IGraphicsData;
import flash.display.Sprite;
import flash.errors.Error;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.Lib;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFieldType;
import flash.ui.Keyboard;
import flash.ui.KeyLocation;
import flash.utils.Dictionary;
import flash.utils.Timer;
import flash.Vector;
import flash.utils.TypedDictionary;

class RaycastTest extends Sprite
{

	static inline var CHARSIZE = .3;
	static inline var VIEWHEIGHT = 1.5;
	static inline var MAX_HEIGHT = #if noMaxHeight 999  #else  4 #end;
	static inline var MAXSTEP = .41;

	// in meters per second:
	static inline var WALKSPEED = 5.4;
	static inline var RUNSPEED = 3.4;
	static inline var TURNSPEED = 3.8;

	static inline var VIEWBOB = 0.1;
	static inline var VIEWBOBSPEED = 10;

	static inline var  KEY_A = 65;
	static inline var  KEY_B = 66;
	static inline var  KEY_D = 68;
	static inline var  KEY_H = 72;
	static inline var  KEY_I = 73;
	static inline var KEY_R = 82;
	static inline var KEY_S = 83;
	static inline var KEY_P = 80;
	static inline var KEY_T = 84;
	static inline var KEY_V = 86;
	static inline var KEY_W = 87;
	static inline var KEY_ARROW_UP = 38;
	static inline var KEY_ARROW_DOWN = 40;
	static inline var KEY_ARROW_LEFT = 37;
	static inline var KEY_ARROW_RIGHT = 39;
	static inline var KEY_WII_UP = 175;
	static inline var KEY_WII_DOWN = 176;
	static inline var KEY_WII_LEFT = 178;
	static inline var KEY_WII_RIGHT = 177;
	static inline var KEY_WII_B = 171;
	
	var player:Player;

	static var viewBob:Float = VIEWHEIGHT;
	static var bobTime:Float = 0;

	var pdx:Float;
	var pdy:Float;

	var dx1:Float;
	var dy1:Float;
	var dx2:Float;
	var dy2:Float;
	var ddx:Float;
	var ddy:Float;
	var playerXInt:Int;
	var playerYInt:Int;


	var raycount:Int;
	var outlineCount:Int;
	var wallcount:Int;
	var divCount:Int;
	
	var mapHeight:Array<Array<Float>>;
	var mapWallColor:Array<Array<UInt>>;
	var mapFloorColor:Array<Array<UInt>>;
	var mapDepth:Int;
	var mapWidth:Int;
	var mapWallIdxCount:Int;

	var wallColors:Array<Array<UInt>>;
	var floorColors:Array<UInt>;

	static var lastmousex:Float = -1;
	static var verbose:Bool = false;
	static var debugMode:Bool = false; 
	static var renderingEnabled:Bool = true;
	static var showStats:Bool = false;
	static var showHelp:Bool = true;
	static var showSplits:Bool = false;
	
	static var isPaused:Bool = false;
	
	// Caching
	static var keys:Dictionary  = new Dictionary();
	static var toggles:TypedDictionary<UInt,Dynamic>  = new TypedDictionary();
	static var keysCache:Dictionary  = new Dictionary();
	var wallCache:TypedDictionary<Int,Wall>;
	var wallArray:Array<Wall>;
	var splitList:Array<Split>;
	
	// Rendering
	public var graphicData:Vector<IGraphicsData>;
	
	// framerate and timer stuff
	static var frames:Int = 0;
	static var fps:Float = 0;
	static var lastFrameSeconds:Float = 0;
	static var curTime:Int;
	static var prevTime:Int;
	static var frameCountStart:Float = 0;
	

	public function new() 
	{
		super();		

		
		Init();
	}
	
	function BuildColors()
	{
		wallColors = [
		[0xff00ff, 0xff00ff, 0xff00ff, 0xff00ff],
		[0x7f7f7f, 0x9f9f9f, 0xbfbfbf, 0x5f5f5f],
		[0x777777, 0x979797, 0xb7b7b7, 0x575757],
		[0x8f6f4f, 0x6f5f3f, 0x8f6f4f, 0x6f5f3f],
		[0x5f3f1f, 0x4f3f1f, 0x5f3f1f, 0x4f3f1f],
		[0x573717, 0x473717, 0x573717, 0x473717],
		[0xdf1f1f, 0xdf1f1f, 0xdf1f1f, 0xdf1f1f]];
	
		floorColors = [0x00ff00, 0x00ef00, 0x00df00, 0x00af00, 0xff00ff,   0xff0000];
	}

///*
function BuildMap()
{
	#if noMaxHeight
		mapHeight = [
		[4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,4.0,1.2,1.2,1.2,1.2,1.4,1.4,1.4,1.6,1.6,1.6,1.8,1.8,1.8,2.0,2.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,4.0,1.2,1.2,1.2,1.2,1.4,1.4,1.4,1.6,1.6,1.6,1.8,1.8,1.8,2.0,2.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,4.0,1.0,1.0,  0,  0,1.4,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,  0,  0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,4.0,1.0,1.0,  0,4.0,1.5,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,4.0,1.0,1.0,  0,  0,1.6,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,4.0,0.8,0.8,  0,  0,1.8,2.0,2.2,2.4,2.6,2.8,  0,  0,  0,  0,4.0,  0,  0,4.0,4.0,4.0,  0,  0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,  0,  0,4.0 ],
		[4.0,4.0,4.0,  0,  0,4.0,4.0,4.0,0.8,0.8,  0,  0,  0,  3.8,3.6,3.4,3.2, 3.0,  0,  0,  0,  0,4.0,  0,  0,4.0,4.0,4.0,  0,  0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,4.0,0.8,0.8,  0,  0,  0,  4,  4,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,4.0,0.6,0.6,  0,  0,  0, 4.2,  4.4,  4.6,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,4.0,0.6,0.6,  0,4.0,  0,  0,  0,  0,  0,  12,  12,  12,  0,  0,4.0,  0,  0,4.0,  0,  0,4.0,4.0,  0,  0,4.0,4.0,  0,  0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,4.0,0.6,0.6,  0,  0,  0,  0,  0,  0,  0,  7,  7,  12,  0,  0,4.0,  0,  0,4.0,  0,  0,4.0,4.0,  0,  0,4.0,4.0,  0,  0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,4.0,0.4,0.4,0.4,0.4,0.2,0.2,0.2,  0,  0,  7,  7,  0,  0,  0,4.0,  0,  0,4.0,  0,  0,  0,  0,4.0,4.0,  0,  0,  0,  0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,4.0,0.4,0.4,0.4,0.4,0.2,0.2,0.2,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,  0,  0,  0,  0,4.0,4.0,  0,  0,  0,  0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,  0,  0,4.0,  0,  0,4.0,4.0,4.0,  0,  0,4.0,4.0,  0,  0,4.0,4.0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,4.0,4.0,  0,  0,4.0,4.0,  0,  0,4.0,4.0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,  0,  0,4.0,4.0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,  0,  0,4.0,0.3,0.3,4.0,  0,  0,4.0,4.0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,4.0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,0.6,0.6,4.0,  0,  0,  0,  0,4.0,4.0,  0,  0,4.0,4.0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,4.0,  0,  0,  0,  0,  0,  0,  0,1.2,  0,  0,  16,  16,  16,  0,  0,4.0,  0,  0,4.0,0.9,0.9,4.0,  0,  0,  0,  0,4.0,4.0,  0,  0,4.0,4.0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,4.0,  0,  0,  0,  0,  0,  0,  0,1.2,  0,  0,  16,  16,  16,  0,  0,4.0,  0,  0,4.0,1.2,1.2,4.0,  0,  0,4.0,4.0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1.2,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,1.5,1.5,4.0,  0,  0,4.0,4.0,  0,  0,  0,  0,  0,  0,4.0,1.0,1.0,4.0 ],
		[4.0,  0,  0,4.0,  0,  0,  0,  0,  0,  0,  0,1.2,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,1.8,1.8,4.0,  0,  0,  0,  0,  0,  0,4.0,4.0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,  0,4.0,  0,  0,  0,  0,  0,  0,  0,1.2,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,2.1,2.1,2.1,4.0,  0,  0,  0,  0,  0,  0,4.0,4.0,  0,  0,  0,  0,  0,4.0 ],
		[4.0, -2, -2,4.0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,2.1,2.1,2.1,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,  0,4.0 ],
		[4.0, -2, -2,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1.0,  0,1.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1.0,1.0,  0,  0,  0,  0,  0,  0,1.0,1.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1.0,1.0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1.0,  0,  0,  0,1.0,  0,  0,  0,  0,1.0,1.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1.0,1.0,  0,4.0 ],
		[4.0,  0,1.0,1.0,  0,  0,  0,  0,  0,  0,  0,  0,1.0,  0,  0,  0,  0,  0,1.0,  0,  0,  0,1.0,1.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,1.0,1.0,  0,  0,  0,  0,  0,  0,  0,  0,1.0,  0,  0,  0,1.0,  0,1.0,1.0,  0,  0,  0,  0,1.0,  0,1.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1.0,  0,  0,  0,  0,  0,1.0,  0,  0,  0,  0,  0,  0,  0,1.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1.0,  0,  0,  0,1.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1.0,1.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0 ]];
	#else
	mapHeight = [
		[4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,4.0,1.2,1.2,1.2,1.2,1.4,1.4,1.4,1.6,1.6,1.6,1.8,1.8,1.8,2.0,2.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,4.0,1.2,1.2,1.2,1.2,1.4,1.4,1.4,1.6,1.6,1.6,1.8,1.8,1.8,2.0,2.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,4.0,1.0,1.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,  0,  0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,4.0,1.0,1.0,  0,4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,4.0,1.0,1.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,4.0,0.8,0.8,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,4.0,4.0,  0,  0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,  0,  0,4.0 ],
		[4.0,4.0,4.0,  0,  0,4.0,4.0,4.0,0.8,0.8,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,4.0,4.0,  0,  0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,4.0,0.8,0.8,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,4.0,0.6,0.6,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,4.0,0.6,0.6,  0,4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,  0,  0,4.0,4.0,  0,  0,4.0,4.0,  0,  0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,4.0,0.6,0.6,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,  0,  0,4.0,4.0,  0,  0,4.0,4.0,  0,  0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,4.0,0.4,0.4,0.4,0.4,0.2,0.2,0.2,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,  0,  0,  0,  0,4.0,4.0,  0,  0,  0,  0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,4.0,0.4,0.4,0.4,0.4,0.2,0.2,0.2,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,  0,  0,  0,  0,4.0,4.0,  0,  0,  0,  0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,  0,  0,4.0,  0,  0,4.0,4.0,4.0,  0,  0,4.0,4.0,  0,  0,4.0,4.0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,4.0,4.0,  0,  0,4.0,4.0,  0,  0,4.0,4.0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,  0,  0,4.0,4.0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,  0,  0,4.0,0.3,0.3,4.0,  0,  0,4.0,4.0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,4.0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,0.6,0.6,4.0,  0,  0,  0,  0,4.0,4.0,  0,  0,4.0,4.0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,4.0,  0,  0,  0,  0,  0,  0,  0,1.2,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,0.9,0.9,4.0,  0,  0,  0,  0,4.0,4.0,  0,  0,4.0,4.0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,4.0,  0,  0,  0,  0,  0,  0,  0,1.2,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,1.2,1.2,4.0,  0,  0,4.0,4.0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1.2,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0,1.5,1.5,4.0,  0,  0,4.0,4.0,  0,  0,  0,  0,  0,  0,4.0,1.0,1.0,4.0 ],
		[4.0,  0,  0,4.0,  0,  0,  0,  0,  0,  0,  0,1.2,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,4.0,1.8,1.8,4.0,  0,  0,  0,  0,  0,  0,4.0,4.0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,  0,4.0,  0,  0,  0,  0,  0,  0,  0,1.2,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,2.1,2.1,2.1,4.0,  0,  0,  0,  0,  0,  0,4.0,4.0,  0,  0,  0,  0,  0,4.0 ],
		[4.0, -2, -2,4.0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,  0,  0,  0,  0,  0,4.0,  0,  0,2.1,2.1,2.1,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,  0,4.0 ],
		[4.0, -2, -2,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,4.0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1.0,  0,1.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1.0,1.0,  0,  0,  0,  0,  0,  0,1.0,1.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1.0,1.0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1.0,  0,  0,  0,1.0,  0,  0,  0,  0,1.0,1.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1.0,1.0,  0,4.0 ],
		[4.0,  0,1.0,1.0,  0,  0,  0,  0,  0,  0,  0,  0,1.0,  0,  0,  0,  0,  0,1.0,  0,  0,  0,1.0,1.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,1.0,1.0,  0,  0,  0,  0,  0,  0,  0,  0,1.0,  0,  0,  0,1.0,  0,1.0,1.0,  0,  0,  0,  0,1.0,  0,1.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1.0,  0,  0,  0,  0,  0,1.0,  0,  0,  0,  0,  0,  0,  0,1.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1.0,  0,  0,  0,1.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,1.0,1.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,4.0 ],
		[4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0, 4.0 ]];
	#end
		
	 mapFloorColor = [
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ]];
	mapWallColor = [
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 4, 5, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 5, 4, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 4, 5, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 5, 4, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 4, 5, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 5, 4, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 4, 5, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 5, 4, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 4, 5, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 5, 4, 5, 4, 5, 4, 5, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 4, 5, 4, 5, 4, 5, 4, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ],
		[ 1, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 2 ],
		[ 2, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 1 ],
		[ 1, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 2 ],
		[ 2, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 1 ],
		[ 1, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 2 ],
		[ 2, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 1 ],
		[ 1, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 2 ],
		[ 2, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 1 ],
		[ 1, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 2 ],
		[ 2, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 1 ],
		[ 1, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 2 ],
		[ 2, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 1 ],
		[ 1, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 5, 4, 2 ],
		[ 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1 ]];
	// depth x width
	mapDepth = mapHeight.length;
	mapWidth = mapHeight[0].length;
	mapWallIdxCount = mapWidth * (mapDepth + 1) + mapDepth * (mapWidth + 1);
}

	var logField:TextField;
	var laggyField:TextField;
	
	inline function SetupStage():Void {
		addChild(  (logField = new TextField()  ) );
		
		logField.multiline = true;
		logField.width = 300;
		logField.autoSize = TextFieldAutoSize.LEFT;
		logField.selectable = true;
		
		addChild ( laggyField = new TextField() ) ;
		laggyField.multiline = true;
		laggyField.width = 300;
		laggyField.y = 400;
		laggyField.autoSize = TextFieldAutoSize.LEFT;
		
		
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}

	function onAddedToStage(e:Event):Void {
		removeEventListener(Event.ADDED, onAddedToStage);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, KeyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, KeyUp);
	}
	
	function AddToggle(key:UInt , func:Dynamic) {
		toggles[key] = func;
	}
	
	function SetupToggles():Void {
		toggles = new flash.utils.TypedDictionary();
		AddToggle(KEY_B, function() { debugMode = !debugMode; });
		//AddToggle(KEY_H, function() { showHelp = !showHelp; });
		AddToggle(KEY_I, function() { showStats = !showStats; });
		AddToggle(KEY_R, function() { renderingEnabled = !renderingEnabled; } );
		AddToggle(KEY_P, togglePause );
		AddToggle(KEY_T, togglePauseAndSplit );
		//AddToggle(KEY_V, function() { verbose = !verbose; } );
	}
	
	function Init() {
		BuildColors();
		BuildMap();
		SetupStage();

		SetupToggles();
		
		
		player = new Player();
		player.x = 1.5;
		player.y = 1.5;

		player.h = mapHeight[1][1];
		player.angle = Math.PI / 4.0;
		
		
		Start();
	}
	

	
	function Start() {
		#if testPosition
		setPosition(24.7, 24.064928781071682);
		setAngle(4.192212856217854);
		#end
		
		#if debugView
		debugMode = true;
		#end
		
		addEventListener(Event.ENTER_FRAME, Render);
	}
	function togglePause(?e:Event=null) {
		 isPaused = !isPaused; if (isPaused) Pause() else UnPause();
	}
	function togglePauseAndSplit(?e:Event = null) {
		
		
			showSplits = true;
			
			Pause();
			laggyField.text = "Loading splits..Please wait.";
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDownResume, false, 1);
			_noTicks = 0;
			stage.addEventListener(Event.EXIT_FRAME, nextTickRender);
		
		
	}
	
	var _noTicks:Int;
	private function nextTickRender(e:Event):Void {
		_noTicks++;
		if (_noTicks > 1) {
		stage.removeEventListener(Event.EXIT_FRAME, nextTickRender);
			Render();
			logField.text += "\nSplits loaded....\nPress and key to continue.";
			laggyField.text = "";
			
		
			_noTicks = 0;
		}
	}
	private function onKeyDownResume(e:KeyboardEvent):Void {
		showSplits = false;
		stage.removeEventListener(Event.EXIT_FRAME, nextTickRender);
		stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDownResume);
		UnPause();
		e.stopImmediatePropagation();

	}
	

	
	
	inline function Pause() {
		isPaused = true;
		laggyField.text = "Paused. Controls locked. Press P to unlock again.";
		removeEventListener(Event.ENTER_FRAME, Render);
	}
	inline function UnPause() {
		isPaused = false;
		showSplits = false;
		removeEventListener(Event.ENTER_FRAME, Render);
		addEventListener(Event.ENTER_FRAME, Render);
		laggyField.text = "";
	}
	
	function Render(?e:Event=null):Void {
		frames++;
		outlineCount = 0;
		wallcount = 0;
		divCount = 0;
		
		// consider: buffering/caching
		wallCache = new TypedDictionary();
		splitList = [];
		graphicData = new Vector();
		wallArray = [];
		

		curTime = getTime();
		lastFrameSeconds = (curTime - prevTime) / 1000;
		if (curTime - frameCountStart > 1000) {
			fps = Std.int(100000 * frames / (curTime - frameCountStart)) / 100;
			frames = 0;
			frameCountStart = curTime;
		}
		prevTime = curTime;
		
		ClearLog();
		
		DoMove();

		DoPreCalcs();
		
		raycount = 0;

		RenderSky();
		RenderMap();
		
		SwapBuffers();

		if (showStats) ShowStats();
		//if (showHelp) ShowHelp();
	}
	inline function getTime():Int {
		return Lib.getTimer();
	}
	inline function DoPreCalcs():Void {
		if (player.angle > 2 * Math.PI) player.angle -= 2 * Math.PI;
		if (player.angle < 0) player.angle += 2 * Math.PI;
		pdx = Math.cos(player.angle);
		pdy = Math.sin(player.angle);
		dx1 = pdx + pdy; // ray for left edge of screen
		dy1 = pdy - pdx;
		dx2 = pdx - pdy; // ray for right edge of screen
		dy2 = pdy + pdx;
		ddx = (dx2 - dx1) / 1000; // difference between rays
		ddy = (dy2 - dy1) / 1000;
		playerXInt = Std.int(player.x);
		playerYInt = Std.int(player.y);
	}
	
	inline function AddDiv(left:Int, right:Int, top1:Int, top2:Int, bottom:Int, z:Float, c:UInt):Void {
		divCount++;
		graphicData.push( new GraphicsSolidFill(c, (debugMode ? .4  : 1)  ) ); //
		var commands : flash.Vector<Int> = new flash.Vector(4, true);
		var data : flash.Vector<Float> = new flash.Vector(8,true);
		commands[0] =  GraphicsPathCommand.MOVE_TO;
		commands[1] =  GraphicsPathCommand.LINE_TO;
		commands[2] =  GraphicsPathCommand.LINE_TO;
		commands[3] =  GraphicsPathCommand.LINE_TO;
		data[0] = left; data[1] = top1;
		data[2] = right; data[3] = top2;
		data[4] = right; data[5] = bottom;
		data[6] = left; data[7] = bottom;
		graphicData.push( new GraphicsPath(commands,data) );
	}

	inline function AddSplitDiv(left:Int, right:Int, top:Int, bottom:Int, c:UInt):Void {
		graphics.lineStyle(0, 0xFF0000);
		var stroke:GraphicsStroke = new GraphicsStroke(0);
		stroke.fill = new GraphicsSolidFill(0xFF0000, .1);
		graphicData.push(stroke );
		
		var commands:Vector<Int> = new Vector(6, true);
		var data:Vector<Float> = new Vector(12, true);
		commands[0] =  GraphicsPathCommand.MOVE_TO;
		commands[1] =  GraphicsPathCommand.LINE_TO;
		commands[2] =  GraphicsPathCommand.MOVE_TO;
		commands[3] =  GraphicsPathCommand.LINE_TO;
		commands[4] =  GraphicsPathCommand.MOVE_TO;
		commands[5] =  GraphicsPathCommand.LINE_TO;
		
		data[0] = left; data[1] = top;
		data[2] = left; data[3] = bottom;
		
		data[4] = right; data[5] = top;
		data[6] = right; data[7] = bottom;
		
		var middle:Int = Math.round( (right - left) * .5);
		data[8] = middle; data[9] = top;
		data[10] = middle; data[11] = bottom;
		
		graphicData.push( new GraphicsPath(commands, data ) );
	}
	
	inline function SwapBuffers():Void {
		graphics.clear();
		if (debugMode) graphics.lineStyle(0, 0);
		graphics.drawGraphicsData(graphicData);
	}
	
	
	
	function RenderSky():Void {
		
	}
	

	
	
	function RenderMap():Void {
		
		var left:Ray = new Ray(0, CastRay(dx1, dy1) );
		var right:Ray = new Ray( 1000, CastRay(dx2, dy2) );
		
		
		SplitRay(left, right, 0, player.h, 500, 500);
		
		if (!renderingEnabled) return;
		
		
		
		untyped wallArray.sortOn("z");
		var len:Int = wallArray.length;
		for (i in 0...len) {
			var wall = wallArray[i];
			#if occlude
			var leftClipped:Bool = wall.leftNode!= null ?  wall.leftNode.isClipped : false;
			var rightClipped:Bool = wall.rightNode != null ? wall.rightNode.isClipped : leftClipped;
	
			
			if (wall.dirtyFlag == 3) {
				
				if (wall.leftNode!=null) wall.top1 = Project(wall.leftNode.t, wall.leftNode.h1);
				if (wall.rightNode != null) wall.top2 = Project(wall.rightNode.t, wall.rightNode.h1);
				
				
			}
			
			var wallIsClipped:Bool = leftClipped && rightClipped && wall.dirtyFlag != 3;
			/*
			if () {
				if (wall.top1 > wall.top2) {
					wall.top2 = wall.top1;
				}
				else {
					wall.top1 = wall.top2;
				}
				wallIsClipped = wall.dirtyFlag != 3;
			}
			*/
			#end
			
			#if occlude  
			if (!wallIsClipped) {
			#end
		
			//wall.bottom += 16;
			//wall.bottom+= wallIsCl16;  // for the case of step-downs, the bottoms need to be extended to fill
			// possible whitespaces
			AddDiv(wall.x1, wall.x2, wall.top1, wall.top2, wall.bottom, wall.z, wall.color);
			#if occlude
			}
			#end
		}
		
		
		if (showSplits) {
			for ( split in splitList) {
				AddSplitDiv(split.left, split.right, 0, 500, 0x000000);
			}
		}
		
		
	}
	

	
	inline function setPosition(x:Float, y:Float):Void {
		player.x = x;
		player.y = y;
		player.h = mapHeight[Std.int(player.y)][Std.int(player.x)];
	}
	inline function setAngle(ang:Float):Void {
		player.angle = ang;
	}
	
	function MoveX(ox:Float, oy:Float, vx:Float, vy:Float, size:Float) {
		var newx = ox + vx;
		var yi = Std.int(oy);
		var h = mapHeight[yi][Std.int(ox)];
		if (vx > 0){
			var xi = Std.int(newx + size);
			if (mapHeight[yi][xi] < h + MAXSTEP) {
				ox = newx;
			} else {
				ox = xi - size;
			}
		} else {
			var xi = Std.int(newx - size);
			if (mapHeight[yi][xi] < h + MAXSTEP) {
				ox = newx;
			} else {
				ox = xi + 1 + size;
			}
		}
		return ox;
	}

	function MoveY(ox:Float, oy:Float, vx:Float, vy:Float, size:Float) {
		var newy = oy + vy;
		var xi = Std.int(ox);
		var h = mapHeight[Std.int(oy)][xi];
		if (vy > 0) {
			var yi = Std.int(newy + size);
			if (mapHeight[yi][xi] < h + MAXSTEP) {
				oy = newy;
			} else {
				oy = yi - size;
			}
		} else {
			var yi = Std.int(newy - size);
			if (mapHeight[yi][xi] < h + MAXSTEP) {
				oy = newy;
			} else {
				oy = yi + 1 + size;
			}
		}
		return oy;
	}

	inline function ShowStats()
	{
		Log(raycount + " rays cast");
		Log(divCount + " objects rendered");
		Log("Position: (" + player.x + ", " + player.y +")");
		Log("Angle: " + player.angle);
		Log("Frame rate: " + fps);
	}
	inline function ClearLog()
	{
		logField.text = "";
	}

	inline function Log(text:String)
	{
		logField.appendText(text+"\n");
	
	}
	
	
	// Cast a ray until a wall of MAXHEIGHT is found
	function CastRay(dx:Float, dy:Float):Vector<Node> {
		raycount++;
		var xt:Float; // time until the next x-intersection
		var dxt:Float; // time between x-intersections
		var yt:Float; // time until the next y-intersection
		var dyt:Float; // time between y-intersections
		var dxi:Int; // direction of the x-intersection
		var dyi:Int; // direction of the y-intersection
		var xi:Int = playerXInt;
		var yi:Int = playerYInt;
		var xoff:Float = player.x - xi;
		var yoff:Float = player.y - yi;
		if (dx < 0) {
			xt = -xoff / dx;
			dxt = -1 / dx;
			dxi = -1;
		} else {
			xt = (1 - xoff) / dx;
			dxt = 1 / dx;
			dxi = 1;
		}
		if (dy < 0) {
			yt = -yoff / dy;
			dyt = -1 / dy;
			dyi = -1;
		} else {
			yt = (1 - yoff) / dy;
			dyt = 1 / dy;
			dyi = 1;
		}

		var t = .0; // intersection time
		var done:Bool = false;
		var c = 0; // intersection count
		var nodes = new Vector<Node>();
		var prevH = mapHeight[yi][xi];
		var h = .0;
		var prevFloorColor = mapFloorColor[yi][xi];
		var wallIdx = -1;
		var side:Int;
		var xint:Float;
		var yint:Float;
		var lastH:Float = 0;
		
		#if occlude
		var yProj:Int = 1000;
		#end
		
		while (!done) {
			if (xt < yt) {
				xi += dxi;
				t = xt;
				side = dxi > 0 ? 1 : 3;
				wallIdx = GetWallIndex(xi - dxi, yi, xi, yi);
				xt += dxt;
			} else {
				yi += dyi;
				t = yt;
				side = dyi > 0 ? 2 : 0;
				wallIdx = GetWallIndex(xi, yi - dyi, xi, yi);
				yt += dyt;
			}
			#if noMaxHeight
			if (yi < 0 || yi >( mapDepth-1) || xi < 0 || xi > (mapWidth-1) ) {
				done = true;
				break;
			}
			#end
		
			h = mapHeight[yi][xi];
			xint = player.x + t * dx;
			yint = player.y + t * dy;
			#if occlude
			var testProj:Int = Project( t, maxF(h, prevH) );
			// consider clip testProj to 0
			//if ( testProj <= yProj ) {	
			var isValid:Bool  = testProj <= yProj;
			#end
				var ppH:Int = Project(t, prevH );
				
				nodes.push( new Node(wallIdx, t, prevH, h, 500 -c,  prevFloorColor, mapWallColor[yi][xi], side #if occlude , testProj,  #if clippedBottoms min(ppH , yProj) #else ppH #end, isValid, yProj<=ppH  #end ));
				
			#if occlude	
			//}
			
			if (testProj < yProj) lastH = h;
			
			//if (prevH != h) 
			yProj  = prevH > h && prevH - h < 1.2  ? yProj : min(testProj, yProj);  //2 without artifacts
			#end
			prevH = h;
			prevFloorColor = mapFloorColor[yi][xi];
			done = (h == MAX_HEIGHT #if (occlude && occludeEarlyOut) || testProj <= 0 #end ); //
			c += 2;
			if (c > 400) {
				t = 400;
				done = true;
			}
		}
		return nodes;
	}
	
	inline function Project(t:Float, h:Float):Int {
		return Std.int(250 - 250 * (h - player.h - viewBob) / t);
	}
	
	inline function diff(v1:Float, v2:Float):Float {
		return v1 < v2 ? v2 - v1 : v2 - v1;
	}
	
	
	function SplitRay(left:Ray, right:Ray, firstIntIdx:Int, prevH:Float, prevLeftY:Int, prevRightY:Int):Void {
		var leftX = left.x;
		var rightX = right.x;
		var leftNodes = left.nodes;
		var rightNodes = right.nodes;
		splitList.push( new Split(leftX, rightX, prevLeftY, prevRightY) );
		if (rightX - leftX > 1) {
			var commonIntersections:Int = min(leftNodes.length, rightNodes.length);
			for ( i in firstIntIdx...commonIntersections) {
				var leftNode = leftNodes[i];
				var rightNode = rightNodes[i];
				if (leftNode.wallIdx == rightNode.wallIdx) {
					var h1 = leftNode.h1;
					var h2 = leftNode.h2;
					var leftY1 =  #if occlude leftNode.prevProjY;   #else  Project(leftNode.t, h1); #end
					var leftY2 =  #if occlude leftNode.projY;       #else  Project(leftNode.t, h2); #end
					var rightY1 = #if occlude rightNode.prevProjY;  #else  Project(rightNode.t, h1); #end
					var rightY2 = #if occlude rightNode.projY;      #else  Project(rightNode.t, h2); #end
					#if occlude
	
					#end
					var z = leftNodes[i].z;
					
					#if occlude if (leftNode.isValid || rightNode.isValid) { #end
				
					if (h1 < h2) {
						CacheWall(leftNode.wallIdx, leftX, rightX, leftY2, rightY2, max(leftY1, rightY1) , z, wallColors[leftNode.wColor][leftNode.side] #if occlude  #end );
					}
					CacheWall(mapWallIdxCount + leftNode.wallIdx, leftX, rightX, leftY1, rightY1, max(prevLeftY, prevRightY) + 2, z + 1, floorColors[leftNode.fColor]  #if occlude , leftNode, rightNode #end );
					#if occlude }  #end
					prevH = h2;
					prevLeftY = #if occlude leftNode.isValid ? #end leftY2  #if occlude :   prevLeftY #end;
					prevRightY = #if occlude rightNode.isValid ? #end rightY2  #if occlude :  prevRightY #end;
				} else {
					var middleX = Std.int((leftX + rightX) / 2);
					var middleDx = dx1 + ddx * middleX;
					var middleDy = dy1 + ddy * middleX;
					var middle = new Ray(middleX, CastRay(middleDx, middleDy) );
					var prevMiddleY = max(prevLeftY, prevRightY);
					SplitRay(left, middle, i, prevH, prevLeftY, prevMiddleY);
					SplitRay(middle, right, i, prevH, prevMiddleY, prevRightY);
					break;
				}
			}
			// if either list is longer, it'll be handled already by the above code
		} else {
			// the rays are adjacent
			// draw the left intersections as single-pixel-wide
			for (i in firstIntIdx...leftNodes.length) {
				var leftNode = leftNodes[i];
				var h1 = leftNode.h1;
				var h2 = leftNode.h2;
				var leftY1 = #if occlude leftNode.prevProjY; #else Project(leftNode.t, h1);	#end
				var leftY2 = #if occlude leftNode.projY; #else Project(leftNode.t, h2);  #end
				var z = leftNode.z;
				#if occlude if (leftNode.isValid) { #end
				if (h1 < h2) {
					CacheWall(leftNode.wallIdx, leftX, rightX, leftY2, leftY2, leftY1 , z, wallColors[leftNode.wColor][leftNode.side]);
				}
				 CacheWall(mapWallIdxCount + leftNode.wallIdx, leftX, rightX, leftY1, leftY1, prevLeftY + 2, z + 1, floorColors[leftNode.fColor] #if occlude , leftNode #end);
				#if occlude } #end
				prevLeftY =  #if occlude leftNode.isValid ? #end leftY2 #if occlude : prevLeftY #end;
			}
		}
	}
	/*
	inline function CacheWallSurface(leftNode:Node, rightNode:Node, leftX:Int, rightX:Float):Void {
		var wallIdx:Int = leftNode.wallIdx;
		var wall:Wall = wallCache[ wallIdx ] || (wallCache[wallIdx] = new Wall(leftNode.);
		
		, leftX, rightX, leftY2, rightY2, max(leftY1, rightY1) , z, wallColors[leftNode.wColor][leftNode.side]
	}
	inline function CacheGroundSurface(leftNode:Node, rightNode:Node):Void {
		
	}
	*/
	
	function CacheWall(wallIdx:Int, x1:Int, x2:Int, top1:Int, top2:Int, bottom:Int, z:Float, color:UInt #if occlude , leftNode:Node = null, rightNode:Node = null #end):Void {
		var wall:Wall;
		//leftNode.isClipped;
		if ( (wall = wallCache[wallIdx]) != null ) {
			#if occlude
			wall.dirtyFlag |= leftNode != null ? leftNode.isClipped ? 2 : 1 : 0;
			wall.dirtyFlag |= rightNode != null ? rightNode.isClipped ? 2 : 1 : 0;
			#end
			if (x1 < wallCache[wallIdx].x1) {
				wall.x1 = x1;
				wall.top1 = top1;
				#if occlude
				if (leftNode != null) wall.leftNode = leftNode;
				#end
			}
			if (x2 > wall.x2) {
				wall.x2 = x2;
				wall.top2 = top2;
				#if occlude
				if (rightNode!=null) wall.rightNode = rightNode;
				#end
			}
			wall.bottom = max(wall.bottom, bottom);
			
		} else {
			wallcount++;
			
			wallArray.push ( 
				wallCache[wallIdx] = wall= new Wall(
					 x1,
					 x2,
					 top1,
					 top2,
					bottom,
					 z,
					 color ) 
			);
			#if occlude
			wall.leftNode = leftNode;
			wall.rightNode = rightNode;
			wall.dirtyFlag |= leftNode != null ? leftNode.isClipped ? 2 : 1 : 0;
			wall.dirtyFlag |= rightNode != null ? rightNode.isClipped ? 2 : 1 : 0;
			#end
		}
	}


	inline function GetWallIndex(x1:Int, y1:Int, x2:Int, y2:Int):Int {
		return x1 == x2  ? mapWidth * min(y1, y2) + x1 : mapWidth * (mapDepth + 1) + (mapWidth + 1) * y1 + min(x1, x2);
		
	}

	inline function min(v1:Int, v2:Int):Int {
		return v1 < v2 ? v1 : v2;
	}
	inline function minF(v1:Float, v2:Float):Float {
		return v1 < v2 ? v1 : v2;
	}
	inline function maxF(v1:Float, v2:Float):Float {
		return v1 < v2 ? v2 : v1;
	}
	inline function max(v1:Int, v2:Int):Int {
		return v1 < v2 ? v2 : v1;
	}

	
	
	inline function MoveBy(vx:Float, vy:Float) {
		player.x = MoveX(player.x, player.y, vx, vy, CHARSIZE);
		player.y = MoveY(player.x, player.y, vx, vy, CHARSIZE);
		player.h = mapHeight[Std.int(player.y)][Std.int(player.x)];
	}


	inline function Forward() {
		MoveBy(lastFrameSeconds * WALKSPEED * pdx, lastFrameSeconds * WALKSPEED * pdy);
	}

	inline function Back() {
		MoveBy(-lastFrameSeconds * WALKSPEED * pdx, -lastFrameSeconds * WALKSPEED * pdy);
	}

	inline function StrafeLeft() {
		MoveBy(lastFrameSeconds * WALKSPEED * pdy, -lastFrameSeconds * WALKSPEED * pdx);
	}

	inline function StrafeRight() {
		MoveBy(-lastFrameSeconds * WALKSPEED * pdy, lastFrameSeconds * WALKSPEED * pdx);
	}
	
	inline function Rotate(i) {
		player.angle += i;
	}

	inline function Left() {
		Rotate(-lastFrameSeconds * TURNSPEED);
	}

	inline function Right() {
		Rotate(lastFrameSeconds * TURNSPEED);
	}


	
	function KeyDown(e:KeyboardEvent) {
		keys[e.keyCode] = true;
		DoToggles();
	}


	function KeyUp(e:KeyboardEvent) {	
		keys[e.keyCode] = false;
	}
	


	inline function Mouse(e) {
		if (lastmousex > 0) {
			var dmousex = e.screenX - lastmousex;
			Rotate(dmousex / 100);
		}
		lastmousex = e.screenX;
	}


	inline function DoToggles() {
		for (k in toggles) {
			if (keys[k]) {
				if (!keysCache[k]) toggles[k]();
				keysCache[k] = true;
			} else {
				keysCache[k] = false;
			}
		}
		
	}

	inline function DoMove() {
		var moving = false;
		if (keys[KEY_W] > 0 || keys[KEY_ARROW_UP] > 0 || keys[KEY_WII_UP]) {
			Forward();
			moving = true;
		}
		if (keys[KEY_S] > 0 || keys[KEY_ARROW_DOWN] > 0 || keys[KEY_WII_DOWN]) {
			Back();
			moving = true;
		}
		if (keys[KEY_ARROW_LEFT] > 0) {
			Left();
			moving = true;
		}
		if (keys[KEY_ARROW_RIGHT] > 0) {
			Right();
			moving = true;
		}
		if (keys[KEY_A] > 0 || keys[KEY_WII_LEFT]){
			StrafeLeft();
			moving = true;
		}
		if (keys[KEY_D] > 0 || keys[KEY_WII_RIGHT]) {
			StrafeRight();
			moving = true;
		}
	
		if (moving) {
			bobTime += lastFrameSeconds;
			viewBob = VIEWHEIGHT + VIEWBOB * Math.sin(bobTime * VIEWBOBSPEED);
		}
	}
	
}