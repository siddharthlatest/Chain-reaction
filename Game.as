package  {
	
	/**
	 * Game class keeps track of score updates and the game end condition
	 */
	public class Game {

		private static var alive:int = 0;
		private static var score:int = 0;
		public function Game() {
			// constructor code
		}
		
		public static function reset():void {
			alive = 0;
			score = 0;
		}
		
		public static function isAlive():Boolean {
			if (alive) 
				return true;
			return false;
		}
		
		public static function updateLife(add:Boolean) {
			if (add)
				alive += 1;
			else 
				alive -= 1;
		}
		
		public static function updateScore(score:int) {
			Game.score += score;
		}
		
		public static function gameScore():int {
			return score;
		}
	}
	
}
