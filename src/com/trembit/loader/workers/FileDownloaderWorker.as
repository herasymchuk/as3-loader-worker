package com.trembit.loader.workers {

import com.trembit.loader.FileDownloader;
import com.trembit.loader.LoadItem;

import flash.display.Sprite;
import flash.events.Event;
import flash.filesystem.File;
import flash.net.registerClassAlias;
import flash.system.MessageChannel;
import flash.system.Worker;

public class FileDownloaderWorker extends Sprite {

	public static const COMPLETE_TOTAL_CHANEL_PROPERTY:String = "completeTotalChannel";
	public static const COMPLETE_ITEM_CHANEL_PROPERTY:String = "completeItemChanel";
	public static const ERROR_CHANEL_PROPERTY:String = "errorChannel";
	public static const ITEM_NOT_FOUND_CHANEL_PROPERTY:String = "itemNotFoundChannel";
	public static const PROGRESS_CHANEL_PROPERTY:String = "progressChannel";
	public static const DESTINATION_DIR_PATH_PROPERTY:String = "destinationDir";
	public static const ITEMS_TO_LOAD_PROPERTY:String = "itemsToLoad";
	public static const INTERRUPT_CHANEL_PROPERTY:String = "interruptChanel";

	protected var completeTotalChannel:MessageChannel;
	protected var completeItemChannel:MessageChannel;
	protected var errorChannel:MessageChannel;
	protected var progressChannel:MessageChannel;
	protected var itemNotFoundChanel:MessageChannel;
	protected var interruptChanel:MessageChannel;

	private var loader:FileDownloader;

	public function FileDownloaderWorker() {

		registerClassAlias("com.trembit.loader.LoadItem", LoadItem);
		registerClassAlias("flash.filesystem.File", File);

		completeTotalChannel = Worker.current.getSharedProperty(COMPLETE_TOTAL_CHANEL_PROPERTY) as MessageChannel;
		completeItemChannel = Worker.current.getSharedProperty(COMPLETE_ITEM_CHANEL_PROPERTY) as MessageChannel;
		errorChannel = Worker.current.getSharedProperty(ERROR_CHANEL_PROPERTY) as MessageChannel;
		itemNotFoundChanel = Worker.current.getSharedProperty(ITEM_NOT_FOUND_CHANEL_PROPERTY) as MessageChannel;
		progressChannel = Worker.current.getSharedProperty(PROGRESS_CHANEL_PROPERTY) as MessageChannel;

		interruptChanel = Worker.current.getSharedProperty(FileDownloaderWorker.INTERRUPT_CHANEL_PROPERTY) as MessageChannel;
		interruptChanel.addEventListener(Event.CHANNEL_MESSAGE, onInterruptChannelMessage);

		loader = new FileDownloader();
		loader.progress.add(onProgress);
		loader.completeItem.add(onCompleteItem);
		loader.completeTotal.addOnce(onCompleteTotal);
		loader.error.add(onIOError);
		loader.itemNotFound.add(onFileNotFound);

		loader.destinationDir = Worker.current.getSharedProperty(DESTINATION_DIR_PATH_PROPERTY) as File;
		var itemsToLoad:Vector.<LoadItem> = Worker.current.getSharedProperty(ITEMS_TO_LOAD_PROPERTY) as Vector.<LoadItem>;
		for each(var item:LoadItem in itemsToLoad) {
			loader.add(item.remotePath, item.localFileName);
		}

		loader.load();
	}

	private function onInterruptChannelMessage(event:Event):void {
		if (loader) {
			loader.interrupt();
			cleanUp();
		}
		Worker.current.terminate();
	}

	private function cleanUp():void {
		loader.progress.removeAll();
		loader.completeItem.removeAll();
		loader.completeTotal.removeAll();
		loader.error.removeAll();
		loader.itemNotFound.removeAll();
		loader = null;
	}

	private function onCompleteTotal():void {
		completeTotalChannel.send(true);
		cleanUp();
		Worker.current.terminate();
	}

	private function onCompleteItem(url:String, localFile:File):void {
		completeItemChannel.send([url, localFile]);
	}

	private function onIOError(e:String):void {
		errorChannel.send(e);
	}

	private function onFileNotFound(e:String):void {
		itemNotFoundChanel.send(e);
	}

	private function onProgress(itemName:String, progress:Number):void {
		progressChannel.send([itemName, progress]);
	}
}
}
