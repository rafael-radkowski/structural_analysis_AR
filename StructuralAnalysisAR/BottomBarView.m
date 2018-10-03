//
//  BottomBarViewController.m
//  StructuralAnalysisAR
//
//  Created by David Wehr on 10/2/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#import "BottomBarView.h"

@interface BottomBarView ()

@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIButton *homeBtn;
@property (weak, nonatomic) IBOutlet UIButton *screenshotBtn;
@property (weak, nonatomic) IBOutlet UIButton *pauseCamBtn;
@property (weak, nonatomic) IBOutlet UIButton *changeTrackingBtn;

@end


@implementation BottomBarView

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self customInit];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    return self;
}

-(void)customInit {
    [[NSBundle mainBundle] loadNibNamed:@"BottomBarView" owner:self options:nil];
    [self addSubview:self.contentView];
    
    // add constraints so subview fills placeholder view
    [self addConstraint:[self pin:self.contentView attribute:NSLayoutAttributeTop]];
    [self addConstraint:[self pin:self.contentView attribute:NSLayoutAttributeLeft]];
    [self addConstraint:[self pin:self.contentView attribute:NSLayoutAttributeBottom]];
    [self addConstraint:[self pin:self.contentView attribute:NSLayoutAttributeRight]];
    
    
    CGColorRef textColor = [UIColor colorWithRed:0.08235 green:0.49412 blue:0.9843 alpha:1.0].CGColor;
    // Setup home button style
    self.homeBtn.layer.borderWidth = 1.5;
    self.homeBtn.imageEdgeInsets = UIEdgeInsetsMake(3, 3, 3, 3);
    self.homeBtn.layer.borderColor = textColor;
    self.homeBtn.layer.cornerRadius = 5;
    
    // Setup screenshot button style
    self.screenshotBtn.layer.borderWidth = 1.5;
    self.screenshotBtn.imageEdgeInsets = UIEdgeInsetsMake(3, 3, 3, 3);
    self.screenshotBtn.layer.borderColor = textColor;
    self.screenshotBtn.layer.cornerRadius = 5;
    
    // Setup freeze frame button
    self.pauseCamBtn.layer.borderWidth = 1.5;
    self.pauseCamBtn.layer.borderColor = textColor;
    self.pauseCamBtn.layer.cornerRadius = 5;
    
    // Setup change tracking button
    self.changeTrackingBtn.layer.borderWidth = 1.5;
    self.changeTrackingBtn.layer.borderColor = textColor;
    self.changeTrackingBtn.layer.cornerRadius = 5;
}


- (NSLayoutConstraint *)pin:(id)item attribute:(NSLayoutAttribute)attribute {
    return [NSLayoutConstraint constraintWithItem:self
                                        attribute:attribute
                                        relatedBy:NSLayoutRelationEqual
                                           toItem:item
                                        attribute:attribute
                                       multiplier:1.0
                                         constant:0.0];
}

@end
