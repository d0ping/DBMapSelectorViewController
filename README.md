# DBMapSelectorViewController

This component allows you to select circular map region from the MKMapView.

![Screenshot of Example](https://github.com/d0ping/DBMapSelectorViewController/blob/develop/Example/Resources/Screenshot.jpg)

## Adding DBMapSelectorViewController to your project

### Cocoapods

To add DBMapSelectorViewController via [CocoaPods](http://cocoapods.org/) into your project:

1. Add a pod entry for DBMapSelectorViewController to your Podfile `pod 'DBMapSelectorViewController', '~> 1.0.0'`
2. Install the pod by running `pod install`

### Source Files

To add DBMapSelectorViewController manually into your project: 

1. Download the latest code, using `git clone`
2. Open your project in Xcode, then drag and drop `DBMapSelectorViewController` folder with all its content into your project (Make sure to select Copy items when asked if you extracted the code archive outside of your project)

## Usage

To use DBMapSelectorViewController in your project you should perform the following steps:

1. Create a subclass of `DBMapSelectorViewController` class (for example `MyViewController` class name)
2. Into your Storyboard file create an instance of ViewController and specify your `MyViewController` class as a parent
3. Add MKMapView instance on ViewController on Storyboard
4. Make a connection for MKMapView and mapView outlets property
5. Set the ViewController as a delegate for the mapView
6. Add your implementation on the `MyViewController.m`

##License

DBMapSelectorViewController - Copyright (c) 2015 Denis Bogatyrev

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.