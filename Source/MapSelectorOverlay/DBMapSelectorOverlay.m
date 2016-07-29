//
//  DBMapSelectorOverlay.m
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

#import "DBMapSelectorOverlay.h"
#import <MapKit/MapKit.h>

@implementation DBMapSelectorOverlay

@synthesize boundingMapRect = _boundingMapRect;

- (instancetype)initWithCenterCoordinate:(CLLocationCoordinate2D)coordinate radius:(CLLocationDistance)radius {
    self = [super init];
    if (self) {
        _coordinate = coordinate;
        _radius = radius;
        _boundingMapRect = [self MKMapRectForCoordinate:_coordinate radius:_radius];
        _editingCoordinate = YES;
        _editingRadius = YES;
        _fillInside = YES;
        _shouldShowRadiusText = YES;
    }
    return self;
}

#pragma mark - Accessor

- (void)setCoordinate:(CLLocationCoordinate2D)coordinate {
    if ((_coordinate.latitude != coordinate.latitude) || (_coordinate.longitude != coordinate.longitude)) {
        _coordinate = coordinate;
        _boundingMapRect = [self MKMapRectForCoordinate:_coordinate radius:_radius];
    }
}

- (void)setRadius:(CLLocationDistance)radius {
    if (_radius != radius) {
        _radius = radius;
        _boundingMapRect = [self MKMapRectForCoordinate:_coordinate radius:_radius];
    }
}

#pragma mark - Additional

- (MKMapRect)MKMapRectForCoordinate:(CLLocationCoordinate2D)coordinate radius:(CLLocationDistance)radius {
    MKCoordinateRegion r = MKCoordinateRegionMakeWithDistance(coordinate, radius *2.f, radius *2.f);
    MKMapPoint a = MKMapPointForCoordinate(CLLocationCoordinate2DMake(r.center.latitude + r.span.latitudeDelta *.5f, r.center.longitude - r.span.longitudeDelta *.5f));
    MKMapPoint b = MKMapPointForCoordinate(CLLocationCoordinate2DMake(r.center.latitude - r.span.latitudeDelta *.5f, r.center.longitude + r.span.longitudeDelta *.5f));
    return MKMapRectMake(MIN(a.x,b.x), MIN(a.y,b.y), ABS(a.x-b.x), ABS(a.y-b.y));
}

@end
