//
//  DBMapSelectorOverlay.h
//  DBMapSelectorViewControllerExample
//
//  Created by Denis Bogatyrev on 27.03.15.
//  Copyright (c) 2015 Denis Bogatyrev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface DBMapSelectorOverlay : NSObject <MKOverlay>

@property (nonatomic, assign) CLLocationCoordinate2D            coordinate;
@property (nonatomic, assign) CLLocationDistance                radius;
@property (nonatomic, assign) BOOL                              editingCoordinate;
@property (nonatomic, assign) BOOL                              editingRadius;
@property (nonatomic, assign) BOOL                              fillInside;

- (instancetype)initWithCenterCoordinate:(CLLocationCoordinate2D)coordinate radius:(CLLocationDistance)radius;

@end
