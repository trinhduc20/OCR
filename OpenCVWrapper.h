//
//  OpenCVWrapper.h
//  ocr
//
//  Created by Trinh Tran on 11/18/15.
//  Copyright © 2015 Trinh Tran. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface OpenCVWrapper : NSObject

+ (UIImage *)processImageWithOpenCV:(UIImage*)inputImage;

@end
