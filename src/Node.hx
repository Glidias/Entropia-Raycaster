/**
 * ...
 * @author Glenn Ko
 */

package ;

class Node 
{
	public var wallIdx:Int;
	public var t:Float;
	public var h1:Float;
	public var h2:Float;
	public var z:Float;
	public var fColor:UInt;
	public var wColor:UInt;
	public var side:Int;
	public var isValid:Bool;
	
	#if occlude
	public var projY:Int;
	public var prevProjY:Int;
	public var isClipped:Bool;
	#end

	public function new(wallIdx:Int, t:Float, h1:Float, h2:Float, z:Float, fColor:UInt, wColor:UInt, side:Int #if occlude ,projY:Int, prevProjY:Int, isValid:Bool =true, isClipped:Bool=false  #end ) 
	{
		this.wallIdx = wallIdx;
		this.t = t;
		this.h1 = h1;
		this.h2 = h2;
		this.z = z;
		this.fColor = fColor;
		this.wColor = wColor;
		this.side = side;
	
		
		#if occlude
		this.projY = projY;
		this.prevProjY = prevProjY;
		this.isValid = isValid;
		this.isClipped = isClipped;
		#end
	}
	
}