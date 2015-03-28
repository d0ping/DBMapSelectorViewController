//
//  DBMapSelectorGestureRecognizer.m
//  DBMapSelectorViewControllerExample
//
//  Created by Denis Bogatyrev on 28.03.15.
//  Copyright (c) 2015 Denis Bogatyrev. All rights reserved.
//

#import "DBMapSelectorGestureRecognizer.h"

@implementation DBMapSelectorGestureRecognizer

@synthesize touchesBeganCallback;
@synthesize touchesMovedCallback;
@synthesize touchesEndedCallback;

- (instancetype)init {
    if (self = [super init]) {
        self.cancelsTouchesInView = NO;
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (touchesBeganCallback) {
        touchesBeganCallback(touches, event);
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if(touchesEndedCallback) {
        touchesEndedCallback(touches, event);
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if(touchesMovedCallback) {
        touchesMovedCallback(touches, event);
    }
}

- (void)reset {
}

- (void)ignoreTouch:(UITouch *)touch forEvent:(UIEvent *)event {
}

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer {
    return NO;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer {
    return NO;
}

@end
