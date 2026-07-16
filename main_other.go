//go:build !darwin

package main

import "fmt"

func main() {
	fmt.Println("sudare is available on macOS only.")
}
