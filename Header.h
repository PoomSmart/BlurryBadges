#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <SpringBoard/SBIconModel.h>
#import <SpringBoard/SBIcon.h>
#import <SpringBoard/SBIconImageInfo.h>
#import <SpringBoard/SBIconView.h>
#import <SpringBoard/SBFolderIconView.h>
#import <SpringBoard/SBIconController.h>

@interface SBWallpaperController : NSObject
+ (instancetype)sharedInstance;
- (NSInteger)variant;
- (UIColor *)averageColorForVariant:(NSInteger)variant;
@end

@interface SBIcon (Additions)
- (void)noteBadgeDidChange;
@end

@interface SBIconImageView : UIView
@end

@interface SBIconView (Additions)
+ (CGSize)defaultIconImageSize;
@property (assign, nonatomic) CGPoint wallpaperRelativeImageCenter;
- (CGPoint)_centerForCloseBoxRelativeToVisibleImageFrame:(CGRect)visibleImageFrame;
- (SBIconImageView *)_iconImageView;
@end

@interface SBIconModel (Additions)
- (NSArray *)leafIcons;
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

@interface SBIconContinuityAccessoryView : UIView
@end

@interface SBIconContinuityBadgeView (BlurryBadges)
@property(retain, nonatomic) UIColor *dominantColor;
@end

@interface SBIconContinuityAccessoryView (BlurryBadges)
@property(retain, nonatomic) UIColor *dominantColor;
@end

@interface SBIconBlurryBackgroundView : UIView
- (void)setWallpaperRelativeCenter:(CGPoint)center;
@end

@interface SBIconAccessoryImage : UIImage
@end

@interface SBDarkeningImageView : UIImageView
@end

@interface SBHIconAccessoryCountedMapImageTuple : NSObject
@end

@interface SBWallpaperEffectViewBase : UIView
- (void)setStyle:(NSInteger)style;
@end

@interface SBWallpaperEffectView : SBWallpaperEffectViewBase // UIView for iOS 13-
- (instancetype)initWithWallpaperVariant:(NSInteger)variant;
- (void)setStyle:(NSInteger)style;
@end
