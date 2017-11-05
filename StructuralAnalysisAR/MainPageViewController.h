//
//  MainPageViewController.h
//  StructuralAnalysisAR
//
//  Created by David Wehr on 8/28/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainPageViewController : UIViewController

// MARK: Properties
@property (weak, nonatomic) IBOutlet UIButton *btnSkywalk;

@property (weak, nonatomic) IBOutlet UIButton *btnWaterTower;

@property (weak, nonatomic) IBOutlet UIButton *btnCampanile;

- (IBAction)backToHomepage:(UIStoryboardSegue*)unwindSegue;

@property (nonatomic) NSString* prefs_path;

- (void) timeUp:(NSTimer*)timer;

@property (weak, nonatomic) IBOutlet UIButton *superSecretButton;
- (IBAction)secretPress:(id)sender;


@end
