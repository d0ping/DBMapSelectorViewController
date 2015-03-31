//
//  DBMapSelectorGestureRecognizer.h
//  DBMapSelectorViewControllerExample
//
//  Created by Denis Bogatyrev on 28.03.15.
//  Copyright (c) 2015 Denis Bogatyrev. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^TouchesEventBlock)(NSSet * touches, UIEvent * event);

@interface DBMapSelectorGestureRecognizer : UIGestureRecognizer {
    TouchesEventBlock touchesBeganCallback;
}

@property(copy) TouchesEventBlock touchesBeganCallback;
@property(copy) TouchesEventBlock touchesMovedCallback;
@property(copy) TouchesEventBlock touchesEndedCallback;

@end
