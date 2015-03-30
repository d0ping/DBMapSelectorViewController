//
//  DBMapSelectorViewController.h
//  DBMapSelectorViewControllerExample
//
//  Created by Denis Bogatyrev on 27.03.15.
//  Copyright (c) 2015 Denis Bogatyrev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

typedef NS_ENUM(NSInteger, DBMapSelectorEditingType) {
    DBMapSelectorEditingTypeFull = 0,
    DBMapSelectorEditingTypeCoordinateOnly,
    DBMapSelectorEditingTypeRadiusOnly,
};

@protocol DBMapSelectorViewControllerProtocol <NSObject>

@optional
- (void)didChangeCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)didChangeRadius:(CLLocationDistance)radius;

@end

@class DBMapSelectorOverlay;
@interface DBMapSelectorViewController : UIViewController <MKMapViewDelegate, DBMapSelectorViewControllerProtocol>

@property (nonatomic, weak) IBOutlet MKMapView          *mapView;

@property (nonatomic, assign) DBMapSelectorEditingType  selectorEditingType;

@property (nonatomic, assign) CLLocationCoordinate2D    selectorCoordinate;
@property (nonatomic, assign) CLLocationDistance        selectorRadius;
@property (nonatomic, assign) CLLocationDistance        selectorRadiusMin;
@property (nonatomic, assign) CLLocationDistance        selectorRadiusMax;

@property (nonatomic, assign) BOOL                      selectorEnabled;
@property (nonatomic, assign) BOOL                      selectorInside;
@property (nonatomic, assign) BOOL                      selectorFixedCoordinate;

@property (nonatomic, strong) UIColor                   *selectorFillColor;
@property (nonatomic, strong) UIColor                   *selectorStrokeColor;

@end
