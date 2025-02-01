#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <SpringBoard/SBIconModel.h>
#import <SpringBoard/SBIcon.h>
#import <SpringBoard/SBIconImageInfo.h>
#import <SpringBoard/SBIconView.h>
#import <SpringBoard/SBFolderIconView.h>
#import <SpringBoard/SBIconController.h>

@interface NSObject (Private)
- (id)safeValueForKey:(NSString *)key;
@end

@interface MTMaterialView : UIView
@end

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
+ (MTMaterialView *)componentBackgroundView;
+ (MTMaterialView *)componentBackgroundViewOfType:(NSInteger)type compatibleWithTraitCollection:(UITraitCollection *)traitCollection initialWeighting:(CGFloat)initialWeighting; // iOS 14+
- (CGPoint)_centerForCloseBoxRelativeToVisibleImageFrame:(CGRect)visibleImageFrame;
- (SBIconImageView *)_iconImageView;
@end

@interface SBIconModel (Additions)
- (NSArray *)leafIcons;
@end

@interface SBIconBadgeView : UIView
- (BOOL)displayingAccessory;
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

@interface SBIconAccessoryImage : UIImage
@end

@interface SBDarkeningImageView : UIImageView
@end

@interface SBHIconAccessoryCountedMapImageTuple : NSObject
@end

@interface SBHomeScreenMaterialView : UIView
@end

@interface SBHomeScreenButton : UIButton
- (instancetype)initWithFrame:(CGRect)frame backgroundView:(UIView *)backgroundView;
- (SBHomeScreenMaterialView *)materialView;
@property (nonatomic, strong, readwrite) UIView *backgroundView;
@end
