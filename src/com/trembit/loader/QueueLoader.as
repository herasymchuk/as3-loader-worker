package com.trembit.loader
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;

	public class QueueLoader extends AbstractQueueLoader
	{
		private var _loader : CustomLoader;
		private var loaderContext:LoaderContext;
		
		public function QueueLoader() {
			super();
			loader = new CustomLoader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onCompleteLoadItemInternal);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onErrorLoadItem);	
			loaderContext = new LoaderContext(false, ApplicationDomain.currentDomain, null);
		}
		
		public function get loader():CustomLoader {
			return _loader;
		}
		
		public function set loader(loader : CustomLoader) : void {
			_loader = loader;
		}		
		
		override protected function loadItem(pathToSWF : String) : void {
			super.loadItem(pathToSWF);
			var urlRequest:URLRequest = new URLRequest(pathToSWF);
			try {
				loader.load(urlRequest, loaderContext);
			} catch(e:Error) {
				trace("Error ID : " + e.errorID + "\nError Message : " + e.message);
			}	
		}
		
		override protected function complete():void {
			loader = new CustomLoader();
			super.complete();
		}
		
		protected function onCompleteLoadItemInternal(event:Event):void {
			super.onCompleteLoadItem(loader.loadedItemName, null);
		}
		
		override protected function onErrorLoadItem(e : IOErrorEvent) : void {
			loader.close();
			super.onErrorLoadItem(e);
		}
		
	}
}
import flash.display.Loader;
import flash.net.URLRequest;
import flash.system.LoaderContext;

class CustomLoader extends Loader
{
	private var itemName : String;
	
	override public function load(request:URLRequest, context:LoaderContext=null) : void {
		itemName = request.url;
		super.load(request, context);
	}
	
	public function get loadedItemName() : String {	
		return itemName;
	}
	
}