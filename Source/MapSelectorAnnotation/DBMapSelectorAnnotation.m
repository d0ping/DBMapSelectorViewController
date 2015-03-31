//
//  DBMapSelectorAnnotation.m
//  DBMapSelectorViewControllerExample
//
//  Created by Denis Bogatyrev on 27.03.15.
//  Copyright (c) 2015 Denis Bogatyrev. All rights reserved.
//

#import "DBMapSelectorAnnotation.h"

@implementation DBMapSelectorAnnotation

@synthesize coordinate = _coordinate;

- (void)setCoordinate:(CLLocationCoordinate2D)coordinate {
    _coordinate = coordinate;
}

@end
