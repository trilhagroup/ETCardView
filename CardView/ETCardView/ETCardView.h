//
//  ETCardView.h
//  InEvent
//
//  Created by Pedro Góes on 09/05/14.
//  Copyright (c) 2014 Pedro G√≥es. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ETCardView : UIView <UITextFieldDelegate>

@property (strong, nonatomic, readonly) NSString *cardFlag;
@property (strong, nonatomic) IBOutlet UITextField *cardNumber;
@property (strong, nonatomic) IBOutlet UITextField *cardCVC;
@property (strong, nonatomic) IBOutlet UITextField *cardExpiration;
@property (strong, nonatomic) IBOutlet UITextField *cardPersonName;

@end
