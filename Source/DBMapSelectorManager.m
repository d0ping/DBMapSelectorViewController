//
//  DBMapSelectorManager.m
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

#import "DBMapSelectorGestureRecognizer.h"

#import "DBMapSelectorAnnotation.h"
#import "DBMapSelectorOverlay.h"
#import "DBMapSelectorOverlayRenderer.h"
#import "DBMapSelectorManager.h"


static const NSInteger kDefaultRadius       = 1000;
static const NSInteger kDefaultMinDistance  = 100;
static const NSInteger kDefaultMaxDistance  = 10000;

@interface DBMapSelectorManager () {
    BOOL                            _isFirstTimeApplySelectorSettings;
    UIView                          *_radiusTouchView;
    UILongPressGestureRecognizer    *_longPressGestureRecognizer;
}

@property (strong, nonatomic) DBMapSelectorOverlay          *selectorOverlay;
@property (strong, nonatomic) DBMapSelectorOverlayRenderer  *selectorOverlayRenderer;

@property (assign, nonatomic) BOOL                          mapViewGestureEnabled;
@property (assign, nonatomic) MKMapPoint                    prevMapPoint;
@property (assign, nonatomic) CLLocationDistance            prevRadius;
@property (assign, nonatomic) CGRect                        radiusTouchRect;

@end

@implementation DBMapSelectorManager

- (instancetype)initWithMapView:(MKMapView *)mapView {
    self = [super init];
    if (self) {
        _isFirstTimeApplySelectorSettings = YES;
        _mapView = mapView;
        [self prepareForFirstUse];
    }
    return self;
}

- (void)prepareForFirstUse {
    [self selectorSetDefaults];
    
    _selectorOverlay = [[DBMapSelectorOverlay alloc] initWithCenterCoordinate:_circleCoordinate radius:_circleRadius];

#ifdef DEBUG
    _radiusTouchView = [[UIView alloc] initWithFrame:CGRectZero];
    _radiusTouchView.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:.5f];
    _radiusTouchView.userInteractionEnabled = NO;
//    [self.mapView addSubview:_radiusTouchView];
#endif

    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognizer:)];
    
    _mapViewGestureEnabled = YES;
    [self.mapView addGestureRecognizer:[self selectorGestureRecognizer]];
    
}

#pragma mark Defaults

- (void)selectorSetDefaults {
    self.editingType = DBMapSelectorEditingTypeFull;
    self.circleRadius = kDefaultRadius;
    self.circleRadiusMin = kDefaultMinDistance;
    self.circleRadiusMax = kDefaultMaxDistance;
    self.hidden = NO;
    self.fillInside = YES;
    self.shouldShowRadiusText = YES;
    self.fillColor = [UIColor orangeColor];
    self.strokeColor = [UIColor darkGrayColor];
    self.mapRegionCoef = 2.f;
}

- (void)applySelectorSettings {
    [self updateMapRegionForMapSelector];
    [self displaySelectorAnnotationIfNeeded];
    [self recalculateRadiusTouchRect];
    if (_isFirstTimeApplySelectorSettings) {
        _isFirstTimeApplySelectorSettings = NO;
        [self.mapView removeOverlay:_selectorOverlay];
        [self.mapView addOverlay:_selectorOverlay];
    }
}

#pragma mark - GestureRecognizer

- (DBMapSelectorGestureRecognizer *)selectorGestureRecognizer {
    
    __weak typeof(self)weakSelf = self;
    DBMapSelectorGestureRecognizer *selectorGestureRecognizer = [[DBMapSelectorGestureRecognizer alloc] init];
    
    selectorGestureRecognizer.touchesBeganCallback = ^(NSSet * touches, UIEvent * event) {
        UITouch *touch = [touches anyObject];
        CGPoint touchPoint = [touch locationInView:weakSelf.mapView];
//        NSLog(@"---- %@", CGRectContainsPoint(weakSelf.selectorRadiusRect, p) ? @"Y" : @"N");
        
        CLLocationCoordinate2D coord = [weakSelf.mapView convertPoint:touchPoint toCoordinateFromView:weakSelf.mapView];
        MKMapPoint mapPoint = MKMapPointForCoordinate(coord);
        
        if (CGRectContainsPoint(weakSelf.radiusTouchRect, touchPoint) && weakSelf.selectorOverlay.editingRadius && !weakSelf.hidden){
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(mapSelectorManagerWillBeginHandlingUserInteraction:)]) {
                [weakSelf.delegate mapSelectorManagerWillBeginHandlingUserInteraction:weakSelf];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.mapView.scrollEnabled = NO;
                weakSelf.mapView.userInteractionEnabled = NO;
                weakSelf.mapViewGestureEnabled = NO;
            });
        } else {
            weakSelf.mapView.scrollEnabled = YES;
            weakSelf.mapView.userInteractionEnabled = YES;
        }
        weakSelf.prevMapPoint = mapPoint;
        weakSelf.prevRadius = weakSelf.circleRadius;
    };
    
    selectorGestureRecognizer.touchesMovedCallback = ^(NSSet * touches, UIEvent * event) {
        if(!weakSelf.mapViewGestureEnabled && [event allTouches].count == 1){
            UITouch *touch = [touches anyObject];
            CGPoint touchPoint = [touch locationInView:weakSelf.mapView];
            
            CLLocationCoordinate2D coord = [weakSelf.mapView convertPoint:touchPoint toCoordinateFromView:weakSelf.mapView];
            MKMapPoint mapPoint = MKMapPointForCoordinate(coord);
            
            double meterDistance = (mapPoint.x - weakSelf.prevMapPoint.x)/MKMapPointsPerMeterAtLatitude(weakSelf.mapView.centerCoordinate.latitude) + weakSelf.prevRadius;
            weakSelf.circleRadius = MIN( MAX( meterDistance, weakSelf.circleRadiusMin ), weakSelf.circleRadiusMax );
        }
    };
    
    selectorGestureRecognizer.touchesEndedCallback = ^(NSSet * touches, UIEvent * event) {
        weakSelf.mapView.scrollEnabled = YES;
        weakSelf.mapView.userInteractionEnabled = YES;

        if (weakSelf.prevRadius != weakSelf.circleRadius) {
            [weakSelf recalculateRadiusTouchRect];
//            if (((weakSelf.prevRadius / weakSelf.circleRadius) >= 1.25f) || ((weakSelf.prevRadius / weakSelf.circleRadius) <= .75f)) {
                [weakSelf updateMapRegionForMapSelector];
//            }
        }
        if(!weakSelf.mapViewGestureEnabled) {
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(mapSelectorManagerDidHandleUserInteraction:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.delegate mapSelectorManagerDidHandleUserInteraction:weakSelf];
                });
            }
        }
        weakSelf.mapViewGestureEnabled = YES;
    };
    
    return selectorGestureRecognizer;
}

- (void)longPressGestureRecognizer:(UILongPressGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] &&
        ( self.editingType == DBMapSelectorEditingTypeFull || self.editingType == DBMapSelectorEditingTypeCoordinateOnly )) {
        switch (gestureRecognizer.state) {
            case UIGestureRecognizerStateBegan: {
                CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
                CLLocationCoordinate2D coord = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
                self.circleCoordinate = coord;
                [self displaySelectorAnnotationIfNeeded];
                break;
            }
            case UIGestureRecognizerStateEnded:
                if (NO == MKMapRectContainsRect(self.mapView.visibleMapRect, _selectorOverlay.boundingMapRect)) {
                    [self updateMapRegionForMapSelector];
                }
                break;
            default:
                break;
        }
    }
}

#pragma mark - Accessors

- (void)setCircleRadius:(CLLocationDistance)circleRadius {
    if (_circleRadius!= MAX(MIN(circleRadius, _circleRadiusMax), _circleRadiusMin)) {
        _circleRadius = MAX(MIN(circleRadius, _circleRadiusMax), _circleRadiusMin);
        _selectorOverlay.radius = _circleRadius;
        if (_delegate && [_delegate respondsToSelector:@selector(mapSelectorManager:didChangeRadius:)]) {
            [_delegate mapSelectorManager:self
                          didChangeRadius:_circleRadius];
        }
    }
}

- (void)setCircleRadiusMax:(CLLocationDistance)circleRadiusMax {
    if (_circleRadiusMax != circleRadiusMax) {
        _circleRadiusMax = circleRadiusMax;
        _circleRadiusMin = MIN(_circleRadiusMin, _circleRadiusMax);
        self.circleRadius = _circleRadius;
    }
}

- (void)setCircleRadiusMin:(CLLocationDistance)circleRadiusMin {
    if (_circleRadiusMin != circleRadiusMin) {
        _circleRadiusMin = circleRadiusMin;
        _circleRadiusMax = MAX(_circleRadiusMax, _circleRadiusMin);
        self.circleRadius = _circleRadius;
    }
}

- (void)setCircleCoordinate:(CLLocationCoordinate2D)circleCoordinate {
    if ((_circleCoordinate.latitude != circleCoordinate.latitude) || (_circleCoordinate.longitude != circleCoordinate.longitude)) {
        _circleCoordinate = circleCoordinate;
        [self.mapView removeOverlay:_selectorOverlay];
        _selectorOverlay.coordinate = _circleCoordinate;
        if (_hidden == NO) {
            [self.mapView addOverlay:_selectorOverlay];
        }
        [self recalculateRadiusTouchRect];
        if (_delegate && [_delegate respondsToSelector:@selector(mapSelectorManager:didChangeCoordinate:)]) {
            [_delegate mapSelectorManager:self
                      didChangeCoordinate:_circleCoordinate];
        }
    }
}

- (void)setFillColor:(UIColor *)fillColor {
    if (_fillColor != fillColor) {
        _fillColor = fillColor;
        _selectorOverlayRenderer.fillColor = fillColor;
        [_selectorOverlayRenderer invalidatePath];
    }
}

- (void)setStrokeColor:(UIColor *)strokeColor {
    if (_strokeColor != strokeColor) {
        _strokeColor = strokeColor;
        _selectorOverlayRenderer.strokeColor = strokeColor;
        [_selectorOverlayRenderer invalidatePath];
    }
}

- (void)setEditingType:(DBMapSelectorEditingType)editingType {
    if (_editingType != editingType) {
        _editingType = editingType;
        
        _selectorOverlay.editingCoordinate = (_editingType == DBMapSelectorEditingTypeCoordinateOnly || _editingType == DBMapSelectorEditingTypeFull);
        _selectorOverlay.editingRadius = (_editingType == DBMapSelectorEditingTypeRadiusOnly || _editingType == DBMapSelectorEditingTypeFull);
        [self displaySelectorAnnotationIfNeeded];
    }
}

- (void)setHidden:(BOOL)hidden {
    if (_hidden != hidden) {
        _hidden = hidden;
        
        [self displaySelectorAnnotationIfNeeded];
        if (_hidden) {
            [self.mapView removeOverlay:_selectorOverlay];
        } else {
            [self.mapView addOverlay:_selectorOverlay];
        }
        [self recalculateRadiusTouchRect];
    }
}

- (void)setFillInside:(BOOL)fillInside {
    if (_fillInside != fillInside) {
        _fillInside = fillInside;
        _selectorOverlay.fillInside = fillInside;
    }
}

- (void)setShouldShowRadiusText:(BOOL)shouldShowRadiusText {
    _selectorOverlay.shouldShowRadiusText = shouldShowRadiusText;
}

- (void)setShouldLongPressGesture:(BOOL)shouldLongPressGesture {
    if (_shouldLongPressGesture != shouldLongPressGesture) {
        _shouldLongPressGesture = shouldLongPressGesture;
        if (_shouldLongPressGesture) {
            [self.mapView addGestureRecognizer:_longPressGestureRecognizer];
        } else {
            [self.mapView removeGestureRecognizer:_longPressGestureRecognizer];
        }
    }
}

#pragma mark - Additional

- (void)recalculateRadiusTouchRect {
    MKMapRect selectorMapRect = _selectorOverlay.boundingMapRect;
    MKMapPoint selectorRadiusPoint = MKMapPointMake(MKMapRectGetMaxX(selectorMapRect), MKMapRectGetMidY(selectorMapRect));
    MKCoordinateRegion coordinateRegion = MKCoordinateRegionMakeWithDistance(MKCoordinateForMapPoint(selectorRadiusPoint), _circleRadius *.3f, _circleRadius *.3f);
    BOOL needDisplay = MKMapRectContainsPoint(self.mapView.visibleMapRect, selectorRadiusPoint) && (_hidden == NO);
    _radiusTouchRect = needDisplay ? [self.mapView convertRegion:coordinateRegion toRectToView:self.mapView] : CGRectZero;
#ifdef DEBUG
    _radiusTouchView.frame = _radiusTouchRect;
    _radiusTouchView.hidden = !needDisplay;
#endif
}

- (void)updateMapRegionForMapSelector {
    MKCoordinateRegion selectorRegion = MKCoordinateRegionForMapRect(_selectorOverlay.boundingMapRect);
    MKCoordinateRegion region;
    region.center = selectorRegion.center;
    region.span = MKCoordinateSpanMake(selectorRegion.span.latitudeDelta * _mapRegionCoef, selectorRegion.span.longitudeDelta * _mapRegionCoef);
    [self.mapView setRegion:region animated:YES];
}

- (void)displaySelectorAnnotationIfNeeded {
    for (id<MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[DBMapSelectorAnnotation class]]) {
            [self.mapView removeAnnotation:annotation];
        }
    }
    
    if (_hidden == NO && ((_editingType == DBMapSelectorEditingTypeFull) || (_editingType == DBMapSelectorEditingTypeCoordinateOnly))) {
        DBMapSelectorAnnotation *selectorAnnotation = [[DBMapSelectorAnnotation alloc] init];
        selectorAnnotation.coordinate = _circleCoordinate;
        [self.mapView addAnnotation:selectorAnnotation];
    }
}

#pragma mark - MKMapView Delegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[DBMapSelectorAnnotation class]]) {
        static NSString *selectorIdentifier = @"DBMapSelectorAnnotationView";
        MKPinAnnotationView *selectorAnnotationView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:selectorIdentifier];
        if (selectorAnnotationView) {
            selectorAnnotationView.annotation = annotation;
        } else {
            selectorAnnotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:selectorIdentifier];
            selectorAnnotationView.pinColor = MKPinAnnotationColorGreen;
            selectorAnnotationView.draggable = YES;
        }
        selectorAnnotationView.selected = YES;
        return selectorAnnotationView;
    } else {
        return nil;
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    if (newState == MKAnnotationViewDragStateStarting) {
        _mapViewGestureEnabled = YES;
    }
    if (newState == MKAnnotationViewDragStateEnding) {
        self.circleCoordinate = annotationView.annotation.coordinate;
        if (NO == MKMapRectContainsRect(mapView.visibleMapRect, _selectorOverlay.boundingMapRect)) {
            [self performSelector:@selector(updateMapRegionForMapSelector)
                       withObject:nil
                       afterDelay:.3f];
        }
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    MKOverlayRenderer *overlayRenderer;
    if ([overlay isKindOfClass:[DBMapSelectorOverlay class]]) {
        _selectorOverlayRenderer = [[DBMapSelectorOverlayRenderer alloc] initWithSelectorOverlay:(DBMapSelectorOverlay *)overlay];
        _selectorOverlayRenderer.fillColor = _fillColor;
        _selectorOverlayRenderer.strokeColor = _strokeColor;
        overlayRenderer = _selectorOverlayRenderer;
    } else if ([overlay isKindOfClass:[MKTileOverlay class]]) {
        overlayRenderer = [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    }
    return overlayRenderer;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    [self recalculateRadiusTouchRect];
}

@end
