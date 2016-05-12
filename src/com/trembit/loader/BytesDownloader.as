package com.trembit.loader {

import flash.errors.IOError;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.net.URLRequest;
import flash.net.URLRequestHeader;
import flash.net.URLRequestMethod;
import flash.net.URLStream;
import flash.utils.ByteArray;

public class BytesDownloader extends QueueLoaderWithAvailabilityChecking implements IDownloader {

    private var stream:URLStream;
    private var remoteItemPath:String;

    public function BytesDownloader() {
        super();
    }

	protected var currentBytesPosition:uint = 0;
	protected var isPaused:Boolean = false;

	protected var bytesLoaded:ByteArray = new ByteArray();

	override protected function loadItemInternal(url:String):void {
		super.loadItemInternal(url);
		if (!stream || !stream.connected) {
			bytesLoaded = new ByteArray();
			currentBytesPosition = 0;
			//downloadCompleteFlag = false;
			stream = new URLStream();
			remoteItemPath = url;
			var requester:URLRequest = new URLRequest(url);
			addEventListeners();
			stream.load(requester);
			trace("Start to load remote item: ", url);
		}
	}

	public function pause():void {
		isPaused = true;
	}

	public function resume():void {
		resumeLoad(remoteItemPath);
	}

	protected function resumeLoad(url:String):void {
		trace("ResumeLoad");
		isPaused = false;
		trace("currentBytesPosition", currentBytesPosition);
		var requestHeader:URLRequestHeader = new URLRequestHeader("Range","bytes=" + currentBytesPosition + "-");
		var requester:URLRequest = new URLRequest(url);
		requester.requestHeaders = [requestHeader];
		stream.load(requester);
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
		trace("cleanUp");
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
        progress.dispatch(remoteItemPath, (e.bytesLoaded + currentBytesPosition) / e.bytesTotal * 100);
		if (isPaused){
			trace("stream.close");
			stream.readBytes(bytesLoaded, currentBytesPosition);
			currentBytesPosition += e.bytesLoaded;
			trace("currentBytesPosition", currentBytesPosition);
			stream.close();
		}
    }

    private function onStreamComplete(e:Event):void {
		trace("onStreamComplete");
		stream.readBytes(bytesLoaded, currentBytesPosition);

		cleanUp();
		trace("currentBytesPosition:", currentBytesPosition);
		onCompleteLoadItem(remoteItemPath, bytesLoaded);
    }

    override protected function onErrorLoadItem(e:IOErrorEvent):void {
		cleanUp();
        super.onErrorLoadItem(e);
    }
}
}