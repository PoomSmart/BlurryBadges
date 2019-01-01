#define UIFUNCTIONS_NOT_C
#import <UIKit/UIColor+Private.h>
#import <UIKit/UIImage+Private.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>
#import <notify.h>
#import "../PS.h"

#define SB CFSTR("com.apple.springboard")
#define BorderWidth CFSTR("SBBadgeBorderWidth")
#define BorderColor CFSTR("SBBadgeBorderColorMode")
#define BadgeTintAlpha CFSTR("SBBadgeTintAlpha")
#define RowHeight 44.0

@interface BackdropBadgePrefController : PSViewController <UITableViewDataSource, UITableViewDelegate> {
	int badgeBorderSize;
	int badgeBorderColorMode;
}
@property(nonatomic, retain) UISlider *slider;
@end

static int integerValueForKey(CFStringRef key, int defaultValue) {
	CFPreferencesAppSynchronize(SB);
	Boolean valid;
	CFIndex value = CFPreferencesGetAppIntegerValue(key, SB, &valid);
	return valid ? value : defaultValue;
}

static float floatValueForKey(CFStringRef key, float defaultValue) {
	id r = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:(NSString *)SB] objectForKey:(NSString *)key];
	return r ? [r floatValue] : defaultValue;
}

@implementation BackdropBadgePrefController

- (void)loadView {
	UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
	tableView.dataSource = self;
	tableView.delegate = self;
	tableView.rowHeight = RowHeight;
	self.view = tableView;
	[tableView release];
}

- (void)setSpecifier:(PSSpecifier *)specifier {
	[super setSpecifier:specifier];
	self.navigationItem.title = [specifier name];
	badgeBorderSize = integerValueForKey(BorderWidth, 3);
	badgeBorderColorMode = integerValueForKey(BorderColor, 2);
	if ([self isViewLoaded]) {
		[(UITableView *)self.view setRowHeight:RowHeight];
		[(UITableView *)self.view reloadData];
	}
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleNone;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table {
	return 3;
}

- (NSString *)tableView:(UITableView *)table titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return @"Border Size";
		case 1:
			return @"Border Color";
		case 2:
			return @"Badge Tint Alpha";
		default:
			return nil;
	}
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	if (section == [self numberOfSectionsInTableView:tableView]-1) {
		UIView *footer2 = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 90)] autorelease];
		footer2.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		footer2.backgroundColor = UIColor.clearColor;

		UILabel *lbl2 = [[UILabel alloc] initWithFrame:footer2.frame];
		lbl2.backgroundColor = [UIColor clearColor];
		lbl2.text = @"© 2013 - 2017 PoomSmart\n© 2018 Spica T";
		lbl2.textColor = UIColor.systemGrayColor;
		lbl2.font = [UIFont systemFontOfSize:14.0];
		lbl2.textAlignment = NSTextAlignmentCenter;
		lbl2.lineBreakMode = NSLineBreakByWordWrapping;
		lbl2.numberOfLines = 2;
		lbl2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		[footer2 addSubview:lbl2];
		[lbl2 release];
    	return footer2;
    }
    return nil;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return section == [self numberOfSectionsInTableView:tableView] - 1 ? 100 : 0;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
	if (section <= 1)
		return 5;
	if (section == 2)
		return 1;
	return 0;
}

- (NSBundle *)bundle {
	return [NSBundle bundleWithPath:@"/Library/PreferenceBundles/BackdropBadgePref.bundle"];
}

- (UIImage *)badgeForSizeMode:(int)size colorMode:(int)color {
	return [UIImage imageNamed:[NSString stringWithFormat:@"badge%d%d", size, color] inBundle:[self bundle]];
}

- (void)sliderValueChanged:(UISlider *)sender {
	CFPreferencesSetAppValue(BadgeTintAlpha, (CFTypeRef)@(sender.value), SB);
	CFPreferencesAppSynchronize(SB);
}

- (UISlider *)badgeTintAlphaSlider {
	if (self.slider == nil) {
		self.slider = [[[UISlider alloc] init] autorelease];
		self.slider.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.slider.minimumValue = 0;
		self.slider.maximumValue = 1;
		[self.slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
	}
	self.slider.value = floatValueForKey(BadgeTintAlpha, 0.65);
	return self.slider;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section <= 1) {
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"selection"] ?: [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"selection"] autorelease];
		cell.textLabel.textAlignment = NSTextAlignmentLeft;
		cell.backgroundColor = UIColor.whiteColor;
		switch (indexPath.section) {
			case 0:
				switch (indexPath.row) {
					case 0:
						cell.textLabel.text = @"No Border";
						break;
					case 1:
						cell.textLabel.text = @"Little";
						break;
					case 2:
						cell.textLabel.text = @"Medium";
						break;
					case 3:
						cell.textLabel.text = @"Pre-iOS 7";
						break;
					case 4:
						cell.textLabel.text = @"Huge";
						break;
				}
				break;
			case 1:
				switch (indexPath.row) {
					case 0:
						cell.textLabel.text = @"Lighter";
						break;
					case 1:
						cell.textLabel.text = @"Darker";
						break;
					case 2:
						cell.textLabel.text = @"White";
						cell.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
						break;
					case 3:
						cell.textLabel.text = @"Black";
						break;
					case 4:
						cell.textLabel.text = @"Random";
						break;
				}
				break;
		}
		CFIndex value;
		switch (indexPath.section) {
			case 0:
				value = badgeBorderSize;
				break;
			case 1:
				value = badgeBorderColorMode;
				break;
		}
		cell.imageView.image = [self badgeForSizeMode:indexPath.section == 0 ? indexPath.row : 3 colorMode:indexPath.section == 1 ? indexPath.row : 3];
		cell.accessoryType = (value == indexPath.row) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
		return cell;
	}
	else if (indexPath.section == 2) {
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"slider"] ?: [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"slider"] autorelease];
		cell.textLabel.text = nil;
		UISlider *tintSlider = [self badgeTintAlphaSlider];
		[cell.contentView addSubview:tintSlider];
		tintSlider.bounds = CGRectMake(0, 0, cell.contentView.bounds.size.width - 30, tintSlider.bounds.size.height);
    	tintSlider.center = CGPointMake(CGRectGetMidX(cell.contentView.bounds), CGRectGetMidY(cell.contentView.bounds));
    	tintSlider.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    	return cell;
	}
	return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	NSInteger section = indexPath.section;
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
		case 3:
			switch (value) {
				case 0:
					[[UIApplication sharedApplication] openURL:[NSURL URLWithString:PS_DONATE_URL]];
					break;
				case 1:
					[[UIApplication sharedApplication] openURL:[NSURL URLWithString:PS_TWITTER_URL]];
					break;
			}
			break;
	}
	if (section <= 1) {
		for (NSInteger i = 0; i <= 4; i++)
			[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section]].accessoryType = (value == i) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
		CFPreferencesSetAppValue(key, (CFTypeRef)@(value), SB);
		CFPreferencesAppSynchronize(SB);
		notify_post("com.ps.backdropbadge.update");
	}
}

- (id)table {
	return nil;
}

- (void)suspend {
	notify_post("com.ps.backdropbadge.update");
	[super suspend];
}

@end
