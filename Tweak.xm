#import "Header.h"
#import <notify.h>
#import <dlfcn.h>
#import <version.h>

struct pixel {
    unsigned char r, g, b, a;
};

static UIImage *imageFromIconServicesIcon(ISIcon *isIcon) {
    if (!isIcon)
        return nil;
    Class descriptorClass = NSClassFromString(@"ISImageDescriptor");
    ISImageDescriptor *descriptor = [[descriptorClass alloc] initWithSize:CGSizeMake(60, 60) scale:2];
    if ([descriptor respondsToSelector:@selector(setShouldApplyMask:)])
        descriptor.shouldApplyMask = YES;
    IFImage *isImage = nil;
    if ([isIcon respondsToSelector:@selector(prepareImageForDescriptor:)])
        isImage = [isIcon prepareImageForDescriptor:descriptor];
    [descriptor release];
    if (!isImage.CGImage || isImage.placeholder)
        return nil;
    CGFloat scale = isImage.scale > 0 ? isImage.scale : 2;
    return [UIImage imageWithCGImage:isImage.CGImage scale:scale orientation:UIImageOrientationUp];
}

static UIImage *snapshotOfView(UIView *view) {
    if (!view || CGRectIsEmpty(view.bounds))
        return nil;
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

static UIColor *dominantColorFromImage(UIImage *iconImage) {
    CGImageRef iconCGImage = iconImage.CGImage;
    if (!iconCGImage)
        return nil;
    size_t width = CGImageGetWidth(iconCGImage);
    size_t height = CGImageGetHeight(iconCGImage);
    if (width == 0 || height == 0)
        return nil;
    struct pixel *pixels = (struct pixel *)calloc(width * height, sizeof(struct pixel));
    if (!pixels)
        return nil;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * 4, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    UIColor *color = nil;
    if (context) {
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), iconCGImage);
        NSUInteger red = 0, green = 0, blue = 0, count = 0;
        NSUInteger numberOfPixels = width * height;
        for (NSUInteger i = 0; i < numberOfPixels; ++i) {
            if (pixels[i].a < 16)
                continue;
            red += pixels[i].r;
            green += pixels[i].g;
            blue += pixels[i].b;
            count++;
        }
        if (count > 0)
            color = [UIColor colorWithRed:(red / (CGFloat)count) / 255.0 green:(green / (CGFloat)count) / 255.0 blue:(blue / (CGFloat)count) / 255.0 alpha:1.0];
        CGContextRelease(context);
    }
    free(pixels);
    return color;
}

static UIColor *dominantColorFromIconView(SBIconView *iconView) {
    SBIcon *icon = iconView.icon;
    SBIconImageView *imageView = [iconView respondsToSelector:@selector(_iconImageView)] ? [iconView _iconImageView] : nil;
    NSMutableArray *candidates = [NSMutableArray array];
    if ([iconView respondsToSelector:@selector(iconImageSnapshot)]) {
        UIImage *snapshot = [iconView iconImageSnapshot];
        if (snapshot)
            [candidates addObject:snapshot];
    }
    if ([imageView respondsToSelector:@selector(snapshot)]) {
        UIImage *snapshot = [imageView snapshot];
        if (snapshot)
            [candidates addObject:snapshot];
    }
    UIImage *viewSnapshot = snapshotOfView(imageView);
    if (viewSnapshot)
        [candidates addObject:viewSnapshot];
    UIImage *displayed = imageView.displayedImage ?: ([imageView respondsToSelector:@selector(contentsImage)] ? [imageView contentsImage] : nil);
    if (displayed)
        [candidates addObject:displayed];

    ISIcon *isIcon = [icon respondsToSelector:@selector(iconServicesIconForImage)] ? [icon iconServicesIconForImage] : nil;
    NSString *bundleID = [icon applicationBundleID] ?: ([icon respondsToSelector:@selector(applicationBundleIdentifierForImage)] ? [icon applicationBundleIdentifierForImage] : nil);
    if (!isIcon && bundleID.length) {
        Class iconClass = NSClassFromString(@"ISBundleIdentifierIcon");
        isIcon = [[iconClass alloc] initWithBundleIdentifier:bundleID];
    } else {
        [isIcon retain];
    }
    UIImage *isImage = imageFromIconServicesIcon(isIcon);
    [isIcon release];
    if (isImage)
        [candidates addObject:isImage];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability-new"
    SBIconImageInfo info = { .size = CGSizeMake(60, 60), .scale = 1, .continuousCornerRadius = 12 };
    UIImage *legacy = nil;
    if ([icon respondsToSelector:@selector(generateIconImageWithInfo:)])
        legacy = [icon generateIconImageWithInfo:info];
    else if ([icon respondsToSelector:@selector(getIconImage:)])
        legacy = [icon getIconImage:MIIconVariantDefault];
#pragma clang diagnostic pop
    if (legacy)
        [candidates addObject:legacy];

    for (UIImage *image in candidates) {
        UIColor *color = dominantColorFromImage(image);
        if (color)
            return color;
    }
    return nil;
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

int borderColorMode;
int borderWidthMode;
CGFloat tintAlpha;

static void loadSettings() {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id r = [defaults objectForKey:@"SBBadgeBorderColorMode"];
    borderColorMode = r ? [r intValue] : 2;
    id r2 = [defaults objectForKey:@"SBBadgeBorderWidth"];
    borderWidthMode = r2 ? [r2 intValue] : 3;
    id r3 = [defaults objectForKey:@"SBBadgeTintOpacity"];
    tintAlpha = r3 ? (([r3 intValue] + 1) * 0.2) : 0.6;
}

static void bbHook(SBIconBadgeView *self, SBIconView *iconView) {
    SBIcon *icon = iconView.icon;
    if (self.dominantColor == nil)
        self.dominantColor = dominantColorFromIconView(iconView);
    SBDarkeningImageView *bgView = [self valueForKey:@"_backgroundView"];
    CGFloat shift = 2;
    CGRect frame = CGRectMake(1, 1, self.frame.size.width - shift, self.frame.size.height - shift);
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
    SBHomeScreenButton *blurView = [bgView viewWithTag:9596];
    CGFloat blurShift = IS_IOS_OR_NEWER(iOS_16_0) ? -1 : 0;
    blurView.frame = CGRectMake(blurShift, blurShift, self.frame.size.width, self.frame.size.height);
    blurView.layer.mask = maskLayer;
    blurView.layer.borderColor = borderWidthMode == 0 ? nil : borderColor.CGColor;
    blurView.layer.borderWidth = borderWidth;

    UIView *tint = [blurView viewWithTag:9597];
    if (tint == nil) tint = [bgView viewWithTag:9597];
    tint.backgroundColor = self.dominantColor;
    tint.alpha = tintAlpha;

    [blurView sendSubviewToBack:[blurView materialView]];
}

static void hookBadge(SBIconView *iconView) {
    if ([iconView valueForKey:@"_icon"]) {
        SBIconBadgeView *badgeView = [iconView valueForKey:@"_accessoryView"];
        if (badgeView)
            bbHook(badgeView, iconView);
    }
}

%hook SBIconView

- (void)_updateAccessoryViewWithAnimation:(id)arg1 {
    %orig;
    hookBadge(self);
}

- (void)_updateAccessoryViewAnimated:(BOOL)animated {
    %orig;
    hookBadge(self);
}

%end

static void initBadgeView(UIView *self) {
    if (self == nil)
        return;
    SBDarkeningImageView *bgView = [self valueForKey:@"_backgroundView"];
    bgView.backgroundColor = nil;
    bgView.image = nil;
    CGRect defaultFrame = CGRectMake(0, 0, 24, 24);
    UIView *tintView = [[UIView alloc] initWithFrame:defaultFrame];
    tintView.tag = 9597;
    UIView *textView = [self safeValueForKey:@"_textView"];
    if (textView) {
        MTMaterialView *blurBgView = IS_IOS_OR_NEWER(iOS_14_0) ? [%c(SBIconView) componentBackgroundViewOfType:1 compatibleWithTraitCollection:self.traitCollection initialWeighting:1] : [%c(SBIconView) componentBackgroundView];
        SBHomeScreenButton *blurView = [[%c(SBHomeScreenButton) alloc] initWithFrame:defaultFrame backgroundView:blurBgView];
        blurView.tag = 9596;
        blurView.layer.cornerRadius = 12;
        blurView.layer.masksToBounds = YES;
        [bgView insertSubview:blurView belowSubview:textView];
        tintView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [blurView addSubview:tintView];
        [blurView release];
    } else {
        tintView.layer.cornerRadius = 12;
        tintView.layer.masksToBounds = YES;
        tintView.frame = CGRectMake(1, 1, 24, 24);
        [bgView addSubview:tintView];
    }
    [tintView release];
}

%hook SBIconBadgeView

%property (retain, nonatomic) UIColor *dominantColor;

- (id)init {
    self = %orig;
    initBadgeView(self);
    return self;
}

- (SBHIconAccessoryCountedMapImageTuple *)_checkoutBackgroundImageTuple {
    SBHIconAccessoryCountedMapImageTuple *tuple = %orig;
    [tuple setValue:nil forKey:@"_image"];
    return tuple;
}

- (void)prepareForReuse {
    %orig;
    SBDarkeningImageView *bgView = [self valueForKey:@"_backgroundView"];
    bgView.image = nil;
    self.dominantColor = nil;
}

%end

%hook SBIconContinuityBadgeView

%property (retain, nonatomic) UIColor *dominantColor;

- (id)init {
    self = %orig;
    initBadgeView(self);
    return self;
}

- (void)prepareForReuse {
    %orig;
    SBDarkeningImageView *bgView = [self valueForKey:@"_backgroundView"];
    bgView.image = nil;
    self.dominantColor = nil;
}

%end

%hook SBIconContinuityAccessoryView

%property (retain, nonatomic) UIColor *dominantColor;

- (id)init {
    self = %orig;
    initBadgeView(self);
    return self;
}

- (void)prepareForReuse {
    %orig;
    SBDarkeningImageView *bgView = [self valueForKey:@"_backgroundView"];
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
    %init;
}
