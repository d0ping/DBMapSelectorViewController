//
//  DBMapSelectorOverlayRenderer.m
//  DBMapSelectorViewControllerExample
//
//  Created by Denis Bogatyrev on 27.03.15.
//  Copyright (c) 2015 Denis Bogatyrev. All rights reserved.
//

#import "DBMapSelectorOverlayRenderer.h"
#import "DBMapSelectorOverlay.h"

@interface DBMapSelectorOverlayRenderer () {
    DBMapSelectorOverlay    *_selectorOverlay;
}

@end

@implementation DBMapSelectorOverlayRenderer

@synthesize fillColor = _fillColor;
@synthesize strokeColor = _strokeColor;

- (instancetype)initWithSelectorOverlay:(DBMapSelectorOverlay *)selectorOverlay {
    self = [super initWithOverlay:selectorOverlay];
    if (self) {
        _selectorOverlay = selectorOverlay;
        _fillColor = [UIColor orangeColor];
        _strokeColor = [UIColor darkGrayColor];
        [self addOverlayObserver];
    }
    return self;
}

- (void)dealloc {
    [self removeOverlayObserver];
}

#pragma mark - Observering

- (void)addOverlayObserver {
    [_selectorOverlay addObserver:self forKeyPath:NSStringFromSelector(@selector(radius)) options:NSKeyValueObservingOptionNew context:nil];
    [_selectorOverlay addObserver:self forKeyPath:NSStringFromSelector(@selector(editingCoordinate)) options:NSKeyValueObservingOptionNew context:nil];
    [_selectorOverlay addObserver:self forKeyPath:NSStringFromSelector(@selector(editingRadius)) options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeOverlayObserver {
    [_selectorOverlay removeObserver:self forKeyPath:NSStringFromSelector(@selector(radius))];
    [_selectorOverlay removeObserver:self forKeyPath:NSStringFromSelector(@selector(editingCoordinate))];
    [_selectorOverlay removeObserver:self forKeyPath:NSStringFromSelector(@selector(editingRadius))];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:[_selectorOverlay class]]) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(radius))] ||
            [keyPath isEqualToString:NSStringFromSelector(@selector(editingCoordinate))] ||
            [keyPath isEqualToString:NSStringFromSelector(@selector(editingRadius))]) {
            [self invalidatePath];
        }
    }
}

#pragma mark - Drawing

- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context {
    MKMapPoint mpoint = MKMapPointForCoordinate([[self overlay] coordinate]);
    
    CGFloat radiusAtLatitude = (_selectorOverlay.radius)*MKMapPointsPerMeterAtLatitude([[self overlay] coordinate].latitude);
    
    MKMapRect circlebounds = MKMapRectMake(mpoint.x, mpoint.y, radiusAtLatitude *2, radiusAtLatitude * 2);
    CGRect overlayRect = [self rectForMapRect:circlebounds];
    
//    CGFloat radiusAtLatitude = (_selectorOverlay.radius) * MKMapPointsPerMeterAtLatitude([[self overlay] coordinate].latitude);
//    CGRect overlayRect = [self rectForMapRect:_selectorOverlay.boundingMapRect];
    
    CGContextSetStrokeColorWithColor(context, self.strokeColor.CGColor);
    CGContextSetFillColorWithColor(context, [self.fillColor colorWithAlphaComponent:.2f].CGColor);
    CGContextSetLineWidth(context, overlayRect.size.width *.015f);
    CGContextSetShouldAntialias(context, YES);
    
    CGContextAddArc(context, overlayRect.origin.x, overlayRect.origin.y, radiusAtLatitude, 0, 2 * M_PI, true);
    CGContextDrawPath(context, kCGPathFillStroke);
    
    CGContextSetFillColorWithColor(context, [self.fillColor colorWithAlphaComponent:.75f].CGColor);
    CGContextAddArc(context, overlayRect.origin.x, overlayRect.origin.y, radiusAtLatitude *(_selectorOverlay.editingCoordinate ? .1f : .015f), 0, 2 * M_PI, true);
    CGContextDrawPath(context, kCGPathFillStroke);
    
    CGContextSetFillColorWithColor(context, self.strokeColor.CGColor);
    CGContextAddArc(context, overlayRect.origin.x + radiusAtLatitude, overlayRect.origin.y, radiusAtLatitude * (_selectorOverlay.editingRadius ? .075f : .015f), 0, 2 * M_PI, true);
    CGContextDrawPath(context, kCGPathFillStroke);
    
    CGFloat kDashedLinesLength[] = {overlayRect.size.width * .01f, overlayRect.size.width * .01f};
    CGContextSetLineWidth(context, overlayRect.size.width *.01f);
    CGContextSetLineDash(context, .0f, kDashedLinesLength, 1.f);
    
    CGContextMoveToPoint(context, overlayRect.origin.x + (_selectorOverlay.editingCoordinate ? overlayRect.size.width * .05f : .0f), overlayRect.origin.y);
    CGContextAddLineToPoint(context, overlayRect.origin.x + overlayRect.size.width * .5f, overlayRect.origin.y);
    CGContextStrokePath(context);
    
    CGFloat fontSize = _selectorOverlay.radius * zoomScale;
    NSString *radiusStr;
    if (_selectorOverlay.radius >= 1000) {
        NSString *diatanceOfKmStr = [NSString stringWithFormat:@"%.1f", _selectorOverlay.radius * .001f];
        radiusStr = [NSString stringWithFormat:@"%@ km", diatanceOfKmStr];
    } else {
        NSString *diatanceOfMeterStr = [NSString stringWithFormat:@"%.0f", _selectorOverlay.radius];
        radiusStr = [NSString stringWithFormat:@"%@ m", diatanceOfMeterStr];
    }
    CGPoint point = CGPointMake([self pointForMapPoint:mpoint].x + overlayRect.size.width * .18f, [self pointForMapPoint:mpoint].y - overlayRect.size.width * .03f);
    CGContextSetFillColorWithColor(context, self.strokeColor.CGColor);
    CGContextSelectFont(context, "HelveticaNeue", fontSize, kCGEncodingMacRoman);
    CGContextSetTextDrawingMode(context, kCGTextFill);
    CGAffineTransform xform = CGAffineTransformMake(1.0 / zoomScale, 0.0, 0.0, -1.0 / zoomScale, 0.0, 0.0);
    CGContextSetTextMatrix(context, xform);
    CGContextShowTextAtPoint(context, point.x, point.y, [radiusStr cStringUsingEncoding:NSUTF8StringEncoding], radiusStr.length);
    
    UIGraphicsPopContext();
}


@end
