//
//  ViewController.h
//  DBMapSelectorViewControllerExample
//
//  Created by Denis Bogatyrev on 27.03.15.
//  Copyright (c) 2015 Denis Bogatyrev. All rights reserved.
//

#import "DBMapSelectorManager.h"

@interface ViewController : UIViewController <DBMapSelectorManagerDelegate, MKMapViewDelegate>

@property (nonatomic, weak) IBOutlet MKMapView          *mapView;

@property (nonatomic, weak) IBOutlet UISwitch               *hiddenSwitch;

@property (nonatomic, weak) IBOutlet UILabel                *coordinateLabel;
@property (nonatomic, weak) IBOutlet UILabel                *radiusLabel;

@property (nonatomic, weak) IBOutlet UISegmentedControl     *editingTypeSegmentedControl;
@property (nonatomic, weak) IBOutlet UISegmentedControl     *fillingModeSegmentedControl;

@property (nonatomic, weak) IBOutlet UITextField            *fillColorTextField;
@property (nonatomic, weak) IBOutlet UITextField            *strokeColorTextField;

@end

