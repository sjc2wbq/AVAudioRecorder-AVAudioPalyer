//
//  GMRecoderTool.h
//  myLawyer
//
//  Created by Marx on 2016/10/10.
//  Copyright © 2016年 lawyer. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^AUDIOBLOCK)(CGFloat value);

@interface GMRecorderTool : NSObject

+ (GMRecorderTool *)shareInstance;

- (void)startRecord:(AUDIOBLOCK)block;
- (NSString *)stopRecord;//返回文件名

@end
