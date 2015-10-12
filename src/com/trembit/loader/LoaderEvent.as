package com.trembit.loader
{
	import flash.events.Event;
	
	public class LoaderEvent extends Event
	{
		public static const COMPLETE_LOAD_ITEM : String = "COMPLETE_LOAD_ITEM";
		public static const LOADING_INTERRUPTED_BY_USER : String = "LOADING_INTERRUPTED_BY_USER";
		
		public static const PROGRESS_LOAD_ITEM : String = "PROGRESS_LOAD_ITEM";
		
		public static const FILE_EXISTS:String = "FILE_EXISTS";
		public static const FILE_NOT_FOUND:String = "FILE_NOT_FOUND";
		
		public var itemName : String;
		public var progress : Number;
		
		public function LoaderEvent(type:String, itemName : String = "", bubbles:Boolean=false, cancelable:Boolean=false, progress : Number = 0) {
			this.itemName = itemName;
			this.progress = progress;
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event { 
			return new LoaderEvent(this.type, this.itemName, this.bubbles, this.cancelable, this.progress);
		}
	}
}