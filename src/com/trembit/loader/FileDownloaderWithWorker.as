package com.trembit.loader {
import com.trembit.loader.workers.FileDownloaderWorker;

import flash.errors.IllegalOperationError;
import flash.events.Event;
import flash.filesystem.File;
import flash.net.registerClassAlias;
import flash.system.MessageChannel;
import flash.system.Worker;
import flash.system.WorkerDomain;
import flash.system.WorkerState;

public class FileDownloaderWithWorker extends AbstractQueueLoader implements IDownloader {

	protected var loaderWorker:Worker;
	protected var completeTotalChannel:MessageChannel;
	protected var completeItemChannel:MessageChannel;
	protected var errorChannel:MessageChannel;
	protected var progressChannel:MessageChannel;
	protected var itemNotFoundChanel:MessageChannel;

	protected var interruptChanel:MessageChannel;

	[Embed(source="workers/FileDownloaderWorker.swf", mimeType="application/octet-stream")]
	protected var loaderWorkerClass:Class;

	private var itemsToLoad:Vector.<LoadItem>;

	public function FileDownloaderWithWorker() {
		super();
		registerClassAlias("com.trembit.loader.LoadItem", LoadItem);
		registerClassAlias("flash.filesystem.File", File);
		itemsToLoad = new Vector.<LoadItem>();
	}

	override public function load():void {
		loaderWorker = WorkerDomain.current.createWorker(new loaderWorkerClass(), true);

		completeTotalChannel = loaderWorker.createMessageChannel(Worker.current);

		completeTotalChannel = loaderWorker.createMessageChannel(Worker.current);
		completeTotalChannel.addEventListener(Event.CHANNEL_MESSAGE, onCompleteTotalChannelMessage);
		completeItemChannel = loaderWorker.createMessageChannel(Worker.current);
		completeItemChannel.addEventListener(Event.CHANNEL_MESSAGE, onCompleteItemChannelMessage);
		errorChannel = loaderWorker.createMessageChannel(Worker.current);
		errorChannel.addEventListener(Event.CHANNEL_MESSAGE, onErrorChannelMessage);
		progressChannel = loaderWorker.createMessageChannel(Worker.current);
		progressChannel.addEventListener(Event.CHANNEL_MESSAGE, onProgressChannelMessage);
		itemNotFoundChanel = loaderWorker.createMessageChannel(Worker.current);
		itemNotFoundChanel.addEventListener(Event.CHANNEL_MESSAGE, onItemNotFoundChannelMessage);

		loaderWorker.setSharedProperty(FileDownloaderWorker.COMPLETE_TOTAL_CHANEL_PROPERTY, completeTotalChannel);
		loaderWorker.setSharedProperty(FileDownloaderWorker.COMPLETE_ITEM_CHANEL_PROPERTY, completeItemChannel);
		loaderWorker.setSharedProperty(FileDownloaderWorker.ERROR_CHANEL_PROPERTY, errorChannel);
		loaderWorker.setSharedProperty(FileDownloaderWorker.ITEM_NOT_FOUND_CHANEL_PROPERTY, itemNotFoundChanel);
		loaderWorker.setSharedProperty(FileDownloaderWorker.PROGRESS_CHANEL_PROPERTY, progressChannel);

		interruptChanel = Worker.current.createMessageChannel(loaderWorker);
		loaderWorker.setSharedProperty(FileDownloaderWorker.INTERRUPT_CHANEL_PROPERTY, interruptChanel);

		loaderWorker.setSharedProperty(FileDownloaderWorker.ITEMS_TO_LOAD_PROPERTY, itemsToLoad);
		loaderWorker.setSharedProperty(FileDownloaderWorker.DESTINATION_DIR_PATH_PROPERTY, destinationDir);

		loaderWorker.start();
	}

	private function onProgressChannelMessage(event:Event):void {
		var data:Array = progressChannel.receive() as Array;
		progress.dispatch(data[0], data[1]);
	}

	private function onErrorChannelMessage(event:Event):void {
		if(pathOueue.length) {
			pathOueue.shift();
		}
		error.dispatch(errorChannel.receive());
	}

	private function onItemNotFoundChannelMessage(event:Event):void {
		if(pathOueue.length) {
			pathOueue.shift();
		}
		itemNotFound.dispatch(itemNotFoundChanel.receive());
	}

	private function onCompleteItemChannelMessage(event:Event):void {
		var data:Array = completeItemChannel.receive() as Array;
		if(pathOueue.length) {
			pathOueue.shift();
		}
		completeItem.dispatch(data[0], data[1]);
	}

	private function onCompleteTotalChannelMessage(event:Event):void {
		completeTotal.dispatch();
	}

	override public function add(remotePath:String, ...args):void {
		if (args.length != 1) {
			throw new IllegalOperationError();
		}
		super.add(remotePath);
		itemsToLoad.push(new LoadItem(remotePath, args[0]));
	}

	private var _destinationDir:File;
	public function get destinationDir():File {
		return _destinationDir;
	}

	public function set destinationDir(value:File):void {
		_destinationDir = value;
	}

	public function interrupt():void {
		interruptChanel.send("");
	}
}
}
