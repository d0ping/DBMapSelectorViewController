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

- (void)selectorSetDefaults {
    _selectorEditingType = DBMapSelectorEditingTypeFull;
    _selectorRadius = defaultRadius;
    _selectorRadiusMin = defaultMinDistance;
    _selectorRadiusMax = defaultMaxDistance;
    _selectorHidden = NO;
}

#pragma mark - Life cycle

- (void)loadView {
    [super loadView];
    [self selectorSetDefaults];
    
    [self displaySelectorAnnotationIfNeeded];
    
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
        
        if (CGRectContainsPoint(_radiusTouchRect, touchPoint) && _selectorOverlay.editingRadius && (_selectorHidden == NO)){
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
        _prevRadius = weakSelf.selectorRadius;
    };
    
    selectorGestureRecognizer.touchesMovedCallback = ^(NSSet * touches, UIEvent * event) {
        if(!_mapViewGestureEnabled && [event allTouches].count == 1){
            UITouch *touch = [touches anyObject];
            CGPoint touchPoint = [touch locationInView:weakSelf.mapView];
            
            CLLocationCoordinate2D coord = [weakSelf.mapView convertPoint:touchPoint toCoordinateFromView:weakSelf.mapView];
            MKMapPoint mapPoint = MKMapPointForCoordinate(coord);
            
            double meterDistance = (mapPoint.x - _prevMapPoint.x)/MKMapPointsPerMeterAtLatitude(self.mapView.centerCoordinate.latitude) + _prevRadius;
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

#pragma mark - Accessors

- (void)setSelectorRadius:(CLLocationDistance)selectorRadius {
    if (_selectorRadius != MAX(MIN(selectorRadius, _selectorRadiusMax), _selectorRadiusMin)) {
        _selectorRadius = MAX(MIN(selectorRadius, _selectorRadiusMax), _selectorRadiusMin);
        _selectorOverlay.radius = _selectorRadius;
        [self didChangeRadius:_selectorRadius];
    }
}

- (void)setSelectorRadiusMax:(CLLocationDistance)selectorRadiusMax {
    if (_selectorRadiusMax != selectorRadiusMax) {
        _selectorRadiusMax = selectorRadiusMax;
        _selectorRadiusMin = MIN(_selectorRadiusMin, _selectorRadiusMax);
        self.selectorRadius = _selectorRadius;
    }
}

- (void)setSelectorRadiusMin:(CLLocationDistance)selectorRadiusMin {
    if (_selectorRadiusMin != selectorRadiusMin) {
        _selectorRadiusMin = selectorRadiusMin;
        _selectorRadiusMax = MAX(_selectorRadiusMax, _selectorRadiusMin);
        self.selectorRadius = _selectorRadius;
    }
}

- (void)setSelectorCoordinate:(CLLocationCoordinate2D)selectorCoordinate {
    if ((_selectorCoordinate.latitude != selectorCoordinate.latitude) || (_selectorCoordinate.longitude != selectorCoordinate.longitude)) {
        _selectorCoordinate = selectorCoordinate;
        
        for (id<MKAnnotation> currentAnnotation in self.mapView.annotations) {
            if ([currentAnnotation isKindOfClass:DBMapSelectorAnnotation.class]) {
                [currentAnnotation setCoordinate:_selectorCoordinate];
                break;
            }
        }
        [self.mapView removeOverlay:_selectorOverlay];
        _selectorOverlay.coordinate = _selectorCoordinate;
        if (_selectorHidden == NO) {
            [self.mapView addOverlay:_selectorOverlay];
        }
        [self recalculateRadiusTouchRect];
        [self didChangeCoordinate:_selectorCoordinate];
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

- (void)setSelectorEditingType:(DBMapSelectorEditingType)selectorEditingType {
    if (_selectorEditingType != selectorEditingType) {
        _selectorEditingType = selectorEditingType;
        
        _selectorOverlay.editingCoordinate = (_selectorEditingType == DBMapSelectorEditingTypeCoordinateOnly || _selectorEditingType == DBMapSelectorEditingTypeFull);
        _selectorOverlay.editingRadius = (_selectorEditingType == DBMapSelectorEditingTypeRadiusOnly || _selectorEditingType == DBMapSelectorEditingTypeFull);
        [self displaySelectorAnnotationIfNeeded];
    }
}

- (void)setSelectorHidden:(BOOL)selectorHidden {
    if (_selectorHidden != selectorHidden) {
        _selectorHidden = selectorHidden;
        
        [self displaySelectorAnnotationIfNeeded];
        if (_selectorHidden) {
            [self.mapView removeOverlay:_selectorOverlay];
        } else {
            [self.mapView addOverlay:_selectorOverlay];
        }
        [self recalculateRadiusTouchRect];
    }
}

#pragma mark - Additional

- (void)recalculateRadiusTouchRect {
    MKMapRect selectorMapRect = _selectorOverlay.boundingMapRect;
    MKMapPoint selectorRadiusPoint = MKMapPointMake(MKMapRectGetMaxX(selectorMapRect), MKMapRectGetMidY(selectorMapRect));
    MKCoordinateRegion coordinateRegion = MKCoordinateRegionMakeWithDistance(MKCoordinateForMapPoint(selectorRadiusPoint), _selectorRadius *.3f, _selectorRadius *.3f);
    BOOL needDisplay = MKMapRectContainsPoint(self.mapView.visibleMapRect, selectorRadiusPoint) && (_selectorHidden == NO);
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

- (void)displaySelectorAnnotationIfNeeded {
    for (id<MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[DBMapSelectorAnnotation class]]) {
            [self.mapView removeAnnotation:annotation];
        }
    }
    
    if (_selectorHidden == NO &&
        ((_selectorEditingType == DBMapSelectorEditingTypeFull) ||
         (_selectorEditingType == DBMapSelectorEditingTypeCoordinateOnly))) {
        DBMapSelectorAnnotation *selectorAnnotation = [[DBMapSelectorAnnotation alloc] init];
        selectorAnnotation.coordinate = _selectorCoordinate;
        [self.mapView addAnnotation:selectorAnnotation];
    }
}

#pragma mark - DBMapSelectorViewController Protocol

- (void)didChangeCoordinate:(CLLocationCoordinate2D)coordinate {
}

- (void)didChangeRadius:(CLLocationDistance)radius {
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
