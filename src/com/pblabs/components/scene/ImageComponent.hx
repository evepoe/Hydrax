/*******************************************************************************
 * Hydrax: haXe port of the PushButton Engine
 * Copyright (C) 2010 Dion Amago
 * For more information see http://github.com/dionjwa/Hydrax
 *
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package com.pblabs.components.scene;

import com.pblabs.components.input.IInteractiveComponent;
import com.pblabs.engine.core.ObjectType;
import com.pblabs.engine.resource.IResource;
import com.pblabs.engine.resource.IResourceManager;
import com.pblabs.engine.resource.ImageResource;
import com.pblabs.engine.resource.ResourceToken;
import com.pblabs.geom.RectangleTools;
import com.pblabs.util.Preconditions;
import com.pblabs.util.StringUtil;

import de.polygonal.motor2.geom.math.XY;

using com.pblabs.components.scene.SceneUtil;

/**
  * Cross platform Image using Scene2D component.
  */
class ImageComponent 
#if css
extends com.pblabs.components.scene.js.css.Base2DComponent
#elseif js
extends com.pblabs.components.scene.js.canvas.Canvas2DComponent
#elseif (flash || cpp)
extends com.pblabs.components.scene.flash.Scene2DComponent  
#end
 {
	/** The IResource name and item id.  Id can be null */
	#if flash
	public var resource :ResourceToken<flash.display.DisplayObject>;
	#elseif js
	public var resource :ResourceToken<js.Dom.Image>;
	#end
	
	#if (js && !css)
	public var displayObject (default, set_displayObject) :js.Dom.Image;
	function set_displayObject (val :js.Dom.Image) :js.Dom.Image
	{
		this.displayObject = val;
		return val;
	}
	override public function draw (ctx :easel.display.Context2d) :Void
	{
		ctx.drawImage(displayObject, -displayObject.width / 2, -displayObject.height / 2);
	}
	#end
	
	public function new () :Void
	{
		super();
	}
	
	#if debug
	public function toString () :String
	{
		return StringUtil.objectToString(this, ["x", "y", "_width", "_height"]);
	}
	#end
	
	override function onAdd () :Void
	{
		com.pblabs.util.Assert.isNotNull(resource, "resource is null for #" + owner.name + "." + name);
		
		#if js
		//Get the DomResource, this makes sure the inline image is loaded
		var image :js.Dom.Image = resource.create(context);//context.getManager(IResourceManager).create(resourceToken.v1, resourceToken.v2);
		Preconditions.checkNotNull(image, "image from resource is null " +resource);
		displayObject = image;
		super.onAdd();
		#elseif (flash || cpp)
		var image :flash.display.DisplayObject = resource.create(context);//context.getManager(IResourceManager).create(resourceToken.v1, resourceToken.v2);
		_displayObject = image;
		super.onAdd();
		#end
		
		com.pblabs.util.Assert.isNotNull(image, "Image loaded from " + resource + " is null");
		
		#if css
		_width = image.width;
		_height = image.height;
		div.appendChild(displayObject);
		#elseif (flash || cpp)
		
		updateTransform();
		#end
	}
	
	#if css
	override public function onFrame (dt :Float) :Void
	{
		if (isTransformDirty) {
			isTransformDirty = false;
			var xOffset = parent.xOffset - width / 2;
			var yOffset = parent.yOffset - height / 2;
			untyped div.style.webkitTransform = "translate(" + (_x + xOffset) + "px, " + (_y + yOffset) + "px) rotate(" + _angle + "rad)";
		}
	}
	
	override function set_width (val :Float) :Float
	{
		if (displayObject != null) { 
			displayObject.setAttribute("width", val + "px");
		}
		return super.set_width(val);
	}
	
	override function set_height (val :Float) :Float
	{
		if (displayObject != null) {
			displayObject.setAttribute("height", val + "px");
		}
		return super.set_height(val);
	}
	#end
}
