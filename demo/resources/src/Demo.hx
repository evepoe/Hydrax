package ;

import com.pblabs.components.scene2D.BaseSceneComponent;
import com.pblabs.components.scene2D.BaseSceneLayer;
import com.pblabs.components.scene2D.ImageComponent;
import com.pblabs.components.scene2D.RectangleShape;
import com.pblabs.components.scene2D.SceneAlignment;
import com.pblabs.components.scene2D.SceneUtil;
import com.pblabs.components.scene2D.SceneView;
import com.pblabs.components.tasks.AngleTask;
import com.pblabs.components.tasks.FunctionTask;
import com.pblabs.components.tasks.LocationTask;
import com.pblabs.components.tasks.ParallelTask;
import com.pblabs.components.tasks.SerialTask;
import com.pblabs.engine.core.IEntity;
import com.pblabs.engine.core.NameManager;
import com.pblabs.engine.core.PBContext;
import com.pblabs.engine.core.PBGame;
import com.pblabs.engine.core.PBGameBase;
import com.pblabs.engine.core.SetManager;
import com.pblabs.engine.core.SignalBondManager;
import com.pblabs.engine.resource.IResourceManager;
import com.pblabs.engine.resource.ImageResource;
import com.pblabs.engine.resource.ResourceManager;
import com.pblabs.engine.resource.ResourceToken;
import com.pblabs.engine.resource.Source;
import com.pblabs.engine.time.IProcessManager;
import com.pblabs.engine.time.ProcessManager;
import com.pblabs.geom.Vector2;
import com.pblabs.util.Rand;
import com.pblabs.util.ds.Tuple;
using com.pblabs.components.scene2D.SceneUtil;
using com.pblabs.components.tasks.TaskUtil;
using com.pblabs.engine.util.PBUtil;

class Demo #if flash extends flash.display.Sprite #end 
{
	public function new() 
	{
		#if (flash || cpp)
		super();
		this.name = "Demo Template";
		#end
		
		com.pblabs.engine.debug.Log.setup();
		
		game = new PBGame();
		
		#if flash
		game.getManager(IResourceManager).addResource(new ImageResource("face", Source.url("../rsrc/face.png")));
		#elseif js
		game.getManager(IResourceManager).addResource(new ImageResource("face", Source.url("rsrc/face.png")));
		#end
		game.getManager(IResourceManager).load(startGame, function (e :Dynamic) {trace("Error loading: " + e);});
	}
	
	function startGame () :Void
	{
		var context :PBContext = game.pushContext(PBContext);
		
		//Scene for game elements
		var gamescene = context.createBaseScene();
		gamescene.sceneAlignment = SceneAlignment.TOP_LEFT;
		var backgroundlayer = gamescene.addLayer("background");
		var layer = gamescene.addLayer("defaultLayer");

		randMove(createImage("image", layer));
		randMove(createRect("rect", layer));
		
		gamescene.update();
	}
	
	function randMove (e :IEntity) :Void 
	{
		var sceneView = e.context.getManager(SceneView);
		var serial = new SerialTask();
		var parallel = new ParallelTask();
		var time = Math.random() * 5;
		time = Math.max(time, 2);
		var sceneComp = e.getComponent(BaseSceneComponent);
		com.pblabs.util.Assert.isNotNull(sceneComp);
		
		var minX = sceneComp.layer.scene.getAlignedPoint(SceneAlignment.TOP_LEFT).x;
		var maxX = sceneComp.layer.scene.getAlignedPoint(SceneAlignment.TOP_RIGHT).x;
		var minY = sceneComp.layer.scene.getAlignedPoint(SceneAlignment.TOP_RIGHT).y;
		var maxY = sceneComp.layer.scene.getAlignedPoint(SceneAlignment.BOTTOM_RIGHT).y;
		
		var targetX = Rand.nextFloatInRange(minX, maxX);
		var targetY = Rand.nextFloatInRange(minY, maxY);
		
		parallel.addTask(LocationTask.CreateSmooth(targetX,  targetY,  time));
		parallel.addTask(AngleTask.CreateLinear(Math.random() * 6, time));
		serial.addTask(parallel);
		var self = this;
		serial.addTask(new FunctionTask(function () :Void {
			self.randMove(e);
		}));
		e.addTask(serial);
	}
	
	function createRect (name :String, layer :BaseSceneLayer<Dynamic, Dynamic>) :IEntity
	{
		var context = layer.context;
		var e = context.createBaseSceneEntity();
		var c = context.allocate(RectangleShape);
		c.parentProperty = layer.entityProp();
		e.addComponent(c);
		e.initialize(name);
		return e;
	}
	
	function createImage (name :String, layer :BaseSceneLayer<Dynamic, Dynamic>) :IEntity
	{
		var context = layer.context;
		var e = context.createBaseSceneEntity();
		var c = context.allocate(ImageComponent);
		c.resource = cast new ResourceToken("face");
		c.parentProperty = layer.entityProp();
		e.addComponent(c);
		e.initialize(name);
		return e;
	}
	
	public static function main() 
	{
		new Demo();
	}
	
	var game :PBGameBase;
}
