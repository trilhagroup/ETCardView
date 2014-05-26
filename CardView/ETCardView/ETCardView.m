//
//  ETCardView.m
//  InEvent
//
//  Created by Pedro Góes on 09/05/14.
//  Copyright (c) 2014 Pedro G√≥es. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ETCardView.h"

@interface ETCardView () {
    NSString *previousTextFieldContent;
    UITextRange *previousSelection;
    NSArray *cardFlagsNames;
    NSArray *cardFlagsRegularExpressions;
    NSArray *cardFlagsImages;
}

@property (strong, nonatomic) IBOutlet UIImageView *cardFlagImage;

@end

@implementation ETCardView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self configureView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        [self configureView];
    }
    return self;
}

#pragma mark - User Methods

- (void)configureView {
    
    // Settings
    cardFlagsNames = @[@"American Express",
                       @"Visa",
                       @"Discover Network",
                       @"MasterCard"];
    
    cardFlagsImages = @[@"payment_method_american_express_card-128.png",
                        @"payment_method_card_visa-128.png",
                        @"payment_method_discover_network_card-128.png",
                        @"payment_method_master_card-128.png"];
    
    cardFlagsRegularExpressions = @[@"^3[47][0-9]{5,}$",
                                    @"^4[0-9]{6,}$",
                                    @"^6(?:011|5[0-9]{2})[0-9]{3,}$",
                                    @"^5[1-5][0-9]{5,}$"];
    
    // View
    [self addSubview:[[[NSBundle mainBundle] loadNibNamed:@"ETCardView" owner:self options:nil] firstObject]];
    [self setBackgroundColor:[UIColor colorWithWhite:0.965 alpha:1.000]];
    [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin];
    [self.layer setCornerRadius:6.0];
    [self.layer setShadowColor:[[UIColor colorWithWhite:0.685 alpha:1.000] CGColor]];
    [self.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
    [self.layer setShadowOpacity:1.0];
    [self.layer setShadowRadius:1.0];
    [self.layer setMasksToBounds:NO];
    [self.layer setBorderWidth:1.0];
    [self.layer setBorderColor:[[UIColor colorWithWhite:0.985 alpha:1.000] CGColor]];
    
    // Card Number
    [_cardNumber.layer addSublayer:[self createBottomBorder]];
    [_cardNumber addTarget:self action:@selector(reformatCardNumber:) forControlEvents:UIControlEventEditingChanged];
    
    // Expiration Date
    [_cardExpiration.layer addSublayer:[self createBottomBorder]];
    [_cardExpiration addTarget:self action:@selector(reformatExpirationDate:) forControlEvents:UIControlEventEditingChanged];
    
    // CVC
    [_cardCVC.layer addSublayer:[self createBottomBorder]];
    
    // Person Name
    [_cardPersonName.layer addSublayer:[self createBottomBorder]];
}

- (CALayer *)createBottomBorder {
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, _cardNumber.frame.size.height - 1.0f, _cardNumber.frame.size.width, 1.0f);
    bottomBorder.backgroundColor = [[UIColor colorWithWhite:0.875f alpha:1.0f] CGColor];
    
    return bottomBorder;
}

- (void)validateAndTabValueOnTextField:(UITextField *)textField {
    if ([self validateValueOnTextField:textField]) {
        if (textField != _cardPersonName) [self navigateByTabbingTextFields:textField];
    }
}

- (void)navigateByTabbingTextFields:(UITextField *)textField {
    
    NSInteger nextTag = textField.tag + 1;
    // Try to find next responder
    UIResponder *nextResponder = [textField.superview viewWithTag:nextTag];
    
    if (nextResponder) {
        // Found next responder, so set it.
        [nextResponder becomeFirstResponder];
    } else {
        // Not found, so remove keyboard.
        [textField resignFirstResponder];
    }
}

- (BOOL)validateValueOnTextField:(UITextField *)textField {
    
    BOOL valid = NO;
    
    // Process text masking
    if (textField == _cardNumber) {
        valid = (textField.text.length == 19);
        
    } else if (textField == _cardCVC) {
        valid = (textField.text.length == 3);
        
    } else if (textField == _cardExpiration) {
        NSArray *dateComponents = [textField.text componentsSeparatedByString:@"/"];
        valid = (textField.text.length >= 5 && [dateComponents count] == 2 && [[dateComponents objectAtIndex:0] integerValue] <= 12 && [[dateComponents objectAtIndex:1] integerValue] <= 99);
        
    } else if (textField == _cardPersonName) {
        NSCharacterSet *alphaSet = [NSCharacterSet letterCharacterSet];
        valid = (textField.text.length >= 11 && [[[textField.text stringByReplacingOccurrencesOfString:@" " withString:@""]stringByTrimmingCharactersInSet:alphaSet] isEqualToString:@""]);
    }
    
    [self changeBottomBorderOnTextField:textField toGivenState:valid];
    
    return valid;
}

- (void)changeBottomBorderOnTextField:(UITextField *)textField toGivenState:(BOOL)state {
    
    UIColor *bottomColor = nil;
    
    // Define its color
    if (state) {
        bottomColor = [UIColor colorWithRed:0.112 green:0.620 blue:0.114 alpha:1.000];
    } else {
        bottomColor = [UIColor colorWithRed:0.923 green:0.000 blue:0.327 alpha:1.000];
    }
    
    // Change text field's color
    ((CALayer *)[textField.layer.sublayers firstObject]).backgroundColor = [bottomColor CGColor];
}

#pragma mark - Card Processing

// Version 1.1
// Source and explanation: http://stackoverflow.com/a/19161529/1709587
- (void)reformatCardNumber:(UITextField *)textField {
    
    // In order to make the cursor end up positioned correctly, we need to
    // explicitly reposition it after we inject spaces into the text.
    // targetCursorPosition keeps track of where the cursor needs to end up as
    // we modify the string, and at the end we set the cursor position to it.
    NSUInteger targetCursorPosition = [textField offsetFromPosition:textField.beginningOfDocument toPosition:textField.selectedTextRange.start];
    
    NSString *cardNumberWithoutSpaces = [self removeNonDigits:textField.text andPreserveCursorPosition:&targetCursorPosition];
    
    if ([cardNumberWithoutSpaces length] > 16) {
        // If the user is trying to enter more than 16 digits, we prevent
        // their change, leaving the text field in its previous state
        [textField setText:previousTextFieldContent];
        textField.selectedTextRange = previousSelection;
        return;
    }
    
    // Process card number and set its flag image
    NSError *error = NULL;
    for (int i = 0; i < [cardFlagsRegularExpressions count]; i++) {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:[cardFlagsRegularExpressions objectAtIndex:i] options:NSRegularExpressionCaseInsensitive error:&error];
        NSArray *ocurrences = [regex matchesInString:cardNumberWithoutSpaces options:0 range:NSMakeRange(0, [cardNumberWithoutSpaces length])];
        
        if ([ocurrences count] > 0) {
            // Set the right image for the current card regex
            _cardFlagImage.image = [UIImage imageNamed:[cardFlagsImages objectAtIndex:i]];
            _cardFlag = [cardFlagsNames objectAtIndex:i];
        }
    }
    
    // Remove spaces from the current field
    NSString *cardNumberWithSpaces = [self performUpdateIntoString:cardNumberWithoutSpaces andPreserveCursorPosition:&targetCursorPosition forConditionMet:^NSString *(NSInteger position, unichar character) {
        return ((position>0) && ((position % 4) == 0)) ? @" " : nil;
    }];
    
    // Update the text with formatted string
    textField.text = cardNumberWithSpaces;
    UITextPosition *targetPosition = [textField positionFromPosition:[textField beginningOfDocument] offset:targetCursorPosition];
    
    [textField setSelectedTextRange:[textField textRangeFromPosition:targetPosition toPosition:targetPosition]];
}

/*
 Removes non-digits from the string, decrementing `cursorPosition` as
 appropriate so that, for instance, if we pass in `@"1111 1123 1111"`
 and a cursor position of `8`, the cursor position will be changed to
 `7` (keeping it between the '2' and the '3' after the spaces are removed).
 */
- (NSString *)removeNonDigits:(NSString *)string andPreserveCursorPosition:(NSUInteger *)cursorPosition {
    
    NSUInteger originalCursorPosition = *cursorPosition;
    NSMutableString *digitsOnlyString = [NSMutableString new];
    for (NSUInteger i=0; i<[string length]; i++) {
        unichar characterToAdd = [string characterAtIndex:i];
        if (isdigit(characterToAdd)) {
            NSString *stringToAdd = [NSString stringWithCharacters:&characterToAdd length:1];
            [digitsOnlyString appendString:stringToAdd];
        } else {
            if (i < originalCursorPosition) {
                (*cursorPosition)--;
            }
        }
    }
    
    return digitsOnlyString;
}

/*
 Inserts spaces into the string to format it as a credit card number,
 incrementing `cursorPosition` as appropriate so that, for instance, if we
 pass in `@"111111231111"` and a cursor position of `7`, the cursor position
 will be changed to `8` (keeping it between the '2' and the '3' after the
 spaces are added).
 */
- (NSString *)performUpdateIntoString:(NSString *)string andPreserveCursorPosition:(NSUInteger *)cursorPosition forConditionMet:(NSString * (^)(NSInteger position, unichar character))conditionBlock {
    
    NSMutableString *stringWithAddedSpaces = [NSMutableString new];
    NSUInteger cursorPositionInSpacelessString = *cursorPosition;
    for (NSUInteger i=0; i<[string length]; i++) {
        NSString *extraString = conditionBlock(i, [string characterAtIndex:i]);
        if (extraString != nil) {
            [stringWithAddedSpaces appendString:extraString];
            if (i < cursorPositionInSpacelessString) {
                (*cursorPosition)++;
            }
        }
        unichar characterToAdd = [string characterAtIndex:i];
        NSString *stringToAdd = [NSString stringWithCharacters:&characterToAdd length:1];
        
        [stringWithAddedSpaces appendString:stringToAdd];
    }
    
    return stringWithAddedSpaces;
}

#pragma mark - Expiration Processing

- (void)reformatExpirationDate:(UITextField *)textField {
    // In order to make the cursor end up positioned correctly, we need to
    // explicitly reposition it after we inject spaces into the text.
    // targetCursorPosition keeps track of where the cursor needs to end up as
    // we modify the string, and at the end we set the cursor position to it.
    NSUInteger targetCursorPosition = [textField offsetFromPosition:textField.beginningOfDocument toPosition:textField.selectedTextRange.start];
    
    NSString *expirationDateWithoutSpaces = [self removeNonDigits:textField.text andPreserveCursorPosition:&targetCursorPosition];
    
    if ([expirationDateWithoutSpaces length] > 5) {
        [textField setText:previousTextFieldContent];
        textField.selectedTextRange = previousSelection;
        return;
    }
    
    // Remove spaces from the current field
    NSString *cardNumberWithSpaces = [self performUpdateIntoString:expirationDateWithoutSpaces andPreserveCursorPosition:&targetCursorPosition forConditionMet:^NSString *(NSInteger position, unichar character) {
        return ((position>0) && ((position % 2) == 0)) ? @"/" : nil;
    }];
    
    // Update the text with formatted string
    textField.text = cardNumberWithSpaces;
    UITextPosition *targetPosition = [textField positionFromPosition:[textField beginningOfDocument] offset:targetCursorPosition];
    
    [textField setSelectedTextRange:[textField textRangeFromPosition:targetPosition toPosition:targetPosition]];
}

#pragma mark - Text Field Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    // Validate and tab textfield
    // We want to make sure that the update has already been set on the outlet, that's why we have a small delay
    [self performSelector:@selector(validateAndTabValueOnTextField:) withObject:textField afterDelay:0.1];
    
    // Process text masking
    if (textField == _cardNumber) {
        // Note textField's current state before performing the change, in case
        // reformatTextField wants to revert it
        previousTextFieldContent = textField.text;
        previousSelection = textField.selectedTextRange;
        
        return YES;
        
    } else if (textField == _cardCVC) {
        return textField.text.length + (string.length - range.length) <= 3;
        
    } else if (textField == _cardExpiration) {
        return textField.text.length + (string.length - range.length) <= 5;
        
    } else if (textField == _cardPersonName) {
        return YES;
    }
    
    return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField {
    // Navigate to the next tab
    [self navigateByTabbingTextFields:textField];
    
    // Remove keyboard
    [textField resignFirstResponder];
    
    // We do not want UITextField to insert line-breaks.
    return YES;
}

@end
