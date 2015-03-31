//
//  DBMapSelectorOverlayRenderer.h
//  DBMapSelectorViewControllerExample
//
//  Created by Denis Bogatyrev on 27.03.15.
//  Copyright (c) 2015 Denis Bogatyrev. All rights reserved.
//

#import <MapKit/MapKit.h>

@class DBMapSelectorOverlay;
@interface DBMapSelectorOverlayRenderer : MKCircleRenderer

- (instancetype)initWithSelectorOverlay:(DBMapSelectorOverlay *)selectorOverlay;

@end
