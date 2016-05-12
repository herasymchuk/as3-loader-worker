package com.trembit.loader {
import flash.events.IEventDispatcher;

import org.osflash.signals.ISignal;

public interface IDownloader {

    function load():void;

	function interrupt():void;

    function getFilesQueueLength():int;

    function add(remotePathUrl:String, ...args):void;

    function get completeTotal():ISignal;

    function get completeItem():ISignal;

    function get error():ISignal;

    function get itemNotFound():ISignal;

    function get progress():ISignal;

	function pause():void;

	function resume():void;

}
}
