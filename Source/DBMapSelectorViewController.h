//
//  DBMapSelectorViewController.h
//  DBMapSelectorViewControllerExample
//
//  Created by Denis Bogatyrev on 18.04.15.
//  Copyright (c) 2015 Denis Bogatyrev. All rights reserved.
//

// DBMapSelectorViewController included in the component for backwards compatibility.
// Recommended to use DBMapSelectorManager for integrating in your project.


#import <UIKit/UIKit.h>
#import "DBMapSelectorManager.h"

@interface DBMapSelectorViewController : UIViewController <MKMapViewDelegate, DBMapSelectorManagerDelegate>

@property (nonatomic, weak) IBOutlet MKMapView              *mapView;

@end
