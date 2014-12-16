#import "NoAnnoyanceHeader.h"

@implementation NoAnnoyanceHeader

- (id)initWithSpecifier:(PSSpecifier *)specifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoAnnoyanceHeader" specifier:specifier];

    if (self) {

        CGRect frame = [self.contentView frame];
        frame.size.height *= 0.8;

        _titleLabel = [[UILabel alloc] initWithFrame:frame];

        _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

        [_titleLabel setTextAlignment:NSTextAlignmentCenter];
        [_titleLabel setText:@"NoAnnoyance"];
        [_titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Thin" size:30]];

        [_titleLabel setNumberOfLines:0];

        [self.contentView addSubview:_titleLabel];

        [_titleLabel release];
    }

    return self;
}

- (float)preferredHeightForWidth:(float)arg1
{
    return 80.f;
}

@end
