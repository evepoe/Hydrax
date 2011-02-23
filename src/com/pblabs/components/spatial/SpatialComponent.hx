/*******************************************************************************
* PushButton Engine
* Copyright (C) 2009 PushButton Labs, LLC
* For more information see http ://www.pushbuttonengine.com
* 
* This file is licensed under the terms of the MIT license, which is included
* in the License.html file at the root directory of this SDK.
******************************************************************************/
package com.pblabs.components.spatial;

import com.pblabs.components.base.Coordinates2D;
import com.pblabs.components.manager.NodeComponent;
import com.pblabs.components.scene.BaseScene2DComponent;
import com.pblabs.components.scene.BaseScene2DLayer;
import com.pblabs.engine.core.IEntity;
import com.pblabs.engine.core.ObjectType;
import com.pblabs.engine.core.PropertyReference;
import com.pblabs.geom.Vector2;

import de.polygonal.motor2.geom.math.XY;
import de.polygonal.motor2.geom.primitive.AABB2;

import flash.xml.XML;

import hsl.haxe.DirectSignaler;
import hsl.haxe.Signaler;

/**
 * Very basic spatial component that exists at a position. 
 */ 
class SpatialComponent extends NodeComponent<BasicSpatialManager2D, Dynamic>, 
	implements ISpatialObject2D 
{
	inline public static var NAME :String = "ISpatialObject2D";
	public static var P_X :PropertyReference<Float> = new PropertyReference("@" + NAME + ".x");
	public static var P_Y :PropertyReference<Float> = new PropertyReference("@" + NAME + ".y");
	public static var P_POINT :PropertyReference<XY> = new PropertyReference("@" + NAME + ".position");
	public static var P_ANGLE :PropertyReference<Float> = new PropertyReference("@" + NAME + ".angle");
	public static var P_COORDINATES :PropertyReference<Coordinates2D> = new PropertyReference("@ISpatialObject2D");
	
	public static function getLocation (c :IEntity) :XY	
	{
	    return c.lookupComponent(ISpatialObject2D).point;
	}
	
	public var position (get_position, set_position) :XY;
	
	public var x (get_x, set_x) : Float;
	public var y (get_y, set_y) : Float;
	public var angle (get_angle, set_angle) : Float;
	public var objectMask(get_objectMask, set_objectMask) :ObjectType;
	public var worldExtents(get_worldExtents, set_worldExtents) :AABB2;
	
	public var signalerLocation (default, null) :Signaler<XY>;
	public var signalerAngle (default, null) :Signaler<Float>;
	
	/**
	 * If set, a SpriteRenderComponent we can use to fulfill point occupied
	 * tests.
	 */
	public var spriteForPointChecks :BaseScene2DComponent<BaseScene2DLayer<Dynamic, Dynamic>>;
	var _objectMask :ObjectType;
	var _vec :XY;
	var _vecForSignalling :XY;
	var _angle :Float;
	var _worldAABB :AABB2;
	
	public function new() 
	{ 
		super();
		signalerAngle = new DirectSignaler(this);
		signalerLocation = new DirectSignaler(this);
		_vec = new Vector2();
		_vecForSignalling = new Vector2();
		_angle = 0;
	}

	function get_point ():XY
	{
		return _vec.clone();
	}

	function set_point (p :XY):XY
	{
		setLocation(p.x, p.y);
		return p;
   }

   	function get_angle () :Float
	{
		return _angle;
	}
	
	function set_angle (val :Float) :Float
	{
		if (_angle != val) {
			_angle = val;
			dispatchAngle();
		}
		return val;
	}
	
	function get_x ():Float
	{
		return _vec.x;
	}

	function set_x (val :Float):Float
	{
		// com.pblabs.util.Assert.isFalse(Math.isNaN(val), com.pblabs.util.Log.getStackTrace());
		if (_vec.x != val) {
			_vec.x = val;
			dispatchLocation();
		}
		return val;
   }

	function get_y ():Float
	{
		return _vec.y;
	}

	function set_y (val :Float):Float
	{
		// com.pblabs.util.Assert.isFalse(Math.isNaN(val), com.pblabs.util.Log.getStackTrace());
		if (_vec.y != val) {
			_vec.y = val;
			dispatchLocation();
		}
		return val;
   }

	public function setLocation (xLoc :Float, yLoc :Float) :Void
	{
		// com.pblabs.util.Assert.isFalse(Math.isNaN(xLoc), com.pblabs.util.Log.getStackTrace());
		// com.pblabs.util.Assert.isFalse(Math.isNaN(yLoc), com.pblabs.util.Log.getStackTrace());
		if (_vec.x != xLoc || _vec.y != yLoc) {
			_vec.x = xLoc;
			_vec.y = yLoc;
			dispatchLocation();
		}
	}
	
	public function serialize (xml :XML) :Void
	{
		xml.createChild("x", _vec.x);
		xml.createChild("y", _vec.y);
		xml.createChild("angle", _angle);
	}
	
	public function deserialize (xml :XML) :Dynamic
	{
		_vec.x = xml.parseFloat("x");
		_vec.y = xml.parseFloat("y");
		_angle = xml.parseFloat("angle");
	}
	
	override function onRemove () :Void
	{
		_vec.x = 0;
		_vec.y = 0;
		_angle = 0;
		super.onRemove();
	}
	
	override function onReset () :Void
	{
		super.onReset();
		dispatchAll();
	}
	
	public function dispatchAngle () :Void
	{
		if (signalerAngle.isListenedTo) {
			signalerAngle.dispatch(_angle);
		}
	}
	
	public function dispatchLocation () :Void
	{
		if ( signalerLocation.isListenedTo) {
			_vecForSignalling.x = _vec.x;
			_vecForSignalling.y = _vec.y;
			signalerLocation.dispatch(_vecForSignalling);
		}
	}
	
	public function dispatchAll () :Void
	{
		dispatchAngle();
		dispatchLocation();
	}
	
	#if debug
	public function toString () :String
	{
		return "[x=" + x + ", y=" + y + ", angle=" + angle + "]";
	}
	
	override public function postDestructionCheck () :Void
	{
		super.postDestructionCheck();
		com.pblabs.util.Assert.isFalse(signalerLocation.isListenedTo);
		com.pblabs.util.Assert.isFalse(signalerAngle.isListenedTo);
	}
	#end
	
	function get_objectMask() :ObjectType
	{
		return _objectMask;
	}
	
	function set_objectMask (val :ObjectType) :ObjectType
	{
		_objectMask = val;
		return value;
	}
	
	function get_worldExtents() :AABB2
	{
		if (_worldAABB != null) {
			return _worldAABB;
		} 
		// return new AABB2(position.x - (size.x * 0.5), position.y - (size.y * 0.5), size.x, size.y);		 
	}
	
	function set_worldExtents(val :AABB2) :AABB2
	{
		_worldAABB = val;
	}
	
	/**
	 * Not currently implemented.
	 */
	// public function castRay (start :XY, end :XY, result :RayHitInfo, ?flags :ObjectType = null):Bool
	// {
	// 	return false;
	// }
	
	/**
	 * All points in our bounding box are occupied.
	 */
	public function containsWorldPoint (pos :XY, ?mask :ObjectType = null):Bool
	{
		//False if masks say so
		if (_objectMask != null && mask != null && !_objectMask.and(mask)) {
			return false;
		}
		// OK, so pass it over to the sprite.
		if(spriteForPointChecks != null) {
			return spriteForPointChecks.containsWorldPoint(pos, mask);
		}
		
		com.pblabs.util.Assert.isNotNull(worldExtents, "No worldExtends for point checking");
		// If no sprite then we just test our bounds.
		return worldExtents.containsWorldPoint(pos);
		
	}
}