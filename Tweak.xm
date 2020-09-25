#import <notify.h>
#import "Header.h"

struct pixel {
    unsigned char r, g, b, a;
};

static UIColor *dominantColorFromIcon(SBIcon *icon) {
	UIImage *iconImage = nil;
	if ([icon respondsToSelector:@selector(generateIconImageWithInfo:)])
		iconImage = [icon generateIconImageWithInfo:(SBIconImageInfo) { .size = CGSizeMake(60, 60), .scale = 1, .continuousCornerRadius = 12 }];
	else if ([icon respondsToSelector:@selector(getIconImage:)])
		iconImage = [icon getIconImage:2];
	if (iconImage == nil)
		return [UIColor blackColor];
	NSUInteger red = 0, green = 0, blue = 0;
	CGImageRef iconCGImage = iconImage.CGImage;
	struct pixel *pixels = (struct pixel *)calloc(1, iconImage.size.width * iconImage.size.height * sizeof(struct pixel));
	if (pixels != nil)     {
		CGContextRef context = CGBitmapContextCreate((void *)pixels, iconImage.size.width, iconImage.size.height, 8, iconImage.size.width * 4, CGImageGetColorSpace(iconCGImage), kCGImageAlphaPremultipliedLast);
		if (context != NULL) {
			CGContextDrawImage(context, CGRectMake(0.0, 0.0, iconImage.size.width, iconImage.size.height), iconCGImage);
			NSUInteger numberOfPixels = iconImage.size.width * iconImage.size.height;
			for (int i = 0; i < numberOfPixels; ++i) {
				red += pixels[i].r;
				green += pixels[i].g;
				blue += pixels[i].b;
			}
			red /= numberOfPixels;
			green /= numberOfPixels;
			blue /= numberOfPixels;
			CGContextRelease(context);
		}
		free(pixels);
	}
	return [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1.0];
}

static UIColor *colorShiftedBy(UIColor *color, CGFloat shift) {
	CGFloat red, green, blue, alpha;
	[color getRed:&red green:&green blue:&blue alpha:&alpha];
	return [UIColor colorWithRed:red + shift green:green + shift blue:blue + shift alpha:alpha];
}

static UIColor *lighterColor(UIColor *color) {
	return colorShiftedBy(color, 0.25);
}

static UIColor *darkerColor(UIColor *color) {
	return colorShiftedBy(color, -0.25);
}

static CGFloat borderSizeFromMode(int mode) {
	switch (mode) {
		case 0:
			return 0.0;
		case 1:
			return 2.0;
		case 2:
			return 2.5;
		case 3:
			return 3.0;
		case 4:
			return 4.0;
	}
	return 0;
}

static UIColor *randomColor() {
	CGFloat hue = (arc4random() % 256 / 256.0);
	CGFloat saturation = (arc4random() % 256 / 256.0);
	CGFloat brightness = (arc4random() % 256 / 256.0);
	UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
	return color;
}

static UIColor *borderColorFromMode(int mode, UIColor *color) {
	switch (mode) {
		case 0:
			return lighterColor(color);
		case 1:
			return darkerColor(color);
		case 2:
			return [UIColor whiteColor];
		case 3:
			return [UIColor blackColor];
		case 4:
			return randomColor();
	}
	return [UIColor clearColor];
}

%hook SBIconBlurryBackgroundView

- (void)didAddSubview:(id)arg1 {
	if (self.tag == 9596)
		return;
}

%end

static UIImage *roundedRectMask(CGSize size) {
	CGFloat realCornerRadius = size.height / 2;
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

static void loadSettings() {
	id r = [[NSUserDefaults standardUserDefaults] objectForKey:@"SBBadgeBorderColorMode"];
	borderColorMode = r != nil ? [r intValue] : 2;
	id r2 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SBBadgeBorderWidth"];
	borderWidthMode = r2 != nil ? [r2 intValue] : 1;
	id r3 = [[NSUserDefaults standardUserDefaults] objectForKey:@"SBBadgeTintAlpha"];
	tintAlpha = r3 != nil ? [r3 floatValue] : 0.65;
}

static void bbHook(SBIconBadgeView *self, SBIcon *icon, int location) {
    if (self.dominantColor == nil)
	    self.dominantColor = dominantColorFromIcon(icon);
	SBDarkeningImageView *bgView = (SBDarkeningImageView *)[self valueForKey:@"_backgroundView"];
	CGRect frame = CGRectMake(1, 1, self.frame.size.width - 2, self.frame.size.height - 2);
	CALayer *maskLayer = [CALayer layer];
	maskLayer.frame = frame;
	maskLayer.contents = (id)[roundedRectMask(frame.size) CGImage];
	UIColor *borderColor = borderColorFromMode(borderColorMode, self.dominantColor);
	if ([icon isFolderIcon]) {
		SBWallpaperController *wallpaperCont = [%c(SBWallpaperController) sharedInstance];
		self.dominantColor = [wallpaperCont averageColorForVariant:1];
		switch (borderColorMode) {
			case 0:
				borderColor = lighterColor(self.dominantColor);
				break;
			case 1:
				borderColor = darkerColor(self.dominantColor);
				break;
		}
	}
	CGFloat borderWidth = borderSizeFromMode(borderWidthMode);
	SBIconBlurryBackgroundView *blurView = (SBIconBlurryBackgroundView *)[bgView viewWithTag:9596];
	blurView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
	blurView.layer.mask = maskLayer;
	blurView.layer.borderColor = borderWidthMode == 0 ? nil : borderColor.CGColor;
	blurView.layer.borderWidth = borderWidth;

	UIView *tint = [blurView viewWithTag:9597];
	tint.backgroundColor = self.dominantColor;
	tint.alpha = tintAlpha;
}

static void hookBadge(SBIconView *iconView) {
	if ([iconView valueForKey:@"_icon"] != nil) {
		SBIconBadgeView *badgeView = (SBIconBadgeView *)[iconView valueForKey:@"_accessoryView"];
		if (badgeView != nil)
			bbHook(badgeView, iconView.icon, iconView.location);
	}
}

extern "C" CGRect UIRectCenteredAboutPoint(CGRect, CGPoint, CGFloat, CGFloat);

%hook SBIconView

static void setBadgePosition(SBIconView *iconView, CGPoint center) {
	if (iconView == nil || CGPointEqualToPoint(center, CGPointZero))
		return;
	if ([iconView valueForKey:@"_icon"] == nil)
		return;
	SBIconBadgeView *badgeView = (SBIconBadgeView *)[iconView valueForKey:@"_accessoryView"];
	if (badgeView == nil)
		return;
	if ([badgeView respondsToSelector:@selector(displayingAccessory)] && [badgeView respondsToSelector:@selector(setWallpaperRelativeCenter:)]) {
		SBDarkeningImageView *bgView = (SBDarkeningImageView *)[badgeView valueForKey:@"_backgroundView"];
		UIView *blurView = [bgView viewWithTag:9596];
		CGRect visibleImageRect = MSHookIvar<CGRect>(iconView, "_visibleImageRect");
		CGRect visibleImageFrame = UIRectCenteredAboutPoint(visibleImageRect, center, visibleImageRect.size.width, visibleImageRect.size.height);
		CGPoint closeBoxCenter = visibleImageFrame.origin;
		CGPoint wallpaperRelativeBadgeCenter = CGPointMake(closeBoxCenter.x + visibleImageRect.size.width - 0.5*blurView.frame.size.width + 10, closeBoxCenter.y);
		if (CGPointEqualToPoint(wallpaperRelativeBadgeCenter, CGPointZero))
			return;
		[badgeView setWallpaperRelativeCenter:wallpaperRelativeBadgeCenter];
	}
}

- (void)setWallpaperRelativeImageCenter:(CGPoint)center {
	%orig;
	setBadgePosition(self, center);
}

- (void)_updateAccessoryViewWithAnimation:(id)arg1 {
	%orig;
	hookBadge(self);
}

- (void)_applyEditingStateAnimated:(BOOL)animated {
	%orig;
	if ([self respondsToSelector:@selector(wallpaperRelativeImageCenter)])
		setBadgePosition(self, self.wallpaperRelativeImageCenter);
}

- (void)layoutSubviews {
	%orig;
	if ([self respondsToSelector:@selector(wallpaperRelativeImageCenter)])
		setBadgePosition(self, self.wallpaperRelativeImageCenter);
}

- (void)_updateAdaptiveColors {
	%orig;
	if ([self respondsToSelector:@selector(wallpaperRelativeImageCenter)])
		setBadgePosition(self, self.wallpaperRelativeImageCenter);
}

%end

static void initBadgeView(UIView *self) {
	if (self == nil)
		return;
	SBDarkeningImageView *bgView = (SBDarkeningImageView *)[self valueForKey:@"_backgroundView"];
	bgView.image = nil;
	CGRect defaultFrame = CGRectMake(0, 0, 24, 24);
	SBIconBlurryBackgroundView *blurView = [[%c(SBIconBlurryBackgroundView) alloc] initWithFrame:defaultFrame];
	blurView.tag = 9596;
	UIView *tintView = [[UIView alloc] initWithFrame:defaultFrame];
	tintView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	tintView.tag = 9597;
	blurView.layer.cornerRadius = 12;
	blurView.layer.masksToBounds = YES;
	[blurView addSubview:tintView];
	[tintView release];
	UIView *textView = nil;
    object_getInstanceVariable(self, "_textView", (void **)&textView);
	if (textView)
		[bgView insertSubview:blurView belowSubview:textView];
	else
		[bgView addSubview:blurView];
	[blurView release];
}

%hook SBIconBadgeView

%property(retain, nonatomic) UIColor *dominantColor;

%new
- (void)setWallpaperRelativeCenter:(CGPoint)point {
	SBDarkeningImageView *bgView = (SBDarkeningImageView *)[self valueForKey:@"_backgroundView"];
	SBIconBlurryBackgroundView *view = (SBIconBlurryBackgroundView *)[bgView viewWithTag:9596];
	if ([view respondsToSelector:@selector(setWallpaperRelativeCenter:)])
		[view setWallpaperRelativeCenter:point];
}

- (id)init {
	self = %orig;
	initBadgeView(self);
	return self;
}

- (void)prepareForReuse {
	%orig;
	SBDarkeningImageView *bgView = (SBDarkeningImageView *)[self valueForKey:@"_backgroundView"];
	bgView.image = nil;
    self.dominantColor = nil;
}

%end

%hook SBIconContinuityBadgeView

%property(retain, nonatomic) UIColor *dominantColor;

- (id)init {
	self = %orig;
	initBadgeView(self);
	return self;
}

- (void)prepareForReuse {
	%orig;
	SBDarkeningImageView *bgView = (SBDarkeningImageView *)[self valueForKey:@"_backgroundView"];
	bgView.image = nil;
    self.dominantColor = nil;
}

%end

static void bbSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	loadSettings();
	SBIconController *cont = [%c(SBIconController) sharedInstance];
	SBIconModel *model = [cont model];
	NSArray *icons = [model leafIcons];
	for (SBIcon *icon in icons)
		[icon noteBadgeDidChange];
}

%ctor {
	loadSettings();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, bbSettingsChanged, CFSTR("com.ps.backdropbadge.update"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	dlopen("/Library/MobileSubstrate/DynamicLibraries/Anemone.dylib", RTLD_LAZY);
	%init;
}
