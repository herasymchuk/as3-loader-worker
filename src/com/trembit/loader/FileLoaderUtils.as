package com.trembit.loader {
import flash.events.EventDispatcher;
import flash.events.IEventDispatcher;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.net.URLRequest;
import flash.net.URLStream;
import flash.utils.Dictionary;

import org.osflash.signals.ISignal;
import org.osflash.signals.Signal;

public class FileLoaderUtils {

    private var loaderStore:Dictionary = new Dictionary(true);
    public const FILE_EXISTS:ISignal = new Signal(String);
    public const FILE_NOT_FOUND:ISignal = new ItemNotFoundSignal();

    public function doesFileExist(url:String):void {
        var req:URLRequest = new URLRequest(url);
        var stream:URLStream = new URLStream();

        loaderStore[stream] = url;
        addListeners(stream);
        try {
            stream.load(req);
        } catch (error:Error) {
            trace("Unable to load requested URL.", url);
        }
    }

    private function progressHandler(e:ProgressEvent):void {
        var stream:URLStream = URLStream(e.target);
        stream.close();
        if (e.bytesTotal < 1000) {
            dispatchEventInternal(stream, false);
        } else {
            dispatchEventInternal(stream, true);
        }
    }

    private function ioErrorHandler(e:IOErrorEvent):void {
        dispatchEventInternal(URLStream(e.target), false);
    }

    private function dispatchEventInternal(stream:URLStream, exists:Boolean):void {

        var url:String = loaderStore[stream];
        loaderStore[url] = null;
        delete loaderStore[url];

        if (exists) {
            FILE_EXISTS.dispatch(url);
        } else {
            FILE_NOT_FOUND.dispatch(url);
        }

        removeListeners(stream);
    }

    private function addListeners(dispatcher:IEventDispatcher):void {
        dispatcher.addEventListener(ProgressEvent.PROGRESS, progressHandler);
        dispatcher.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
    }

    private function removeListeners(dispatcher:IEventDispatcher):void {
        dispatcher.removeEventListener(ProgressEvent.PROGRESS, progressHandler);
        dispatcher.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
    }

    public function destroy():void {
        for each (var s:String in loaderStore) {
            loaderStore[s] = null;
            delete loaderStore[s];
            s = null;
        }
        loaderStore = null;

        //delete this;
    }
}
}