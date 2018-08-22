# JPEGEncoder
Swift demo project that implements JPEG image compression algorithm

## About
The purpose of this project is to showcase the JPEG algorithm and demonstrate how it can be implemented in Swift. It reads a Bitmap file, compresses it, and saves into another file, which can then be uncompressed and viewed by this app. The resulting file does not conform the JPEG/JFIF standard, so it can't be opened with conventional image viewers.

This project is made for fun and for demo purposes only. It's not intended for commercial use, obviously. It's not optimized and works considerably slower than conventional algorithms.

The idea was to make a project that successfully compresses a raw Bitmap image without the use of any Apple's tools for image processing. CoreGraphics is only used once to convert an array of RGB pixels into an `NSImage`.

## Technical considerations
The compression level is not adjustable and isn't saved into the file's metadata. The quantization table is hardcoded and if changed after compressing an image, the reverse process will lead to data loss, artifacts and all kinds of unpredictable results.

## Prerequisites
Runs only on mac. You'll need Xcode to successfully build it.

## Installation
1. Clone the repo
1. Add the submodule `https://github.com/cyborgtomato/CBTHuffmanEncoder.git` to the destination folder `./HuffmanEncoder`. 

If Xcode fails to locate `CBTHuffmanEncoder` project, set the path manually.

## Usage
### Compression
Run the app. Tap "Open Bitmap" and locate the file you'd like to compress. The app only supports uncompressed Bitmap files (`.bmp`). Tap "Open" and wait until the image has been loaded. It will appear in the left section of the window. Tap "Export to JPEG" to compress and save to a file.
### Uncompression
Run the app. Tap "Open JPEG" and locate the file you've created in the previous step. Tap "Open". After the image is loaded it's shown in the left section of the window.

## Contributing
Want to help the project? Your contribution is greatly appreciated! Submit your pull requests and I will be happy to review them. Bonus points if you tune up the computations and make the algorithm be executed considerably faster.

## Readme TODO
* add implementation details

## License
[MIT](https://github.com/sergeysmagleev/JPEGEncoder/blob/master/LICENSE)
