/*******************************************************************************
 * Hydrax: haXe port of the PushButton Engine
 * Copyright (C) 2010 Dion Amago
 * For more information see http://github.com/dionjwa/Hydrax
 *
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package com.pblabs.components.scene.js;
import com.pblabs.components.scene.BaseScene2DComponent;
import com.pblabs.components.scene.BaseScene2DLayer;

class JSLayer <Scene :JSSceneManager<Dynamic>, Component :BaseScene2DComponent<Dynamic>> extends BaseScene2DLayer<Scene, Component>
#if js
{
	public var div (default, null) :js.Dom.HtmlDom;
	
	public function new ()
	{
		super();
	}
	
	// public function updateTransform () :Void
	// {
		
	// 	_transformDirty = false;
		
	// 	// Center it appropriately.
	// 	Preconditions.checkNotNull(_tempPoint);
	// 	Preconditions.checkNotNull(sceneAlignment);
	// 	Preconditions.checkNotNull(sceneView);
	// 	SceneUtil.calculateOutPoint(_tempPoint, sceneAlignment, sceneView.width, sceneView.height);
	// 	// _rootTransform.translate(_tempPoint.x, _tempPoint.y);

	// 	// Apply the transform.
	// 	// _rootSprite.transform.matrix = _rootTransform;
		
		
		
	// 	// var xOffset = parent.xOffset;
	// 	// var yOffset = parent.yOffset;
	// 	// var _position :Vector2;
	// // var _zoom :Float;
	// // var _rotation :Float;
	// // var _transformDirty :Bool;
	
	// // untyped _rootContainer.style.webkitTransform = "translate(" + (_position.x) + "px, " + (_position.y) + "px) scale(" + zoom + ") rotate(" + _rotation + "rad) translate(" + (_tempPoint.x) + "px, " + (_tempPoint.y) + "px)  ";
	// //Revsered
	// untyped _rootContainer.style.webkitTransform = "translate(" + (_tempPoint.x) + "px, " + (_tempPoint.y) + "px) rotate(" + _rotation + "rad) scale(" + zoom + ") translate(" + (_position.x) + "px, " + (_position.y) + "px)";
	// // untyped _rootContainer.style.webkitTransform = "translate(" + (_position.x) + "px, " + (_position.y) + "px) rotate(" + _rotation + "rad), scale(" + zoom + ")";
	// }
	
	public function fixPosition () :Void
	{
		com.pblabs.util.Assert.isNotNull(div, "div is null");
		
		//Make sure the layers have an adjusted offset
		var offsetHeight = 0;
		var offsetWidth = 0;
		var sib = div.previousSibling;
		while (sib != null || sib == div) {
			offsetHeight += sib.offsetHeight;
			offsetWidth += sib.offsetWidth;
			sib = sib.previousSibling;
		}
		untyped div.style.webkitTransform = "translate(0px, -" + offsetHeight + "px)";
	}
	
	override function addedToParent () :Void
	{
		super.addedToParent();
		//Add to the HtmlDom container
		parent.setLayerIndex(this, parent.getLayerIndex(this));
		fixPosition();
	}
	
	override function removingFromParent () :Void
	{
		super.removingFromParent();
		if (div.parentNode == parent.container) { 
			parent.container.removeChild(div);
		}
	}
	
	override function onRemove () :Void
	{
		super.onRemove();
		div = null;
	}
	
	override function onAdd () :Void
	{
		super.onAdd();
		div = cast js.Lib.document.createElement("div");
		div.style.cssText = "position:relative;left:0px;top:0px;";
	}
}
#else
{}
#end
