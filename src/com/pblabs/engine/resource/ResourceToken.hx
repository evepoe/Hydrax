package com.pblabs.engine.resource;

import com.pblabs.engine.core.IPBContext;

class ResourceToken<T>
{
	public var resourceId :String;
	public var key :String;
	
	public function new (resourceId :String, ?key :String = null)
	{
		this.resourceId = resourceId;
		this.key = key;
	}
	
	public function create (context :IPBContext) :T
	{
	    var rm = context.getManager(IResourceManager);
	    com.pblabs.util.Assert.isNotNull(rm);
	    return rm.create(this);
	}
	
	public function toString () :String
	{
	    return resourceId + "." + key;
	}
}