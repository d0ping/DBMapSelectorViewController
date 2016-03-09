//
//  DBMapSelectorOverlayRenderer.m
//  DBMapSelectorViewController
//
//  Created by Denis Bogatyrev on 27.03.15.
//
//  The MIT License (MIT)
//  Copyright (c) 2015 Denis Bogatyrev.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
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

- (NSArray *)overlayObserverArray {
    return @[NSStringFromSelector(@selector(radius)),
             NSStringFromSelector(@selector(editingCoordinate)),
             NSStringFromSelector(@selector(editingRadius)),
             NSStringFromSelector(@selector(fillInside))];
}

- (void)addOverlayObserver {
    for (NSString *keyPath in [self overlayObserverArray]) {
        [_selectorOverlay addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)removeOverlayObserver {
    for (NSString *keyPath in [self overlayObserverArray]) {
        [_selectorOverlay removeObserver:self forKeyPath:keyPath];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:[_selectorOverlay class]]) {
        if ([[self overlayObserverArray] containsObject:keyPath]) {
            [self invalidatePath];
        }
    }
}

#pragma mark - Drawing

- (void)drawMapRect:(MKMapRect)mapRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context {
    MKMapPoint mpoint = MKMapPointForCoordinate([[self overlay] coordinate]);

    CLLocationDistance radius = _selectorOverlay.radius;
    CGFloat radiusAtLatitude = radius * MKMapPointsPerMeterAtLatitude([[self overlay] coordinate].latitude);
    
    MKMapRect circlebounds = MKMapRectMake(mpoint.x, mpoint.y, radiusAtLatitude *2, radiusAtLatitude * 2);
    CGRect overlayRect = [self rectForMapRect:circlebounds];
    
//    CGFloat radiusAtLatitude = (_selectorOverlay.radius) * MKMapPointsPerMeterAtLatitude([[self overlay] coordinate].latitude);
//    CGRect overlayRect = [self rectForMapRect:_selectorOverlay.boundingMapRect];
    
    [self drawMainOverlayFillInside:_selectorOverlay.fillInside mapRect:mapRect radius:radiusAtLatitude overlayRect:overlayRect inContext:context];
    [self drawCenterPointWithAllowEditing:_selectorOverlay.editingCoordinate mapRect:mapRect radius:radiusAtLatitude overlayRect:overlayRect inContext:context];
    [self drawRadiusPointWithAllowEditing:_selectorOverlay.editingRadius mapRect:mapRect radius:radiusAtLatitude overlayRect:overlayRect inContext:context];
    [self drawRadiusLineWithText:_selectorOverlay.shouldShowRadiusText mapRect:mapRect centerMapPoint:mpoint radius:radius overlayRect:overlayRect zoomScale:zoomScale inContext:context];
    
    UIGraphicsPopContext();
}

#pragma mark Helpers

- (void)drawMainOverlayFillInside:(BOOL)fillInside mapRect:(MKMapRect)mapRect radius:(CGFloat)radius overlayRect:(CGRect)overlayRect inContext:(CGContextRef)context {
    CGRect rect = [self rectForMapRect:mapRect];
    if (fillInside && !CGRectIntersectsRect( rect, [self rectForMapRect:[self.overlay boundingMapRect]] )) {
        return;
    }
    
    CGContextSetStrokeColorWithColor(context, self.strokeColor.CGColor);
    CGContextSetLineWidth(context, overlayRect.size.width *.015f);
    CGContextSetShouldAntialias(context, YES);
    
    if (!fillInside) {
        CGRect rect = [self rectForMapRect:mapRect];
        CGContextSaveGState(context);
        CGContextAddRect(context, rect);
        CGContextSetFillColorWithColor(context, [self.fillColor colorWithAlphaComponent:.2f].CGColor);
        CGContextFillRect(context, rect);
        CGContextRestoreGState(context);
        
        CGContextSaveGState(context);
        CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
        CGContextSetBlendMode(context, kCGBlendModeClear);
        CGContextFillEllipseInRect(context, [self rectForMapRect:[self.overlay boundingMapRect]]);
        CGContextRestoreGState(context);
    }
    
    CGContextSetFillColorWithColor(context, (fillInside ? [self.fillColor colorWithAlphaComponent:.2f].CGColor : [UIColor clearColor].CGColor));
    CGContextAddArc(context, overlayRect.origin.x, overlayRect.origin.y, radius, 0, 2 * M_PI, true);
    CGContextDrawPath(context, kCGPathFillStroke);
}

- (void)drawCenterPointWithAllowEditing:(BOOL)allowEdit mapRect:(MKMapRect)mapRect radius:(CGFloat)radius overlayRect:(CGRect)overlayRect inContext:(CGContextRef)context {
    CGRect rect = [self rectForMapRect:mapRect];
    CGFloat pointRadius = radius * (allowEdit ? .1f : .015f);
    CGRect pointVisibleRect = CGRectMake(overlayRect.origin.x - pointRadius * 1.5f, overlayRect.origin.y - pointRadius * 1.5f, pointRadius *3.f, pointRadius *3.f) ;
    if (!CGRectIntersectsRect( rect, pointVisibleRect)) {
        return;
    }
    
    CGContextSetFillColorWithColor(context, [self.fillColor colorWithAlphaComponent:.75f].CGColor);
    CGContextAddArc(context, overlayRect.origin.x, overlayRect.origin.y, pointRadius, 0, 2 * M_PI, true);
    CGContextDrawPath(context, kCGPathFillStroke);
}

- (void)drawRadiusPointWithAllowEditing:(BOOL)allowEdit mapRect:(MKMapRect)mapRect radius:(CGFloat)radius overlayRect:(CGRect)overlayRect inContext:(CGContextRef)context {
    CGRect rect = [self rectForMapRect:mapRect];
    CGFloat pointRadius = radius * (allowEdit ? .075f : .015f);
    CGRect pointVisibleRect = CGRectMake(overlayRect.origin.x + radius - pointRadius * 1.5f, overlayRect.origin.y - pointRadius * 1.5f, pointRadius *3.f, pointRadius *3.f) ;
    if (!CGRectIntersectsRect( rect, pointVisibleRect)) {
        return;
    }
    
    CGContextSetFillColorWithColor(context, self.strokeColor.CGColor);
    CGContextAddArc(context, overlayRect.origin.x + radius, overlayRect.origin.y, pointRadius, 0, 2 * M_PI, true);
    CGContextDrawPath(context, kCGPathFillStroke);
}

- (void)drawRadiusLineWithText:(BOOL)showText mapRect:(MKMapRect)mapRect centerMapPoint:(MKMapPoint)centerMapPoint radius:(CGFloat)radius overlayRect:(CGRect)overlayRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context {
    CGRect rect = [self rectForMapRect:mapRect];
    CGRect lineVisibleRect = CGRectMake(overlayRect.origin.x, overlayRect.origin.y - overlayRect.size.height *.2f, overlayRect.size.width, overlayRect.size.height *.25f) ;
    if (!CGRectIntersectsRect( rect, lineVisibleRect)) {
        return;
    }
    
    CGFloat kDashedLinesLength[] = {overlayRect.size.width * .01f, overlayRect.size.width * .01f};
    CGContextSetLineWidth(context, overlayRect.size.width *.01f);
    CGContextSetLineDash(context, .0f, kDashedLinesLength, 1.f);
    
    CGContextMoveToPoint(context, overlayRect.origin.x + (_selectorOverlay.editingCoordinate ? overlayRect.size.width * .05f : .0f), overlayRect.origin.y);
    CGContextAddLineToPoint(context, overlayRect.origin.x + overlayRect.size.width * .5f, overlayRect.origin.y);
    CGContextStrokePath(context);
    
    if (showText) {
        CGFloat fontSize = radius * zoomScale;
        NSString *radiusStr = [self.class stringForRadius:radius];
        CGPoint point = CGPointMake([self pointForMapPoint:centerMapPoint].x + overlayRect.size.width * .18f, [self pointForMapPoint:centerMapPoint].y - overlayRect.size.width * .03f);
        CGContextSetFillColorWithColor(context, self.strokeColor.CGColor);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        CGContextSelectFont(context, "HelveticaNeue-Bold", fontSize, kCGEncodingMacRoman);
#pragma clang diagnostic pop
        CGContextSetTextDrawingMode(context, kCGTextFill);
        CGAffineTransform xform = CGAffineTransformMake(1.0 / zoomScale, 0.0, 0.0, -1.0 / zoomScale, 0.0, 0.0);
        CGContextSetTextMatrix(context, xform);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        CGContextShowTextAtPoint(context, point.x, point.y, [radiusStr cStringUsingEncoding:NSUTF8StringEncoding], radiusStr.length);
#pragma clang diagnostic pop
    }
}

#pragma mark - Public

+ (NSString *)stringForRadius:(CLLocationDistance)radius {
    NSString *radiusStr;
    if (radius >= 1000) {
        NSString *diatanceOfKmStr = [NSString stringWithFormat:@"%.1f", radius * .001f];
        radiusStr = [NSString stringWithFormat:NSLocalizedString(@"%@ km", @"RADIUS_IN_KILOMETRES km"), diatanceOfKmStr];
    } else {
        NSString *diatanceOfMeterStr = [NSString stringWithFormat:@"%.0f", radius];
        radiusStr = [NSString stringWithFormat:NSLocalizedString(@"%@ m", @"RADIUS IN METRES m"), diatanceOfMeterStr];
    }
    return radiusStr;
}

@end
