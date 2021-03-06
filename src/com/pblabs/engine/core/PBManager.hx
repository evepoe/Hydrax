package com.pblabs.engine.core;

/**
  * Very basic IPBManager base class, used by contexts.
  */
class PBManager
	implements IPBManager, implements de.polygonal.ds.Hashable
{
	/** Key for hashing. Don't modify. */
	public var key :Int;
	
	@inject("com.pblabs.engine.core.IPBContext")
	var context :IPBContext;
	
	public function new () 
	{
		key = com.pblabs.engine.util.PBUtil.KEY_COUNT++;
	}
	
	public function startup () :Void
	{
		com.pblabs.util.Assert.isNotNull(context, "context is null, failed injection?");
	}
	
	public function shutdown () :Void
	{
		//Remove signals bound to this manager.
		if (context.getManager(SignalBondManager) != null) {
			context.getManager(SignalBondManager).destroyBonds(this);
		}
	    context = null;
	}
}
