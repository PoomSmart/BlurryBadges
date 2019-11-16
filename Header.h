#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

typedef struct SBIconImageInfo {
	CGSize size;
	CGFloat scale;
	CGFloat continuousCornerRadius;
} SBIconImageInfo;

@interface SBWallpaperController : NSObject
+ (instancetype)sharedInstance;
- (NSInteger)variant;
- (UIColor *)averageColorForVariant:(NSInteger)variant;
@end

@interface SBIcon : NSObject
- (UIImage *)getIconImage:(NSInteger)type; // iOS < 13
- (UIImage *)generateIconImageWithInfo:(SBIconImageInfo)imageInfo; // iOS 13+
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
- (int)location;
- (CGPoint)_centerForCloseBoxRelativeToVisibleImageFrame:(CGRect)visibleImageFrame;
- (SBIcon *)icon;
- (SBIconImageView *)_iconImageView;
@end

@interface SBIconModel : NSObject
- (NSArray *)leafIcons;
@end

@interface SBIconController : NSObject
+ (instancetype)sharedInstance;
- (SBIconModel *)model;
@end

@interface SBFolderIconView : SBIconView
@end

@interface SBIconBadgeView : UIView
- (BOOL)displayingAccessory;
- (void)setWallpaperRelativeCenter:(CGPoint)center;
@end

@interface SBIconBadgeView (BlurryBadges)
@property(retain, nonatomic) UIColor *dominantColor;
@end

@interface SBIconContinuityBadgeView : UIView
@end

@interface SBIconContinuityBadgeView (BlurryBadges)
@property(retain, nonatomic) UIColor *dominantColor;
@end

@interface SBIconBlurryBackgroundView : UIView
- (void)setWallpaperRelativeCenter:(CGPoint)center;
@end

@interface SBIconAccessoryImage : UIImage
@end

@interface SBDarkeningImageView : UIImageView
@end