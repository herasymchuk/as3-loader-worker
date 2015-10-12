package com.trembit {
import com.trembit.loader.FileDownloader;
import com.trembit.loader.IDownloader;

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.filesystem.File;
import flash.utils.ByteArray;

import org.flexunit.asserts.assertEquals;
import org.flexunit.asserts.assertFalse;
import org.flexunit.asserts.assertNotNull;
import org.flexunit.asserts.assertNull;
import org.flexunit.asserts.fail;
import org.flexunit.async.Async;

public class FileDownloaderTest extends EventDispatcher {

	private static const REQUEST_TIMEOUT:int = 10000;
	private var loader:IDownloader = new FileDownloader();
	private var filesInQueue:int = 0;
	private var isFileExist:Boolean = false;

	[Before(async)]
	public function init():void {
		filesInQueue = 0;
		isFileExist = true;
		assertEquals(filesInQueue, loader.getFilesQueueLength());
		loader.progress.add(onProgress);
		loader.completeItem.add(onRemoteItemLoadComplete);
		loader.error.add(onIOError);
		loader.itemNotFound.add(onFileNotFound);
		loader.completeTotal.addOnce(onAllRemoteItemsLoadComplete);

		(loader as FileDownloader).destinationDir = File.documentsDirectory;
	}

	[Test(async)]
	public function FileLoaderTest():void {
		loader.add("http://trembit.com/sandbox/cogmed/resources-mobile/CPI_en_GB_1_0.tar", "file 1");
		isFileExist = true;
		filesInQueue = 1;
		assertEquals(filesInQueue, loader.getFilesQueueLength());
		loader.completeItem.addOnce(function (url:String, localFile:File):void {
			assertEquals("http://trembit.com/sandbox/cogmed/resources-mobile/CPI_en_GB_1_0.tar", url);
			assertEquals("file 1", localFile.name);
		});
		loader.load();

		Async.proceedOnEvent(this, this, Event.COMPLETE, REQUEST_TIMEOUT);
	}

	[Test(async)]
	public function FileLoaderQueueTest():void {
		var urls:Array = ["http://trembit.com/sandbox/cogmed/resources-mobile/CPI_en_GB_1_0.tar", "http://trembit.com/sandbox/cogmed/resources-mobile/CPI_en_US_1_0.tar"];
		loader.add(urls[0], "file1");
		loader.add(urls[1], "file2");
		isFileExist = true;
		filesInQueue = 2;
		assertEquals(filesInQueue, loader.getFilesQueueLength());
		var curFileNum:int = 0;
		loader.completeItem.add(function (url:String, localFile:File):void {
			assertEquals(urls[curFileNum++], url);
			assertNotNull(localFile);
		});
		loader.load();

		Async.proceedOnEvent(this, this, Event.COMPLETE, REQUEST_TIMEOUT);
	}

	[Test(async)]
	public function FileLoaderMissedFilesTest():void {
		loader.add("http://trembit.com/sandbox/cogmed/resources-mobile/CPI_en_GB_1_0.tar", "file 2");
		loader.add("http://trembit.com/sandbox/cogmed/resources-mobile/CPI_en_US_2_0.tar", "file 3");
		isFileExist = false;
		filesInQueue = 2;
		assertEquals(filesInQueue, loader.getFilesQueueLength());
		loader.completeItem.addOnce(function (url:String, localFile:File):void {
			assertEquals("http://trembit.com/sandbox/cogmed/resources-mobile/CPI_en_GB_1_0.tar", url);
		});
		loader.load();

		Async.proceedOnEvent(this, this, Event.COMPLETE, REQUEST_TIMEOUT);
	}

	private function onRemoteItemLoadComplete(url:String, localFile:File):void {
		assertEquals(--filesInQueue, loader.getFilesQueueLength());
		assertNotNull(url);
		assertNotNull(localFile);
	}

	private function onIOError(e:String):void {
		fail(e);
	}

	private function onFileNotFound(e:String):void {
		assertFalse(e, isFileExist);
	}

	private function onAllRemoteItemsLoadComplete():void {
		assertEquals(0, loader.getFilesQueueLength());
		//loader.close();
		dispatchEvent(new Event(Event.COMPLETE));
	}

	private function onProgress(itemName:String, progress:Number):void {
	}


}
}
