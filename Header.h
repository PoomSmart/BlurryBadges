#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface SBWallpaperController : NSObject
+ (instancetype)sharedInstance;
- (NSInteger)variant;
- (UIColor *)averageColorForVariant:(NSInteger)variant;
@end

@interface SBIcon : NSObject
- (UIImage *)getIconImage:(NSInteger)type;
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

@interface SBIconBlurryBackgroundView : UIView
- (void)setWallpaperRelativeCenter:(CGPoint)center;
@end

@interface SBIconAccessoryImage : UIImage
@end

@interface SBDarkeningImageView : UIImageView
@end