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
    DBMapSelectorEditingTypeNone,
};

@protocol DBMapSelectorViewControllerProtocol <NSObject>

@optional
- (void)didChangeCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)didChangeRadius:(CLLocationDistance)radius;

@end

@class DBMapSelectorOverlay;
@interface DBMapSelectorViewController : UIViewController <MKMapViewDelegate, DBMapSelectorViewControllerProtocol>

@property (nonatomic, weak) IBOutlet MKMapView          *mapView;

/*!
 @brief Used to specify the selector editing type
 @discussion Property can equal one of four values:
 DBMapSelectorEditingTypeFull allows to edit coordinate and radius,
 DBMapSelectorEditingTypeCoordinateOnly allows to edit cooordinate only,
 DBMapSelectorEditingTypeRadiusOnly allows to edit radius only,
 DBMapSelectorEditingTypeNone read only mode.
 */
@property (nonatomic, assign) DBMapSelectorEditingType  selectorEditingType;

/*! @brief Used to specify the selector coordinate */
@property (nonatomic, assign) CLLocationCoordinate2D    selectorCoordinate;

/*! @brief Used to specify the selector radius */
@property (nonatomic, assign) CLLocationDistance        selectorRadius;

/*! @brief Used to specify the minimum selector radius */
@property (nonatomic, assign) CLLocationDistance        selectorRadiusMin;

/*! @brief Used to specify the maximum selector radius */
@property (nonatomic, assign) CLLocationDistance        selectorRadiusMax;

/*! 
 @brief Used to specify the selector fill color
 @discussion Color is used to fill the circular map region
 */
@property (nonatomic, strong) UIColor                   *selectorFillColor;

/*! 
 @brief Used to specify the selector stroke color 
 @discussion Color is used to delimit the circular map region
 */
@property (nonatomic, strong) UIColor                   *selectorStrokeColor;

@end
