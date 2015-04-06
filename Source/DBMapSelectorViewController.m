//
//  DBMapSelectorViewController.m
//  DBMapSelectorViewControllerExample
//
//  Created by Denis Bogatyrev on 27.03.15.
//  Copyright (c) 2015 Denis Bogatyrev. All rights reserved.
//

#import "DBMapSelectorViewController.h"

#import "DBMapSelectorGestureRecognizer.h"

#import "DBMapSelectorAnnotation.h"
#import "DBMapSelectorOverlay.h"
#import "DBMapSelectorOverlayRenderer.h"


NSInteger const defaultRadius       = 1000;
NSInteger const defaultMinDistance  = 100;
NSInteger const defaultMaxDistance  = 10000;


@interface DBMapSelectorViewController () {
    DBMapSelectorOverlay            *_selectorOverlay;
    DBMapSelectorOverlayRenderer    *_selectorOverlayRenderer;

    BOOL                            _mapViewGestureEnabled;
    MKMapPoint                      _prevMapPoint;
    CLLocationDistance              _prevRadius;
    CGRect                          _radiusTouchRect;
    UIView                          *_radiusTouchView;
}

@end

@implementation DBMapSelectorViewController

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

- (void)viewDidLoad {
    [super viewDidLoad];
    [self selectorSetDefaults];
    
    [self displaySelectorAnnotationIfNeeded];
    
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

#pragma mark - GestureRecognizer

- (DBMapSelectorGestureRecognizer *)selectorGestureRecognizer {
    
    __weak typeof(self)weakSelf = self;
    DBMapSelectorGestureRecognizer *selectorGestureRecognizer = [[DBMapSelectorGestureRecognizer alloc] init];
    
    selectorGestureRecognizer.touchesBeganCallback = ^(NSSet * touches, UIEvent * event) {
        UITouch *touch = [touches anyObject];
        CGPoint touchPoint = [touch locationInView:weakSelf.mapView];
//        NSLog(@"---- %@", CGRectContainsPoint(_selectorRadiusRect, p) ? @"Y" : @"N");
        
        CLLocationCoordinate2D coord = [weakSelf.mapView convertPoint:touchPoint toCoordinateFromView:weakSelf.mapView];
        MKMapPoint mapPoint = MKMapPointForCoordinate(coord);
        
        if (CGRectContainsPoint(_radiusTouchRect, touchPoint) && _selectorOverlay.editingRadius && (weakSelf.hidden == NO)){
            __block int t = 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                t = 1;
                weakSelf.mapView.scrollEnabled = NO;
                _mapViewGestureEnabled = NO;
            });
        } else {
            weakSelf.mapView.scrollEnabled = YES;
        }
        _prevMapPoint = mapPoint;
        _prevRadius = weakSelf.circleRadius;
    };
    
    selectorGestureRecognizer.touchesMovedCallback = ^(NSSet * touches, UIEvent * event) {
        if(!_mapViewGestureEnabled && [event allTouches].count == 1){
            UITouch *touch = [touches anyObject];
            CGPoint touchPoint = [touch locationInView:weakSelf.mapView];
            
            CLLocationCoordinate2D coord = [weakSelf.mapView convertPoint:touchPoint toCoordinateFromView:weakSelf.mapView];
            MKMapPoint mapPoint = MKMapPointForCoordinate(coord);
            
            double meterDistance = (mapPoint.x - _prevMapPoint.x)/MKMapPointsPerMeterAtLatitude(self.mapView.centerCoordinate.latitude) + _prevRadius;
            weakSelf.circleRadius = MIN( MAX( meterDistance, weakSelf.circleRadiusMin ), weakSelf.circleRadiusMax );
//            NSLog(@"%.2f", (float)meterDistance);
        }
    };
    
    selectorGestureRecognizer.touchesEndedCallback = ^(NSSet * touches, UIEvent * event) {
        _mapViewGestureEnabled = YES;
        weakSelf.mapView.zoomEnabled = YES;
        weakSelf.mapView.scrollEnabled = YES;
        weakSelf.mapView.userInteractionEnabled = YES;
        
        if (_prevRadius != weakSelf.circleRadius) {
            [weakSelf recalculateRadiusTouchRect];
            if (((_prevRadius / weakSelf.circleRadius) >= 1.25f) || ((_prevRadius / weakSelf.circleRadius) <= .75f)) {
                [weakSelf updateMapRegionForMapSelector];
            }
        }
    };
    
    return selectorGestureRecognizer;
}

#pragma mark - Accessors

- (void)setCircleRadius:(CLLocationDistance)circleRadius {
    if (_circleRadius!= MAX(MIN(circleRadius, _circleRadiusMax), _circleRadiusMin)) {
        _circleRadius = MAX(MIN(circleRadius, _circleRadiusMax), _circleRadiusMin);
        _selectorOverlay.radius = _circleRadius;
        if (_delegate && [_delegate respondsToSelector:@selector(mapSelectorViewController:didChangeRadius:)]) {
            [_delegate mapSelectorViewController:self didChangeRadius:_circleRadius];
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
        
        for (id<MKAnnotation> currentAnnotation in self.mapView.annotations) {
            if ([currentAnnotation isKindOfClass:DBMapSelectorAnnotation.class]) {
                [currentAnnotation setCoordinate:_circleCoordinate];
                break;
            }
        }
        [self.mapView removeOverlay:_selectorOverlay];
        _selectorOverlay.coordinate = _circleCoordinate;
        if (_hidden == NO) {
            [self.mapView addOverlay:_selectorOverlay];
        }
        [self recalculateRadiusTouchRect];
        if (_delegate && [_delegate respondsToSelector:@selector(mapSelectorViewController:didChangeCoordinate:)]) {
            [_delegate mapSelectorViewController:self didChangeCoordinate:_circleCoordinate];
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

#pragma mark - Additional

- (void)recalculateRadiusTouchRect {
    MKMapRect selectorMapRect = _selectorOverlay.boundingMapRect;
    MKMapPoint selectorRadiusPoint = MKMapPointMake(MKMapRectGetMaxX(selectorMapRect), MKMapRectGetMidY(selectorMapRect));
    MKCoordinateRegion coordinateRegion = MKCoordinateRegionMakeWithDistance(MKCoordinateForMapPoint(selectorRadiusPoint), _circleRadius *.3f, _circleRadius *.3f);
    BOOL needDisplay = MKMapRectContainsPoint(self.mapView.visibleMapRect, selectorRadiusPoint) && (_hidden == NO);
    _radiusTouchRect = needDisplay ? [self.mapView convertRegion:coordinateRegion toRectToView:self.view] : CGRectZero;
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
        return selectorAnnotationView;
    } else {
        return nil;
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    if ([annotationView.annotation isKindOfClass:[DBMapSelectorAnnotation class]]) {
        if(newState == MKAnnotationViewDragStateStarting){
            _mapViewGestureEnabled = YES;
        }
        if (newState == MKAnnotationViewDragStateEnding) {
            self.circleCoordinate = annotationView.annotation.coordinate;
            if (NO == MKMapRectContainsRect(mapView.visibleMapRect, _selectorOverlay.boundingMapRect)) {
                [self performSelector:@selector(updateMapRegionForMapSelector) withObject:nil afterDelay:.3f];
            }
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
