package com.trembit.loader {

import org.osflash.signals.Signal;

public class CompleteLoadItemSignal extends Signal {
    public function CompleteLoadItemSignal() {
        super(String, Object); //the second param could be File either ByteArray
    }
}
}
