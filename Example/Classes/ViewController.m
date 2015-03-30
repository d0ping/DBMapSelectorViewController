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

@end

@implementation ViewController

@synthesize mapView = _mapView;

#pragma mark - Source

- (void)loadView {
    [super loadView];
    
    _mapView.showsUserLocation = YES;
    
    // Set Begin Settings
    self.selectorCoordinate = CLLocationCoordinate2DMake(55.75399400, 37.62209300);
    self.selectorRadius = 3000;
    self.selectorRadiusMax = 25000;
    
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
    self.selectorFillColor = _fillColorDict[fillColorKey];
    
    NSString *strokeColorKey = @"Dark Gray";
    _strokeColorTextField.text = strokeColorKey;
    self.selectorStrokeColor = _strokeColorDict[strokeColorKey];
    
    
    [self didChangeCoordinate:self.selectorCoordinate];
    [self didChangeRadius:self.selectorRadius];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    self.selectorEditingType = sender.selectedSegmentIndex;
}

- (IBAction)enableSwitchValueDidChange:(UISwitch *)sender {
    self.selectorEnabled = sender.on;
    self.editingTypeSegmentedControl.enabled = self.selectorEnabled;
}

#pragma mark - DBMapSelectorViewController Protocol

- (void)didChangeCoordinate:(CLLocationCoordinate2D)coordinate {
    _coordinateLabel.text = [NSString stringWithFormat:@"Coordinate = {%.5f, %.5f}", coordinate.latitude, coordinate.longitude];
}

- (void)didChangeRadius:(CLLocationDistance)radius {
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
        self.selectorFillColor = _fillColorDict[colorKey];
    } else if ([pickerView isEqual:_strokeColorPickerView]) {
        self.strokeColorTextField.text = colorKey;
        self.selectorStrokeColor = _strokeColorDict[colorKey];
    }
}

#pragma mark - UITextField Delegate

//- (BOOL) textFieldShouldBeginEditing:(UITextView *)textView {
//    _fillColorPickerView.frame = CGRectMake(0, 500, _fillColorPickerView.frame.size.width, _fillColorPickerView.frame.size.height);
//    [UIView beginAnimations:nil context:NULL];
//    [UIView setAnimationDuration:.3f];
//    [UIView setAnimationDelegate:self];
//    _fillColorPickerView.frame = CGRectMake(0, 200, _fillColorPickerView.frame.size.width, _fillColorPickerView.frame.size.height);
//    [self.view addSubview:_fillColorPickerView];
//    [UIView commitAnimations];
//    return NO;
//}

@end
