package com.trembit.loader {
import org.osflash.signals.Signal;

public class ProgressLoaderSignal extends Signal {
    public function ProgressLoaderSignal() {
        super(String, Number);
    }
}
}
