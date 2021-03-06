/*******************************************************************************
 * Hydrax: haXe port of the PushButton Engine
 * Copyright (C) 2010 Dion Amago
 * For more information see http://github.com/dionjwa/Hydrax
 *
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package com.pblabs.util;


import haxe.rtti.CType;

using Lambda;

/**
  * Will get/set fields with accessor methods, as long as 
  * the accessor methods are formatted get_xY, set_xY, where
  * xY is the variable.
  */
class ReflectUtil
{
	static var cacheXml = new Hash<Xml>();
	static var cacheClassdef = new Hash<Classdef>();
	// static var classDefParser = new haxe.rtti.XmlParser();
	static var fieldTypes = new Hash<CType>();
	
	public static function tinyClassName (obj :Dynamic) :String
	{
		return tinyName(Type.getClass(obj));
	}
	
	inline public static function tinyName (cls :Class<Dynamic>) :String
	{
		#if debug
		com.pblabs.util.Assert.isNotNull(cls);
		var name = Type.getClassName(cls);
		com.pblabs.util.Assert.isNotNull(name, "null class name from class object");
		var tokens = name.split(".");
		return tokens[tokens.length - 1];
		#else
		var tokens = Type.getClassName(cls).split(".");
		return tokens[tokens.length - 1];
		#end
	}
	
	public static function getClassName (obj :Dynamic) :String
	{
		return Type.getClassName(getClass(obj));
	}
	
	public static function isSameClass (obj1 :Dynamic, obj2 :Dynamic) :Bool
	{
		return getClass(obj1) == getClass(obj2);
	}
	
	public static function hasStaticMetadata (cls :Class<Dynamic>, field :String, metaId :String) :Bool
	{
		var m = haxe.rtti.Meta.getStatics(cls);
		if (m != null) {
			if (Reflect.hasField(m, field)) {
				return Reflect.hasField(Reflect.field(m, field), metaId);
			}
		} 
		return false;
	}
	
	/** Alt Std.is implementation for cpp while Std.is bug exists */
	public static function is (instance :Dynamic, type :String) :Bool
	{
		var cls = getClass(instance);
		while (cls != null) {
			var classdef = getClassdef(cls);
			if (classdef != null) {
				if (classdef.path == type) {
					return true;
				}
				for (i in classdef.interfaces) {
					if (i.path == type) {
						return true;
					}
				}
			} else {
				com.pblabs.util.Log.error("ReflectUtil.is called, but the type has no rtti info: " + Type.getClassName(cls) + " is " + type + "?");
				return false;
			}
			cls = Type.getSuperClass(cls);
		}
		return false;
	}
	
	public static function hasSuperClass (cls :Class<Dynamic>, superClass :Class<Dynamic>) :Bool
	{
		var sc = Type.getSuperClass(cls);
		while (sc != null) {
			if (superClass == sc) {
				return true;
			}
			sc = Type.getSuperClass(sc);
		}
		return false;
	}
	
	public static function getClass (obj :Dynamic) :Class<Dynamic>
	{
		switch (Type.typeof(obj)) {
			case TUnknown:
				throw "Unknown map key type";
			case TObject:
				//Assume obj is a class or interface 
				return obj;
			case TNull:
				return null;
			case TInt:
				return Int;
			case TFunction:
				return null;
			case TFloat:
				return Float;
			case TEnum(e):
				return null;
			case TClass(c):
				return c;
			case TBool:
				return null;
		}
	}
	
	public static function getRttiXml(cls : Class <Dynamic> ) :Xml
	{
		var name = Type.getClassName(cls);
		if (cacheXml.exists(name)) {
			return cacheXml.get(name);
		}
		// #if cpp
		// //If you don't check for the field first, in cpp an error is thrown.
		// if (!Type.getClassFields(cls).has("__rtti")) {//untyped cls.__rtti == null
		// 	cacheXml.set(name, null);
		// 	return null;
		// }
		// #end
		var rtti = Reflect.field(cls, "__rtti");
		if (rtti == null) {
			cacheXml.set(name, null);
			return null;
		}
		
		var x = Xml.parse(rtti).firstChild();//untyped cls.__rtti
		cacheXml.set(name, x);
		return x;
	}
	
	public static function getClassdef (cls : Class< Dynamic>) :Classdef
	{
		var name = Type.getClassName(cls);
		if (cacheClassdef.exists(name)) {
			return cacheClassdef.get(name);
		}
		var x :Xml = getRttiXml(cls);
		if (x == null) {
			return null;
		}

		var typeTree = new haxe.rtti.XmlParser().processElement(x);
		
		var cdef :Classdef = switch (typeTree) {
			case TClassdecl(c): c;
			default: null;
		}
		
		cacheClassdef.set(name, cdef);
		return cdef;
	}
	
	public static function getFieldType (cls : Class< Dynamic>, field :String) :CType
	{
		var id = Type.getClassName(cls) + "." + field;
		if (fieldTypes.exists(id)) {
			return fieldTypes.get(id);
		}
		
		var cdef :Classdef = getClassdef(cls);
		if (cdef == null) {
			return null;
		}
		
		for (f in cdef.fields) {
			if (f.name == field) {
				fieldTypes.set(id, f.type);
				return f.type;
			}
		}
		
		var sp = Type.getSuperClass(cls);
		var type = if (sp == null) null else getFieldType(sp, field);
		fieldTypes.set(id, type);
		return type;
	}
	
	public static function getVarFieldType (cls : Class< Dynamic>, field :String) :Class<Dynamic>
	{
		var type = getFieldType(cls, field);
		if (type != null) {
			switch (type) {
				case CClass(name, params):
				return Type.resolveClass(name);
				default:
				Log.error(getClassName(cls) + "." + field + " is not a class var");
				return null;
			}
		}
		Log.error("No rtti for " + getClassName(cls));
		return null;
	}
	
	public static function field (obj :Dynamic, field :String) :Dynamic
	{
		if (Lambda.has(Type.getInstanceFields(Type.getClass(obj)), "get_" + field)) {
		//Probably faster, but sometimes doesn't work
		// if (Reflect.field(obj, "get_" + field) != null) {cg
			return Reflect.callMethod(obj, Reflect.field(obj, "get_" + field), EMPTY_ARRAY);
		} else {
			return Reflect.field(obj, field);
		}
	}
	
	public static function setField (obj :Dynamic, field :String, val :Dynamic) :Void
	{
		// if (Reflect.field(obj, "set_" + field) != null) {
		if (Reflect.hasField(obj, "set_" + field)) {
			Reflect.callMethod(obj, Reflect.field(obj, "set_" + field), [val]);
		} else {
			Reflect.setField(obj, field, val);
		}
	}
	
	static var EMPTY_ARRAY :Array<Dynamic> = new Array();
}


