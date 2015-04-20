# DBMapSelectorViewController

This component allows you to select circular map region from the MKMapView.

![Screenshot of Example](https://github.com/d0ping/DBMapSelectorViewController/blob/master/Example/Resources/Screenshot.jpg)

## Adding to your project

### Cocoapods

To add DBMapSelectorViewController via [CocoaPods](http://cocoapods.org/) into your project:

1. Add a pod entry for DBMapSelectorViewController to your Podfile `pod 'DBMapSelectorViewController', '~> 1.0.0'`
2. Install the pod by running `pod install`

### Source Files

To add DBMapSelectorViewController manually into your project: 

1. Download the latest code, using `git clone`
2. Open your project in Xcode, then drag and drop entire contents of the `Source` folder into your project (Make sure to select Copy items when asked if you extracted the code archive outside of your project)

## Usage

To use DBMapSelectorViewController in your project you should perform the following steps:

1. Import DBMapSelectorManager.h on your UIViewController subclass. Your class must include MKMapView instance and be his delegate.
2. In your class implementation create instance of DBMapSelectorManager class. In Initialization method specify mapView instance: 
```objc
    self.mapSelectorManager = [[DBMapSelectorManager alloc] initWithMapView:self.mapView];
```
3. After initialization, set the initial map selector settings (center and radius) and apply settings:
```objc
    self.mapSelectorManager.circleCoordinate = CLLocationCoordinate2DMake(55.75399400, 37.62209300);
    self.mapSelectorManager.circleRadius = 3000;
    [self.mapSelectorManager applySelectorSettings];
```
4. Forward following messages mapView delegate by the MapSelectorManager instance as shown below:
```objc
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
```



1. Create a subclass of `DBMapSelectorViewController` class (for example `MyViewController` class name)
2. Into your Storyboard file create an instance of ViewController and specify your `MyViewController` class as a parent
3. Add MKMapView instance on ViewController on Storyboard
4. Make a connection for MKMapView and mapView outlets property
5. Set the ViewController as a delegate for the mapView
6. Add your implementation on the `MyViewController.m`

### Setting

To customize the selector you should set selector properties in the `viewDidLoad` method of your `MyViewController`. Selector properties must be set after execute `[super viewDidLoad];`.

After you have set the `circleCoordinate` and `circleRadius` parameters manually you must execute `updateMapRegionForMapSelector` method.

For example, how it can be implemented:

```objc
- (void)viewDidLoad {
    [super viewDidLoad];

    self.circleCoordinate = CLLocationCoordinate2DMake(55.75399400, 37.62209300);
    self.circleRadius = 2500;
    self.circleRadiusMin = 500;
    self.circleRadiusMax = 25000;
    [self updateMapRegionForMapSelector];

    self.fillColor = [UIColor purpleColor];
    self.strokeColor = [UIColor darkGrayColor];
}
```

### Property list selector

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
- `UIColor *strokeColor` - Used to specify the selector stroke color. Color is used to delimit the circular map region.

### DBMapSelectorViewControllerDelegate

To be able to react when the main properties (coordinate and radius) of the selector will be changed you must become delegate DBMapSelectorViewController. DBMapSelectorViewControllerDelegate protocol you can see here:

```objc
@protocol DBMapSelectorViewControllerDelegate <NSObject>

@optional
- (void)mapSelectorViewController:(DBMapSelectorViewController *)mapSelectorViewController didChangeCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)mapSelectorViewController:(DBMapSelectorViewController *)mapSelectorViewController didChangeRadius:(CLLocationDistance)radius;

@end
```

You can implement these methods in your `MyViewController` class in order to respond to these changes. For example, how it can be implemented in your class:

```objc
- (void)mapSelectorViewController:(DBMapSelectorViewController *)mapSelectorViewController didChangeCoordinate:(CLLocationCoordinate2D)coordinate {
    _coordinateLabel.text = [NSString stringWithFormat:@"Coordinate = {%.5f, %.5f}", coordinate.latitude, coordinate.longitude];
}

- (void)mapSelectorViewController:(DBMapSelectorViewController *)mapSelectorViewController didChangeRadius:(CLLocationDistance)radius {
    NSString *radiusStr = (radius >= 1000) ? [NSString stringWithFormat:@"%.1f km", radius * .001f] : [NSString stringWithFormat:@"%.0f m", radius];
    _radiusLabel.text = [@"Radius = " stringByAppendingString:radiusStr];
}
```
## Version history

### 1.1.0
- Added Outside circle mode.

### 1.2.0
- The DBMapSelectorViewController was replaced by a DBMapSelectorManager. This change allows the functionality provided by this component to be more easily integrated into existing projects where, for instance, the target view controller already inherits from another custom view controller. (Thank [Marcelo Schroeder](https://github.com/marcelo-schroeder) for giving solution).
- Improved user experience when moving the map selector.
- Fixed bug with incorrect determinating zoom button position in some cases.

## Contact

Denis Bogatyrev (maintainer)

- https://github.com/d0ping
- denis.bogatyrev@gmail.com

##License

DBMapSelectorViewController - Copyright (c) 2015 Denis Bogatyrev

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.