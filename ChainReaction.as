package  {
	import flash.display.MovieClip;
	import flash.display.StageScaleMode;
	import flash.display.Shape;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.ui.Mouse;
	
	/**
	 * This is the main controller class.
	 * @author: Siddharth Kothari
	 */
	public class ChainReaction extends MovieClip {
		
		static var balls:Array;						// Container for MotionBalls instances
		
		private var stripePadding:int = 30;			// Padding b/w background stipes
		private var darkStripeColor:int = 0x999999;	// Dark stripe color (dark shade of grey)
		private var lightStripeColor:int = 0x666666;// Light stripe color (light shade of grey)
		
		private var numberBalls:int = 20; 			// Number of balls to keep on the stage
		private var mousePointer:PointerBall;		// PointerBall extends MovieClip (defined in .fla)
		
		public function ChainReaction() {
			
			// The following two lines are necessary to create a fluid layout
			stage.scaleMode = StageScaleMode.NO_SCALE;	// We don't want stage to scale by itself
			stage.align = StageAlign.TOP_LEFT;			// top-left should be (0,0)
	
			drawBackground();							// We draw some stripes on the background
			
			// Add initial balls
			balls = new Array();
			var ball:MotionBalls;
			for (var i:int = 0; i < numberBalls; i++) {
			  ball = new MotionBalls();
			  ball.x = Math.random()*(stage.stageWidth-ball.width);   // place them at random locations
			  ball.y = Math.random()*(stage.stageHeight-ball.height); // place them at random locations
			  // Add balls to the stage
			  stage.addChild(ball);
			  balls.push(ball);
			}
	
			// Hide the actual mouse pointer, use PointerBall instance instead
			Mouse.hide();
			mousePointer = new PointerBall();
			stage.addChild(mousePointer);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, emulateMouse);
			stage.addEventListener(MouseEvent.CLICK, stopEmulation);
			stage.addEventListener(Event.RESIZE, resizeStage);
			stage.addEventListener(Event.ENTER_FRAME, duringEnterFrame);
		}
		
		/**
		 * Called by MOUSE_MOVE event listener. Updates position of global_var mousePointer
		 * based on actual mouse position
		 * @global_var mousePointer (modifies position)
		 */
		private function emulateMouse(e:MouseEvent):void {
			mousePointer.x = stage.mouseX;
			mousePointer.y = stage.mouseY;
		}
		
		/**
		 * Start the chain reaction, and restore the original mouse pointer
		 * Called by mouse click event listener
		 * @global_var stage (removes mousePointer and click listener)
		 */
		private function stopEmulation(e:MouseEvent):void {
			stage.removeChild(mousePointer);
			stage.removeEventListener(MouseEvent.CLICK, stopEmulation);
			var b:MotionBalls = new MotionBalls(true);
			b.x = stage.mouseX;
			b.y = stage.mouseY;
			stage.addChild(b);
			balls.push(b);
			Mouse.show();		// show the mouse now
		}
		
		/**
		 * Mundane tasks which would be executed on every frame.
		 * @global_var balls (modifies this variable)
		 */
		function duringEnterFrame(e:Event):void {
			for (var i:int = 0; i < balls.length; i++) {
				var b:MotionBalls = MotionBalls(balls[i]);
				b.animateExpansion();
				b.checkCollision();
				b.translate();
			}
		}
		
		/**
		 * Called by RESIZE event (this doesn't work when embedding swf in html),
		 * probably because html uses scrollbars
		 */
		private function resizeStage(e:Event):void {
			drawBackground();
		}
		
		/**
		 * Adds vertical and horizontal lines to the background canvas. Should be called
		 * at the start of the game and every time the screen is re-sized.
		 * @global_var stripePadding (read-only usage)
		 * @global_var darkStripeColor (read-only usage)
		 * @global_var stage (write use: add lines as direct children of stage)
		 */
		private function drawBackground():void {
			var line:Shape = new Shape();
			line.graphics.lineStyle(1, darkStripeColor, 0.8);
			for (var i:int = stripePadding; i < stage.stageWidth; i += stripePadding) {
				line.graphics.moveTo(i,0);
				line.graphics.lineTo(i,stage.stageHeight);
				stage.addChild(line);
				stage.setChildIndex(line, 0);	// Managing layers: It should be behind everything
			}
			for (i = stripePadding; i < stage.stageHeight; i += stripePadding) {
				line.graphics.moveTo(0, i);
				line.graphics.lineTo(stage.stageWidth,i);
				stage.addChild(line);
				stage.setChildIndex(line, 0);	// Managing layers: It shoudl be behind everything
			}
		}
	}
}
