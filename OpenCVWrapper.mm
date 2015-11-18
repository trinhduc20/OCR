//
//  OpenCVWrapper.m
//  ocr
//
//  Created by Trinh Tran on 11/18/15.
//  Copyright © 2015 Trinh Tran. All rights reserved.
//

#import "OpenCVWrapper.h"
#import "UIImage+OpenCV.h"

#include <opencv2/opencv.hpp>

using namespace cv;
using namespace std;

@implementation OpenCVWrapper

+ (UIImage *)processImageWithOpenCV:(UIImage*)inputImage {
    Mat mat = [inputImage CVMat];
    
    // do your processing here
    
    return [UIImage imageWithCVMat:mat];
}

@end
