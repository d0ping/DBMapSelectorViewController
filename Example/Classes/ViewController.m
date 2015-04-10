//
//  ViewController.m
//  DBMapSelectorViewControllerExample
//
//  Created by Denis Bogatyrev on 27.03.15.
//  Copyright (c) 2015 Denis Bogatyrev. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <UIPickerViewDataSource, UIPickerViewDelegate> {
    NSDictionary        *_fillColorDict;
    NSDictionary        *_strokeColorDict;
    UIPickerView        *_fillColorPickerView;
    UIPickerView        *_strokeColorPickerView;
}

@property (nonatomic) DBMapSelectorManager *mapSelectorManager;

@end

@implementation ViewController

- (DBMapSelectorManager *)mapSelectorManager {
    if (!_mapSelectorManager) {
        _mapSelectorManager = [DBMapSelectorManager new];
        _mapSelectorManager.delegate = self;
    }
    return _mapSelectorManager;
}

#pragma mark - Source

- (void)viewDidLoad {
    [super viewDidLoad];

    self.mapSelectorManager.mapView = self.mapView;

    _mapView.showsUserLocation = YES;
    
    // Set Begin Settings
    self.mapSelectorManager.circleCoordinate = CLLocationCoordinate2DMake(55.75399400, 37.62209300);
    self.mapSelectorManager.circleRadius = 3000;
    self.mapSelectorManager.circleRadiusMax = 25000;
    [self.mapSelectorManager updateMapRegionForMapSelector];
    
    _fillColorDict = @{@"Orange": [UIColor orangeColor], @"Green": [UIColor greenColor],  @"Pure": [UIColor purpleColor],  @"Cyan": [UIColor cyanColor], @"Yellow": [UIColor yellowColor],  @"Magenta": [UIColor magentaColor]};
    _strokeColorDict = @{@"Dark Gray": [UIColor darkGrayColor], @"Black": [UIColor blackColor], @"Brown": [UIColor brownColor], @"Red": [UIColor redColor], @"Blue": [UIColor blueColor]};
    
    _fillColorPickerView = [[UIPickerView alloc] init];
    _fillColorPickerView.delegate = self;
    _fillColorPickerView.dataSource = self;
    _fillColorPickerView.showsSelectionIndicator = YES;
    
    _strokeColorPickerView = [[UIPickerView alloc] init];
    _strokeColorPickerView.delegate = self;
    _strokeColorPickerView.dataSource = self;
    _strokeColorPickerView.showsSelectionIndicator = YES;
    
    NSString *fillColorKey = @"Orange";
    _fillColorTextField.text = fillColorKey;
    self.mapSelectorManager.fillColor = _fillColorDict[fillColorKey];
    
    NSString *strokeColorKey = @"Dark Gray";
    _strokeColorTextField.text = strokeColorKey;
    self.mapSelectorManager.strokeColor = _strokeColorDict[strokeColorKey];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(inputAccessoryViewDidFinish)];
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0,0, 320, 44)];
    [toolbar setItems:@[doneButton] animated:NO];
    
    _fillColorTextField.inputView = _fillColorPickerView;
    _fillColorTextField.inputAccessoryView = toolbar;
    
    _strokeColorTextField.inputView = _strokeColorPickerView;
    _strokeColorTextField.inputAccessoryView = toolbar;
    
}

- (void)inputAccessoryViewDidFinish {
    [_fillColorTextField resignFirstResponder];
    [_strokeColorTextField resignFirstResponder];
}

#pragma mark - Actions

- (IBAction)editingTypeSegmentedControlValueDidChange:(UISegmentedControl *)sender {
    self.mapSelectorManager.editingType = sender.selectedSegmentIndex;
}

- (IBAction)fillingModeSegmentedControlValueDidChange:(UISegmentedControl *)sender {
    self.mapSelectorManager.fillInside = (sender.selectedSegmentIndex == 0);
}

- (IBAction)hiddenSwitchValueDidChange:(UISwitch *)sender {
    self.mapSelectorManager.hidden = !sender.on;
}

#pragma mark - DBMapSelectorViewController Delegate

- (void)mapSelectorManager:(DBMapSelectorManager *)mapSelectorViewController
       didChangeCoordinate:(CLLocationCoordinate2D)coordinate {
    _coordinateLabel.text = [NSString stringWithFormat:@"Coordinate = {%.5f, %.5f}", coordinate.latitude, coordinate.longitude];
}

- (void)mapSelectorManager:(DBMapSelectorManager *)mapSelectorViewController
           didChangeRadius:(CLLocationDistance)radius {
    NSString *radiusStr = (radius >= 1000) ? [NSString stringWithFormat:@"%.1f km", radius * .001f] : [NSString stringWithFormat:@"%.0f m", radius];
    _radiusLabel.text = [@"Radius = " stringByAppendingString:radiusStr];
}

#pragma mark - UIPickerView Delegate && DataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    NSDictionary *dict = [pickerView isEqual:_fillColorPickerView] ? _fillColorDict : _strokeColorDict;
    return dict.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSDictionary *dict = [pickerView isEqual:_fillColorPickerView] ? _fillColorDict : _strokeColorDict;
    return dict.allKeys[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSDictionary *dict = [pickerView isEqual:_fillColorPickerView] ? _fillColorDict : _strokeColorDict;
    NSString *colorKey = dict.allKeys[row];
    if ([pickerView isEqual:_fillColorPickerView]) {
        self.fillColorTextField.text = colorKey;
        self.mapSelectorManager.fillColor = _fillColorDict[colorKey];
    } else if ([pickerView isEqual:_strokeColorPickerView]) {
        self.strokeColorTextField.text = colorKey;
        self.mapSelectorManager.strokeColor = _strokeColorDict[colorKey];
    }
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView
    annotationView:(MKAnnotationView *)annotationView
didChangeDragState:(MKAnnotationViewDragState)newState
      fromOldState:(MKAnnotationViewDragState)oldState {
    [self.mapSelectorManager mapView:mapView
                      annotationView:annotationView
                  didChangeDragState:newState
                        fromOldState:oldState];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView
            rendererForOverlay:(id <MKOverlay>)overlay {
    return [self.mapSelectorManager mapView:mapView
                         rendererForOverlay:overlay];
}

- (void)        mapView:(MKMapView *)mapView
regionDidChangeAnimated:(BOOL)animated {
    [self.mapSelectorManager mapView:mapView
             regionDidChangeAnimated:animated];
}

@end
