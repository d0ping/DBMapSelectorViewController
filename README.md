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

### Setting

To customize the selector you should set selector properties in the loadView method of your `MyViewController`. Selector properties must be set after execute `[super loadView];`. For example, how it can be implemented:

```objc
- (void)loadView {
    [super loadView];

    self.selectorCoordinate = CLLocationCoordinate2DMake(55.75399400, 37.62209300);
    self.selectorRadius = 2500;
    self.selectorRadiusMin = 500;
    self.selectorRadiusMax = 25000;

    self.selectorFillColor = [UIColor pureColor];
    self.selectorStrokeColor = [UIColor darkGrayColor];
}
```

### Property list selector

- `DBMapSelectorEditingType selectorEditingType` - Used to specify the selector editing type. Property can equal one of four values:
  - `DBMapSelectorEditingTypeFull` allows to edit coordinate and radius,
  - `DBMapSelectorEditingTypeCoordinateOnly` allows to edit cooordinate only,
  - `DBMapSelectorEditingTypeRadiusOnly` allows to edit radius only,
  - `DBMapSelectorEditingTypeNone` read only mode;
- `CLLocationCoordinate2D selectorCoordinate` - Used to specify the selector coordinate;
- `CLLocationDistance selectorRadius` - Used to specify the selector radius;
- `CLLocationDistance selectorRadiusMin` - Used to specify the minimum selector radius;
- `CLLocationDistance selectorRadiusMax` - Used to specify the maximum selector radius;
- `UIColor *selectorFillColor` - Used to specify the selector fill color. Color is used to fill the circular map region;
- `UIColor *selectorStrokeColor` - Used to specify the selector stroke color. Color is used to delimit the circular map region.

### DBMapSelectorViewControllerProtocol

Inside the `DBMapSelectorViewController` class is implemented `DBMapSelectorViewControllerProtocol`. It's allows to receive messages when the main properties (coordinate and radius) of the selector will be changed.

```objc
@protocol DBMapSelectorViewControllerProtocol <NSObject>

@optional
- (void)didChangeCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)didChangeRadius:(CLLocationDistance)radius;

@end
```

You can implement these methods in your `MyViewController` class in order to respond to these changes. For example, how it can be implemented in your class:

```objc
- (void)didChangeCoordinate:(CLLocationCoordinate2D)coordinate {
    _coordinateLabel.text = [NSString stringWithFormat:@"Coordinate = {%.5f, %.5f}", coordinate.latitude, coordinate.longitude];
}

- (void)didChangeRadius:(CLLocationDistance)radius {
    NSString *radiusStr = (radius >= 1000) ? [NSString stringWithFormat:@"%.1f km", radius * .001f] : [NSString stringWithFormat:@"%.0f m", radius];
    _radiusLabel.text = [@"Radius = " stringByAppendingString:radiusStr];
}
```

## Contact

Denis Bogatyrev

- https://github.com/d0ping
- denis.bogatyrev@gmail.com

##License

DBMapSelectorViewController - Copyright (c) 2015 Denis Bogatyrev

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.