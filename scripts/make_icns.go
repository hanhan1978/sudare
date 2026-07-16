package main

import (
	"encoding/binary"
	"fmt"
	"os"
	"path/filepath"
)

var iconEntries = []struct {
	code string
	file string
}{
	{"icp4", "icon_16x16.png"},
	{"icp5", "icon_32x32.png"},
	{"icp6", "icon_32x32@2x.png"},
	{"ic07", "icon_128x128.png"},
	{"ic08", "icon_256x256.png"},
	{"ic09", "icon_512x512.png"},
	{"ic10", "icon_512x512@2x.png"},
}

func main() {
	if len(os.Args) != 3 {
		fmt.Fprintf(os.Stderr, "usage: make_icns ICONSET_DIR OUTPUT_ICNS\n")
		os.Exit(2)
	}

	iconsetDir := os.Args[1]
	outputPath := os.Args[2]

	type chunk struct {
		code string
		data []byte
	}

	chunks := make([]chunk, 0, len(iconEntries))
	totalLen := uint32(8)

	for _, entry := range iconEntries {
		data, err := os.ReadFile(filepath.Join(iconsetDir, entry.file))
		if err != nil {
			fmt.Fprintf(os.Stderr, "read %s: %v\n", entry.file, err)
			os.Exit(1)
		}

		chunks = append(chunks, chunk{code: entry.code, data: data})
		totalLen += uint32(8 + len(data))
	}

	out, err := os.Create(outputPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "create output: %v\n", err)
		os.Exit(1)
	}
	defer out.Close()

	if _, err := out.Write([]byte("icns")); err != nil {
		fmt.Fprintf(os.Stderr, "write magic: %v\n", err)
		os.Exit(1)
	}
	if err := binary.Write(out, binary.BigEndian, totalLen); err != nil {
		fmt.Fprintf(os.Stderr, "write length: %v\n", err)
		os.Exit(1)
	}

	for _, chunk := range chunks {
		if _, err := out.Write([]byte(chunk.code)); err != nil {
			fmt.Fprintf(os.Stderr, "write chunk type: %v\n", err)
			os.Exit(1)
		}
		if err := binary.Write(out, binary.BigEndian, uint32(8+len(chunk.data))); err != nil {
			fmt.Fprintf(os.Stderr, "write chunk length: %v\n", err)
			os.Exit(1)
		}
		if _, err := out.Write(chunk.data); err != nil {
			fmt.Fprintf(os.Stderr, "write chunk data: %v\n", err)
			os.Exit(1)
		}
	}
}
