//
//  BezierLine.cpp
//  StructuralAnalysisAR
//
//  Created by David Wehr on 9/12/17.
//  Copyright © 2017 David Wehr. All rights reserved.
//

#include "BezierLine.h"
#include <algorithm>


//BezierLine::BezierLine() {
//    lineNode = [SCNNode nodeWithGeometry:meshFromPath([UIBezierPath bezierPath])];
//    rootNode = [SCNNode node];
//    [rootNode addChildNode:lineNode];
//    
//    // Make a material
//    lineNode.geometry.firstMaterial = [SCNMaterial material];
//    lineNode.geometry.firstMaterial.diffuse.contents = [UIColor redColor];
//}
//
//
//BezierLine::BezierLine(const std::vector<std::vector<float>>& points) {
//    UIBezierPath* pointsPath = interpolatePoints(points, thickness);
//    
//    lineNode = [SCNNode nodeWithGeometry:meshFromPath(pointsPath)];
//    rootNode = [SCNNode node];
//    [rootNode addChildNode:lineNode];
//    
//    // Make a material
//    lineNode.geometry.firstMaterial = [SCNMaterial material];
//    lineNode.geometry.firstMaterial.diffuse.contents = [UIColor colorWithRed:0.05 green:0.9 blue:1 alpha:1];
//}

BezierLine::BezierLine(UIBezierPath* path) {
    lineNode = [SCNNode nodeWithGeometry:meshFromPath(path)];
    rootNode = [SCNNode node];
    [rootNode addChildNode:lineNode];
    
    // Make a material
    lineNode.geometry.firstMaterial = [SCNMaterial material];
    lineNode.geometry.firstMaterial.diffuse.contents = [UIColor colorWithRed:0.05 green:0.9 blue:1 alpha:1];
    
    labelEmpty = [SCNNode node];
    [rootNode addChildNode:labelEmpty];
    defLabel.setObject(labelEmpty);
    defLabel.setCenter(0.5, 1);
}

void BezierLine::setScenes(SKScene* scene2d, SCNView* view3d) {
    defLabel.setScenes(scene2d, view3d);
}

void BezierLine::doUpdate() {
    defLabel.doUpdate();
}

void BezierLine::setTextHidden(bool new_hidden) {
    labelHidden = new_hidden;
    defLabel.setHidden(labelHidden || hidden);
}

void BezierLine::setHidden(bool new_hidden) {
    rootNode.hidden = hidden;
    defLabel.setHidden(hidden || labelHidden);
    hidden = new_hidden;
}

SCNShape* BezierLine::meshFromPath(UIBezierPath* path) {
    SCNShape* shape = [SCNShape shapeWithPath:path extrusionDepth:thickness];
//    shape.chamferRadius = thickness / 2;
    return shape;
}

void BezierLine::addAsChild(SCNNode* node) {
    [node addChildNode:rootNode];
}

void BezierLine::setPosition(GLKVector3 pos) {
    rootNode.position = SCNVector3FromGLKVector3(pos);
}

void BezierLine::setOrientation(GLKQuaternion ori) {
    rootNode.orientation = SCNVector4Make(ori.x, ori.y, ori.z, ori.w);
}

void BezierLine::setThickness(float newThickness) {
    thickness = newThickness;
}

void BezierLine::setMagnification(float new_mag) {
    magnification = new_mag;
}

void BezierLine::setTextLocX(float fac_along_x) {
    x_pos_frac = fac_along_x;
    defLabel.markPosDirty();
}

void BezierLine::updatePath(const std::vector<std::vector<float>>& points) {
    SCNShape* shapeGeom = (SCNShape*) lineNode.geometry;
    std::vector<std::vector<float>> pointsCopy(2);
    pointsCopy[0] = points[0];
    pointsCopy[1] = std::vector<float>(points[1].size());
    std::transform(points[1].begin(), points[1].end(), pointsCopy[1].begin(), [this](float orig_y) {return orig_y * magnification;});
    shapeGeom.path = interpolatePoints(pointsCopy, thickness);
    float extreme_y = 0;
    for (const float y : points[1]) {
        if (std::abs(y) > std::abs(extreme_y)) {extreme_y = y;}
    }
    float x_range = points[0][points[0].size() - 1] + points[0][0];
    float desired_x = x_range * x_pos_frac;
//    auto closest_elem = std::find_if(points[0].begin(), points[0].end(), [desired_x] (float val) {return val >= desired_x;});
//    size_t idx = (closest_elem - points[0].begin());
    labelEmpty.position = SCNVector3Make(desired_x, extreme_y * magnification, 0);
    defLabel.setText([NSString stringWithFormat:@"%.3f in.", extreme_y * 12]);
    defLabel.markPosDirty();
}

UIBezierPath* BezierLine::interpolatePoints(const std::vector<std::vector<float>>& points, float height) {
    int n_points = static_cast<int>(points[0].size());
    assert(points[0].size() == n_points); // Validate cast to int
    assert(n_points >= 3); // Need at least two points for a line
    assert(points.size() == 2); // can only make 2-dimensional UIBezierPath
    assert(points[0].size() == points[1].size()); // x and y match
    
    int n_paths = n_points - 1;
    int mat_dim = n_paths - 1;
    
    // create modified coefficients from 1 4 1 tridiagonal matrix
    std::vector<float> c_primes(n_paths - 1);
    c_primes[0] = (1.0 / 4.0); // First is always 1/4
    for (int i = 1; i < mat_dim; ++i) {
        c_primes[i] = 1 / (4 - c_primes[i-1]);
    }
    
    std::vector<std::vector<float>> splinePoints;
    // Solve for spline control points for each dimension
    for (const std::vector<float>& axialPoints : points) {
        // Will be
        std::vector<float> axialSplinePoints(n_points);
        // First and last spline control points are just the original points
        axialSplinePoints[0] = axialPoints[0];
        axialSplinePoints[n_points - 1] = axialPoints[n_points-1];
        
        // Calculate right-hand side of the equation at the same time as modifying it for solving
        std::vector<float> rhs_primes(mat_dim);
        // rhs[0] = (6*p_1 - p_0)
        // rhs'[0] = rhs[0] / 4
        rhs_primes[0] = (6*axialPoints[1] - axialPoints[0]) / 4;
        for (int i = 1; i < mat_dim - 1; ++i) {
            float rhs_i = 6*axialPoints[i+1];
            rhs_primes[i] = (rhs_i - rhs_primes[i-1]) / (4 - c_primes[i-1]);
        }
        // rhs[last] = 6*p_secondlast - p_last
        rhs_primes[mat_dim - 1] = (6*axialPoints[n_points - 2] - axialPoints[n_points - 1] - rhs_primes[mat_dim-2]) / (4 - c_primes[mat_dim - 2]);
        
        // Now solve by back-substitution. Index is weird because the first and last spline points aren't part of the solution
        axialSplinePoints[n_points - 2] = rhs_primes[mat_dim - 1];
        for (long i = mat_dim - 2; i >= 0; --i) {
            axialSplinePoints[i + 1] = rhs_primes[i] - c_primes[i] * axialSplinePoints[i+2];
        }
        splinePoints.push_back(axialSplinePoints);
        // sanity check
        assert(axialSplinePoints.size() == axialPoints.size());
    }
    
    // Now that spline points are found, create actual path
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(points[0][0], points[1][0] * magnification)];
    const float twoThirds = 2.0 / 3.0;
    const float oneThird = 1.0 / 3.0;
    for (int i = 0; i < n_paths; ++i) {
        [path addCurveToPoint:CGPointMake(points[0][i+1], points[1][i+1])
                controlPoint1:CGPointMake(
                                          twoThirds*splinePoints[0][i] + oneThird*splinePoints[0][i+1],
                                          twoThirds*splinePoints[1][i] + oneThird*splinePoints[1][i+1])
                controlPoint2:CGPointMake(
                                          oneThird*splinePoints[0][i] + twoThirds*splinePoints[0][i+1],
                                          oneThird*splinePoints[1][i] + twoThirds*splinePoints[1][i+1])];
    }
    // Straight vertical line to make height
    [path addLineToPoint:CGPointMake(points[0][n_points - 1], points[1][n_points - 1] + height)];
    // Now create curves in reverse order to give thickness to path
    for (int i = n_paths - 1; i >= 0; --i) {
        [path addCurveToPoint:CGPointMake(points[0][i], points[1][i] + height)
                controlPoint1:CGPointMake(
                                          oneThird*splinePoints[0][i] + twoThirds*splinePoints[0][i+1],
                                          oneThird*splinePoints[1][i] + twoThirds*splinePoints[1][i+1] + height)
                controlPoint2:CGPointMake(
                                          twoThirds*splinePoints[0][i] + oneThird*splinePoints[0][i+1],
                                          twoThirds*splinePoints[1][i] + oneThird*splinePoints[1][i+1] + height)];
    }
    [path closePath];
    path.flatness = 0.1;
    return path;
}
