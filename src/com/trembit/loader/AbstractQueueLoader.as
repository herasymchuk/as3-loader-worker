package com.trembit.loader {
import flash.events.IOErrorEvent;

import org.osflash.signals.ISignal;
import org.osflash.signals.Signal;

public class AbstractQueueLoader {

    private var PROGRESS_SIGNAL:ISignal = new ProgressLoaderSignal();
    public function get progress():ISignal {
        return PROGRESS_SIGNAL;
    }

    private var COMPLETE_SIGNAL:ISignal = new Signal();
    public function get completeTotal():ISignal {
        return COMPLETE_SIGNAL;
    }

    private var COMPLETE_ITEM_SIGNAL:ISignal = new CompleteLoadItemSignal();
    public function get completeItem():ISignal {
        return COMPLETE_ITEM_SIGNAL;
    }

    private var ITEM_NOT_FOUND_SIGNAL:ISignal = new ItemNotFoundSignal();
    public function get itemNotFound():ISignal {
        return ITEM_NOT_FOUND_SIGNAL;
    }

    private var ERROR_SIGNAL:ISignal = new Signal(String);
    public function get error():ISignal {
        return ERROR_SIGNAL;
    }

    public function AbstractQueueLoader() {
        pathOueue = [];
    }

    public var filterFunction:Function;
    protected var pathOueue:Array;

    public function add(path:String, ...args):void {
        pathOueue.push(path);
    }

    protected function sortQueue():void {
        if (filterFunction != null) {
            for (var i:int = 0; i < pathOueue.length; i++) {
                if (filterFunction(pathOueue[i])) {
                    pathOueue.splice(0, 0, (pathOueue.splice(i, 1) as Array)[0]);
                }
            }
        }
    }

    public function load():void {
        sortQueue();
        loadNext();
    }

    protected function loadNext():void {
        if (pathOueue.length > 0) {
            loadItem(pathOueue.shift() as String);
        } else {
            complete();
        }
    }

    protected function loadItem(remotePath:String):void {

    }

    protected function onCompleteLoadItem(path:String, result:Object):void {
        completeItem.dispatch(path, result);
        loadNext();
    }

    protected function onErrorLoadItem(e:IOErrorEvent):void {
        error.dispatch(e.toString());
        loadNext();
    }

    protected function complete():void {
        completeTotal.dispatch();
    }

	public function getFilesQueueLength():int {
		return pathOueue.length;
	}

}
}