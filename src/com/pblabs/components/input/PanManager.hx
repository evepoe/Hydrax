package com.pblabs.components.input;

import com.pblabs.components.Constants;
import com.pblabs.components.input.InputManager;
import com.pblabs.components.scene.BaseSceneComponent;
import com.pblabs.components.scene.BaseSceneManager;
import com.pblabs.components.scene.SceneUtil;
import com.pblabs.components.spatial.SpatialComponent;
import com.pblabs.components.tasks.AnimatePropertyTask;
import com.pblabs.components.tasks.TaskComponent;
import com.pblabs.components.tasks.TaskComponentTicked;
import com.pblabs.engine.core.EntityComponent;
import com.pblabs.engine.core.IEntity;
import com.pblabs.engine.core.IEntityComponent;
import com.pblabs.engine.core.IPBManager;
import com.pblabs.engine.core.PropertyReference;
import com.pblabs.engine.time.IAnimatedObject;
import com.pblabs.engine.time.IProcessManager;
import com.pblabs.geom.Vector2;
import com.pblabs.util.Preconditions;
import com.pblabs.util.ReflectUtil;
import com.pblabs.util.ds.Tuple;

import de.polygonal.motor2.geom.math.XY;

import haxe.Timer;

import hsl.haxe.DirectSignaler;
import hsl.haxe.Signaler;

using com.pblabs.components.scene.SceneUtil;
using com.pblabs.components.tasks.TaskUtil;
using com.pblabs.engine.util.PBUtil;
using com.pblabs.geom.VectorTools;
using com.pblabs.util.IterUtil;
using com.pblabs.util.MathUtil;
using com.pblabs.util.NumberUtil;

typedef Translatable = {
	public var x (get_x, set_x) :Float;
	public var y (get_y, set_y) :Float;
}

/**
  * Handles panning of a Scene and components.
  */
class PanManager extends EntityComponent, 
	implements IPBManager, implements haxe.rtti.Infos
{
	public var dragSignaler :Signaler<BaseSceneComponent<Dynamic>>;
	
	/** When panning stops, does the scene ease out? */
	// public var defaultEasing (get_defaultEasing, set_defaultEasing) :Bool;
	// public var _isEasing :Bool;
	
	/** Easing will only occur if the last <frameWindowSize> frames had a device dragging distance at least this. */
	public var minimumDistanceToEase :Float;
	/** The number of most recent frames to analyse angles and  minimumDistanceToEase*/
	public var frameWindowSize :Int;
	/** The time (in seconds) for scene easing */
	public var timeToHalt :Float;
 
	var isPanning (get_isPanning, set_isPanning) :Bool;
	var _scene :BaseSceneManager<Dynamic>;
	var _sceneComponent :BaseSceneComponent<Dynamic>;
	var _panVectors :Array<XY>;
	var _lastMouseMove :XY;
	var _isPanning :Bool;
	var _isGesturing :Bool;
	var _timer :Timer;
	var _isEasing :Bool;
	/** If there are too many frames without movement, no easing will occur. */
	var _framesWithoutMovement :Int;
	/** If panning slows rendering too much, you can pause the game while panning. */
	var _pauseProcessManagerOnPan :Bool;
	var _inputManager :InputManager;
	var _startMouse :XY;
	var _startObj :XY;
	var _xProp :PropertyReference<Float>;
	var _yProp :PropertyReference<Float>;
	
	public function new ()
	{
		super();
		dragSignaler = new DirectSignaler(this);
		_startMouse = new Vector2();
		_startObj = new Vector2();
		
		_isEasing = true;
		_isPanning = false;
		_isEasing = false;
		_panVectors = [];
		minimumDistanceToEase = 40;
		frameWindowSize = 8;
		timeToHalt = 1.0;
		_pauseProcessManagerOnPan = true;
		_framesWithoutMovement = 0;
	}
	
	public function startup():Void
	{
		var e = context.allocate(IEntity);
		e.initialize(ReflectUtil.tinyClassName(Type.getClass(this)));
		e.deferring = true;
		e.addComponent(this);
		e.addComponent(context.allocate(TaskComponentTicked), TaskComponent.NAME);
		e.deferring = false;
		
		_inputManager = context.getManager(InputManager);
		com.pblabs.util.Assert.isNotNull(_inputManager);
	}
	
	public function shutdown():Void
	{
		if (isRegistered) {
			owner.destroy();
		}
	}
	
	public function panScene (scene :BaseSceneManager<Dynamic>, ?easing :Bool = true, ?pauseScene :Bool = false) :Void
	{
		endPanning();
		_isEasing = easing;
		_pauseProcessManagerOnPan = pauseScene;
		Preconditions.checkNotNull(scene);
		_scene = scene;
		_sceneComponent = null;
		
		_xProp = null;
		_yProp = null;
		beginPanning();
	}
	
	public function panComponent (c :BaseSceneComponent<Dynamic>, ?easing :Bool = false, ?pauseScene :Bool = false, 
		?xProp :PropertyReference<Float> = null, ?yProp :PropertyReference<Float> = null) :Void
	{
		endPanning();
		_isEasing = easing;
		_pauseProcessManagerOnPan = pauseScene;
		Preconditions.checkNotNull(c);
		_sceneComponent = c;
		_scene = null;//c.layer.scene;
		
		_xProp = xProp;
		_yProp = yProp;
		
		//Guess the properties if null
		if (_xProp == null || _yProp == null) {
			//Maybe coordinates?
			if (_sceneComponent.owner.lookupComponent(SpatialComponent) != null) {
				_xProp = Constants.DEFAULT_X_PROP;
				_yProp = Constants.DEFAULT_Y_PROP;
			}
		}
		
		if (_xProp == null || _yProp == null) {
			_xProp = _sceneComponent.componentProp("x");
			_yProp = _sceneComponent.componentProp("y");
		}
		
		com.pblabs.util.Assert.isNotNull(_xProp);
		com.pblabs.util.Assert.isNotNull(_yProp);
		
		_startObj.x = _sceneComponent.owner.getProperty(_xProp);
		_startObj.y = _sceneComponent.owner.getProperty(_yProp);
		
		beginPanning();
	}
	
	function beginPanning () :Void
	{
		if (isPanning) {
			return;
		}
		owner.removeAllTasks();
		isPanning = true;
		_panVectors = [_inputManager.inputLocation.clone()];
		_framesWithoutMovement = 0;
		_inputManager.deviceMove.bind(onDeviceMove);
		_inputManager.deviceUp.bind(onDeviceUp);
		_startMouse.x = _inputManager.inputLocation.x;
		_startMouse.y = _inputManager.inputLocation.y;
	}
	
	public function endPanning () :Void
	{
		if (!isPanning) {
			return;
		}
		_inputManager.deviceMove.unbind(onDeviceMove);
		_inputManager.deviceUp.unbind(onDeviceUp);
		isPanning = false;
		_isEasing = false;
		_scene = null;
		_sceneComponent = null;
	}
	
	override function onRemove () :Void
	{
		super.onRemove();
		endPanning();
		_inputManager = null;
	}
	
	function onDeviceMove (e :IInputData) :Void
	{
		_lastMouseMove = e.inputLocation;
		if (isPanning) {
			if (_isEasing) {
				_framesWithoutMovement = Std.int(Math.max(_framesWithoutMovement - 1, 0));
			}
			if (_sceneComponent == null) {//Pan the scene
				var diff = e.inputLocation.subtract(_panVectors[_panVectors.length - 1]);
				diff.scaleLocal(1 / _scene.zoom);
				diff.rotateLocal(-_scene.rotation);
				// _panAngles.push(diff.angle());
				_scene.x += diff.x;
				_scene.y += diff.y;
				if (dragSignaler.isListenedTo) {
					dragSignaler.dispatch(null);
				}
				
			} else {//Pan the scene component
				var worldStart = SceneUtil.translateScreenToWorld(_sceneComponent.layer.parent, _startMouse);
				var worldNow = SceneUtil.translateScreenToWorld(_sceneComponent.layer.parent, e.inputLocation);
				var worldDiff = worldNow.subtract(worldStart);
				_sceneComponent.owner.setProperty(_xProp, _startObj.x + worldDiff.x);
				_sceneComponent.owner.setProperty(_yProp, _startObj.y + worldDiff.y);
				
				// var world = _scene.translateScreenToWorld(e.inputLocation);
				// _sceneComponent.x = world.x;
				// _sceneComponent.y = world.y;
				if (dragSignaler.isListenedTo) {
					dragSignaler.dispatch(_sceneComponent);
				}
			}
			if (_pauseProcessManagerOnPan && _scene != null) {
				if (Std.is(_scene, IAnimatedObject)) {
					cast(_scene, IAnimatedObject).onFrame(0);
				}
			}
			if (_isEasing) {
				_panVectors.push(e.inputLocation.clone());
			}
			
		}
	}
	
	function onDeviceUp (e :IInputData) :Void
	{
		if (isPanning) {
			if (_isEasing && _framesWithoutMovement < 3 && _scene != null) {
				//Most recent window of [frameWindowSize] mouse locations
				var lastVectors = _panVectors.length > frameWindowSize ? _panVectors.slice(_panVectors.length - frameWindowSize) : _panVectors;
				var mostRecent = lastVectors[lastVectors.length - 1];
				//Distance between first and last vector within the window
				var diff = lastVectors[lastVectors.length - 1].distance(lastVectors[0]);
				//Most recent at the end of the array
				var oldest = lastVectors[0];
				//For computing the mean angle, use the mean unit vector
				var meanVector = new Vector2();
				com.pblabs.util.Assert.isNotNull(_scene);
				if (diff > minimumDistanceToEase) {
					var angles = [];
					for (i in 1...lastVectors.length) {
						var unit = lastVectors[i - 1].angleTo(lastVectors[i]).angleToVector2();
						angles.push(unit.angle.toFixed(3));
						meanVector.x += unit.x;
						meanVector.y += unit.y;
					}
					meanVector.x /= _panVectors.length;
					meanVector.y /= _panVectors.length;
					var toAdd = meanVector.angle.angleToVector2(diff / 3);
					toAdd.scaleLocal(1 / _scene.zoom);
					toAdd.rotateLocal(-_scene.rotation);
					var currentScene = new Vector2(_scene.x,_scene.y); 
					var finalStop = currentScene.add(toAdd);
	
					//The bigger the distance to move, the longer it takes
					var comp :IEntityComponent = _scene;
					var easeX = AnimatePropertyTask.CreateEaseOut(comp.entityProp("x"), finalStop.x, timeToHalt);
					var easeY = AnimatePropertyTask.CreateEaseOut(comp.entityProp("y"), finalStop.y, timeToHalt);
					owner.addTask(easeX);
					owner.addTask(easeY);
				}
			}
			endPanning();
		}
		#if testing
		js.Lib.document.getElementById("haxe:test2").innerHTML = "pan onDeviceUp: _fingersDown=" + e.touchCount + ", _isEasing=" + _isEasing + ", isPanning=" + isPanning;
		#end
	}
	
	inline function get_isPanning () :Bool
	{
		return _isPanning;
	}
	
	function set_isPanning (val :Bool) :Bool
	{
		if (_isPanning == val) {
			return val;
		}
		_isPanning = val;
		if (_isPanning) {
			context.getManager(IProcessManager).isRunning = !(_pauseProcessManagerOnPan && _scene != null); 
		} else {
			context.getManager(IProcessManager).isRunning = true;
		}
		if (_isPanning) {
			_timer = new Timer(Std.int(1000/30));
			_timer.run = notMoving;
		} else {
			if (_timer != null) {
				_timer.stop();
			}
			_timer = null;
		}
		return val;
	}
	
	function notMoving () :Void
	{
		_framesWithoutMovement++;
	}
}
