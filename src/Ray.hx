/**
 * ...
 * @author Glenn Ko
 */

package ;

import flash.Vector;

class Ray 
{
	public var nodes:Vector<Node>;
	public var x:Int;

	public function new(x:Int, nodes:Vector<Node>) 
	{
		this.x = x;
		this.nodes = nodes;
	}
	
}