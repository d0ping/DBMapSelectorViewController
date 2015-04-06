//
//  DBMapSelectorViewController.h
//  DBMapSelectorViewControllerExample
//
//  Created by Denis Bogatyrev on 27.03.15.
//  Copyright (c) 2015 Denis Bogatyrev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

/*! @brief Determines how the selector can be edited */
typedef NS_ENUM(NSInteger, DBMapSelectorEditingType) {
    DBMapSelectorEditingTypeFull = 0,
    DBMapSelectorEditingTypeCoordinateOnly,
    DBMapSelectorEditingTypeRadiusOnly,
    DBMapSelectorEditingTypeNone,
};

@class DBMapSelectorViewController;
@protocol DBMapSelectorViewControllerDelegate <NSObject>

@optional
- (void)mapSelectorViewController:(DBMapSelectorViewController *)mapSelectorViewController didChangeCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)mapSelectorViewController:(DBMapSelectorViewController *)mapSelectorViewController didChangeRadius:(CLLocationDistance)radius;

@end

@class DBMapSelectorOverlay;
@interface DBMapSelectorViewController : UIViewController <MKMapViewDelegate>

@property (nonatomic, weak) id<DBMapSelectorViewControllerDelegate> delegate;
@property (nonatomic, weak) IBOutlet MKMapView          *mapView;

/*!
 @brief Used to specify the selector editing type
 @discussion Property can equal one of four values:
 DBMapSelectorEditingTypeFull allows to edit coordinate and radius,
 DBMapSelectorEditingTypeCoordinateOnly allows to edit cooordinate only,
 DBMapSelectorEditingTypeRadiusOnly allows to edit radius only,
 DBMapSelectorEditingTypeNone read only mode.
 */
@property (nonatomic, assign) DBMapSelectorEditingType  editingType;

/*! @brief Used to specify the selector coordinate */
@property (nonatomic, assign) CLLocationCoordinate2D    circleCoordinate;

/*! @brief Used to specify the selector radius */
@property (nonatomic, assign) CLLocationDistance        circleRadius;           // default is equal 1000 meter

/*! @brief Used to specify the minimum selector radius */
@property (nonatomic, assign) CLLocationDistance        circleRadiusMin;        // default is equal 100 meter

/*! @brief Used to specify the maximum selector radius */
@property (nonatomic, assign) CLLocationDistance        circleRadiusMax;        // default is equal 10000 meter

/*! @brief Used to hide or show selector */
@property (nonatomic, getter=isHidden) BOOL             hidden;                 // default is NO

/*! @brief Used to switching between inside or outside filling */
@property (nonatomic, getter=isFillInside) BOOL         fillInside;             // default is YES

/*! 
 @brief Used to specify the selector fill color
 @discussion Color is used to fill the circular map region
 */
@property (nonatomic, strong) UIColor                   *fillColor;

/*! 
 @brief Used to specify the selector stroke color 
 @discussion Color is used to delimit the circular map region
 */
@property (nonatomic, strong) UIColor                   *strokeColor;

- (void)updateMapRegionForMapSelector;

@end
