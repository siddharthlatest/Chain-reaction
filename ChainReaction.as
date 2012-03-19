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
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flashx.textLayout.formats.TextAlign;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.ui.MouseCursor;
	
	/**
	 * This is the main controller class.
	 * @author: Siddharth Kothari
	 */
	public class ChainReaction extends MovieClip {
		
		static var balls:Array;						// Container for MotionBalls instances
		private static var lines:Sprite;			// Container for background lines
		
		private var stripePadding:int = 30;			// Padding b/w background stipes
		private var darkStripeColor:int = 0x666666;	// Dark stripe color (dark shade of grey)
		private var lightStripeColor:int = 0x999999;// Light stripe color (light shade of grey)
		
		private var numberBalls:int = 40; 			// Number of balls to keep on the stage
		private var mousePointer:PointerBall;		// PointerBall extends MovieClip (defined in .fla)
		
		private var msgbox:Sprite;
		
		private static var previousStageWidth:int;
		private static var previousStageHeight:int;
		
		public function ChainReaction() {
			
			// The following two lines are necessary to create a fluid layout
			stage.scaleMode = StageScaleMode.NO_SCALE;	// We don't want stage to scale by itself
			stage.align = StageAlign.TOP_LEFT;			// top-left should be (0,0)
	
			drawBackground();							// We draw some stripes on the background
			
			init();
			stage.addEventListener(Event.RESIZE, resizeStage);
			stage.addEventListener(Event.ENTER_FRAME, duringEnterFrame);
		}
		
		private function init(e:MouseEvent=null):void {
			if (e != null && stage.contains(msgbox)) {
				e.stopPropagation();		// don't propogate this event further
				stage.removeChild(msgbox);
				// remove all the balls
				for (var i:int = 0; i < balls.length; i++)
				  stage.removeChild(balls[i]);
				Game.reset();
				msgbox = null;
			}
			// Store height and width of stage
			previousStageWidth = stage.stageWidth;
			previousStageHeight = stage.stageHeight;
			trace("removed msgbox");
			// Add initial balls
			balls = new Array();
			var ball:MotionBalls;
			for (i = 0; i < numberBalls; i++) {
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
			mousePointer.x = stage.mouseX;
			mousePointer.y = stage.mouseY;
			stage.addChild(mousePointer);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, emulateMouse);
			stage.addEventListener(MouseEvent.CLICK, stopEmulation);
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
			b.setScoreText();
			balls.push(b);
			Mouse.show();		// show the mouse 
			stage.addEventListener(Event.REMOVED, checkGameEnd);
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
			trace("resize called "+stage.numChildren);
			drawBackground();
			MotionBalls.resetStaticBalls();
			if (msgbox != null)
				checkGameEnd(null);
			previousStageWidth = stage.stageWidth;
			previousStageHeight = stage.stageHeight;
		}
		
		/**
		 * Adds vertical and horizontal lines to the background canvas. Should be called
		 * at the start of the game and every time the screen is re-sized.
		 * @global_var stripePadding (read-only usage)
		 * @global_var darkStripeColor (read-only usage)
		 * @global_var stage (write use: add lines as direct children of stage)
		 */
		private function drawBackground():void {
			if (lines != null && stage.contains(lines)) {
				stage.removeChild(lines);
				lines = null;
			}
			lines = new Sprite();
			var line:Shape = new Shape();
			line.graphics.lineStyle(1, lightStripeColor, 0.8);
			for (var i:int = stripePadding; i < stage.stageWidth; i += stripePadding) {
				line.graphics.moveTo(i,0);
				line.graphics.lineTo(i,stage.stageHeight);
				lines.addChild(line);
			}
			for (i = stripePadding; i < stage.stageHeight; i += stripePadding) {
				line.graphics.moveTo(0, i);
				line.graphics.lineTo(stage.stageWidth,i);
				lines.addChild(line);
			}
			stage.addChild(lines);
			stage.setChildIndex(lines, 0);
		}
		
		/**
		 * Checks for game-end condition. If the game has ended, it displays
		 * a dialog box with score and a replay button
		 */
		private function checkGameEnd(e:Event=null):void {
			if (Game.isAlive())
				return;
			stage.removeEventListener(Event.REMOVED, checkGameEnd);
			if (msgbox != null && stage.contains(msgbox))
			 	stage.removeChild(msgbox);
        	// drawing a white rectangle
			msgbox = new Sprite();
        	msgbox.graphics.beginFill(lightStripeColor); // light-grey      
			msgbox.graphics.drawRect(stage.stageWidth/2-stage.stageWidth/6,stage.stageHeight/2-stage.stageHeight/8,stage.stageWidth/3, stage.stageHeight/4); // x, y, width, height
          	msgbox.graphics.endFill();
 
          	// drawing a black border
          	msgbox.graphics.lineStyle(4, 0x555555, 100);  // line thickness, line color (black), line alpha or opacity
          	msgbox.graphics.drawRect(stage.stageWidth/2-stage.stageWidth/6,stage.stageHeight/2-stage.stageHeight/8,stage.stageWidth/3, stage.stageHeight/4); // x, y, width, height
        
			// some text (for score)
          	var textfield:TextField = new TextField();
			var fontSize:int = 12*Math.sqrt(stage.stageWidth/500);
			textfield.text = "Final Score: "+Game.gameScore();
		  	textfield.setTextFormat(new TextFormat("Arial",fontSize,darkStripeColor,true,null,null,null,null,"center",0,0));
			textfield.width = stage.stageWidth/3;
			textfield.x = stage.stageWidth/2-textfield.width/2;
		  	textfield.y = stage.stageHeight/2-stage.stageHeight/16;
			
			// A play again option
			var playAgain:Replay = new Replay();
			playAgain.width = stage.stageHeight/9;
			playAgain.height = stage.stageHeight/9;
			playAgain.x = stage.stageWidth/2;
			playAgain.y = textfield.y+textfield.textHeight+stage.stageHeight/72+playAgain.height/2;
			playAgain.addEventListener(MouseEvent.CLICK,init);
			playAgain.addEventListener(MouseEvent.ROLL_OVER, cursorAsHand);
			playAgain.addEventListener(MouseEvent.ROLL_OUT, cursorAsArrow);
			msgbox.addChild(textfield);
			msgbox.addChild(playAgain);
          	stage.addChild(msgbox);
		}
		
		private function cursorAsHand(e:MouseEvent):void {
			Mouse.cursor = MouseCursor.HAND;
		}
		
		private function cursorAsArrow(e:MouseEvent):void {
			Mouse.cursor = MouseCursor.ARROW;
		}
		
		public static function getPreviousStageWidth():int {
			return previousStageWidth;
		}
		
		public static function getPreviousStageHeight():int {
			return previousStageHeight;
		}
	}
}
