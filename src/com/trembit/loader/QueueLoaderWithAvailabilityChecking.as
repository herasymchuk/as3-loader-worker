package com.trembit.loader {

public class QueueLoaderWithAvailabilityChecking extends AbstractQueueLoader {

	private var fileLoaderUtils:FileLoaderUtils;

	override protected function loadItem(remotePath:String):void {
		if (null == fileLoaderUtils) {
			fileLoaderUtils = new FileLoaderUtils();
		}
		fileLoaderUtils.FILE_EXISTS.add(onFileAvailableListener);
		fileLoaderUtils.FILE_NOT_FOUND.add(onFileNotAvailableListener);
		fileLoaderUtils.doesFileExist(remotePath);
	}

	protected function onFileAvailableListener(url:String):void {
		super.loadItem(url);
		loadItemInternal(url);
	}

	protected function loadItemInternal(url:String):void {

	}

	protected function onFileNotAvailableListener(url:String):void {
		trace("File not available " + url);
		cleanUp();
		itemNotFound.dispatch(url);
		loadNext();
	}

	private function removeFileAvailabilityListeners():void {
		if (fileLoaderUtils) {
			fileLoaderUtils.FILE_EXISTS.remove(onFileAvailableListener);
			fileLoaderUtils.FILE_NOT_FOUND.remove(onFileNotAvailableListener);
		}
	}

	public function cleanUp():void {
		removeFileAvailabilityListeners();
	}
}
}
