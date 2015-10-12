package com.trembit.loader {
import flash.utils.ByteArray;

import org.osflash.signals.Signal;

public class ItemNotFoundSignal extends Signal {
    public function ItemNotFoundSignal() {
        super(String);
    }
}
}
