package  {
	import flash.geom.ColorTransform;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import com.coreyoneil.collision.*;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.display.Stage;
	
	/**
	 * MotionBalls class name is actually a little misleading since it can create
	 * both static and moving balls. The class has methods for ball's translation and
	 * collision. Pixel-perfect collision is not supported by default in Flash, and is 
	 * done using an external library collisiondetectionkit (http://code.google.com/p/collisiondetectionkit/)
	 * @extends Ball (a MovieClip class created in .fla)
	 */
	public class MotionBalls extends Ball {
		
		private var speedX:Number;
		private var speedY:Number;
		
		private static var expandRadius:int = 100;   	// in pixels
		private var popTime:int = 6;   		 			// in seconds

		private var isStatic:Boolean = false; 			// can the ball move?
		private static var framesToExpand:int = 24;		// Frames to wait before expanding

		private static var speedChoices = [-4,-5,-3,3,5,4];	// different speed choices
		private static var colorChoices = [0xff0000,0x00ff00,0x0000ff,0xffff00,0x00ffff,0xff00ff];
		
		private var score:int;
		private var scoreText:TextField;
		
		// Note: Actionscript supports function overloading by providing keyword arguments
		// to a function (this is different from Java)
		public function MotionBalls(isStatic:Boolean=false, staticColor:int=0xd3d3d3,score:int=1) {
			var obj_color:ColorTransform;
			if (!isStatic) {
			  obj_color = new ColorTransform();
			  obj_color.color = colorChoices[int(Math.random()*colorChoices.length)];
			  this.transform.colorTransform = obj_color;
			  speedX = speedChoices[int(Math.random()*speedChoices.length)];
			  speedY = speedChoices[int(Math.random()*speedChoices.length)];
			} else {
				obj_color = new ColorTransform();
				obj_color.color = staticColor;
				this.transform.colorTransform = obj_color;
				this.isStatic = true;
				this.score = score;
				Game.updateScore(Math.pow(score,3)*100);
				this.scoreText = new TextField();
				this.alpha = 0.6;	// keep the expanded balls translucent
				// Start the timer
				var timer:Timer = new Timer(popTime*1000, 1);
				timer.addEventListener(TimerEvent.TIMER_COMPLETE, axeMe);
				timer.start();
				// Update life status 
				Game.updateLife(true);
			}
		}
		
		/**
		 * Removes the current MotionBall instance from the stage, triggered by 
		 * Timer event set in the object's constructor.
		 * @global_var stage (removes the current MotionBall instance)
		 * Note: Arrays work similar to Javascript here (more like Java ArrayList),
		 * and Python's List data-structure
		 */
		private function axeMe(e:TimerEvent):void {
			// Prepare to die (ha ha)
			Game.updateLife(false);
			stage.removeChild(this.scoreText);
			stage.removeChild(this);
			ChainReaction.balls.splice(ChainReaction.balls.indexOf(this),1);
		}
		
		public function getSpeedX():Number {
			return speedX;
		}
		
		public function getSpeedY():Number {
			return speedY;
		}
		
		public function setSpeedX(val:Number):void {
			speedX = val;
		}
		
		public function setSpeedY(val:Number):void {
			speedY = val;
		}
		
		/**
		 * Move the (non-static) balls by their speedX and speedY properties, and wraps them within the
		 * stage boundaries.
		 * @global_var setSpeedX, setSpeedY (may change speed in X and Y directions)
		 * Note: stage could be null sometimes, as the object may no longer exist (due to collision)
		 */
		public function translate():void {
			if (stage == null || this.isStatic)
				return;
			this.x += this.getSpeedX();
			this.y += this.getSpeedY();
			if (this.x <= this.width/2) {
				this.x = this.width/2;
				this.setSpeedX(-this.getSpeedX());
			} else if (this.x > stage.stageWidth-this.width/2) {
				this.x = 2*(stage.stageWidth-this.width/2)-this.x;
				this.setSpeedX(-this.getSpeedX());
			}
			if (this.y <= this.height/2) {
				this.y = this.height/2;
				this.setSpeedY(-this.getSpeedY());
			} else if (this.y > stage.stageHeight-this.height/2) {
				this.y = 2*(stage.stageHeight-this.height/2)-this.y;
				this.setSpeedY(-this.getSpeedY());
			}
		}
		
		/**
		 * Check collision uses collisiondetectionkit for detecting pixel-perfect collisions,
		 * something not supported out of box in flash. For the current ball, it detects if there
		 * is a collision with any of the static balls.
		 * @global_var stage (remove/add balls)
		 */
		public function checkCollision():void {
			if (this.isStatic) return;	// there is no effect of collision on static objects
			var staticBalls:Array = ChainReaction.balls.filter(filterBalls);
			var colList:CollisionList = new CollisionList(this);
			for (var i:int = 0; i < staticBalls.length; i++)
				colList.addItem(staticBalls[i]);
			var detectCol:Array = colList.checkCollisions();
			if (detectCol.length > 0) {
				// Get a new object now
				var oldScore:int  = Math.max(MotionBalls(detectCol[0].object2).score, MotionBalls(detectCol[0].object1).score);
				var b:MotionBalls = new MotionBalls(true, transform.colorTransform.color, oldScore+1);
				b.x = this.x;
				b.y = this.y;
				stage.addChild(b);
				b.setScoreText();
				ChainReaction.balls.push(b);
				// Axe this poor guy as well.
				stage.removeChild(this);
				ChainReaction.balls.splice(ChainReaction.balls.indexOf(this),1);
			}
		}
		
		// filters static balls from the balls Array
		static function filterBalls(element:MotionBalls, index:int, array:Array):Boolean {
			return element.isStatic;
		}
		
		// Called on every frame (this is bad. should be done instead using Timer event)
		public function animateExpansion():void {
			if (this.isStatic && this.width < expandRadius) {
			  this.width = Math.min(expandRadius, this.width+expandRadius/framesToExpand);
			  this.height = Math.min(expandRadius, this.height+expandRadius/framesToExpand);
			}
		}
		
		/**
		 * Sets the scoreText field based on the score for the ball
		 * @global_var score (read-only use)
		 * @global_var scoreText (creates TextField based on score field)
		 */
		public function setScoreText():void {
			if (scoreText != null && stage.contains(scoreText))
				stage.removeChild(this.scoreText);
			scoreText = new TextField();
			var fontSize:int = 12*Math.pow(stage.stageWidth/500, 1/3);
			scoreText.text = "+"+Math.pow(score,3)*100;
			scoreText.setTextFormat(new TextFormat("Arial",fontSize,0xffffff,true));
			scoreText.x = this.x - scoreText.textWidth/2;
			scoreText.y = this.y - scoreText.textHeight/2;
			stage.addChild(this.scoreText);
		}
		
		/**
		 * Reset the position of the static balls based on the stage dimensions.
		 * This is a class function, and modifies the scorefield position
		 */
		public static function resetStaticBalls():void {
			var staticBalls:Array = ChainReaction.balls.filter(filterBalls);
			for (var i:int = 0; i < staticBalls.length; i++) {
				staticBalls[i].x = staticBalls[i].stage.stageWidth*staticBalls[i].x/ChainReaction.getPreviousStageWidth();
				staticBalls[i].y = staticBalls[i].stage.stageHeight*staticBalls[i].y/ChainReaction.getPreviousStageHeight();
				MotionBalls(staticBalls[i]).setScoreText();
			}
		}
	}
}