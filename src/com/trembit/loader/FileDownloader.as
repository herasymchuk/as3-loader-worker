package com.trembit.loader {

import flash.errors.IOError;
import flash.errors.IllegalOperationError;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.OutputProgressEvent;
import flash.events.ProgressEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.net.URLRequest;
import flash.net.URLStream;
import flash.utils.ByteArray;
import flash.utils.Dictionary;

public class FileDownloader extends QueueLoaderWithAvailabilityChecking implements IDownloader {

    private var urlStream:URLStream;
    private var fileStream:FileStream;
    private var currentPosition:uint = 0;
    //private var downloadCompleteFlag:Boolean = false;
    private var curLocalFile:File;
	private var remoteItemPath:String;
    private var localFilesNames:Dictionary;

    public function FileDownloader() {
        super();
        localFilesNames = new Dictionary(true);
    }

	override protected function loadItemInternal(url:String):void {
		super.loadItemInternal(url);
		if (!urlStream || !urlStream.connected) {
			currentPosition = 0;
			//downloadCompleteFlag = false;
			remoteItemPath = url;
			urlStream = new URLStream();
			fileStream = new FileStream();
			if(!destinationDir) {
				throw new Error("destinationDir should be set!");
			}
			curLocalFile = _destinationDir.resolvePath(localFilesNames[url]);
			var requester:URLRequest = new URLRequest(url);
			fileStream.open(curLocalFile, FileMode.WRITE);
			addEventListeners();
			urlStream.load(requester);
			trace("Start to load remote item: ", url);
		}
	}

    private var _destinationDir:File;
    public function get destinationDir():File {
        return _destinationDir;
    }
    public function set destinationDir(value:File):void {
        _destinationDir = value;
    }

    override public function add(remotePath:String, ...args):void {
        if (args.length != 1) {
            throw new IllegalOperationError();
        }
        super.add(remotePath);
        localFilesNames[remotePath] = args[0];
    }

    private function addEventListeners():void {
//		if(fileStream) {
//			fileStream.addEventListener( OutputProgressEvent.OUTPUT_PROGRESS, onOutputProgress);
//		}
        if (urlStream) {
            urlStream.addEventListener(IOErrorEvent.IO_ERROR, onErrorLoadItem);
            urlStream.addEventListener(ProgressEvent.PROGRESS, onStreamProgress);
            urlStream.addEventListener(Event.COMPLETE, onStreamComplete);
        }
    }

//	private function onOutputProgress(result:OutputProgressEvent):void {
//		// Function to call oncomplete, once the download finishes and
//		//  	all data has been written to disc
//		trace("nOutputProgress ", result.bytesPending, downloadCompleteFlag);
////		if (result.bytesPending == 0 && downloadCompleteFlag) {
////			cleanUp();
////			onCompleteLoadItem(remoteItemPath, null);
////		}
//	}

    override public function cleanUp():void {
        super.cleanUp();
		//downloadCompleteFlag = true;
		removeEventListeners();
		if (urlStream) {
			try {
				urlStream.close();
			} catch (e:IOError) {
			}
			urlStream = null;
		}
		if (fileStream) {
			try {
				fileStream.close();
			} catch (e:IOError) {
			}
			fileStream = null;
		}
		curLocalFile = null;
    }

	private function removeEventListeners():void {
//		if (fileStream) {
//			fileStream.removeEventListener(OutputProgressEvent.OUTPUT_PROGRESS, onOutputProgress);
//		}
		if (urlStream) {
			urlStream.removeEventListener(IOErrorEvent.IO_ERROR, super.onErrorLoadItem);
			urlStream.removeEventListener(ProgressEvent.PROGRESS, onStreamProgress);
			urlStream.removeEventListener(Event.COMPLETE, onStreamComplete);
		}
	}

    public function interrupt():void {
		if (curLocalFile && curLocalFile.exists) {
			try {
				curLocalFile.deleteFile();
			} catch (e:Error) {
			}
		}
        cleanUp();
    }

    private function onStreamProgress(e:ProgressEvent):void {
		var bytes:ByteArray = new ByteArray();
		var thisStart:uint = currentPosition;
		currentPosition += urlStream.bytesAvailable;
		urlStream.readBytes(bytes, thisStart);
		fileStream.writeBytes(bytes, thisStart);
        progress.dispatch(remoteItemPath, e.bytesLoaded / e.bytesTotal * 100);
    }

    private function onStreamComplete(e:Event):void {
        //downloadCompleteFlag = true;
		var f:File = curLocalFile;
		cleanUp();
        onCompleteLoadItem(remoteItemPath, f);
    }

    override protected function onErrorLoadItem(e:IOErrorEvent):void {
		cleanUp();
        super.onErrorLoadItem(e);
    }
}
}