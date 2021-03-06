/*******************************************************************************
 * Hydrax: haXe port of the PushButton Engine
 * Copyright (C) 2010 Dion Amago
 * For more information see http://github.com/dionjwa/Hydrax
 *
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package com.pblabs.engine.resource;

import com.pblabs.engine.resource.IResource;

import com.pblabs.util.StringUtil;

/**
  * Base class for extending to more specific Resource types.
  */
class ResourceBase<T>
	implements IResource<T> 
{
	public var name (get_name, never) :String;
	
	public function new (name :String)
	{
		_name = name;
		_isLoaded = false;
	}
	
	public function get (?name :String) :T
	{
		//Subclasses must override this to be useful.
		throw "Override";
		return null;
	}
	
	public function load (onLoad :Void->Void, onError :Dynamic->Void) :Void
	{
		_onLoad = onLoad;
		_onError = onError;
	}
	
	public function unload () :Void
	{
		_onLoad = null;
		_onError = null;
		_isLoaded = false;
	}
	
	public function isLoaded () :Bool
	{
		return _isLoaded;
	}
	
	function get_name () :String
	{
		return _name;
	}
	
	function loaded () :Void
	{
		_isLoaded = true;
		_onLoad();
		_onLoad = null;
		_onError = null;
	}

	var _name :String;
	var _onLoad :Void->Void;
	var _onError :Dynamic->Void;
	var _isLoaded :Bool;
	
	#if debug
	public function toString () :String
	{
		return StringUtil.objectToString(this, ["name"]);
	}
	
	#end
	
	// #if (editor || debug)
	// public function reload (onLoad :Void->Void, onError :Dynamic->Void) :Void
	// {
	// 	unload();
	// 	load(onLoad, onError);
	// }
	// #end
}


