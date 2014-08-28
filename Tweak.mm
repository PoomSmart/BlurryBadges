#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface SBIconColorSettings : NSObject
@end

@interface SBRootSettings : NSObject
- (SBIconColorSettings *)iconColorSettings;
@end

@interface SBPrototypeController : NSObject
+ (id)sharedInstance;
- (SBRootSettings *)rootSettings;
@end

@interface SBIcon : NSObject
- (UIImage *)getIconImage:(int)type;
- (BOOL)isFolderIcon;
- (void)noteBadgeDidChange;
@end

@interface SBIconImageView : UIView
@end

@interface SBIconView : UIView {
	CGPoint _wallpaperRelativeCloseBoxCenter;
	CGRect _visibleImageRect;
}
+ (CGSize)defaultIconImageSize;
@property(assign, nonatomic) CGPoint wallpaperRelativeImageCenter;
- (SBIcon *)icon;
- (SBIconImageView *)_iconImageView;
- (CGRect)_frameForAccessoryView;
@end

@interface SBIconListView : UIView
- (CGPoint)_wallpaperRelativeIconCenterForIconView:(SBIconView *)iconView;
@end

@interface SBFolderController : NSObject
- (SBIconListView *)iconListViewContainingIcon:(SBIcon *)icon;
@end

@interface SBIconModel : NSObject
- (NSArray *)leafIcons;
@end

@interface SBIconController : NSObject
+ (id)sharedInstance;
- (SBIconModel *)model;
- (SBFolderController *)_rootFolderController;
@end

@interface SBFolderIconView : SBIconView
@end

@interface SBIconBadgeView : UIView
- (CGPoint)accessoryOriginForIconBounds:(CGRect)frame;
- (void)setWallpaperRelativeCenter:(CGPoint)center;
@end

@interface SBIconBlurryBackgroundView : UIView
- (void)setWantsBlurEvaluator:(SBIconColorSettings *)iconColorSettings;
- (void)setWallpaperRelativeCenter:(CGPoint)center;
@end

@interface SBIconAccessoryImage : UIImage
@end

@interface SBDarkeningImageView : UIImageView
@end

struct pixel {
    unsigned char r, g, b, a;
};

@interface UIImage (Addition)
- (UIColor *)dominantColor;
@end

@interface UIColor (Addition)
- (UIColor *)shiftColor:(CGFloat)shift;
- (UIColor *)lighterColor;
- (UIColor *)darkerColor;
@end

@interface UIColor (API)
+ (UIColor *)systemGrayColor;
@end

@implementation UIImage (Addition)
 
- (UIColor *)dominantColor
{
    NSUInteger red = 0;
    NSUInteger green = 0;
    NSUInteger blue = 0;
    struct pixel* pixels = (struct pixel*) calloc(1, self.size.width * self.size.height * sizeof(struct pixel));
    if (pixels != nil)
    {
        CGContextRef context = CGBitmapContextCreate((void*) pixels, self.size.width, self.size.height, 8, self.size.width * 4, CGImageGetColorSpace(self.CGImage), kCGImageAlphaPremultipliedLast);
        if (context != NULL)
        {
            CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, self.size.width, self.size.height), self.CGImage);
            NSUInteger numberOfPixels = self.size.width * self.size.height;
            for (int i=0; i<numberOfPixels; i++) {
                red += pixels[i].r;
                green += pixels[i].g;
                blue += pixels[i].b;
            }
            red /= numberOfPixels;
            green /= numberOfPixels;
            blue/= numberOfPixels;
            CGContextRelease(context);
        }
        free(pixels);
    }
    return [UIColor colorWithRed:red/255.0f green:green/255.0f blue:blue/255.0f alpha:1.0f];
}
 
@end

@implementation UIColor (Addition)

- (UIColor *)shiftColor:(CGFloat)shift
{
	CGFloat red, green, blue, alpha;
	[self getRed:&red green:&green blue:&blue alpha:&alpha];
	return [UIColor colorWithRed:red + shift green:green + shift blue:blue + shift alpha:alpha]; // red/blue shift? lol.
}

- (UIColor *)lighterColor
{
	return [self shiftColor:0.25];
}

- (UIColor *)darkerColor
{
	return [self shiftColor:-0.25];
}

@end

static CGFloat borderSizeFromMode(int mode)
{
	switch (mode) {
		case 0:
			return 0;
		case 1:
			return 2;
		case 2:
			return 2.5;
		case 3:
			return 4;
	}
	return 0;
}

static UIColor *borderColorFromMode(int mode, UIColor *color)
{
	switch (mode) {
		case 0:
			return [color lighterColor];
		case 1:
			return [color darkerColor];
		case 2:
			return [UIColor whiteColor];
		case 3:
			return [UIColor blackColor];
	}
	return [UIColor clearColor];
}

%hook SBIconBlurryBackgroundView

- (void)didAddSubview:(id)arg1
{
	return;
}

%end

static UIImage *roundedRectMask(CGSize size)
{
	CGFloat realCornerRadius = size.height/2;
	CGRect rect = CGRectMake(0.0, 0.0, size.width, size.height);
	UIGraphicsBeginImageContextWithOptions(size, NO, 0);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
	[[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:realCornerRadius] addClip];
	CGContextFillRect(context, rect);
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}

int borderColorMode = 2;
int borderWidthMode = 3;
CGFloat tintAlpha = 0.65;


static CGPoint badgePointCorrection(SBIconView *iconView)
{
	CGPoint defaultCenter = MSHookIvar<CGPoint>(iconView, "_wallpaperRelativeCloseBoxCenter");
	return CGPointMake(defaultCenter.x + [%c(SBIconView) defaultIconImageSize].width, defaultCenter.y);
}

static void loadSettings()
{
	id r = [[NSUserDefaults standardUserDefaults] objectForKey:@"SBBadgeBorderColorMode"];
	borderColorMode = r != nil ? [r intValue] : 2;
	
	id r2 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SBBadgeBorderWidth"];
	borderWidthMode = r2 != nil ? [r2 intValue] : 1;
	
	id r3 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SBBadgeTintAlpha"];
	tintAlpha = r3 != nil ? [r3 floatValue] : 0.65;

}

static void bbHook(SBIconBadgeView *self, SBIcon *icon, int location, BOOL highlighted)
{
	UIImage *iconImage = [icon getIconImage:2];
	UIColor *dominantColor = [iconImage dominantColor];
	SBDarkeningImageView *bgView = MSHookIvar<SBDarkeningImageView *>(self, "_backgroundView");
	CGRect frame = CGRectMake(1, 1, self.frame.size.width-2, self.frame.size.height-2);
	CALayer *maskLayer = [CALayer layer];
	maskLayer.frame = frame;
	maskLayer.contents = (id)[roundedRectMask(frame.size) CGImage];
	
	UIColor *borderColor = borderColorFromMode(borderColorMode, dominantColor);
	if ([icon isFolderIcon]) {
		switch (borderColorMode) {
			case 0:
				borderColor = [[UIColor systemGrayColor] lighterColor];
				break;
			case 1:
				borderColor = [[UIColor systemGrayColor] darkerColor];
				break;
		} 
	}

	CGFloat borderWidth = borderSizeFromMode(borderWidthMode);
   
	for (id view in [bgView subviews]) {
		NSString *theClass = NSStringFromClass([view class]);
		if ([theClass isEqualToString:@"SBIconBlurryBackgroundView"]) {

			((UIView *)view).frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
			((UIView *)view).layer.mask = maskLayer;
			((UIView *)view).layer.borderColor = borderColor.CGColor;

			((UIView *)view).layer.borderWidth = borderWidth;

			UIView *tint = [(UIView *)view viewWithTag:9597];
			[tint setBackgroundColor:dominantColor];
			tint.alpha = tintAlpha;
		}
	}
}

/*%hook SBFolderIconView

- (void)_updateAdaptiveColors
{
	%orig;
	SBIconBadgeView *badgeView = (SBIconBadgeView *)MSHookIvar<UIView *>(self, "_accessoryView");
	[badgeView setWallpaperRelativeCenter:badgePointCorrection(self, badgeView)];
}

%end*/

/*%hook SBFolderIconImageView

- (void)setWallpaperRelativeCenter:(CGPoint)center
{
	%orig;
	SBIconBadgeView *badgeView = (SBIconBadgeView *)MSHookIvar<UIView *>((SBFolderIconView *)[self superview], "_accessoryView");
	[badgeView setWallpaperRelativeCenter:badgePointCorrection((SBFolderIconView *)[self superview], badgeView)];
}

%end*/

%hook SBIconView

- (void)setWallpaperRelativeImageCenter:(CGPoint)center
{
	%orig;
	SBIconBadgeView *badgeView = (SBIconBadgeView *)MSHookIvar<UIView *>(self, "_accessoryView");
	if ([badgeView respondsToSelector:@selector(setWallpaperRelativeCenter:)])
		[badgeView setWallpaperRelativeCenter:badgePointCorrection(self)];
}

- (void)_updateAccessoryViewWithAnimation:(id)arg1
{
	%orig;
	SBIconBadgeView *badgeView = (SBIconBadgeView *)MSHookIvar<UIView *>(self, "_accessoryView");
	if ([badgeView respondsToSelector:@selector(setWallpaperRelativeCenter:)])
		[badgeView setWallpaperRelativeCenter:badgePointCorrection(self)];
}

- (void)_updateAdaptiveColors
{
	%orig;
	SBIconBadgeView *badgeView = (SBIconBadgeView *)MSHookIvar<UIView *>(self, "_accessoryView");
	if ([badgeView respondsToSelector:@selector(setWallpaperRelativeCenter:)])
		[badgeView setWallpaperRelativeCenter:badgePointCorrection(self)];
}

%end

%hook SBIconBadgeView

- (void)configureForIcon:(SBIcon *)icon location:(int)location highlighted:(BOOL)highlighted
{
	%orig;
	bbHook(self, icon, location, highlighted);
}

- (void)configureAnimatedForIcon:(SBIcon *)icon location:(int)location highlighted:(BOOL)highlighted withPreparation:(id)preparation animation:(id)animation completion:(id)completion
{
	%orig;
	bbHook(self, icon, location, highlighted);
}

%new
- (void)setWallpaperRelativeCenter:(CGPoint)point
{
	SBDarkeningImageView *bgView = MSHookIvar<SBDarkeningImageView *>(self, "_backgroundView");
	for (id view in [bgView subviews]) {
		NSString *theClass = NSStringFromClass([view class]);
			if ([theClass isEqualToString:@"SBIconBlurryBackgroundView"])
				[((SBIconBlurryBackgroundView *)view) setWallpaperRelativeCenter:point];
	}
}

- (void)layoutSubviews
{
	%orig;
	[self setWallpaperRelativeCenter:badgePointCorrection((SBIconView *)[self superview])];
}

- (id)init
{
	self = %orig;
	if (self) {
		loadSettings();
		SBDarkeningImageView *bgView = MSHookIvar<SBDarkeningImageView *>(self, "_backgroundView");
		[bgView setImage:nil];
		SBIconBlurryBackgroundView *blurView = [[%c(SBIconBlurryBackgroundView) alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
		//[blurView setWantsBlurEvaluator:[[[%c(SBPrototypeController) sharedInstance] rootSettings] iconColorSettings]];
		UIView *tintView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
		tintView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		tintView.tag = 9597;
		
		blurView.layer.cornerRadius = 12;
		blurView.layer.masksToBounds = YES;
		
		[blurView addSubview:tintView];
		[tintView release];
		[bgView insertSubview:blurView belowSubview:MSHookIvar<SBDarkeningImageView *>(self, "_textView")];
		[blurView release];
	}
	return self;
}

%end

static void bbSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	loadSettings();
	SBIconController *cont = [%c(SBIconController) sharedInstance];
	SBIconModel *model = [cont model];
	NSArray *icons = [model leafIcons];
	for (SBIcon *icon in icons) {
		[icon noteBadgeDidChange];
	}
}

%ctor
{
	loadSettings();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, bbSettingsChanged, CFSTR("com.ps.backdropbadge.update"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	%init;
}
