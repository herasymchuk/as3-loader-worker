package com.trembit {
import com.trembit.loader.FileDownloaderWithWorker;
import com.trembit.loader.IDownloader;

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.filesystem.File;
import flash.utils.setTimeout;

import org.flexunit.asserts.assertEquals;
import org.flexunit.asserts.assertFalse;
import org.flexunit.asserts.assertNotNull;
import org.flexunit.asserts.fail;
import org.flexunit.async.Async;

public class FileDownloaderWithWorkerTest extends EventDispatcher {

	private static const REQUEST_TIMEOUT:int = 10000;
	private var loader:IDownloader = new FileDownloaderWithWorker();
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

		(loader as FileDownloaderWithWorker).destinationDir = File.documentsDirectory;
	}

	[Test(async)]
	public function FileLoaderTest():void {
		loader.add("http://trembit.com/sandbox/cogmed/resources-mobile/CPI_en_GB_1_0.tar", "file 1");
		isFileExist = true;
		filesInQueue = 1;
		assertEquals(filesInQueue, loader.getFilesQueueLength());
		loader.completeItem.addOnce(function (url:String, localFile:File):void {
			assertEquals("http://trembit.com/sandbox/cogmed/resources-mobile/CPI_en_GB_1_0.tar", url);
			assertNotNull(localFile);
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
			assertNotNull(localFile);
		});
		loader.load();

		Async.proceedOnEvent(this, this, Event.COMPLETE, REQUEST_TIMEOUT);
	}

	[Test(async)]
	public function FileLoaderQueueInterruptionTest():void {
		var urls:Array = ["http://trembit.com/sandbox/cogmed/resources-mobile/CPI_en_GB_1_0.tar", "http://trembit.com/sandbox/cogmed/resources-mobile/CPI_en_US_1_0.tar"];
		loader.add(urls[0], "file1111111111111111111111111111111");
		loader.add(urls[1], "file2222222222222222222222222222222");
		isFileExist = true;
		filesInQueue = 2;
		var curFileNum:int = 0;
		loader.completeItem.addOnce(function (url:String, localFile:File):void {
			fail("Should be interrupted");
		});
		loader.load();

		setTimeout(loader.interrupt, 500);

		//Async.proceedOnEvent(this, this, Event.COMPLETE, REQUEST_TIMEOUT);
	}

	private function onRemoteItemLoadComplete(url:String, file:File):void {
		assertEquals(--filesInQueue, loader.getFilesQueueLength());
		assertNotNull(url);
		assertNotNull(file);
	}

	private static function onIOError(e:String):void {
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
		//empty
	}


}
}
