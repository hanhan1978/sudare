//go:build darwin

package main

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Cocoa -framework Foundation

void app_start(void);
*/
import "C"

import "runtime"

func main() {
	runtime.LockOSThread()
	C.app_start()
}
