package com.trembit.loader {
public class LoadItem {

	public var localFileName:String;
	public var remotePath:String;


	public function LoadItem(remotePath:String="", localFileName:String = "") {
		this.remotePath = remotePath;
		this.localFileName = localFileName;
	}
}
}
