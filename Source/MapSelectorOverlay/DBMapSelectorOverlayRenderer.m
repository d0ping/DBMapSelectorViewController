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

static const CGFloat kDefaultAlphaComponent = .2f;
static const CGFloat kCenterPointAlphaComponent = .75f;

static const CGFloat kDefaultLineWidthCoef = .015f;
static const CGFloat kFullLineWidthCoef = 1.f;
static const CGFloat kDefaultPointRadiusCoef = .015f;
static const CGFloat kEditCenterPointRadiusCoef = .1f;
static const CGFloat kEditRadiusPointRadiusCoef = .05f;
static const CGFloat kDefaultDashLineCoef = .01f;

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
    
    MKMapRect circlebounds = MKMapRectMake(mpoint.x, mpoint.y, radiusAtLatitude *2.f, radiusAtLatitude *2.f);
    CGRect overlayRect = [self rectForMapRect:circlebounds];
    
    [self drawMainCircleOverlayIfNeddedOnMapRect:mapRect fillInside:_selectorOverlay.fillInside radius:radiusAtLatitude overlayRect:overlayRect inContext:context];
    [self drawCenterPointIfNeddedOnMapRect:mapRect allowEditing:_selectorOverlay.editingCoordinate radius:radiusAtLatitude overlayRect:overlayRect inContext:context];
    [self drawRadiusPointIfNeddedOnMapRect:mapRect allowEditing:_selectorOverlay.editingRadius radius:radiusAtLatitude overlayRect:overlayRect inContext:context];
    [self drawRadiusLineIfNeddedOnMapRect:mapRect showText:_selectorOverlay.shouldShowRadiusText centerMapPoint:mpoint radius:radius overlayRect:overlayRect zoomScale:zoomScale inContext:context];
}

#pragma mark Helpers

- (void)drawMainCircleOverlayIfNeddedOnMapRect:(MKMapRect)mapRect fillInside:(BOOL)fillInside radius:(CGFloat)radius overlayRect:(CGRect)overlayRect inContext:(CGContextRef)context {
    CGRect rect = [self rectForMapRect:mapRect];
    if (fillInside && !CGRectIntersectsRect( rect, [self rectForMapRect:[self.overlay boundingMapRect]] )) {
        return;
    }
    
    CGContextSetStrokeColorWithColor(context, self.strokeColor.CGColor);
    CGContextSetLineWidth(context, overlayRect.size.width * kDefaultLineWidthCoef);
    CGContextSetShouldAntialias(context, YES);
    
    if (!fillInside) {
        CGRect rect = [self rectForMapRect:mapRect];
        CGContextSaveGState(context);
        CGContextAddRect(context, rect);
        CGContextSetFillColorWithColor(context, [self.fillColor colorWithAlphaComponent:kDefaultAlphaComponent].CGColor);
        CGContextFillRect(context, rect);
        CGContextRestoreGState(context);
        
        CGContextSaveGState(context);
        CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
        CGContextSetBlendMode(context, kCGBlendModeClear);
        CGContextFillEllipseInRect(context, [self rectForMapRect:[self.overlay boundingMapRect]]);
        CGContextRestoreGState(context);
    }
    
    CGContextSetFillColorWithColor(context, (fillInside ? [self.fillColor colorWithAlphaComponent:kDefaultAlphaComponent].CGColor : [UIColor clearColor].CGColor));
    CGContextAddArc(context, overlayRect.origin.x, overlayRect.origin.y, radius, 0, 2 * M_PI, true);
    CGContextDrawPath(context, kCGPathFillStroke);
}

- (void)drawCenterPointIfNeddedOnMapRect:(MKMapRect)mapRect allowEditing:(BOOL)allowEdit radius:(CGFloat)radius overlayRect:(CGRect)overlayRect inContext:(CGContextRef)context {
    CGRect rect = [self rectForMapRect:mapRect];
    CGFloat pointRadius = radius * (allowEdit ? kEditCenterPointRadiusCoef : kDefaultPointRadiusCoef);
    CGSize pointVisibleSize = CGSizeMake(pointRadius *3.f, pointRadius *3.f);           // set 150% because drawing point with border line
    CGRect pointVisibleRect = CGRectMake(overlayRect.origin.x - pointVisibleSize.width *.5f, overlayRect.origin.y - pointVisibleSize.height *.5f, pointVisibleSize.width, pointVisibleSize.height) ;
    if (!CGRectIntersectsRect( rect, pointVisibleRect)) {
        return;
    }
    
    CGContextSetFillColorWithColor(context, [self.fillColor colorWithAlphaComponent:kCenterPointAlphaComponent].CGColor);
    CGContextAddArc(context, overlayRect.origin.x, overlayRect.origin.y, pointRadius, 0, 2 * M_PI, true);
    CGContextDrawPath(context, kCGPathFillStroke);
}

- (void)drawRadiusPointIfNeddedOnMapRect:(MKMapRect)mapRect allowEditing:(BOOL)allowEdit radius:(CGFloat)radius overlayRect:(CGRect)overlayRect inContext:(CGContextRef)context {
    CGRect rect = [self rectForMapRect:mapRect];
    CGFloat pointRadius = radius * (allowEdit ? kEditRadiusPointRadiusCoef : kDefaultPointRadiusCoef);
    CGSize pointVisibleSize = CGSizeMake(pointRadius *3.f, pointRadius *3.f);           // set 150% because drawing point with border line
    CGRect pointVisibleRect = CGRectMake(overlayRect.origin.x + radius - pointVisibleSize.width *.5f, overlayRect.origin.y - pointVisibleSize.height *.5f, pointVisibleSize.width, pointVisibleSize.height) ;
    if (!CGRectIntersectsRect( rect, pointVisibleRect)) {
        return;
    }
    
    CGContextSetFillColorWithColor(context, self.strokeColor.CGColor);
    CGContextAddArc(context, overlayRect.origin.x + radius, overlayRect.origin.y, pointRadius, 0, 2 * M_PI, true);
    CGContextDrawPath(context, kCGPathFillStroke);
}

- (void)drawRadiusLineIfNeddedOnMapRect:(MKMapRect)mapRect showText:(BOOL)showText centerMapPoint:(MKMapPoint)centerMapPoint radius:(CGFloat)radius overlayRect:(CGRect)overlayRect zoomScale:(MKZoomScale)zoomScale inContext:(CGContextRef)context {
    CGRect rect = [self rectForMapRect:mapRect];
    CGSize lineVisibleSize = CGSizeMake(overlayRect.size.width *.5f, overlayRect.size.height *.15f);        // set 15% of overlayRect.size for drawing line with text
    CGRect lineVisibleRect = CGRectMake(overlayRect.origin.x, overlayRect.origin.y - overlayRect.size.height *.1f, lineVisibleSize.width, lineVisibleSize.height) ;
    if (!CGRectIntersectsRect( rect, lineVisibleRect)) {
        return;
    }
    
    CGFloat kDashedLinesLength[] = {overlayRect.size.width * kDefaultDashLineCoef, overlayRect.size.width * kDefaultDashLineCoef};
    CGContextSetLineWidth(context, overlayRect.size.width * kDefaultDashLineCoef);
    CGContextSetLineDash(context, .0f, kDashedLinesLength, kFullLineWidthCoef);
    
    CGContextMoveToPoint(context, overlayRect.origin.x + (_selectorOverlay.editingCoordinate ? overlayRect.size.width * kEditRadiusPointRadiusCoef : .0f), overlayRect.origin.y);
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
        CGAffineTransform xform = CGAffineTransformMakeScale(1.0 / zoomScale, -1.0 / zoomScale);
        CGContextSetTextMatrix(context, xform);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        CGContextShowTextAtPoint(context, point.x, point.y, [radiusStr cStringUsingEncoding:NSUTF8StringEncoding], radiusStr.length);
#pragma clang diagnostic pop
    }
}

#pragma mark - Public

+ (NSString *)stringForRadius:(CLLocationDistance)radius {
    NSString *radiusStr = nil;
    if (radius >= 1000) {       // 1000 meters
        NSString *diatanceOfKmStr = [NSString stringWithFormat:@"%.1f", radius * .001f];
        radiusStr = [NSString stringWithFormat:NSLocalizedString(@"%@ km", @"RADIUS_IN_KILOMETRES km"), diatanceOfKmStr];
    } else {
        NSString *diatanceOfMeterStr = [NSString stringWithFormat:@"%.0f", radius];
        radiusStr = [NSString stringWithFormat:NSLocalizedString(@"%@ m", @"RADIUS IN METRES m"), diatanceOfMeterStr];
    }
    return radiusStr;
}

@end
