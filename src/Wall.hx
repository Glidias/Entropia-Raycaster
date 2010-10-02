/**
 * ...
 * @author Glenn Ko
 */

package ;

class Wall 
{
	public var x1 : Int;
	public var x2 : Int;
	public var top1 : Int;
	public var top2 : Int;
	public var bottom : Int;
	public var z : Float;
	public var color : UInt;

	public function new(x1:Int, x2:Int, top1:Int, top2:Int, bottom:Int, z:Float, color:UInt) 
	{
		this.x1 = x1;
		this.x2 = x2;
		this.top1 = top1;
		this.top2 = top2;
		this.bottom = bottom;
		this.z = z;
		this.color = color;
	}
	
}