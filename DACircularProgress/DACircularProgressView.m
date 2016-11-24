//
//  DACircularProgressView.m
//  DACircularProgress
//
//  Created by Daniel Amitay on 2/6/12.
//  Copyright (c) 2012 Daniel Amitay. All rights reserved.
//

#import "DACircularProgressView.h"

#import <QuartzCore/QuartzCore.h>

@interface DACircularProgressLayer : CALayer

@property(nonatomic, strong) UIColor *trackTintColor; ///< 进度圆的颜色 默认[[UIColor whiteColor] colorWithAlphaComponent:0.3f]]
@property(nonatomic, strong) UIColor *progressTintColor; ///< 剩余部分圆的颜色 默认[UIColor whiteColor]
@property(nonatomic, strong) UIColor *innerTintColor; ///< 默认nil
@property(nonatomic) NSInteger roundedCorners; ///< 进度条的两端是否圆形 参考lineCap round 默认NO
@property(nonatomic) CGFloat thicknessRatio; ///< 进度条占整个进度圆的比例 默认0.3f
@property(nonatomic) CGFloat progress;
@property(nonatomic) NSInteger clockwiseProgress;///< 是否顺时针旋转 默认YES

@end

@implementation DACircularProgressLayer

@dynamic trackTintColor;
@dynamic progressTintColor;
@dynamic innerTintColor;
@dynamic roundedCorners;
@dynamic thicknessRatio;
@dynamic progress;
@dynamic clockwiseProgress;

/// 进度改变redisplay 这样就可以使用[CABasicAnimation animationWithKeyPath:@"progress"];
+ (BOOL)needsDisplayForKey:(NSString *)key
{
    if ([key isEqualToString:@"progress"]) {
        return YES;
    } else {
        return [super needsDisplayForKey:key];
    }
}

- (void)drawInContext:(CGContextRef)context
{
    CGRect rect = self.bounds;
    CGPoint centerPoint = CGPointMake(rect.size.width / 2.0f, rect.size.height / 2.0f);
    // 半径以长宽中小的为准
    CGFloat radius = MIN(rect.size.height, rect.size.width) / 2.0f;
    
    // 是否顺时针方向
    BOOL clockwise = (self.clockwiseProgress != 0);
    
    // 最大进度不超过1
    CGFloat progress = MIN(self.progress, 1.0f - FLT_EPSILON);
    
    // 顺时针[-90,270] 逆时针[270,-90]
    CGFloat radians = 0;
    if (clockwise) {
        radians = (float)((progress * 2.0f * M_PI) - M_PI_2);
    } else {
        radians = (float)(3 * M_PI_2 - (progress * 2.0f * M_PI));
    }
    
    // 进度的圆 是个完整的圆
    // 添加一个圆 半径为radius 角度范围[360,0] 填充颜色trackTintColor
    CGContextSetFillColorWithColor(context, self.trackTintColor.CGColor);
    CGMutablePathRef trackPath = CGPathCreateMutable();
    CGPathMoveToPoint(trackPath, NULL, centerPoint.x, centerPoint.y);
    CGPathAddArc(trackPath, NULL, centerPoint.x, centerPoint.y, radius, (float)(2.0f * M_PI), 0.0f, TRUE);
    CGPathCloseSubpath(trackPath);
    CGContextAddPath(context, trackPath);
    CGContextFillPath(context);
    CGPathRelease(trackPath);
    
    // 剩余部分的圆形 用这个圆将上面的圆遮住
    // 添加一个圆 半径为radius 角度范围[270,radians] 填充颜色progressTintColor
    if (progress > 0.0f) {
        CGContextSetFillColorWithColor(context, self.progressTintColor.CGColor);
        CGMutablePathRef progressPath = CGPathCreateMutable();
        CGPathMoveToPoint(progressPath, NULL, centerPoint.x, centerPoint.y);
        CGPathAddArc(progressPath, NULL, centerPoint.x, centerPoint.y, radius, (float)(3.0f * M_PI_2), radians, !clockwise);
        CGPathCloseSubpath(progressPath);
        CGContextAddPath(context, progressPath);
        CGContextFillPath(context);
        CGPathRelease(progressPath);
    }
    
    if (progress > 0.0f && self.roundedCorners) {
        CGFloat pathWidth = radius * self.thicknessRatio;
        CGFloat xOffset = radius * (1.0f + ((1.0f - (self.thicknessRatio / 2.0f)) * cosf(radians)));
        CGFloat yOffset = radius * (1.0f + ((1.0f - (self.thicknessRatio / 2.0f)) * sinf(radians)));
        CGPoint endPoint = CGPointMake(xOffset, yOffset);
        
        CGRect startEllipseRect = (CGRect) {
            .origin.x = centerPoint.x - pathWidth / 2.0f,
            .origin.y = 0.0f,
            .size.width = pathWidth,
            .size.height = pathWidth
        };
        CGContextAddEllipseInRect(context, startEllipseRect);
        CGContextFillPath(context);
        
        CGRect endEllipseRect = (CGRect) {
            .origin.x = endPoint.x - pathWidth / 2.0f,
            .origin.y = endPoint.y - pathWidth / 2.0f,
            .size.width = pathWidth,
            .size.height = pathWidth
        };
        CGContextAddEllipseInRect(context, endEllipseRect);
        CGContextFillPath(context);
    }

    // 内圆 通过这个较小的内圆覆盖前面的大圆来实现进度条的样式
    // kCGBlendModeClear R=0 R is the premultiplied result
    CGContextSetBlendMode(context, kCGBlendModeClear);
    CGFloat innerRadius = radius * (1.0f - self.thicknessRatio);
    CGRect clearRect = (CGRect) {
        .origin.x = centerPoint.x - innerRadius,
        .origin.y = centerPoint.y - innerRadius,
        .size.width = innerRadius * 2.0f,
        .size.height = innerRadius * 2.0f
    };
    CGContextAddEllipseInRect(context, clearRect);
    CGContextFillPath(context);

    // 内圆的填充颜色
    if (self.innerTintColor) {
        CGContextSetBlendMode(context, kCGBlendModeNormal);
        CGContextSetFillColorWithColor(context, [self.innerTintColor CGColor]);
        CGContextAddEllipseInRect(context, clearRect);
        CGContextFillPath(context);
    }
}

@end

@interface DACircularProgressView ()

@end

@implementation DACircularProgressView

+ (void) initialize
{
    if (self == [DACircularProgressView class]) {
        DACircularProgressView *circularProgressViewAppearance = [DACircularProgressView appearance];
        [circularProgressViewAppearance setTrackTintColor:[[UIColor whiteColor] colorWithAlphaComponent:0.3f]];
        [circularProgressViewAppearance setProgressTintColor:[UIColor whiteColor]];
        [circularProgressViewAppearance setInnerTintColor:nil];
        [circularProgressViewAppearance setBackgroundColor:[UIColor clearColor]];
        [circularProgressViewAppearance setThicknessRatio:0.3f];
        [circularProgressViewAppearance setRoundedCorners:NO];
        [circularProgressViewAppearance setClockwiseProgress:YES];
        
        [circularProgressViewAppearance setIndeterminateDuration:2.0f];
        [circularProgressViewAppearance setIndeterminate:NO];
    }
}

+ (Class)layerClass
{
    return [DACircularProgressLayer class];
}

- (DACircularProgressLayer *)circularProgressLayer
{
    return (DACircularProgressLayer *)self.layer;
}

- (id)init
{
    return [super initWithFrame:CGRectMake(0.0f, 0.0f, 40.0f, 40.0f)];
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    CGFloat windowContentsScale = self.window.screen.scale;
    self.circularProgressLayer.contentsScale = windowContentsScale;
    [self.circularProgressLayer setNeedsDisplay];
}


#pragma mark - Progress

- (CGFloat)progress
{
    return self.circularProgressLayer.progress;
}

- (void)setProgress:(CGFloat)progress
{
    [self setProgress:progress animated:NO];
}

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated
{
    [self setProgress:progress animated:animated initialDelay:0.0];
}

- (void)setProgress:(CGFloat)progress
           animated:(BOOL)animated
       initialDelay:(CFTimeInterval)initialDelay
{
    CGFloat pinnedProgress = MIN(MAX(progress, 0.0f), 1.0f);
    // duration 0-1
    [self setProgress:progress
             animated:animated
         initialDelay:initialDelay
         withDuration:fabs(self.progress - pinnedProgress)];
}

- (void)setProgress:(CGFloat)progress
           animated:(BOOL)animated
       initialDelay:(CFTimeInterval)initialDelay
       withDuration:(CFTimeInterval)duration
{
    [self.layer removeAnimationForKey:@"indeterminateAnimation"];
    [self.circularProgressLayer removeAnimationForKey:@"progress"];
    
    CGFloat pinnedProgress = MIN(MAX(progress, 0.0f), 1.0f);
    if (animated) {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"progress"];
        animation.duration = duration;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        animation.fillMode = kCAFillModeForwards;
        animation.fromValue = [NSNumber numberWithFloat:self.progress];
        animation.toValue = [NSNumber numberWithFloat:pinnedProgress];
        animation.beginTime = CACurrentMediaTime() + initialDelay;
        animation.delegate = self;
        [self.circularProgressLayer addAnimation:animation forKey:@"progress"];
    } else {
        [self.circularProgressLayer setNeedsDisplay];
        self.circularProgressLayer.progress = pinnedProgress;
    }
}

/// 通过Layer的needsDisplayForKey方法返回YES来使progress变成可动画的
/// 但是animation.fillMode = kCAFillModeForwards;仍然无效 所以这边需要处理
- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)flag
{
   NSNumber *pinnedProgressNumber = [animation valueForKey:@"toValue"];
   self.circularProgressLayer.progress = [pinnedProgressNumber floatValue];
}


#pragma mark - UIAppearance methods

- (UIColor *)trackTintColor
{
    return self.circularProgressLayer.trackTintColor;
}

- (void)setTrackTintColor:(UIColor *)trackTintColor
{
    self.circularProgressLayer.trackTintColor = trackTintColor;
    [self.circularProgressLayer setNeedsDisplay];
}

- (UIColor *)progressTintColor
{
    return self.circularProgressLayer.progressTintColor;
}

- (void)setProgressTintColor:(UIColor *)progressTintColor
{
    self.circularProgressLayer.progressTintColor = progressTintColor;
    [self.circularProgressLayer setNeedsDisplay];
}

- (UIColor *)innerTintColor
{
    return self.circularProgressLayer.innerTintColor;
}

- (void)setInnerTintColor:(UIColor *)innerTintColor
{
    self.circularProgressLayer.innerTintColor = innerTintColor;
    [self.circularProgressLayer setNeedsDisplay];
}

- (NSInteger)roundedCorners
{
    return self.roundedCorners;
}

- (void)setRoundedCorners:(NSInteger)roundedCorners
{
    self.circularProgressLayer.roundedCorners = roundedCorners;
    [self.circularProgressLayer setNeedsDisplay];
}

- (CGFloat)thicknessRatio
{
    return self.circularProgressLayer.thicknessRatio;
}

- (void)setThicknessRatio:(CGFloat)thicknessRatio
{
    self.circularProgressLayer.thicknessRatio = MIN(MAX(thicknessRatio, 0.f), 1.f);
    [self.circularProgressLayer setNeedsDisplay];
}

/// 无限旋转 大于0顺时针旋转 小于0逆时针旋转
- (NSInteger)indeterminate
{
    CAAnimation *spinAnimation = [self.layer animationForKey:@"indeterminateAnimation"];
    return (spinAnimation == nil ? 0 : 1);
}

- (void)setIndeterminate:(NSInteger)indeterminate
{
    if (indeterminate) {
        if (!self.indeterminate) {
            CABasicAnimation *spinAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
            spinAnimation.byValue = [NSNumber numberWithDouble:indeterminate > 0 ? 2.0f*M_PI : -2.0f*M_PI];
            spinAnimation.duration = self.indeterminateDuration;
            spinAnimation.repeatCount = HUGE_VALF;
            [self.layer addAnimation:spinAnimation forKey:@"indeterminateAnimation"];
        }
    } else {
        [self.layer removeAnimationForKey:@"indeterminateAnimation"];
    }
}

- (NSInteger)clockwiseProgress
{
    return self.circularProgressLayer.clockwiseProgress;
}

- (void)setClockwiseProgress:(NSInteger)clockwiseProgres
{
    self.circularProgressLayer.clockwiseProgress = clockwiseProgres;
    [self.circularProgressLayer setNeedsDisplay];
}

@end
