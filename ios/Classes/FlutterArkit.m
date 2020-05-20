#import "FlutterArkit.h"
#import "Color.h"
#import "GeometryBuilder.h"
#import "SceneViewDelegate.h"
#import "CodableUtils.h"
#import "DecodableUtils.h"

@interface FlutterArkitFactory()
@property NSObject<FlutterBinaryMessenger>* messenger;
@end

@implementation FlutterArkitFactory

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
  self = [super init];
  if (self) {
    self.messenger = messenger;
  }
  return self;
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec {
  return [FlutterStandardMessageCodec sharedInstance];
}

- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
  FlutterArkitController* arkitController =
      [[FlutterArkitController alloc] initWithWithFrame:frame
                                         viewIdentifier:viewId
                                              arguments:args
                                        binaryMessenger:self.messenger];
  return arkitController;
}

@end

@interface FlutterArkitController()
@property ARPlaneDetection planeDetection;
@property int64_t viewId;
@property FlutterMethodChannel* channel;
@property (strong) SceneViewDelegate* delegate;
@property (readwrite) ARConfiguration *configuration;
@property BOOL forceUserTapOnCenter;
@property (nonatomic, strong) ARHitTestResult *initialHitTestResult;
//@property (nonatomic, strong) SCNNode *movedObject;
@end

@implementation FlutterArkitController

- (instancetype)initWithWithFrame:(CGRect)frame
                   viewIdentifier:(int64_t)viewId
                        arguments:(id _Nullable)args
                  binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
  if ([super init]) {
    _viewId = viewId;
    _sceneView = [[ARSCNView alloc] initWithFrame:frame];
    NSString* channelName = [NSString stringWithFormat:@"arkit_%lld", viewId];
    _channel = [FlutterMethodChannel methodChannelWithName:channelName binaryMessenger:messenger];
    __weak __typeof__(self) weakSelf = self;
    [_channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
      [weakSelf onMethodCall:call result:result];
    }];
    self.delegate = [[SceneViewDelegate alloc] initWithChannel: _channel];
    _sceneView.delegate = self.delegate;
  }
  return self;
}

- (UIView*)view {
  return _sceneView;
}

- (void)onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([[call method] isEqualToString:@"init"]) {
    [self init:call result:result];
  } else if ([[call method] isEqualToString:@"addARKitNode"]) {
      [self onAddNode:call result:result];
  } else if ([[call method] isEqualToString:@"removeARKitNode"]) {
      [self onRemoveNode:call result:result];
  } else if ([[call method] isEqualToString:@"getNodeBoundingBox"]) {
      [self onGetNodeBoundingBox:call result:result];
  } else if ([[call method] isEqualToString:@"positionChanged"]) {
      [self updatePosition:call andResult:result];
  } else if ([[call method] isEqualToString:@"rotationChanged"]) {
      [self updateRotation:call andResult:result];
  } else if ([[call method] isEqualToString:@"eulerAnglesChanged"]) {
      [self updateEulerAngles:call andResult:result];
  } else if ([[call method] isEqualToString:@"scaleChanged"]) {
      [self updateScale:call andResult:result];
  } else if ([[call method] isEqualToString:@"updateSingleProperty"]) {
      [self updateSingleProperty:call andResult:result];
  } else if ([[call method] isEqualToString:@"updateMaterials"]) {
      [self updateMaterials:call andResult:result];
  } else if ([[call method] isEqualToString:@"getLightEstimate"]) {
      [self onGetLightEstimate:call andResult:result];
  } else if ([[call method] isEqualToString:@"projectPoint"]) {
      [self onProjectPoint:call andResult:result];
  } else if ([[call method] isEqualToString:@"unprojectPoint"]) {
      [self onUnprojectPoint:call andResult:result];
  } else if ([[call method] isEqualToString:@"cameraProjectionMatrix"]) {
      [self onCameraProjectionMatrix:call andResult:result];
  } else if ([[call method] isEqualToString:@"screenToWorld"]) {
      [self onScreenToWorld:call andResult:result];
  } else if ([[call method] isEqualToString:@"playAnimation"]) {
      [self onPlayAnimation:call andResult:result];
  } else if ([[call method] isEqualToString:@"stopAnimation"]) {
      [self onStopAnimation:call andResult:result];
  } else if ([[call method] isEqualToString:@"dispose"]) {
      [self.sceneView.session pause];
  } else if([[call method] isEqualToString:@"runConfig"]){
      [self runConfig:call andResult:result];
  } else if([[call method] isEqualToString:@"pauseSession"]){
      [self pauseSession:call andResult:result];
  } else if([[call method] isEqualToString:@"snapshot"]){
      [self saveImage:call andResult:result];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

-(void)saveImage:(FlutterMethodCall*)call andResult:(FlutterResult)result{
    NSLog(@"save image");
    UIImage* image = [_sceneView snapshot];
    if(image != nil){
        UIImageWriteToSavedPhotosAlbum(image,nil,nil,nil);
        result(@(0));
    }else {
        result(@(-1));
    }
}

-(void)pauseSession:(FlutterMethodCall*)call andResult:(FlutterResult)result{
    NSLog(@"pause session");
    [_sceneView.session pause];
    result(nil);
}

- (void)runConfig:(FlutterMethodCall*)call andResult:(FlutterResult)result{
    NSDictionary * params = call.arguments;
    if(params == nil){
        result(nil);
        return;
    }
    if(params[@"autoenablesDefaultLighting"] != nil){
        NSNumber* autoenablesDefaultLighting = params[@"autoenablesDefaultLighting"];
        self.sceneView.autoenablesDefaultLighting = [autoenablesDefaultLighting boolValue];
    }
    if(params[@"planeDetection"]!= nil){
        NSNumber* requestedPlaneDetection = params[@"planeDetection"];
        self.planeDetection = [self getPlaneFromNumber:[requestedPlaneDetection intValue]];
    }
    _configuration = [self buildConfiguration: call.arguments];

    if(params[@"runOptions"] != nil){
        NSNumber* runOptions = params[@"runOptions"];
        [self.sceneView.session runWithConfiguration:_configuration options:[self getOptionsFromNumber:[runOptions intValue]]];
    } else  {
        [self.sceneView.session runWithConfiguration:_configuration];
    }
    

    result(nil);
}

- (void)init:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSNumber* showStatistics = call.arguments[@"showStatistics"];
    self.sceneView.showsStatistics = [showStatistics boolValue];
  
    NSNumber* autoenablesDefaultLighting = call.arguments[@"autoenablesDefaultLighting"];
    self.sceneView.autoenablesDefaultLighting = [autoenablesDefaultLighting boolValue];
    
    NSNumber* forceUserTapOnCenter = call.arguments[@"forceUserTapOnCenter"];
    self.forceUserTapOnCenter = [forceUserTapOnCenter boolValue];
  
    NSNumber* requestedPlaneDetection = call.arguments[@"planeDetection"];
    self.planeDetection = [self getPlaneFromNumber:[requestedPlaneDetection intValue]];
    
    if ([call.arguments[@"enableTapRecognizer"] boolValue]) {
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
        [self.sceneView addGestureRecognizer:tapGestureRecognizer];
    }
    
    if ([call.arguments[@"enablePinchRecognizer"] boolValue]) {
        UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchFrom:)];
        [self.sceneView addGestureRecognizer:pinchGestureRecognizer];
    }
    
    if ([call.arguments[@"enablePanRecognizer"] boolValue]) {
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
        [self.sceneView addGestureRecognizer:panGestureRecognizer];
    }
    
    if ([call.arguments[@"enableRotationRecognizer"] boolValue]) {
        UIRotationGestureRecognizer *rotationGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotationFrom:)];
        [self.sceneView addGestureRecognizer:rotationGestureRecognizer];
    }
    
    self.sceneView.debugOptions = [self getDebugOptions:call.arguments];
    
    _configuration = [self buildConfiguration: call.arguments];

    [self.sceneView.session runWithConfiguration:[self configuration]];
    result(nil);
}

- (ARConfiguration*) buildConfiguration: (NSDictionary*)params {
    int configurationType = [params[@"configuration"] intValue];
    ARConfiguration* _configuration;
    
//    if (configurationType == 0) {
        if (ARWorldTrackingConfiguration.isSupported) {
            ARWorldTrackingConfiguration* worldTrackingConfiguration = [ARWorldTrackingConfiguration new];
            worldTrackingConfiguration.planeDetection = self.planeDetection;
            NSString* detectionImages = params[@"detectionImagesGroupName"];
            if ([detectionImages isKindOfClass:[NSString class]]) {
                worldTrackingConfiguration.detectionImages = [ARReferenceImage referenceImagesInGroupNamed:detectionImages bundle:nil];
            }
            _configuration = worldTrackingConfiguration;
        }
    NSNumber* worldAlignment = params[@"worldAlignment"];
    _configuration.worldAlignment = [self getWorldAlignmentFromNumber:[worldAlignment intValue]];
    return _configuration;
}

- (void)onAddNode:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSDictionary* geometryArguments = call.arguments[@"geometry"];
    SCNGeometry* geometry = [GeometryBuilder createGeometry:geometryArguments withDevice: _sceneView.device];
    [self addNodeToSceneWithGeometry:geometry andCall:call andResult:result];
}

- (void)onRemoveNode:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString* nodeName = call.arguments[@"nodeName"];
    SCNNode* node = [self.sceneView.scene.rootNode childNodeWithName:nodeName recursively:YES];
    [node removeFromParentNode];
    result(nil);
}

- (void)onGetNodeBoundingBox:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSDictionary* geometryArguments = call.arguments[@"geometry"];
    SCNGeometry* geometry = [GeometryBuilder createGeometry:geometryArguments withDevice: _sceneView.device];
    SCNNode* node = [self getNodeWithGeometry:geometry fromDict:call.arguments];
    SCNVector3 minVector, maxVector;
    [node getBoundingBoxMin:&minVector max:&maxVector];
    
    result(@[[CodableUtils convertSimdFloat3ToString:SCNVector3ToFloat3(minVector)],
             [CodableUtils convertSimdFloat3ToString:SCNVector3ToFloat3(maxVector)]]
           );
}

#pragma mark - Lazy loads

-(ARConfiguration *)configuration {
    return _configuration;
}

#pragma mark - Scene tap event
- (void) handleTapFrom: (UITapGestureRecognizer *)recognizer
{
    if (![recognizer.view isKindOfClass:[ARSCNView class]])
        return;
    
    ARSCNView* sceneView = (ARSCNView *)recognizer.view;
    CGPoint touchLocation = self.forceUserTapOnCenter
        ? self.sceneView.center
        : [recognizer locationInView:sceneView];
    NSLog(@"touch location: %@", NSStringFromCGPoint(touchLocation));
    NSArray<SCNHitTestResult *> * hitResults = [sceneView hitTest:touchLocation options:@{}];
    if ([hitResults count] != 0) {
        SCNNode *node = hitResults[0].node;
        if(node == nil || [node.name isEqualToString:@"floor"]){
            //过滤掉floor
            if([hitResults count] > 1){
                node = hitResults[1].node;
            } else {
                node = nil;
            }
        }
        if(node != nil){
            NSString* parentName = @"";
            if(node.parentNode != nil && node.parentNode.name != nil){
                parentName = [NSString stringWithString:node.parentNode.name];
            }
            NSLog(@"on NodeTap %@, parent: %@",node.name, parentName);
            [_channel invokeMethod: @"onNodeTap" arguments: @{@"name" : node.name, @"parentName": parentName}];
            NSLog(@"onNodeTap finished");
        }
    }

    NSArray<ARHitTestResult *> *arHitResults = [sceneView hitTest:touchLocation types:ARHitTestResultTypeFeaturePoint
                                                + ARHitTestResultTypeEstimatedHorizontalPlane
                                                + ARHitTestResultTypeEstimatedVerticalPlane
                                                + ARHitTestResultTypeExistingPlane
                                                + ARHitTestResultTypeExistingPlaneUsingExtent
                                                + ARHitTestResultTypeExistingPlaneUsingGeometry
                                                ];
    if ([arHitResults count] != 0) {
        NSMutableArray<NSDictionary*>* results = [NSMutableArray arrayWithCapacity:[arHitResults count]];
        for (ARHitTestResult* r in arHitResults) {
            [results addObject:[self getDictFromHitResult:r]];
        }
        NSLog(@"onARTap start");
        [_channel invokeMethod: @"onARTap" arguments: results];
        NSLog(@"onARTap finished");
    }
}

- (void) handlePinchFrom: (UIPinchGestureRecognizer *) recognizer
{
    if (![recognizer.view isKindOfClass:[ARSCNView class]])
        return;
    
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        ARSCNView* sceneView = (ARSCNView *)recognizer.view;
        CGPoint touchLocation = [recognizer locationInView:sceneView];
        
//        NSArray<SCNHitTestResult *> * hitResults = [sceneView hitTest:touchLocation options:@{}];        
        NSArray<NSDictionary*>* r = @[@{@"name": @"", @"scale":@(recognizer.scale)}];
//        NSMutableArray<NSDictionary*>* results = [NSMutableArray arrayWithCapacity:[hitResults count]];
//        for (SCNHitTestResult* r in hitResults) {
//            if (r.node.name != nil) {
//                NSString* parentName = @"";
//                if(r.node.parentNode != nil && r.node.parentNode.name != nil){
//                    parentName = [NSString stringWithString:r.node.parentNode.name];
//                }
//                [results addObject:@{@"name" : r.node.name,@"scale" : @(recognizer.scale), @"parentName" : parentName }];
//            }
//        }
//        if ([results count] != 0) {
//            [_channel invokeMethod: @"onNodePinch" arguments: results];
//        }
        [_channel invokeMethod:@"onNodePinch" arguments:r];
        recognizer.scale = 1;
    }
}
- (void) handleRotationFrom: (UIRotationGestureRecognizer *) recognizer
{
    if (![recognizer.view isKindOfClass:[ARSCNView class]])
        return;
    
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        ARSCNView* sceneView = (ARSCNView *)recognizer.view;
        CGPoint touchLocation = [recognizer locationInView:sceneView];
        
        NSArray<NSDictionary*>* r = @[@{@"name": @"",
        @"velocity":@(recognizer.velocity),
        @"rotation":@(recognizer.rotation)}];
        [_channel invokeMethod:@"onNodeRotation" arguments:r];
        recognizer.rotation = 0;
    }
}

- (void) handlePanFrom: (UIPanGestureRecognizer *) recognizer
{
    if (![recognizer.view isKindOfClass:[ARSCNView class]])
        return;
    if(recognizer.state == UIGestureRecognizerStateBegan){
        ARSCNView* sceneView = (ARSCNView *)recognizer.view;
        CGPoint tapPoint = [recognizer locationInView:sceneView];
        NSArray<ARHitTestResult*>* arTestResults = [sceneView hitTest:tapPoint types:ARHitTestResultTypeFeaturePoint];
        if([arTestResults count] == 0){
            return;
        }
        self.initialHitTestResult = [arTestResults firstObject];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        ARSCNView* sceneView = (ARSCNView *)recognizer.view;
        CGPoint tapPoint = [recognizer locationInView:sceneView];
        NSArray<ARHitTestResult *> * arHitResults = [sceneView hitTest:tapPoint types:ARHitTestResultTypeFeaturePoint];
        
        if(arHitResults.count == 0){
            return;
        }
        if(_initialHitTestResult == nil){
            _initialHitTestResult = [arHitResults firstObject];
        }
        ARHitTestResult* result = [arHitResults firstObject];
        SCNMatrix4 initialMatrix = SCNMatrix4FromMat4(self.initialHitTestResult.worldTransform);
        SCNVector3 initialVector = SCNVector3Make(initialMatrix.m41, initialMatrix.m42, initialMatrix.m43);
        
        SCNMatrix4 matrix = SCNMatrix4FromMat4(result.worldTransform);
        SCNVector3 vector = SCNVector3Make(matrix.m41, matrix.m42, matrix.m43);
        
        CGFloat dx= vector.x - initialVector.x;
        CGFloat dz= vector.z - initialVector.z;
        
        NSMutableArray<NSDictionary*>* results = [NSMutableArray arrayWithCapacity:1];
        [results addObject:@{@"name": @"", @"x" : @(dx), @"y":@(dz)}];
        [_channel invokeMethod:@"onNodePan" arguments:results];
        self.initialHitTestResult = result;
    } else if(recognizer.state == UIGestureRecognizerStateEnded){
        self.initialHitTestResult = nil;
    }
}

#pragma mark - Parameters
- (void) updatePosition:(FlutterMethodCall*)call andResult:(FlutterResult)result{
    NSString* name = call.arguments[@"name"];
    SCNNode* node = [self.sceneView.scene.rootNode childNodeWithName:name recursively:YES];
    node.position = [DecodableUtils parseVector3:call.arguments];
    result(nil);
}

- (void) updateRotation:(FlutterMethodCall*)call andResult:(FlutterResult)result{
    NSString* name = call.arguments[@"name"];
    SCNNode* node = [self.sceneView.scene.rootNode childNodeWithName:name recursively:YES];
    node.rotation = [DecodableUtils parseVector4:call.arguments];
    result(nil);
}

- (void) updateEulerAngles:(FlutterMethodCall*)call andResult:(FlutterResult)result{
    NSString* name = call.arguments[@"name"];
    SCNNode* node = [self.sceneView.scene.rootNode childNodeWithName:name recursively:YES];
    node.eulerAngles = [DecodableUtils parseVector3:call.arguments];
    result(nil);
}

- (void) updateScale:(FlutterMethodCall*)call andResult:(FlutterResult)result{
    NSString* name = call.arguments[@"name"];
    SCNNode* node = [self.sceneView.scene.rootNode childNodeWithName:name recursively:YES];
    node.scale = [DecodableUtils parseVector3:call.arguments];
    result(nil);
}

- (void) updateSingleProperty:(FlutterMethodCall*)call andResult:(FlutterResult)result{
    NSString* name = call.arguments[@"name"];
    SCNNode* node = [self.sceneView.scene.rootNode childNodeWithName:name recursively:YES];
    
    NSString* keyProperty = call.arguments[@"keyProperty"];
    id object = [node valueForKey:keyProperty];
    
    [object setValue:call.arguments[@"propertyValue"] forKey:call.arguments[@"propertyName"]];
    result(nil);
}

- (void) updateMaterials:(FlutterMethodCall*)call andResult:(FlutterResult)result{
    NSString* name = call.arguments[@"name"];
    SCNNode* node = [self.sceneView.scene.rootNode childNodeWithName:name recursively:YES];
    SCNGeometry* geometry = [GeometryBuilder createGeometry:call.arguments withDevice: _sceneView.device];
    node.geometry = geometry;
    result(nil);
}

- (void) onGetLightEstimate:(FlutterMethodCall*)call andResult:(FlutterResult)result{
    ARFrame* frame = self.sceneView.session.currentFrame;
    if (frame != nil && frame.lightEstimate != nil) {
        NSDictionary* res = @{
                              @"ambientIntensity": @(frame.lightEstimate.ambientIntensity),
                              @"ambientColorTemperature": @(frame.lightEstimate.ambientColorTemperature)
                              };
        result(res);
    }
    result(nil);
}

- (void) onProjectPoint:(FlutterMethodCall*)call andResult:(FlutterResult)result{
    SCNVector3 point =  [DecodableUtils parseVector3:call.arguments[@"point"]];
    SCNVector3 projectedPoint = [_sceneView projectPoint:point];
    NSString* coded = [CodableUtils convertSimdFloat3ToString:SCNVector3ToFloat3(projectedPoint)];
    result(coded);
}

- (void) onUnprojectPoint:(FlutterMethodCall*)call andResult:(FlutterResult)result{
    SCNVector3 point =  [DecodableUtils parseVector3:call.arguments[@"point"]];
    SCNVector3 unprojectPoint = [_sceneView unprojectPoint:point];
    NSString* coded = [CodableUtils convertSimdFloat3ToString:SCNVector3ToFloat3(unprojectPoint)];
    result(coded);
}

- (void) onScreenToWorld:(FlutterMethodCall*)call andResult:(FlutterResult)result{
    CGPoint point = [DecodableUtils parseCGPoint: call.arguments[@"point"]];
    // ARHitTestResultType.existingPlaneUsingExtent
    NSArray<ARHitTestResult *> * results = [_sceneView hitTest:point types: ARHitTestResultTypeExistingPlaneUsingExtent];
    if([results count] == 0){
        result(nil);
        return;
    }
    ARHitTestResult* hitResult = [results firstObject];
    NSString* coded = [CodableUtils convertSimdFloat4x4ToString:hitResult.worldTransform];
    result(coded);
}

- (void) onCameraProjectionMatrix:(FlutterMethodCall*)call andResult:(FlutterResult)result{
    NSString* coded = [CodableUtils convertSimdFloat4x4ToString:_sceneView.session.currentFrame.camera.projectionMatrix];
    result(coded);
}

- (void) onPlayAnimation:(FlutterMethodCall*)call andResult:(FlutterResult)result{
    NSString* key = call.arguments[@"key"];
    NSString* sceneName = call.arguments[@"sceneName"];
    NSString* animationIdentifier = call.arguments[@"animationIdentifier"];
    
    NSURL* sceneURL = [NSBundle.mainBundle URLForResource:sceneName withExtension:@"dae"];
    SCNSceneSource* sceneSource = [SCNSceneSource sceneSourceWithURL:sceneURL options:nil];
    
    CAAnimation* animationObject = [sceneSource entryWithIdentifier:animationIdentifier withClass:[CAAnimation self]];
    animationObject.repeatCount = 1;
    animationObject.fadeInDuration = 1;
    animationObject.fadeOutDuration = 0.5;
    [_sceneView.scene.rootNode addAnimation:animationObject forKey:key];
    
    result(nil);
}

- (void) onStopAnimation:(FlutterMethodCall*)call andResult:(FlutterResult)result{
    NSString* key = call.arguments[@"key"];
    [_sceneView.scene.rootNode removeAnimationForKey:key blendOutDuration:0.5];
    result(nil);
}

#pragma mark - Utils
-(ARPlaneDetection) getPlaneFromNumber: (int) number {
  if (number == 0) {
    return ARPlaneDetectionNone;
  } else if (number == 1) {
    return ARPlaneDetectionHorizontal;
  }
  return ARPlaneDetectionVertical;
}

-(ARSessionRunOptions) getOptionsFromNumber:(int)number {
    if(number == 0){
        return ARSessionRunOptionResetTracking;
    }else if(number == 1){
        return ARSessionRunOptionRemoveExistingAnchors;
    }else if(number == 2){
        return ARSessionRunOptionStopTrackedRaycasts;
    }
    return ARSessionRunOptionResetTracking;
}

-(ARWorldAlignment) getWorldAlignmentFromNumber: (int) number {
    if (number == 0) {
        return ARWorldAlignmentGravity;
    } else if (number == 1) {
        return ARWorldAlignmentGravityAndHeading;
    }
    return ARWorldAlignmentCamera;
}

- (SCNNode *) getNodeWithGeometry:(SCNGeometry *)geometry fromDict:(NSDictionary *)dict {
    SCNNode* node;
    if ([dict[@"dartType"] isEqualToString:@"ARKitNode"]) {
        node = [SCNNode nodeWithGeometry:geometry];
    } else if ([dict[@"dartType"] isEqualToString:@"ARKitReferenceNode"]) {
        NSString* url = dict[@"url"];
        NSURL* referenceURL = [[NSBundle mainBundle] URLForResource:url withExtension:nil];
        node = [SCNReferenceNode referenceNodeWithURL:referenceURL];
        [(SCNReferenceNode*)node load];
    } else {
        return nil;
    }
    node.position = [DecodableUtils parseVector3:dict[@"position"]];
    
    if (dict[@"scale"] != nil) {
        node.scale = [DecodableUtils parseVector3:dict[@"scale"]];
    }
    if (dict[@"rotation"] != nil) {
        node.rotation = [DecodableUtils parseVector4:dict[@"rotation"]];
    }
    if(dict[@"eulerAngles"] != nil){
        node.eulerAngles = [DecodableUtils parseVector3:dict[@"eulerAngles"]];
    }
    if (dict[@"name"] != nil) {
        node.name = dict[@"name"];
    }
    if (dict[@"physicsBody"] != nil) {
        NSDictionary *physics = dict[@"physicsBody"];
        node.physicsBody = [self getPhysicsBodyFromDict:physics];
    }
    if (dict[@"light"] != nil) {
        NSDictionary *light = dict[@"light"];
        node.light = [self getLightFromDict: light];
    }
    
    NSNumber* renderingOrder = dict[@"renderingOrder"];
    node.renderingOrder = [renderingOrder integerValue];
    
    return node;
}

- (SCNPhysicsBody *) getPhysicsBodyFromDict:(NSDictionary *)dict {
    NSNumber* type = dict[@"type"];
    
    SCNPhysicsShape* shape;
    if (dict[@"shape"] != nil) {
        NSDictionary* shapeDict = dict[@"shape"];
        if (shapeDict[@"geometry"] != nil) {
            shape = [SCNPhysicsShape shapeWithGeometry:[GeometryBuilder createGeometry:shapeDict[@"geometry"] withDevice:_sceneView.device] options:nil];
        }
    }
    
    SCNPhysicsBody* physicsBody = [SCNPhysicsBody bodyWithType:[type intValue] shape:shape];
    if (dict[@"categoryBitMask"] != nil) {
        NSNumber* mask = dict[@"categoryBitMask"];
        physicsBody.categoryBitMask = [mask unsignedIntegerValue];
    }
    
    return physicsBody;
}

- (SCNLight *) getLightFromDict:(NSDictionary *)dict {
    SCNLight* light = [SCNLight light];
    if (dict[@"type"] != nil) {
        SCNLightType lightType;
        int type = [dict[@"type"] intValue];
        switch (type) {
            case 0:
                lightType = SCNLightTypeAmbient;
                break;
            case 1:
                lightType = SCNLightTypeOmni;
                break;
            case 2:
                lightType =SCNLightTypeDirectional;
                break;
            case 3:
                lightType =SCNLightTypeSpot;
                break;
            case 4:
                lightType =SCNLightTypeIES;
                break;
            case 5:
                lightType =SCNLightTypeProbe;
                break;
            default:
                break;
        }
        light.type = lightType;
    }
    if (dict[@"temperature"] != nil) {
        NSNumber* temperature = dict[@"temperature"];
        light.temperature = [temperature floatValue];
    }
    if (dict[@"intensity"] != nil) {
        NSNumber* intensity = dict[@"intensity"];
        light.intensity = [intensity floatValue];
    }
    if (dict[@"spotInnerAngle"] != nil) {
        NSNumber* spotInnerAngle = dict[@"spotInnerAngle"];
        light.spotInnerAngle = [spotInnerAngle floatValue];
    }
    if (dict[@"spotOuterAngle"] != nil) {
        NSNumber* spotOuterAngle = dict[@"spotOuterAngle"];
        light.spotOuterAngle = [spotOuterAngle floatValue];
    }
    if (dict[@"color"] != nil) {
        NSNumber* color = dict[@"color"];
        light.color = [UIColor fromRGB: [color integerValue]];
    }
    if (dict[@"shadowMode"] != nil) {
        int mode = [dict[@"shadowMode"] intValue];
        SCNShadowMode shadowMode;
        switch (mode) {
            case 0:
                shadowMode = SCNShadowModeForward;
                break;
            case 1:
                shadowMode = SCNShadowModeDeferred;
                break;
            case 2:
                shadowMode = SCNShadowModeModulated;
                break;
            default:
                shadowMode = SCNShadowModeForward;
                break;
        }
        light.shadowMode = shadowMode;
    }
    if (dict[@"castsShadow"] != nil) {
        light.castsShadow = [dict[@"castsShadow"] boolValue];
    }
    if (dict[@"automaticallyAdjustsShadowProjection"] != nil) {
        light.automaticallyAdjustsShadowProjection = [dict[@"automaticallyAdjustsShadowProjection"] boolValue];
    }
    if (dict[@"shadowSampleCount"] != nil) {
        NSNumber* sampleCount = dict[@"shadowSampleCount"];
        light.shadowSampleCount = [sampleCount integerValue];
    }
    if (dict[@"shadowRadius"] != nil) {
        NSNumber* shadowRadius = dict[@"shadowRadius"];
        light.shadowRadius = [shadowRadius floatValue];
    }
    if (dict[@"shadowMapWidth"] != nil &&
        dict[@"shadowMapHeight"] != nil) {
        NSNumber* shadowMapWidth = dict[@"shadowMapWidth"];
        NSNumber* shadowMapHeight = dict[@"shadowMapHeight"];
        light.shadowMapSize = CGSizeMake([shadowMapWidth floatValue], [shadowMapHeight floatValue]);
    }
    if (dict[@"shadowColor"] != nil) {
        NSNumber* color = dict[@"shadowColor"];
        light.shadowColor = [UIColor fromRGB: [color integerValue]];
    }
    return light;
}

- (void) addNodeToSceneWithGeometry:(SCNGeometry*)geometry andCall: (FlutterMethodCall*)call andResult:(FlutterResult)result{
    NSLog(@"add node to scene %@", call.arguments);
    SCNNode* node = [self getNodeWithGeometry:geometry fromDict:call.arguments];
    if (call.arguments[@"parentNodeName"] != nil) {
        SCNNode *parentNode = [self.sceneView.scene.rootNode childNodeWithName:call.arguments[@"parentNodeName"] recursively:YES];
        [parentNode addChildNode:node];
    } else {
        [self.sceneView.scene.rootNode addChildNode:node];
    }
    result(nil);
}

- (SCNDebugOptions) getDebugOptions:(NSDictionary*)arguments{
    SCNDebugOptions debugOptions = SCNDebugOptionNone;
    if ([arguments[@"showFeaturePoints"] boolValue]) {
        debugOptions += ARSCNDebugOptionShowFeaturePoints;
    }
    if ([arguments[@"showWorldOrigin"] boolValue]) {
        debugOptions += ARSCNDebugOptionShowWorldOrigin;
    }
    return debugOptions;
}

- (NSDictionary*) getDictFromHitResult: (ARHitTestResult*) result {
    NSMutableDictionary* dict = [@{
             @"type": @(result.type),
             @"distance": @(result.distance),
             @"localTransform": [CodableUtils convertSimdFloat4x4ToString:result.localTransform],
             @"worldTransform": [CodableUtils convertSimdFloat4x4ToString:result.worldTransform]
             } mutableCopy];
    if (result.anchor != nil) {
        [dict setValue:[CodableUtils convertARAnchorToDictionary:result.anchor] forKey:@"anchor"];
    }
    return dict;
}

@end
