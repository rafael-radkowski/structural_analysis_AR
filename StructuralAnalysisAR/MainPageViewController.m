//
//  MainPageViewController.m
//  StructuralAnalysisAR
//
//  Created by David Wehr on 8/28/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#import "MainPageViewController.h"

@interface MainPageViewController ()

@end

@implementation MainPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set borders on the buttons
    CGColorRef textColor = [UIColor colorWithRed:0.08235 green:0.49412 blue:0.9843 alpha:1.0].CGColor;
    float borderWidth = 2;
    float cornerRadius = 8;
    self.btnSkywalk.layer.borderWidth = borderWidth;
    self.btnSkywalk.layer.cornerRadius = cornerRadius;
    self.btnSkywalk.layer.borderColor = textColor;
    
    self.btnWaterTower.layer.borderWidth = borderWidth;
    self.btnWaterTower.layer.cornerRadius = cornerRadius;
    self.btnWaterTower.layer.borderColor = textColor;
    
    self.btnCampanile.layer.borderWidth = borderWidth;
    self.btnCampanile.layer.cornerRadius = cornerRadius;
    self.btnCampanile.layer.borderColor = textColor;
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
