# DBMapSelectorViewController
[![Version](https://img.shields.io/cocoapods/v/DBMapSelectorViewController.svg?style=flat)](http://cocoadocs.org/docsets/DBMapSelectorViewController)
[![License](https://img.shields.io/cocoapods/l/DBMapSelectorViewController.svg?style=flat)](http://cocoadocs.org/docsets/DBMapSelectorViewController)
[![Platform](https://img.shields.io/cocoapods/p/DBMapSelectorViewController.svg?style=flat)](http://cocoadocs.org/docsets/DBMapSelectorViewController)
![Language](https://img.shields.io/badge/Language-%20Objective%20C%20-blue.svg)

This component allows you to select circular map region from the MKMapView.

![Screenshot of Example](https://github.com/d0ping/DBMapSelectorViewController/blob/master/Example/Resources/Screenshot.jpg)

## Adding to your project

### CocoaPods

To add DBMapSelectorViewController via [CocoaPods](http://cocoapods.org/) into your project:

1. Add a pod entry for DBMapSelectorViewController to your Podfile `pod 'DBMapSelectorViewController', '~> 1.2.0'`
2. Install the pod by running `pod install`

### Source Files

To add DBMapSelectorViewController manually into your project: 

1. Download the latest code, using `git clone`
2. Open your project in Xcode, then drag and drop entire contents of the `Source` folder into your project (Make sure to select Copy items when asked if you extracted the code archive outside of your project)

## Usage

To use DBMapSelectorViewController in your project you should perform the following steps:

1. Import DBMapSelectorManager.h on your UIViewController subclass. Your class must include MKMapView instance and be his delegate.
2. In your class implementation create instance of DBMapSelectorManager class. In Initialization method specify mapView instance. Assign your class as the delegate mapSelectorManager if needed.
3. After initialization, set the initial map selector settings (center and radius) and apply settings.
4. Forward following messages mapView delegate by the MapSelectorManager instance.

```objc
...
// (1)
#import "DBMapSelectorManager.h"

@interface ViewController () <DBMapSelectorManagerDelegate>
@property (nonatomic, strong) DBMapSelectorManager *mapSelectorManager;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // (2)
    self.mapSelectorManager = [[DBMapSelectorManager alloc] initWithMapView:self.mapView];
    self.mapSelectorManager.delegate = self;

    // (3)
    self.mapSelectorManager.circleCoordinate = CLLocationCoordinate2DMake(55.75399400, 37.62209300);
    self.mapSelectorManager.circleRadius = 3000;
    [self.mapSelectorManager applySelectorSettings];
}

...

// (4)
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    return [self.mapSelectorManager mapView:mapView viewForAnnotation:annotation];
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    [self.mapSelectorManager mapView:mapView annotationView:annotationView didChangeDragState:newState fromOldState:oldState];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay {
    return [self.mapSelectorManager mapView:mapView rendererForOverlay:overlay];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    [self.mapSelectorManager mapView:mapView regionDidChangeAnimated:animated];
}

@end
```

### Property list selector

You can change additional MapSelector properties. Full properties list is shown below:
- `DBMapSelectorEditingType editingType` - Used to specify the selector editing type. Property can equal one of four values:
  - `DBMapSelectorEditingTypeFull` allows to edit coordinate and radius,
  - `DBMapSelectorEditingTypeCoordinateOnly` allows to edit cooordinate only,
  - `DBMapSelectorEditingTypeRadiusOnly` allows to edit radius only,
  - `DBMapSelectorEditingTypeNone` read only mode;
- `CLLocationCoordinate2D circleCoordinate` - Used to specify the selector coordinate;
- `CLLocationDistance circleRadius` - Used to specify the selector radius. Default is equal 1000 meter;
- `CLLocationDistance circleRadiusMin` - Used to specify the minimum selector radius. Default is equal 100 meter;
- `CLLocationDistance circleRadiusMax` - Used to specify the maximum selector radius. Default is equal 10000 meter;
- `BOOL hidden` - Used to hide or show selector. Default is NO;
- `BOOL fillInside` - Used to switching between inside or outside filling;
- `UIColor *fillColor` - Used to specify the selector fill color. Color is used to fill the circular map region;
- `UIColor *strokeColor` - Used to specify the selector stroke color. Color is used to delimit the circular map region;
- `CGFloat mapRegionCoef` - Used to specify the magnification factor maps region. This parameter affects display the maps region after changing the selector settings. It is recommended to set a value greater than 1.f;
- `BOOL shouldShowRadiusText` - Indicates whether the radius text should be displayed or not;
- `BOOL shouldLongPressGesture` - It allows to move the selector to a new location via long press gesture.

### DBMapSelectorManagerDelegate

To be able to react when the main properties (coordinate and radius) of the selector will be changed you must become delegate DBMapSelectorManager. DBMapSelectorManagerDelegate protocol you can see here:

```objc
@protocol DBMapSelectorManagerDelegate <NSObject>

@optional
- (void)mapSelectorManager:(DBMapSelectorManager *)mapSelectorManager didChangeCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)mapSelectorManager:(DBMapSelectorManager *)mapSelectorManager didChangeRadius:(CLLocationDistance)radius;
- (void)mapSelectorManagerWillBeginHandlingUserInteraction:(DBMapSelectorManager *)mapSelectorManager;
- (void)mapSelectorManagerDidHandleUserInteraction:(DBMapSelectorManager *)mapSelectorManager;

@end
```

You can implement these methods in your `MyViewController` class in order to respond to these changes. For example, how it can be implemented in your class:

```objc
- (void)mapSelectorManager:(DBMapSelectorManager *)mapSelectorManager didChangeCoordinate:(CLLocationCoordinate2D)coordinate {
    _coordinateLabel.text = [NSString stringWithFormat:@"Coordinate = {%.5f, %.5f}", coordinate.latitude, coordinate.longitude];
}

- (void)mapSelectorManager:(DBMapSelectorManager *)mapSelectorManager didChangeRadius:(CLLocationDistance)radius {
    NSString *radiusStr = (radius >= 1000) ? [NSString stringWithFormat:@"%.1f km", radius * .001f] : [NSString stringWithFormat:@"%.0f m", radius];
    _radiusLabel.text = [@"Radius = " stringByAppendingString:radiusStr];
}
```
## Version history

### 1.2.2
- Improve rendering speed by code optimization
- Other optimizations

### 1.2.1
- Added new property `BOOL shouldLongPressGesture`. It allows to move the selector to a new location via long press gesture.
- Added new property `CGFloat mapRegionCoef`. The magnification factor maps region after changing the selector settings. It is recommended to set a value greater than 1.f.
- Improved drawing selector after first display map controller. Fixed problem when sometimes it cuts the circle after first load.

### 1.2.0
- The DBMapSelectorViewController was replaced by a DBMapSelectorManager. This change allows the functionality provided by this component to be more easily integrated into existing projects where, for instance, the target view controller already inherits from another custom view controller. (Thank [Marcelo Schroeder](https://github.com/marcelo-schroeder) for giving solution).
- Improved user experience when moving the map selector.
- Fixed bug with incorrect determinating zoom button position in some cases.

### 1.1.0
- Added Outside circle mode.

## Contact

Denis Bogatyrev (maintainer)

- https://github.com/d0ping
- denis.bogatyrev@gmail.com

##License

DBMapSelectorViewController - Copyright (c) 2015 Denis Bogatyrev

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.