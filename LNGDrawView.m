//
//  LNGDrawView.m
//  TouchTracker
//
//  Created by Lumi on 14-7-10.
//  Copyright (c) 2014年 LumiNg. All rights reserved.
//

#import "LNGDrawView.h"
#import "LNGLine.h"

@interface LNGDrawView() <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIPanGestureRecognizer *moveRecognizer;
@property (nonatomic, strong) NSMutableDictionary *linesInProgress;
@property (nonatomic, strong) NSMutableArray *finishedLines;
@property (nonatomic, weak) LNGLine *selectedLine;

@end

@implementation LNGDrawView

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.linesInProgress = [[NSMutableDictionary alloc] init];
        self.finishedLines = [[NSMutableArray alloc] init];
        self.backgroundColor = [UIColor grayColor];
        self.multipleTouchEnabled = YES;
        
        // Add gesture recognizer for double tap
        UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        doubleTapRecognizer.numberOfTapsRequired = 2;
        doubleTapRecognizer.delaysTouchesBegan = YES;
        [self addGestureRecognizer:doubleTapRecognizer];
        
        // Add gesture recognizer for tap-to-select
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        tapRecognizer.delaysTouchesBegan = YES;
        [tapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer]; // Important
        [self addGestureRecognizer:tapRecognizer];
        
        // Add gesture of long press
        UILongPressGestureRecognizer *pressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        [self addGestureRecognizer:pressRecognizer];
        
        // Add gesture of panning
        self.moveRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveLine:)];
        self.moveRecognizer.delegate = self;
        self.moveRecognizer.cancelsTouchesInView = NO;
        [self addGestureRecognizer:self.moveRecognizer];
    }
    return self;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == self.moveRecognizer) {
        return YES;
    }
    return NO;
}

- (void)moveLine:(UIPanGestureRecognizer *)gestureRecognizer
{
    if (!self.selectedLine) {
        return;
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if (self.selectedLine && [self point:[gestureRecognizer locationInView:self] isNearToLine:self.selectedLine]) {
            self.moveRecognizer.cancelsTouchesInView = YES;
        } else {
            self.selectedLine = nil;
        }
        UIMenuController *menu = [UIMenuController sharedMenuController];
        [menu setMenuVisible:NO animated:YES];
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        if (self.selectedLine) {
            // How far has the pan moved/
            CGPoint translation = [gestureRecognizer translationInView:self];
            
            // Add the translation to the current beginning and end points of the line
            CGPoint begin = self.selectedLine.begin;
            CGPoint end = self.selectedLine.end;
            begin.x += translation.x;
            begin.y += translation.y;
            end.x += translation.x;
            end.y += translation.y;
            
            self.selectedLine.begin = begin;
            self.selectedLine.end = end;
            
            [self setNeedsDisplay];
            [gestureRecognizer setTranslation:CGPointZero inView:self];
        }
        
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        self.moveRecognizer.cancelsTouchesInView = NO;
        if (self.selectedLine) {
            UIMenuController *menu = [UIMenuController sharedMenuController];
            CGPoint menuPoint;
            menuPoint.x = (self.selectedLine.begin.x + self.selectedLine.end.x) / 2;
            menuPoint.y = (self.selectedLine.begin.y + self.selectedLine.end.y) / 2;
            [menu setTargetRect:CGRectMake(menuPoint.x, menuPoint.y, 1, 1) inView:self];
            [menu setMenuVisible:YES animated:YES];
        }
    }
}

- (void)longPress:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [gestureRecognizer locationInView:self];
        self.selectedLine = [self lineAtPoint:point];
        
        if (self.selectedLine) {
            [self.linesInProgress removeAllObjects];
        }
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        self.selectedLine = nil;
    }
    [self setNeedsDisplay];
}

- (void)doubleTap:(UIGestureRecognizer *)gestureRecognizer
{
    NSLog(@"Recognized Double Tap");
    [self.linesInProgress removeAllObjects];
    [self.finishedLines removeAllObjects];
    [self setNeedsDisplay];
}

- (void)tap:(UIGestureRecognizer *)gestureRecognizer
{
    NSLog(@"Recognized Tap");
    
    CGPoint point = [gestureRecognizer locationInView:self];
    self.selectedLine = [self lineAtPoint:point];
    
    if (self.selectedLine) {
        
        // Make ourselves the target of menu item action messages
        [self becomeFirstResponder];
        
        // Grab the menu controller
        UIMenuController *menu = [UIMenuController sharedMenuController];
        
        // Create a new delete UIMenuItem
        UIMenuItem *deleteItem = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(deleteLine:)];
        
        menu.menuItems = @[deleteItem];
        
        // Tell the menu where it should come from and show it
        [menu setTargetRect:CGRectMake(point.x, point.y, 1, 1) inView:self];
        [menu setMenuVisible:YES animated:YES];
    } else {
        // Hide the menu if no line is selected
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
    }
    
    [self setNeedsDisplay];
}

- (void)deleteLine:(id)sender
{
    [self.finishedLines removeObject:self.selectedLine];
    [self setNeedsDisplay];
}

- (void)strokeLine:(LNGLine *)line
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineWidth = 10;
    path.lineCapStyle = kCGLineCapRound;
    
    [path moveToPoint:line.begin];
    [path addLineToPoint:line.end];
    [path stroke];
}

- (LNGLine *)lineAtPoint:(CGPoint)p
{
    // Find a line close to p
    for (LNGLine *line in self.finishedLines) {
        CGPoint start = line.begin;
        CGPoint end = line.end;
        
        // Check a few points on the line
        for (float t = 0.0; t <= 1.0; t += 0.05) {
            float x = start.x + t * (end.x - start.x);
            float y = start.y + t * (end.y - start.y);
            
            if (hypot(x - p.x, y - p.y) < 20.0) {
                return line;
            }
        }
    }
    
    return nil;
}

- (BOOL)point:(CGPoint)p isNearToLine:(LNGLine *)line
{
    CGPoint start = line.begin;
    CGPoint end = line.end;
    
    // Check a few points on the line
    for (float t = 0.0; t <= 1.0; t += 0.05) {
        float x = start.x + t * (end.x - start.x);
        float y = start.y + t * (end.y - start.y);
        
        if (hypot(x - p.x, y - p.y) < 20.0) {
            return YES;
        }
    }
    
    return NO;
}

- (void)drawRect:(CGRect)rect
{
    // Draw finished lines in black
    [[UIColor blackColor] set];
    for (LNGLine *line in self.finishedLines) {
        [self strokeLine:line];
    }
    
    [[UIColor redColor] set];
    for (NSValue *key in self.linesInProgress) {
        [self strokeLine:self.linesInProgress[key]];
    }
    
    if (self.selectedLine) {
        [[UIColor greenColor] set];
        [self strokeLine:self.selectedLine];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Began %@", NSStringFromSelector(_cmd));
    
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInView:self];
        
        LNGLine *line = [[LNGLine alloc] init];
        line.begin = location;
        line.end = location;
        
        NSValue *key = [NSValue valueWithNonretainedObject:touch];
        self.linesInProgress[key] = line;
    }
    
    [self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Moved %@", NSStringFromSelector(_cmd));
    
    for (UITouch *touch in touches) {
        NSValue *key = [NSValue valueWithNonretainedObject:touch];
        LNGLine *line = self.linesInProgress[key];
        line.end = [touch locationInView:self];
    }
    
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Ended %@", NSStringFromSelector(_cmd));
    
    for (UITouch *touch in touches) {
        NSValue *key = [NSValue valueWithNonretainedObject:touch];
        LNGLine *line = self.linesInProgress[key];
        [self.finishedLines addObject:line];
        [self.linesInProgress removeObjectForKey:key];
    }
    
    [self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Cancelled %@", NSStringFromSelector(_cmd));
    
    for (UITouch *touch in touches) {
        NSValue *key = [NSValue valueWithNonretainedObject:touch];
        [self.linesInProgress removeObjectForKey:key];
    }
    
    [self setNeedsDisplay];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
