#import <UIKit/UIKit.h>
#import <UIKit/UIColor+Private.h>
#import <UIKit/UIImage+Private.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>
#import <notify.h>
#import "../PS.h"

@interface PSTableCell (Additions)
- (void)setChecked:(BOOL)checked;
@end

#define SB CFSTR("com.apple.springboard")
#define BorderWidth CFSTR("SBBadgeBorderWidth")
#define BorderColor CFSTR("SBBadgeBorderColorMode")
#define BadgeTintAlpha CFSTR("SBBadgeTintAlpha")
#define PostNotification CFSTR("com.ps.backdropbadge.update")

@interface BackdropBadgePrefController : PSListController {
	int badgeBorderSize;
	int badgeBorderColorMode;
}
@end

static int integerValueForKey(CFStringRef key, int defaultValue) {
	CFPreferencesAppSynchronize(SB);
	Boolean valid;
	CFIndex value = CFPreferencesGetAppIntegerValue(key, SB, &valid);
	return valid ? value : defaultValue;
}

@implementation BackdropBadgePrefController

- (NSArray *)borderSizes {
	return @[@"No Border", @"Little", @"Medium", @"Pre-iOS 7", @"Huge"];
}

- (NSArray *)borderColors {
	return @[@"Lighter", @"Darker", @"White", @"Black", @"Random"];
}

- (NSMutableArray *)specifiers {
    if (!_specifiers) {
		_specifiers = [NSMutableArray new];
		PSSpecifier *borderSizeGroupSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Border Size" target:nil set:nil get:nil detail:nil cell:PSGroupCell edit:nil];
        [_specifiers addObject:borderSizeGroupSpecifier];
		for (NSString *borderSize in [self borderSizes]) {
			PSSpecifier *borderSizeSpecifier = [PSSpecifier preferenceSpecifierNamed:borderSize target:nil set:nil get:nil detail:nil cell:PSStaticTextCell edit:nil];
            [borderSizeSpecifier setProperty:@([[self borderSizes] indexOfObject:borderSize]) forKey:@"borderSize"];
            [borderSizeSpecifier setProperty:@YES forKey:@"enabled"];
            [_specifiers addObject:borderSizeSpecifier];
		}
		PSSpecifier *borderColorGroupSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Border Color" target:nil set:nil get:nil detail:nil cell:PSGroupCell edit:nil];
        [_specifiers addObject:borderColorGroupSpecifier];
		for (NSString *borderColor in [self borderColors]) {
			PSSpecifier *borderColorSpecifier = [PSSpecifier preferenceSpecifierNamed:borderColor target:nil set:nil get:nil detail:nil cell:PSStaticTextCell edit:nil];
            [borderColorSpecifier setProperty:@([[self borderColors] indexOfObject:borderColor]) forKey:@"borderColor"];
            [borderColorSpecifier setProperty:@YES forKey:@"enabled"];
            [_specifiers addObject:borderColorSpecifier];
		}

		PSSpecifier *badgeTintAlphaSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Badge Tint Alpha (Disabled)" target:nil set:nil get:nil detail:nil cell:PSGroupCell edit:nil];
        [_specifiers addObject:badgeTintAlphaSpecifier];
		PSSpecifier *sliderSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Slider" target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:nil cell:PSSliderCell edit:nil];
		[sliderSpecifier setProperty:@(0.0) forKey:@"min"];
		[sliderSpecifier setProperty:@(1.0) forKey:@"max"];
		[sliderSpecifier setProperty:@(0.65) forKey:@"default"];
		[sliderSpecifier setProperty:@YES forKey:@"showValue"];
		[sliderSpecifier setProperty:(__bridge NSString *)BadgeTintAlpha forKey:@"key"];
		[sliderSpecifier setProperty:(__bridge NSString *)SB forKey:@"defauts"];
		[sliderSpecifier setProperty:(__bridge NSString *)PostNotification forKey:@"PostNotification"];
		// [sliderSpecifier setProperty:@YES forKey:@"enabled"]; // FIXME: make the slider works
		[_specifiers addObject:sliderSpecifier];

		PSSpecifier *footerSpecifier = [PSSpecifier emptyGroupSpecifier];
        [footerSpecifier setProperty:@"© 2013 - 2017, 2021 PoomSmart" forKey:@"footerText"];
        [footerSpecifier setProperty:@1 forKey:@"footerAlignment"];
        [_specifiers addObject:footerSpecifier];
	}

	return _specifiers;
}

- (void)setSpecifier:(PSSpecifier *)specifier {
	[super setSpecifier:specifier];
	self.navigationItem.title = [specifier name];
	badgeBorderSize = integerValueForKey(BorderWidth, 3);
	badgeBorderColorMode = integerValueForKey(BorderColor, 2);
}

- (NSBundle *)bundle {
	return [NSBundle bundleWithPath:@"/Library/PreferenceBundles/BackdropBadgePref.bundle"];
}

- (UIImage *)badgeForSizeMode:(int)size colorMode:(int)color {
	return [UIImage imageNamed:[NSString stringWithFormat:@"badge%d%d", size, color] inBundle:[self bundle]];
}

- (PSTableCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	PSTableCell *cell = (PSTableCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];

	if (indexPath.section <= 1) {
		PSSpecifier *specifier = [cell specifier];
		switch (indexPath.section) {
			case 0: {
				NSNumber *value = [specifier propertyForKey:@"borderSize"];
				[cell setChecked:badgeBorderSize == [value intValue]];
				break;
			}
			case 1: {
				NSNumber *value = [specifier propertyForKey:@"borderColor"];
				[cell setChecked:badgeBorderColorMode == [value intValue]];
				if (indexPath.row == 2) {
					cell.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1];
				}
				break;
			}
		}

		cell.imageView.image = [self badgeForSizeMode:indexPath.section == 0 ? indexPath.row : 3 colorMode:indexPath.section == 1 ? indexPath.row : 3];
	}

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[super tableView:tableView didSelectRowAtIndexPath:indexPath];
	NSInteger section = indexPath.section;
	if (section > 1) return;
	NSInteger value = indexPath.row;
	CFStringRef key;
	switch (section) {
		case 0:
			key = BorderWidth;
			badgeBorderSize = value;
			break;
		case 1:
			key = BorderColor;
			badgeBorderColorMode = value;
			break;
	}
	for (NSInteger i = 0; i <= 4; ++i)
		[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section]].accessoryType = (value == i) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	CFPreferencesSetAppValue(key, (CFTypeRef)@(value), SB);
	CFPreferencesAppSynchronize(SB);
	notify_post("com.ps.backdropbadge.update");
}

- (void)suspend {
	notify_post("com.ps.backdropbadge.update");
	[super suspend];
}

@end
