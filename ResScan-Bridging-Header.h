//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

# include "Wrapper.h"
# include "opencv2/opencv.hpp"

// Bridging headers for Swift

using namespace cv;

class Wrapper {
    public:
        // findBands
        NSArray findBands(Mat img);
        // run func
        void run();
    private:
        // validContours
        bool validContours(vector<Point> contour);
        // displayResults
        void displayResults(NSArray * sortedbands);
    
};



