package com.trembit.loader {

import flash.errors.IOError;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.net.URLRequest;
import flash.net.URLStream;
import flash.utils.ByteArray;

public class BytesDownloader extends QueueLoaderWithAvailabilityChecking implements IDownloader {

    private var stream:URLStream;
    private var remoteItemPath:String;

    public function BytesDownloader() {
        super();
    }

    override protected function loadItemInternal(url:String):void {
        super.loadItemInternal(url);
        if (!stream || !stream.connected) {
            //currentPosition = 0;
            //downloadCompleteFlag = false;
            stream = new URLStream();
            remoteItemPath = url;
            var requester:URLRequest = new URLRequest(url);
            addEventListeners();
            stream.load(requester);
            trace("Start to load remote item: ", url);
        }
    }

    private function addEventListeners():void {
        if (stream) {
            stream.addEventListener(IOErrorEvent.IO_ERROR, onErrorLoadItem);
            stream.addEventListener(ProgressEvent.PROGRESS, onStreamProgress);
            stream.addEventListener(Event.COMPLETE, onStreamComplete);
        }
    }

    override public function cleanUp():void {
        super.cleanUp();
		if (stream) {
			try {
				stream.close();
			} catch (e:IOError) {
			}
			stream.removeEventListener(IOErrorEvent.IO_ERROR, super.onErrorLoadItem);
			stream.removeEventListener(ProgressEvent.PROGRESS, onStreamProgress);
			stream.removeEventListener(Event.COMPLETE, onStreamComplete);
			stream = null;
		}
    }

    public function interrupt():void {
		cleanUp();
    }

    private function onStreamProgress(e:ProgressEvent):void {
        progress.dispatch(remoteItemPath, e.bytesLoaded / e.bytesTotal * 100);
    }

    private function onStreamComplete(e:Event):void {
        var bytes:ByteArray = new ByteArray();
        stream.readBytes(bytes);

		cleanUp();

		onCompleteLoadItem(remoteItemPath, bytes);
    }

    override protected function onErrorLoadItem(e:IOErrorEvent):void {
		cleanUp();
        super.onErrorLoadItem(e);
    }
}
}