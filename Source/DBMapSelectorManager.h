//
//  DBMapSelectorManager.h
//  DBMapSelectorViewController
//
//  Created by Denis Bogatyrev on 27.03.15.
//
//  The MIT License (MIT)
//  Copyright (c) 2015 Denis Bogatyrev.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

#import <MapKit/MapKit.h>

@class DBMapSelectorManager;

/*! @brief Determines how the selector can be edited */
typedef NS_ENUM(NSInteger, DBMapSelectorEditingType) {
    DBMapSelectorEditingTypeFull = 0,
    DBMapSelectorEditingTypeCoordinateOnly,
    DBMapSelectorEditingTypeRadiusOnly,
    DBMapSelectorEditingTypeNone,
};

@protocol DBMapSelectorManagerDelegate <NSObject>

@optional
- (void)mapSelectorManager:(DBMapSelectorManager *)mapSelectorManager didChangeCoordinate:(CLLocationCoordinate2D)coordinate;
- (void)mapSelectorManager:(DBMapSelectorManager *)mapSelectorManager didChangeRadius:(CLLocationDistance)radius;
- (void)mapSelectorManagerWillBeginHandlingUserInteraction:(DBMapSelectorManager *)mapSelectorManager;
- (void)mapSelectorManagerDidHandleUserInteraction:(DBMapSelectorManager *)mapSelectorManager;

@end

@class DBMapSelectorOverlay;
@interface DBMapSelectorManager : NSObject <MKMapViewDelegate>

@property (nonatomic, weak) id<DBMapSelectorManagerDelegate> delegate;
@property (nonatomic, strong, readonly) MKMapView       *mapView;

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

/*!
 @brief The magnification factor maps region after changing the selector settings
 @discussion It is recommended to set a value greater than 1.f
 */
@property (nonatomic, assign) CGFloat                   mapRegionCoef;          // default is equal 2.f

/*! @brief Indicates whether the radius text should be displayed or not */
@property (nonatomic) BOOL                              shouldShowRadiusText;

/*! @brief It allows to move the selector to a new location via long press gesture */
@property (nonatomic) BOOL                              shouldLongPressGesture; // default is NO

- (instancetype)initWithMapView:(MKMapView *)mapView;
- (void)applySelectorSettings;

#pragma mark - MKMapViewDelegate (forward when relevant)

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation;
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState;
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay;
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated;

@end
