//
//  DBMapSelectorViewController.m
//  DBMapSelectorViewControllerExample
//
//  Created by Denis Bogatyrev on 27.03.15.
//  Copyright (c) 2015 Denis Bogatyrev. All rights reserved.
//

#import "DBMapSelectorGestureRecognizer.h"

#import "DBMapSelectorOverlay.h"
#import "DBMapSelectorOverlayRenderer.h"
#import "DBMapSelectorManager.h"


NSInteger const defaultRadius       = 1000;
NSInteger const defaultMinDistance  = 100;
NSInteger const defaultMaxDistance  = 10000;


@interface DBMapSelectorManager () {
    DBMapSelectorOverlay            *_selectorOverlay;
    DBMapSelectorOverlayRenderer    *_selectorOverlayRenderer;

    BOOL                            _mapViewGestureEnabled;
    MKMapPoint                      _prevMapPoint;
    CLLocationDistance              _prevRadius;
    CGRect                          _radiusTouchRect;
    UIView                          *_radiusTouchView;
}

@end

@implementation DBMapSelectorManager

- (void)setMapView:(MKMapView *)mapView {
    _mapView = mapView;
    [self prepareForFirstUse];
}

- (void)prepareForFirstUse {

    [self selectorSetDefaults];

    _selectorOverlay = [[DBMapSelectorOverlay alloc] initWithCenterCoordinate:_circleCoordinate radius:_circleRadius];
    [self.mapView addOverlay:_selectorOverlay];

#ifdef DEBUG
    _radiusTouchView = [[UIView alloc] initWithFrame:CGRectZero];
    _radiusTouchView.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:.5f];
    _radiusTouchView.userInteractionEnabled = NO;
//    [self.mapView addSubview:_radiusTouchView];
#endif

    _mapViewGestureEnabled = YES;
    [self.mapView addGestureRecognizer:[self selectorGestureRecognizer]];

    [self performSelector:@selector(recalculateRadiusTouchRect) withObject:nil afterDelay:.2f];

}

#pragma mark Defaults

- (void)selectorSetDefaults {
    self.editingType = DBMapSelectorEditingTypeFull;
    self.circleRadius = defaultRadius;
    self.circleRadiusMin = defaultMinDistance;
    self.circleRadiusMax = defaultMaxDistance;
    self.hidden = NO;
    self.fillInside = YES;
}

#pragma mark - Life cycle

#pragma mark - GestureRecognizer

- (DBMapSelectorGestureRecognizer *)selectorGestureRecognizer {
    
    __weak typeof(self)weakSelf = self;
    DBMapSelectorGestureRecognizer *selectorGestureRecognizer = [[DBMapSelectorGestureRecognizer alloc] init];
    
    selectorGestureRecognizer.touchesBeganCallback = ^(NSSet * touches, UIEvent * event) {
//        NSLog(@"touchesBeganCallback");
        UITouch *touch = [touches anyObject];
        CGPoint touchPoint = [touch locationInView:weakSelf.mapView];
//        NSLog(@"---- %@", CGRectContainsPoint(_selectorRadiusRect, p) ? @"Y" : @"N");
        
        CLLocationCoordinate2D coord = [weakSelf.mapView convertPoint:touchPoint toCoordinateFromView:weakSelf.mapView];
        MKMapPoint mapPoint = MKMapPointForCoordinate(coord);
        
        if (CGRectContainsPoint(_radiusTouchRect, touchPoint) && _selectorOverlay.editingRadius && !weakSelf.hidden){
            if (_delegate && [_delegate respondsToSelector:@selector(mapSelectorManagerWillBeginHandlingUserInteraction:)]) {
                [_delegate mapSelectorManagerWillBeginHandlingUserInteraction:self];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.mapView.scrollEnabled = NO;
                weakSelf.mapView.userInteractionEnabled = NO;
                _mapViewGestureEnabled = NO;
            });
        } else {
            weakSelf.mapView.scrollEnabled = YES;
            weakSelf.mapView.userInteractionEnabled = YES;
        }
        _prevMapPoint = mapPoint;
        _prevRadius = weakSelf.circleRadius;
    };
    
    selectorGestureRecognizer.touchesMovedCallback = ^(NSSet * touches, UIEvent * event) {
//        NSLog(@"  touchesMovedCallback");
        if(!_mapViewGestureEnabled && [event allTouches].count == 1){
            UITouch *touch = [touches anyObject];
            CGPoint touchPoint = [touch locationInView:weakSelf.mapView];
            
            CLLocationCoordinate2D coord = [weakSelf.mapView convertPoint:touchPoint toCoordinateFromView:weakSelf.mapView];
            MKMapPoint mapPoint = MKMapPointForCoordinate(coord);
            
            double meterDistance = (mapPoint.x - _prevMapPoint.x)/MKMapPointsPerMeterAtLatitude(weakSelf.mapView.centerCoordinate.latitude) + _prevRadius;
            weakSelf.circleRadius = MIN( MAX( meterDistance, weakSelf.circleRadiusMin ), weakSelf.circleRadiusMax );
        }
    };
    
    selectorGestureRecognizer.touchesEndedCallback = ^(NSSet * touches, UIEvent * event) {
//        NSLog(@"    touchesEndedCallback");
        weakSelf.mapView.scrollEnabled = YES;
        weakSelf.mapView.userInteractionEnabled = YES;

        if (_prevRadius != weakSelf.circleRadius) {
            [weakSelf recalculateRadiusTouchRect];
//            if (((_prevRadius / weakSelf.circleRadius) >= 1.25f) || ((_prevRadius / weakSelf.circleRadius) <= .75f)) {
                [weakSelf updateMapRegionForMapSelector];
//            }
        }
        if(!_mapViewGestureEnabled) {
            if (_delegate && [_delegate respondsToSelector:@selector(mapSelectorManagerDidHandleUserInteraction:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate mapSelectorManagerDidHandleUserInteraction:self];
                });
            }
        }
        _mapViewGestureEnabled = YES;
    };
    
    return selectorGestureRecognizer;
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
    }
}

- (void)setHidden:(BOOL)hidden {
    if (_hidden != hidden) {
        _hidden = hidden;
        
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
    region.span = MKCoordinateSpanMake(selectorRegion.span.latitudeDelta *2.f, selectorRegion.span.longitudeDelta *2.f);
    [self.mapView setRegion:region animated:YES];
}

#pragma mark - MKMapView Delegate

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
