#import <Preferences/Preferences.h>

@interface PSTableCell (Settings)

- (id)initWithStyle:(int)style reuseIdentifier:(id)identifier specifier:(id)specifier;
- (UIView *)contentView;

@end

@interface NoAnnoyanceHeader : PSTableCell {
    UILabel * _titleLabel;
}
@end
