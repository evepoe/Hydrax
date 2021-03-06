/*******************************************************************************
 * Hydrax: haXe port of the PushButton Engine
 * Copyright (C) 2010 Dion Amago
 * For more information see http://github.com/dionjwa/Hydrax
 *
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package com.pblabs.components.scene2D;
import com.pblabs.geom.RectangleTools;
import com.pblabs.geom.Vector2;
import com.pblabs.util.StringUtil;

using com.pblabs.components.scene2D.SceneUtil;

class RectangleShape extends ShapeComponent
{
	public function new (?w :Float = 20, ?h :Float = 20)
	{
		super();
		#if js
		_rect = cast js.Lib.document.createElement("div");
		div.appendChild(_rect);
		#end
		_unscaledBounds.xmin = -w / 2;
		_unscaledBounds.xmax = w / 2;
		_unscaledBounds.ymin = -h / 2;
		_unscaledBounds.ymax = h / 2;
		_bounds = _unscaledBounds.clone();
		redraw();
	}
	
	// /** Don't scale, rather resize and redraw */
	override public function updateTransform () :Void
	{
		if (!isTransformDirty) {
			return;
		}
		_transformMatrix.identity();
		_transformMatrix.translate(-registrationPoint.x, - registrationPoint.y);
		_transformMatrix.rotate(_angle + _angleOffset);
		_transformMatrix.translate(_x + _locationOffset.x, _y + _locationOffset.y);
		
		#if flash
		_displayObject.transform.matrix = _transformMatrix;
		_displayObject.alpha = _alpha;
		_displayObject.visible = (alpha > 0);
		#end
		
		isTransformDirty = false;
	}
	
	override function onAdd () :Void
	{
		super.onAdd();
		context.getManager(com.pblabs.engine.time.IProcessManager).callLater(redraw);
	}
	
	override function onReset () :Void
	{
		super.onReset();
		redraw();
	}
	
	override function redraw () :Void
	{
		#if (flash || cpp)
		var zoom = parent != null && parent.parent != null ? parent.parent.zoom : 1.0;
		var g = cast(_displayObject, flash.display.Shape).graphics;
		g.clear();
		g.beginFill(this.fillColor, 1);
		g.drawRect(0, 0, width, height);
		g.endFill();
		g.lineStyle(borderStroke, borderColor, 1.0);
		g.drawRect(0, 0, width - borderStroke, height - borderStroke);
		#elseif js
		trace('StringUtil.toColorString(fillColor, "#")=' + StringUtil.toColorString(fillColor, "#"));
		_rect.style.cssText = "opacity:" +alpha + ";left:0px;top:0px;width:" + width + "px; height:" + height + "px; background-color:" + StringUtil.toColorString(fillColor, "#") + "; border-color:" + StringUtil.toColorString(borderColor, "#") + "; border-style:solid; border-width:" + borderStroke + "px";
		#end
		registrationPoint = new Vector2(width / 2, height / 2);
	}
	
	#if js
	override public function draw (ctx :easel.display.Context2d)
	{
		ctx.fillStyle = StringUtil.toColorString(fillColor, "#");
		ctx.fillRect(0, 0, width, height);
		if (borderStroke > 0) {
			ctx.strokeStyle = StringUtil.toColorString(borderColor, "#");
			ctx.lineWidth = borderStroke;
			ctx.beginPath();
			ctx.rect(0, 0, width, height);
			ctx.stroke();
		}
	}
	
		override function set_width (val :Float) :Float
	{
		com.pblabs.util.Assert.isTrue(val >= 0, "val=" + val + " " + com.pblabs.util.Log.getStackTrace());
		var unscaledWidth = val / _scaleX;
		_unscaledBounds.xmin = _x - unscaledWidth / 2;
		_unscaledBounds.xmax = _x + unscaledWidth / 2;
		_bounds.xmin = _x - val / 2;
		_bounds.xmax = _x + val / 2;
		_scaleX = val / unscaledWidth; 
		isTransformDirty = true;
		redraw();
		return val;
	}
	
	override function set_height (val :Float) :Float
	{
		com.pblabs.util.Assert.isTrue(val >= 0, "val=" + val + " " + com.pblabs.util.Log.getStackTrace());
		var unscaledHeight = val / _scaleY;
		_unscaledBounds.ymin = _y - unscaledHeight / 2;
		_unscaledBounds.ymax = _y + unscaledHeight / 2;
		_bounds.ymin = _y - val / 2;
		_bounds.ymax = _y + val / 2;
		_scaleY = val / unscaledHeight;
		isTransformDirty = true;
		redraw();
		return val;
	}
	
	var _rect :js.Dom.HtmlDom;
	#end
}
