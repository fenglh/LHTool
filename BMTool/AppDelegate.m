//
//  AppDelegate.m
//  BMTool
//
//  Created by 冯立海 on 2020/4/15.
//  Copyright © 2020 LH. All rights reserved.
//

#import "AppDelegate.h"
#import "WAYWindow.h"

@interface AppDelegate ()
@property (unsafe_unretained) IBOutlet NSTextView *htmlTextView;
@property (unsafe_unretained) IBOutlet NSTextView *targetTextView;
@property (weak) IBOutlet NSWindow *imageWindow;


@property (weak) IBOutlet WAYWindow *window;

@property (nonatomic, strong) NSWindow *subWindow;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
        [NSApp activateIgnoringOtherApps:YES];
        [self.window makeKeyAndOrderFront:self];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {

    [NSApp activateIgnoringOtherApps:YES];
    [self.window makeKeyAndOrderFront:self];
    return YES;
}

- (IBAction)startClick:(NSButton *)btn {
    if (self.htmlTextView.string.length <=0) {
        return;
    }
    NSData *xmlData =  [self.htmlTextView.string dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSXMLDocument *document = [[NSXMLDocument alloc] initWithData:xmlData options:NSXMLNodePreserveWhitespace error:&error];
    if (error) {
        [self alertTitle:@"错误" msg:@"格式不正确"];
        return;
    }
    [self parseXMLElement:document.rootElement];
}
- (IBAction)helpClick:(NSButton *)btn {
    [self.imageWindow makeKeyAndOrderFront:self];
}

- (void)alertTitle:(NSString *)title msg:(NSString *)msg {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setIcon:[NSImage imageNamed:@"application"]];
    [alert setMessageText:title];
    [alert setInformativeText:msg];
    [alert addButtonWithTitle:@"确定"];
    [alert setAlertStyle:NSAlertStyleWarning];
    [alert runModal];
}

- (void)onStartClick:(NSButton *)btn {
    NSLog(@"开始");
}
- (void)parseXMLElement:(NSXMLElement *)element {
    if (!element) {
        return;
    }
    
    //生成.h和.m文件
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path  = [NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES) firstObject];
    path = [path stringByAppendingPathComponent:@"BMTool"];
    if(![fileManager fileExistsAtPath:path]){
         [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }else {
        [fileManager removeItemAtPath:path error:nil];
    }
    
    
    
    NSArray *elements = [element elementsForName:@"li"];
    NSMutableArray *aLabels = [NSMutableArray array];
    for (NSXMLElement *subElement in elements) {
        NSXMLElement *node  = [self findALabel:subElement];
        if (node) {
            [aLabels addObject:node];
        }
    }
    for (NSXMLElement *element in aLabels) {
        NSArray *divElements =  [element elementsForName:@"div"];
        NSString *name = nil;
        NSString *url=nil;
        NSString *remark=nil;
        for (NSXMLElement *divElement in divElements) {
            NSXMLNode * node = [divElement attributeForName:@"class"];
            if ([node.stringValue isEqualToString:@"name"]) {
                remark =  [divElement stringValue];
            }else if ([node.stringValue isEqualToString:@"url"]) {
                url =  [divElement stringValue];
                
                if (url.length <= 0 || [url isEqualToString:@"null"]) {
                    break;
                }
                
                NSString *lastComponent = [url lastPathComponent];
                name = [lastComponent stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[lastComponent substringToIndex:1] capitalizedString]];
            }
        }
        if (url.length > 0) {
            NSString *ApiPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", name]];
            if(![fileManager fileExistsAtPath:ApiPath]){
                 [fileManager createDirectoryAtPath:ApiPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            
            NSString *interfaceUrl = [NSString stringWithFormat:@"#define INTERFACE_%@\t\t\t@\"%@\"//%@\r\n",name,url,remark];
            self.targetTextView.string = [self.targetTextView.string stringByAppendingString:interfaceUrl];
            NSString *headFilePath = [NSString stringWithFormat:@"%@/BM%@APIManager.h",ApiPath,name];
            NSString *sourceFilePath = [NSString stringWithFormat:@"%@/BM%@APIManager.m",ApiPath,name];
            [fileManager createFileAtPath:headFilePath contents:[self headContent:name remark:remark] attributes:nil];
            [fileManager createFileAtPath:sourceFilePath contents:[self sourceContent:name remark:remark] attributes:nil];
        }


    }
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"file://%@",path]]];
    
}

- (NSData *)headContent:(NSString *)name remark:(NSString *)remark {
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *app_Name = [infoDictionary objectForKey:@"CFBundleName"];
    NSString *createBy = [NSString stringWithFormat:@"%@-%@",app_Name, app_Version];
    
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd"];
    NSString *timeStr = [dateFormatter stringFromDate:date];
    NSString *Copyright = @"Copyright © 2020 月亮小屋（中国）有限公司";
    NSString *content = [NSString stringWithFormat:@"//\r\n//  BM%@APIManager.h\r\n//\r\n//  Created by %@ on %@.\r\n//  %@. All rights reserved.\r\n//\r\n\r\n#import \"BMBaseAPIManager.h\"\r\n\r\nNS_ASSUME_NONNULL_BEGIN\r\n\r\n//%@\r\n@interface  BM%@APIManager : BMBaseAPIManager\r\n\r\n@end\r\n\r\nNS_ASSUME_NONNULL_END\r\n",name, createBy,timeStr, Copyright,remark,name];
    return [content dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData *)sourceContent:(NSString *)name remark:(NSString *)remark{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *app_Name = [infoDictionary objectForKey:@"CFBundleName"];
    NSString *createBy = [NSString stringWithFormat:@"%@-%@",app_Name, app_Version];
    
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd"];
    NSString *timeStr = [dateFormatter stringFromDate:date];
    
    NSString *Copyright = @"Copyright © 2020 月亮小屋（中国）有限公司";
    NSString *content = [NSString stringWithFormat:@"//\r\n//  BM%@APIManager.h\r\n//\r\n//  Created by %@ on %@.\r\n//  %@. All rights reserved.\r\n//\r\n\r\n#import \"BM%@APIManager.h\"\r\n\r\n@implementation BM%@APIManager\r\n- (NSString *)interfaceUrl {\r\n\treturn INTERFACE_%@;\r\n}\r\n@end\r\n\r\n",name, createBy,timeStr, Copyright, name,name,name];
    return [content dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSXMLElement * )findALabel:(NSXMLElement *)element {
    if ([element.name isEqualToString:@"a"]) {
        return element;
    }
    
    for (NSXMLElement *subElement in element.children) {
        return [self findALabel:subElement];
    }
    return nil;
}

@end
