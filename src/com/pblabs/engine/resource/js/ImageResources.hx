/*******************************************************************************
 * Hydrax: haXe port of the PushButton Engine
 * Copyright (C) 2010 Dion Amago
 * For more information see http://github.com/dionjwa/Hydrax
 *
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package com.pblabs.engine.resource.js;

import com.pblabs.engine.resource.ResourceBase;
import com.pblabs.util.Preconditions;
import com.pblabs.util.ReflectUtil;
import com.pblabs.util.StringUtil;
import com.pblabs.util.ds.Map;
import com.pblabs.util.ds.Maps;

/**
  * Javascript image loader.
  */
#if js
class ImageResources extends ResourceBase<js.Dom.Image>
{
	public function new (name :String, baseLoc :String, imageRefs :Array<String>)
	{
		super(name);
		_imageRefs = imageRefs;
		_images = Maps.newHashMap(ValueType.TClass(String));
		_baseLocation = baseLoc;
	}
	
	override public function load (onLoad :Void->Void, onError :Dynamic->Void) :Void
	{
		var self = this;
		var total = _imageRefs.length;
		var complete = 0;

		for (href in _imageRefs) {
			var image :js.Dom.Image = untyped __js__ ("new Image()");
			image.onload = function (_) {
				//Format the href to something friendly
				var key = href.split("/")[href.split("/").length - 1];
				key = key.split(".")[0];
				self._images.set(key, image);
				complete += 1;
				if (complete == total) {
					onLoad();
				}
			}
			image.onerror = function (_) {
				trace("Error loading image");
				onError("Error loading " + self._baseLocation + href);
			}
			image.src = _baseLocation+href;
		}
	}
	
	override public function get (?imageName :String) :js.Dom.Image
	{
		Preconditions.checkNotNull(imageName, "image name cannot be null");
		var srcImage = _images.get(imageName);
		Preconditions.checkNotNull(srcImage, "No image with key=" + imageName);
		var newImage :js.Dom.Image = untyped __js__ ("new Image()");
		newImage.src = srcImage.src;
		return newImage;
	}
	
	#if debug
	public function toString () :String
	{
		return "[ImageResources: " + _images + "]";
	}
	#end

	var _imageRefs :Array<String>;
	var _images :Map<String, js.Dom.Image>;
	var _baseLocation :String;
}
#else
class ImageResources extends ResourceBase<Dynamic>{}
#end
