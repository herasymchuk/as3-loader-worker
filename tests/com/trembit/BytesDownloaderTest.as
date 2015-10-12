package com.trembit {
import com.trembit.loader.BytesDownloader;
import com.trembit.loader.IDownloader;

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.utils.ByteArray;

import org.flexunit.asserts.assertEquals;
import org.flexunit.asserts.assertFalse;
import org.flexunit.asserts.assertNotNull;
import org.flexunit.asserts.assertTrue;
import org.flexunit.asserts.fail;
import org.flexunit.async.Async;

public class BytesDownloaderTest extends EventDispatcher {

    private static const REQUEST_TIMEOUT:int = 10000;
    private var loader:IDownloader = new BytesDownloader();
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
    }

    [Test(async)]
    public function BytesLoaderTest():void {
        loader.add("http://trembit.com/sandbox/cogmed/resources-mobile/CPI_en_GB_1_0.tar", "file 1");
        isFileExist = true;
        filesInQueue = 1;
        assertEquals(filesInQueue, loader.getFilesQueueLength());
        loader.completeItem.addOnce(function (url:String, byteArray:ByteArray):void {
            assertEquals("http://trembit.com/sandbox/cogmed/resources-mobile/CPI_en_GB_1_0.tar", url);
        });
        loader.load();

        Async.proceedOnEvent(this, this, Event.COMPLETE, REQUEST_TIMEOUT);
    }

    [Test(async)]
    public function BytesLoaderQueueTest():void {
        var urls:Array = ["http://trembit.com/sandbox/cogmed/resources-mobile/CPI_en_GB_1_0.tar", "http://trembit.com/sandbox/cogmed/resources-mobile/CPI_en_US_1_0.tar"];
        loader.add(urls[0], "file1");
        loader.add(urls[1], "file2");
        isFileExist = true;
        filesInQueue = 2;
        assertEquals(filesInQueue, loader.getFilesQueueLength());
        var curFileNum:int = 0;
        loader.completeItem.add(function (url:String, byteArray:ByteArray):void {
            assertEquals(urls[curFileNum++], url);
        });
        loader.load();

        Async.proceedOnEvent(this, this, Event.COMPLETE, REQUEST_TIMEOUT);
    }

    [Test(async)]
    public function BytesLoaderMissedFilesTest():void {
        loader.add("http://trembit.com/sandbox/cogmed/resources-mobile/CPI_en_GB_1_0.tar", "file1");
        loader.add("http://trembit.com/sandbox/cogmed/resources-mobile/CPI_en_US_2_0.tar", "file 2");
        isFileExist = false;
        filesInQueue = 2;
        assertEquals(filesInQueue, loader.getFilesQueueLength());
        loader.completeItem.addOnce(function (url:String, byteArray:ByteArray):void {
            assertEquals("http://trembit.com/sandbox/cogmed/resources-mobile/CPI_en_GB_1_0.tar", url);
        });
        loader.load();

        Async.proceedOnEvent(this, this, Event.COMPLETE, REQUEST_TIMEOUT);
    }

    private function onRemoteItemLoadComplete(url:String, byteArray:ByteArray):void {
        assertEquals(--filesInQueue, loader.getFilesQueueLength());
        assertNotNull(url);
        assertNotNull(byteArray);
        assertTrue(byteArray.length > 0);
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

    private function onProgress(itemName:String, p):void {
    }


}
}
