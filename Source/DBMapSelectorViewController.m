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


NSInteger const defaultMinDistance = 100;
NSInteger const defaultMaxDistance = 10000;


@interface DBMapSelectorViewController () {
    DBMapSelectorOverlay            *_selectorOverlay;
    DBMapSelectorOverlayRenderer    *_selectorOverlayRenderer;

    // TODO:
    BOOL                        _mapViewGestureEnabled;
    MKMapPoint                  _lastPoint;
    CLLocationDistance          _prevRadius;
    CGRect                      _radiusTouchRect;
    
    UIView                      *_radiusTouchView;
}

@end

@implementation DBMapSelectorViewController

- (void)selectorSetDefaults {
    _selectorCoordinate = CLLocationCoordinate2DMake(55.75399400, 37.62209300);// _mapView.userLocation.coordinate;
    _selectorRadius = 1000;
    _selectorRadiusMin = defaultMinDistance;
    _selectorRadiusMax = defaultMaxDistance;
    _selectorEnabled = YES;
    _selectorFixedCoordinate = NO;
    _selectorInside = YES;
}

#pragma mark - Life cycle

- (void)loadView {
    [super loadView];
    [self selectorSetDefaults];
    
    DBMapSelectorAnnotation *selectorAnnotation = [[DBMapSelectorAnnotation alloc] init]; //WithCoordinate:_selectorCoordinate];
    selectorAnnotation.coordinate = _selectorCoordinate;
    [self.mapView addAnnotation:selectorAnnotation];
    
    _selectorOverlay = [[DBMapSelectorOverlay alloc] initWithCenterCoordinate:_selectorCoordinate radius:_selectorRadius];
    [self.mapView addOverlay:_selectorOverlay];
    
    _mapViewGestureEnabled = YES;
    
    [self.mapView addGestureRecognizer:[self selectorGestureRecognizer]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
#ifdef DEBUG
    _radiusTouchView = [[UIView alloc] initWithFrame:CGRectZero];
    _radiusTouchView.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:.5f];
    _radiusTouchView.userInteractionEnabled = NO;
//    [self.mapView addSubview:_radiusTouchView];
#endif
    
    [self setMapRegionForSelector];
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
        
        if (CGRectContainsPoint(_radiusTouchRect, touchPoint)){
            __block int t = 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                t = 1;
                weakSelf.mapView.scrollEnabled = NO;
                _mapViewGestureEnabled = NO;
            });
        } else {
            weakSelf.mapView.scrollEnabled = YES;
        }
        _lastPoint = mapPoint;
        _prevRadius = weakSelf.selectorRadius;
    };
    
    selectorGestureRecognizer.touchesMovedCallback = ^(NSSet * touches, UIEvent * event) {
        if(!_mapViewGestureEnabled && [event allTouches].count == 1){
            UITouch *touch = [touches anyObject];
            CGPoint touchPoint = [touch locationInView:weakSelf.mapView];
            
            CLLocationCoordinate2D coord = [weakSelf.mapView convertPoint:touchPoint toCoordinateFromView:weakSelf.mapView];
            MKMapPoint mapPoint = MKMapPointForCoordinate(coord);
            
            double meterDistance = (mapPoint.x - _lastPoint.x)/MKMapPointsPerMeterAtLatitude(self.mapView.centerCoordinate.latitude) + _prevRadius;
            weakSelf.selectorRadius = MIN( MAX( meterDistance, _selectorRadiusMin ), _selectorRadiusMax );
//            NSLog(@"%.2f", (float)meterDistance);
        }
    };
    
    selectorGestureRecognizer.touchesEndedCallback = ^(NSSet * touches, UIEvent * event) {
        _mapViewGestureEnabled = YES;
        weakSelf.mapView.zoomEnabled = YES;
        weakSelf.mapView.scrollEnabled = YES;
        weakSelf.mapView.userInteractionEnabled = YES;
        
        if (_prevRadius != weakSelf.selectorRadius) {
            [weakSelf recalculateRadiusTouchRect];
//            if (_delegate && [_delegate respondsToSelector:@selector(mapViewController:didChangedSelectorRadius:)]) {
//                [_delegate mapViewController:self didChangedSelectorRadius:_setRadius];
//            }
            
            if (((_prevRadius / weakSelf.selectorRadius) >= 1.25f) || ((_prevRadius / weakSelf.selectorRadius) <= .75f)) {
                [weakSelf setMapRegionForSelector];
            }
        }
    };
    
    return selectorGestureRecognizer;
}

#pragma mark - DBMapSelectorViewController Protocol

- (void)didChangeCoordinate:(CLLocationCoordinate2D)coordinate {
}

- (void)didChangeRadius:(CLLocationDistance)radius {
}

#pragma mark - Accessors

- (void)setSelectorRadius:(CLLocationDistance)selectorRadius {
    if (_selectorRadius != selectorRadius) {
        _selectorRadius = selectorRadius;
        
        [self didChangeRadius:_selectorRadius];
        
        _selectorOverlay.radius = _selectorRadius;
    }
}

- (void)setSelectorCoordinate:(CLLocationCoordinate2D)selectorCoordinate {
    if ((_selectorCoordinate.latitude != selectorCoordinate.latitude) || (_selectorCoordinate.longitude != selectorCoordinate.longitude)) {
        _selectorCoordinate = selectorCoordinate;
        
        [self didChangeCoordinate:_selectorCoordinate];
        
        [self.mapView removeOverlay:_selectorOverlay];
        _selectorOverlay.coordinate = _selectorCoordinate;
        [self.mapView addOverlay:_selectorOverlay];
        [self recalculateRadiusTouchRect];
    }
}

- (void)setSelectorFillColor:(UIColor *)selectorFillColor {
    if (_selectorFillColor != selectorFillColor) {
        _selectorFillColor = selectorFillColor;
        _selectorOverlayRenderer.fillColor = selectorFillColor;
        [_selectorOverlayRenderer invalidatePath];
    }
}

- (void)setSelectorStrokeColor:(UIColor *)selectorStrokeColor {
    if (_selectorStrokeColor != selectorStrokeColor) {
        _selectorStrokeColor = selectorStrokeColor;
        _selectorOverlayRenderer.strokeColor = selectorStrokeColor;
        [_selectorOverlayRenderer invalidatePath];
    }
}

- (void)setSelectorEnabled:(BOOL)selectorEnabled {
    if (_selectorEnabled != selectorEnabled) {
        _selectorEnabled = selectorEnabled;
        _selectorOverlay.editing = _selectorEnabled;
        
        for (id<MKAnnotation> annotation in self.mapView.annotations) {
            if ([annotation isKindOfClass:[DBMapSelectorAnnotation class]]) {
                [self.mapView removeAnnotation:annotation];
            }
        }
        
        if (_selectorEnabled) {
            DBMapSelectorAnnotation *selectorAnnotation = [[DBMapSelectorAnnotation alloc] init];
            selectorAnnotation.coordinate = _selectorCoordinate;
            [self.mapView addAnnotation:selectorAnnotation];
        }
    }
}

#pragma mark - DEBUG

- (void)recalculateRadiusTouchRect {
    MKMapRect selectorMapRect = _selectorOverlay.boundingMapRect;
    MKMapPoint selectorRadiusPoint = MKMapPointMake(MKMapRectGetMaxX(selectorMapRect), MKMapRectGetMidY(selectorMapRect));
    MKCoordinateRegion coordinateRegion = MKCoordinateRegionMakeWithDistance(MKCoordinateForMapPoint(selectorRadiusPoint), _selectorRadius *.3f, _selectorRadius *.3f);
    BOOL needDisplay = MKMapRectContainsPoint(self.mapView.visibleMapRect, selectorRadiusPoint);
    _radiusTouchRect = needDisplay ? [self.mapView convertRegion:coordinateRegion toRectToView:self.view] : CGRectZero;
#ifdef DEBUG
    _radiusTouchView.frame = _radiusTouchRect;
    _radiusTouchView.hidden = !needDisplay;
#endif
}

- (void)setMapRegionForSelector {
    MKCoordinateRegion selectorRegion = MKCoordinateRegionForMapRect(_selectorOverlay.boundingMapRect);
    MKCoordinateRegion region;
    region.center = selectorRegion.center;
    region.span = MKCoordinateSpanMake(selectorRegion.span.latitudeDelta *2.f, selectorRegion.span.longitudeDelta *2.f);
    [self.mapView setRegion:region animated:YES];
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
            self.selectorCoordinate = annotationView.annotation.coordinate;

            // TODO:
//            if (_delegate && [_delegate respondsToSelector:@selector(mapViewController:didChangedSelectorCenter:)]) {
//                [_delegate mapViewController:self didChangedSelectorCenter:annotationView.annotation.coordinate];
//            }
            if (NO == MKMapRectContainsRect(mapView.visibleMapRect, _selectorOverlay.boundingMapRect)) {
                [self performSelector:@selector(setMapRegionForSelector) withObject:nil afterDelay:.3f];
            }
        }
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    MKOverlayRenderer *overlayRenderer;
    if ([overlay isKindOfClass:[DBMapSelectorOverlay class]]) {
        _selectorOverlayRenderer = [[DBMapSelectorOverlayRenderer alloc] initWithSelectorOverlay:(DBMapSelectorOverlay *)overlay];
        _selectorOverlayRenderer.fillColor = _selectorFillColor;
        _selectorOverlayRenderer.strokeColor = _selectorStrokeColor;
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
