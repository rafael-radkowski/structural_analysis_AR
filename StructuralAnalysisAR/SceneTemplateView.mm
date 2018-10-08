//
//  SceneTemplateView.m
//  StructuralAnalysisAR
//
//  Created by David Wehr on 10/3/18.
//  Copyright © 2018 David Wehr. All rights reserved.
//

#import "SceneTemplateView.h"

@implementation SceneTemplateView

- (void)prepareForInterfaceBuilder {
    [super prepareForInterfaceBuilder];
    [self customInit];
    [self.contentView prepareForInterfaceBuilder];
}

- (IBAction)screenshotBtnPressed:(id)sender {
    return [self.managingParent screenshotBtnPressed:sender infoBox:self.screenshotInfoBox];
}

- (IBAction)homeBtnPressed:(id)sender {
    return [self.managingParent homeBtnPressed:sender];
}

- (IBAction)pauseCamBtnpressed:(id)sender {
    [self.managingParent freezePressed:sender freezeBtn:self.pauseCamBtn curtain:self.processingCurtainView];
}

- (IBAction)changeTrackingBtnPressed:(id)sender {
    CGRect frame = [self.changeTrackingBtn.superview convertRect:self.changeTrackingBtn.frame toView:self];
    [self.managingParent changeTrackingMode:frame];
}

- (void)setCameraLabelPaused:(bool)isPaused isEnabled:(bool)enabled {
    if (isPaused) {
        [self.pauseCamBtn setTitle:@"Resume Camera" forState:UIControlStateNormal];
    }
    else {
        [self.pauseCamBtn setTitle:@"Pause Camera" forState:UIControlStateNormal];
    }
    self.pauseCamBtn.enabled = enabled;
}

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
    NSString* nibName = NSStringFromClass(self.class);
    NSBundle* bundle = [NSBundle bundleForClass:self.class];
    UINib* nib = [UINib nibWithNibName:nibName bundle:bundle];
    self.contentView = [nib instantiateWithOwner:self options:nil][0];
    self.contentView.frame = self.bounds;
//    self.contentView = [[NSBundle bundleForClass:[self class]] loadNibNamed:@"SceneTemplateView" owner:self options:nil].firstObject;
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    
//    [self addSubview:self.contentView];
    [self insertSubview:self.contentView atIndex:0];
    
    // add constraints so subview fills placeholder view
    [self addConstraint:[self from:self pinTo:self.contentView attribute:NSLayoutAttributeTop]];
    [self addConstraint:[self from:self pinTo:self.contentView attribute:NSLayoutAttributeLeft]];
    [self addConstraint:[self from:self pinTo:self.contentView attribute:NSLayoutAttributeBottom]];
    [self addConstraint:[self from:self pinTo:self.contentView attribute:NSLayoutAttributeRight]];
    
    // Add a semi-transparent background to the visualization options box so
    UIView* stackBg = [[UIView alloc] initWithFrame:self.visOptionsBox.bounds];
    stackBg.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.28];
    stackBg.translatesAutoresizingMaskIntoConstraints = NO;
    [self.visOptionsBox insertSubview:stackBg atIndex:0];
    [self addConstraint:[self from:stackBg pinTo:self.visOptionsBox attribute:NSLayoutAttributeTop]];
    [self addConstraint:[self from:stackBg pinTo:self.visOptionsBox attribute:NSLayoutAttributeLeft]];
    [self addConstraint:[self from:stackBg pinTo:self.visOptionsBox attribute:NSLayoutAttributeBottom]];
    [self addConstraint:[self from:stackBg pinTo:self.visOptionsBox attribute:NSLayoutAttributeRight]];
    
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
    
    // Setup screenshot info box
    self.screenshotInfoBox.layer.cornerRadius = self.screenshotInfoBox.bounds.size.height / 2;
    
    // Processing curtain view
    self.processingCurtainView.hidden = YES;
    self.processingSpinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
}


- (NSLayoutConstraint *)from:(id)fromItem pinTo:(id)toItem attribute:(NSLayoutAttribute)attribute {
    return [NSLayoutConstraint constraintWithItem:fromItem
                                        attribute:attribute
                                        relatedBy:NSLayoutRelationEqual
                                           toItem:toItem
                                        attribute:attribute
                                       multiplier:1.0
                                         constant:0.0];
}
@end
