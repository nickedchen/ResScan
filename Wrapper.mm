//
//  Wrapper.mm
//  ResScan
//
//  Created by Nick Chen on 2023-01-01.
//

#import "Wrapper.h"
#import <Foundation/Foundation.h>
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>

@implementation Wrapper : NSObject
using namespace cv;

//Defining the resistor colour ranges
NSArray *Colour_Range = @[
    @[@(0), @(0), @(0), @(255), @(255), @(20), @"BLACK", @(0), @(0), @(0)],
    @[@(0), @(90), @(10), @(15), @(250), @(100), @"BROWN", @(1), @(0), @(51), @(102)],
    @[@(0), @(30), @(80), @(10), @(255), @(200), @"RED", @(2), @(0), @(0), @(255)],
    @[@(5), @(150), @(150), @(15), @(235), @(250), @"ORANGE", @(3), @(0), @(128), @(255)],
    @[@(50), @(100), @(100), @(70), @(255), @(255), @"YELLOW", @(4), @(0), @(255), @(255)],
    @[@(45), @(100), @(50), @(75), @(255), @(255), @"GREEN", @(5), @(0), @(255), @(0)],
    @[@(100), @(150), @(0), @(140), @(255), @(255), @"BLUE", @(6), @(255), @(0), @(0)],
    @[@(120), @(40), @(100), @(140), @(250), @(220), @"VIOLET", @(7), @(255), @(0), @(127)],
    @[@(0), @(0), @(50), @(179), @(50), @(80), @"GRAY", @(8), @(128), @(128), @(128)],
    @[@(0), @(0), @(90), @(179), @(15), @(250), @"WHITE", @(9), @(255), @(255), @(255)],
]

NSArray *redTopLow = @[@160, @30, @80];
NSArray *redTopHigh = @[@179, @255, @200];

double min_area = 0;
int font = FONT_HERSHEY_SIMPLEX;

//Image pre-processing
- (NSArray *)findBands:(Mat)img {
    Mat img1;
    // Using bilateral filter to remove noise
    bilateralFilter(img, img1, 40, 90, 90); 
    Mat imgGray;
    cvtColor(img1, imgGray, COLOR_BGR2GRAY);
    Mat imgHSV;
    cvtColor(img1, imgHSV, COLOR_BGR2HSV);
    Mat thresh;
    // Adaptive thresholding to remove background noise
    adaptiveThreshold(imgGray, thresh, 255, ADAPTIVE_THRESH_MEAN_C, THRESH_BINARY, 79, 2);
    // Invert the image
    bitwise_not(thresh, thresh);

    NSMutableArray *bandpos = [NSMutableArray array];

    // Loop through each colour range
    for (NSArray *clr in colorRange) {
        Mat mask;
        // Find the mask for each colour range
        inRange(imgHSV, Scalar([clr[0] intValue], [clr[1] intValue], [clr[2] intValue]), Scalar([clr[3] intValue], [clr[4] intValue], [clr[5] intValue]), mask);
        // If the colour is red, find the mask for the top half of the image
        if ([clr[6] isEqualToString:@"RED"]) {
            Mat redMask;
            inRange(imgHSV, Scalar(160, 30, 80), Scalar(179, 255, 200), redMask);
            bitwise_or(redMask, mask, mask);
        }
        // Apply the mask to the image
        bitwise_and(mask, thresh, mask, mask);
        vector<vector<Point>> contours;
        vector<Vec4i> hierarchy;
        // Find the contours
        findContours(mask, contours, hierarchy, RETR_TREE, CHAIN_APPROX_SIMPLE);

        // Loop through each contour
        for (int i = (int)contours.size() - 1; i >= 0; i--) {
            // If the contour is valid, find the leftmost point and add it to the array
            if (validContours(contours[i])) {
                Point lmp = contours[i][min(contours[i][:, :, 0])][0];
                [bandpos addObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:lmp.x], [NSNumber numberWithInt:lmp.y], clr[6], clr[7], clr[8], clr[9], nil]];
            } else { // else remove it from the array
                contours.erase(contours.begin() + i);
            }
        }
        // Draw the contours
        drawContours(img1, contours, -1, Scalar([clr[8] intValue], [clr[9] intValue], [clr[10] intValue]), 3);
    }

    imshow("Contour Display", img1);
    return [bandpos sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self.0" ascending:YES]]];
}

// Check if the contour is valid
- (BOOL)validContours:(vector<Point>)cont {
    if (contourArea(cont) < minArea) {
        return NO;
    } else {
        Rect boundingRect = boundingRect(cont);
        if (boundingRect.width / boundingRect.height > 0.40) {
            return NO;
        }
    }
    return YES;
}
// Display the results
- (void)displayResults:(NSArray *)sortedbands {
    NSString *strvalue = @"";
    if (sortedbands.count == 3 || sortedbands.count == 4 || sortedbands.count == 5) {
        for (NSArray *band in [sortedbands subarrayWithRange:NSMakeRange(0, sortedbands.count - 1)]) {
            strvalue = [strvalue stringByAppendingString:[band[3] stringValue]];
        }
        int intvalue = [strvalue intValue];
        intvalue *= pow(10, [[sortedbands.lastObject[3] stringValue] intValue]);
        NSLog(@"The Resistance is %d ohms", intvalue);
    }
}

// Run function that calls all the other functions
- (void)run {
    Mat image = imread("testresistor.jpg");
    NSArray *sortedbands = [self findBands:image];
    [self displayResults:sortedbands];
    waitKey(0);
    destroyAllWindows();
}
 
// OpenCV version
+ (NSString *)openCVVersionString {
return [NSString stringWithFormat:@"OpenCV Version %s",  CV_VERSION];
}
 
@end
