//
//  DBMapSelectorViewController.m
//  DBMapSelectorViewControllerExample
//
//  Created by Denis Bogatyrev on 18.04.15.
//  Copyright (c) 2015 Denis Bogatyrev. All rights reserved.
//

#import "DBMapSelectorViewController.h"
#import "DBMapSelectorManager.h"

@interface DBMapSelectorViewController ()

@property (nonatomic) DBMapSelectorManager *mapSelectorManager;

@end

@implementation DBMapSelectorViewController

- (DBMapSelectorManager *)mapSelectorManager {
    if (!_mapSelectorManager) {
        _mapSelectorManager = [DBMapSelectorManager new];
        _mapSelectorManager.delegate = self;
    }
    return _mapSelectorManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mapSelectorManager.mapView = _mapView;
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    return [self.mapSelectorManager mapView:mapView viewForAnnotation:annotation];
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    [self.mapSelectorManager mapView:mapView annotationView:annotationView didChangeDragState:newState fromOldState:oldState];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay {
    return [self.mapSelectorManager mapView:mapView rendererForOverlay:overlay];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    [self.mapSelectorManager mapView:mapView regionDidChangeAnimated:animated];
}

@end
