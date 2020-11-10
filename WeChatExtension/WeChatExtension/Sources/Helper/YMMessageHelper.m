//
//  YMMessageHelper.m
//  WeChatExtension
//
//  Created by MustangYM on 2019/1/22.
//  Copyright © 2019 MustangYM. All rights reserved.
//

#import "YMMessageHelper.h"
#import <objc/runtime.h>
#import "XMLReader.h"

@implementation YMMessageHelper
+ (MessageData *)getMessageData:(AddMsg *)addMsg
{
    if (!addMsg) {
        return nil;
    }
    MessageService *msgService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
    return [msgService GetMsgData:addMsg.fromUserName.string svrId:addMsg.newMsgId];
}

+ (WCContactData *)getContactData:(AddMsg *)addMsg
{
    if (!addMsg) {
        return nil;
    }
    MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
    
    if (LargerOrEqualVersion(@"2.3.26")) {
        return [sessionMgr getSessionContact:addMsg.fromUserName.string];
    }

    return [sessionMgr getContact:addMsg.fromUserName.string];
}

+ (void)parseMiniProgramMsg:(AddMsg *)addMsg
{
    // 显示49信息
    if (addMsg.msgType == 49) {
        //      xml 转 dict
        NSString *msgContentStr = nil;
        if ([addMsg.fromUserName.string containsString:@"@chatroom"]) {
            NSArray *msgAry = [addMsg.content.string componentsSeparatedByString:@":\n<?xml"];
            if (msgAry.count > 1) {
                msgContentStr = [NSString stringWithFormat:@"<?xml %@",msgAry[1]];
            } else {//对付<msg>开头的数据
                msgAry = [addMsg.content.string componentsSeparatedByString:@":\n<msg"];
                if (msgAry.count > 1) {
                    msgContentStr = [NSString stringWithFormat:@"<msg%@",msgAry[1]];
                }
            }
        } else {
            msgContentStr = addMsg.content.string;
        }
        NSError *error;
        NSDictionary *xmlDict = [XMLReader dictionaryForXMLString:msgContentStr error:&error];
        NSDictionary *msgDict = [xmlDict valueForKey:@"msg"];
        NSDictionary *appMsgDict = [msgDict valueForKey:@"appmsg"];
        NSDictionary *typeDict = [appMsgDict valueForKey:@"type"];
        NSString *type = [typeDict valueForKey:@"text"];
        
        NSString *session = addMsg.fromUserName.string;
        
        if(type.intValue == 51){// 显示视频号
            NSString *nickname = @"";
            NSString *desc = @"";
            
            NSDictionary *finderFeed = [appMsgDict valueForKey:@"finderFeed"];
            
            NSDictionary *nicknameDict = [finderFeed valueForKey:@"nickname"];
            nickname = [nicknameDict valueForKey:@"text"];
            
            NSDictionary *descDict = [finderFeed valueForKey:@"desc"];
            desc = [descDict valueForKey:@"text"];
            
            NSString *newMsgContent = @"";
            
            newMsgContent = [NSString stringWithFormat:@"收到视频号消息\n%@：%@\n",
                           nickname,
                           desc];
            
            
            
            MessageData *newMsgData = ({
                      MessageData *msg = [[objc_getClass("MessageData") alloc] initWithMsgType:0x2710];
                      [msg setFromUsrName:session];
                      [msg setToUsrName:session];
                      [msg setMsgStatus:4];
                      [msg setMsgContent:newMsgContent];
                      [msg setMsgCreateTime:[[NSDate date] timeIntervalSince1970]];
                      msg;
                  });
                  
            MessageService *msgService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
            [msgService AddLocalMsg:session msgData:newMsgData];
            
        }
        
        if (type.intValue == 33 || type.intValue == 36) {// 显示小程序信息
            NSDictionary *weappInfoDict = [appMsgDict valueForKey:@"weappinfo"];
            NSString *title = @"";
            NSString *url = @"";
            NSString *appid = @"";
            NSString *pagepath = @"";
            NSString *sourcedisplayname = @"";
            NSDictionary *titleDict = [appMsgDict valueForKey:@"title"];
            title = [titleDict valueForKey:@"text"];
            
            NSDictionary *urlDict = [appMsgDict valueForKey:@"url"];
            url = [urlDict valueForKey:@"text"];
            
            NSDictionary *appidDict = [weappInfoDict valueForKey:@"appid"];
            appid = [appidDict valueForKey:@"text"];
            
            NSDictionary *pagepathDict = [weappInfoDict valueForKey:@"pagepath"];
            pagepath = [pagepathDict valueForKey:@"text"];
            
            
            NSDictionary *sourcedisplaynameDict = [appMsgDict valueForKey:@"sourcedisplayname"];
            sourcedisplayname = [sourcedisplaynameDict valueForKey:@"text"];
            
            MessageService *msgService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
            
            NSString *newMsgContent = @"";
            if(type.intValue == 36){//36为app分享小程序
                NSDictionary *urlDict = [appMsgDict valueForKey:@"url"];
                NSString *url = [urlDict valueForKey:@"text"];
                
                newMsgContent = [NSString stringWithFormat:@"%@ \n%@%@(%@) \n%@%@ \n%@%@ \n%@%@ \n",
                                 YMLocalizedString(@"assistant.msgInfo.miniprogram"),
                                 YMLocalizedString(@"assistant.msgInfo.miniprogram.name"),
                                 sourcedisplayname,
                                 appid,
                                 YMLocalizedString(@"assistant.msgInfo.miniprogram.title"),
                                 title,
                                 YMLocalizedString(@"assistant.msgInfo.miniprogram.path"),
                                 pagepath,
                                 YMLocalizedString(@"assistant.msgInfo.miniprogram.url"),
                                 url
                                 ];
            }else{
                newMsgContent = [NSString stringWithFormat:@"%@ \n%@%@(%@) \n%@%@ \n%@%@ \n",
                                 YMLocalizedString(@"assistant.msgInfo.miniprogram"),
                                 YMLocalizedString(@"assistant.msgInfo.miniprogram.name"),
                                 sourcedisplayname,
                                 appid,
                                 YMLocalizedString(@"assistant.msgInfo.miniprogram.title"),
                                 title,
                                 YMLocalizedString(@"assistant.msgInfo.miniprogram.path"),
                                 pagepath
                                 ];
            }
            
            MessageData *newMsgData = ({
                MessageData *msg = [[objc_getClass("MessageData") alloc] initWithMsgType:0x2710];
                [msg setFromUsrName:session];
                [msg setToUsrName:session];
                [msg setMsgStatus:4];
                [msg setMsgContent:newMsgContent];
                [msg setMsgCreateTime:[[NSDate date] timeIntervalSince1970]];
                msg;
            });
            
            [msgService AddLocalMsg:session msgData:newMsgData];
                   
        } else if (type.intValue == 2001) {// 显示红包信息
            NSDictionary *wcpayInfoDict = [appMsgDict valueForKey:@"wcpayinfo"];
            NSString *title = @"";
            NSDictionary *titleDict = [wcpayInfoDict valueForKey:@"sendertitle"];
            title = [titleDict valueForKey:@"text"];
            
            
            //红包提醒 start
            MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
            WCContactData *msgContact = nil;
            if (LargerOrEqualVersion(@"2.3.26")) {
                msgContact = [sessionMgr getSessionContact:session];
            } else {
                msgContact = [sessionMgr getContact:session];
            }
            
            NSUserNotification *localNotify = [[NSUserNotification alloc] init];
            
            localNotify.title = @"红包提醒";//标题
            localNotify.subtitle = msgContact.m_nsNickName;//副标题
            
            localNotify.contentImage = [NSImage imageNamed: @"swift"];//显示在弹窗右边的提示。
            
            localNotify.informativeText = addMsg.pushContent;
            localNotify.soundName = NSUserNotificationDefaultSoundName;
            
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:localNotify];

            //红包提醒end
            
            MessageService *msgService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
            NSString *newMsgContent = [NSString stringWithFormat:@"%@ \n%@%@ \n",
                                       YMLocalizedString(@"assistant.msgInfo.wcpay.redPacket"),
                                       YMLocalizedString(@"assistant.msgInfo.wcpay.redPacket.title"),
                                       title
                                       ];
            MessageData *newMsgData = ({
                MessageData *msg = [[objc_getClass("MessageData") alloc] initWithMsgType:0x2710];
                [msg setFromUsrName:session];
                [msg setToUsrName:session];
                [msg setMsgStatus:4];
                [msg setMsgContent:newMsgContent];
                [msg setMsgCreateTime:[[NSDate date] timeIntervalSince1970]];
                msg;
            });
            
            [msgService AddLocalMsg:session msgData:newMsgData];
            
        }else if (type.intValue == 2000) {// 显示转账信息
            NSDictionary *wcpayInfoDict = [appMsgDict valueForKey:@"wcpayinfo"];
            NSString *feedesc = @"";
            NSString *payMemo = @"";
            NSDictionary *feedescDict = [wcpayInfoDict valueForKey:@"feedesc"];
            feedesc = [feedescDict valueForKey:@"text"];
            
            NSDictionary *payMemoDict = [wcpayInfoDict valueForKey:@"pay_memo"];
            payMemo = [payMemoDict valueForKey:@"text"];
            
            MessageService *msgService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
            NSString *newMsgContent = [NSString stringWithFormat:@"%@ \n%@【%@】%@ \n",
                                       YMLocalizedString(@"assistant.msgInfo.wcpay.transfer"),
                                       YMLocalizedString(@"assistant.msgInfo.wcpay.transfer.desc"),
                                       feedesc,
                                       payMemo
                                       ];
            MessageData *newMsgData = ({
                MessageData *msg = [[objc_getClass("MessageData") alloc] initWithMsgType:0x2710];
                [msg setFromUsrName:session];
                [msg setToUsrName:session];
                [msg setMsgStatus:4];
                [msg setMsgContent:newMsgContent];
                [msg setMsgCreateTime:[[NSDate date] timeIntervalSince1970]];
                msg;
            });
            
            [msgService AddLocalMsg:session msgData:newMsgData];
        }
    }
}

+ (void)addLocalWarningMsg:(NSString *)msg fromUsr:(NSString *)fromUsr
{
    if (!msg || !fromUsr) {
        return;
    }
    MessageService *msgService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
    NSString *newMsgContent = msg;
    MessageData *newMsgData = ({
        MessageData *msg = [[objc_getClass("MessageData") alloc] initWithMsgType:0x2710];
        [msg setFromUsrName:fromUsr];
        [msg setToUsrName:fromUsr];
        [msg setMsgStatus:4];
        [msg setMsgContent:newMsgContent];
        [msg setMsgCreateTime:[[NSDate date] timeIntervalSince1970]];
        msg;
    });
    
    [msgService AddLocalMsg:fromUsr msgData:newMsgData];
    
}
@end
