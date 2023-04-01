#import <UIKit/UIColor+Private.h>
#import <UIKit/UIImage+Private.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>
#import <notify.h>
#import <rootless.h>

#define SB CFSTR("com.apple.springboard")
#define BorderWidth CFSTR("SBBadgeBorderWidth")
#define BorderColor CFSTR("SBBadgeBorderColorMode")
#define BadgeTintOpacity CFSTR("SBBadgeTintOpacity")
#define PostNotification CFSTR("com.ps.backdropbadge.update")

@interface BackdropBadgePrefController : PSListController {
	int badgeBorderSize;
	int badgeBorderColorMode;
	int badgeOpacity;
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

- (NSArray *)opacitys {
	return @[@"20%", @"40%", @"60%", @"80%", @"100%"];
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

		PSSpecifier *badgeTintOpacitySpecifier = [PSSpecifier preferenceSpecifierNamed:@"Badge Tint Opacity" target:nil set:nil get:nil detail:nil cell:PSGroupCell edit:nil];
        [_specifiers addObject:badgeTintOpacitySpecifier];
		for (NSString *opacity in [self opacitys]) {
			PSSpecifier *opacitySpecifier = [PSSpecifier preferenceSpecifierNamed:opacity target:nil set:nil get:nil detail:nil cell:PSStaticTextCell edit:nil];
			[opacitySpecifier setProperty:@([[self opacitys] indexOfObject:opacity]) forKey:@"opacity"];
			[opacitySpecifier setProperty:@YES forKey:@"enabled"];
			[_specifiers addObject:opacitySpecifier];
		}

		PSSpecifier *footerSpecifier = [PSSpecifier emptyGroupSpecifier];
        [footerSpecifier setProperty:@"© 2013 - 2017, 2021 - 2023 PoomSmart" forKey:@"footerText"];
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
	badgeOpacity = integerValueForKey(BadgeTintOpacity, 2);
}

- (NSBundle *)bundle {
	return [NSBundle bundleWithPath:ROOT_PATH_NS(@"/Library/PreferenceBundles/BackdropBadgePref.bundle")];
}

- (UIImage *)badgeForSizeMode:(int)size colorMode:(int)color {
	return [UIImage imageNamed:[NSString stringWithFormat:@"badge%d%d", size, color] inBundle:[self bundle]];
}

- (PSTableCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	PSTableCell *cell = (PSTableCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];

	if (indexPath.section <= 2) {
		PSSpecifier *specifier = [cell specifier];
		switch (indexPath.section) {
			case 0: {
				NSNumber *value = [specifier propertyForKey:@"borderSize"];
				[cell setChecked:badgeBorderSize == [value intValue]];
				cell.imageView.image = [self badgeForSizeMode:indexPath.row colorMode:3];
				break;
			}
			case 1: {
				NSNumber *value = [specifier propertyForKey:@"borderColor"];
				[cell setChecked:badgeBorderColorMode == [value intValue]];
				if (indexPath.row == 2)
					cell.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1];
				cell.imageView.image = [self badgeForSizeMode:3 colorMode:indexPath.row];
				break;
			}
			case 2: {
				NSNumber *value = [specifier propertyForKey:@"opacity"];
				[cell setChecked:badgeOpacity == [value intValue]];
				cell.imageView.image = nil;
				break;
			}
		}
	}

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[super tableView:tableView didSelectRowAtIndexPath:indexPath];
	NSInteger section = indexPath.section;
	if (section > 2) return;
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
		case 2:
			key = BadgeTintOpacity;
			badgeOpacity = value;
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
