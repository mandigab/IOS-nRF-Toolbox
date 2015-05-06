/*
 * Copyright (c) 2015, Nordic Semiconductor
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this
 * software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "JsonParser.h"


@implementation JsonParser

-(InitData *)parseJson:(NSData *)data
{    
    if(data) {
        NSError *error;
        NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if (error) {
            NSLog(@"JSON parser failed %@",error);
            return nil;
        }
        if ([jsonDictionary isKindOfClass:[NSDictionary class]]) {
            NSLog(@"JSON has valid top level dictionary");
            NSString *manifestKey = @"manifest";
            id manifestValue = [jsonDictionary objectForKey:manifestKey];
            if ([manifestValue isEqual:[NSNull null]]) {
                NSLog(@"Manifest value is null");
                return nil;
            }
            self.packetData = [[InitData alloc]init];
            for (id key in manifestValue) {
                id value = [manifestValue objectForKey:key];
                if ([key isEqualToString:@"application"]) {
                    if (![value isEqual:[NSNull null]]) {
                        self.packetData.firmwareType = APPLICATION;
                        [self processManifest:value];
                    }
                }
                else if ([key isEqualToString:@"bootloader"])
                {
                    if (![value isEqual:[NSNull null]]) {
                        self.packetData.firmwareType = BOOTLOADER;
                        [self processManifest:value];
                    }
                }
                else if ([key isEqualToString:@"softdevice"])
                {
                    if (![value isEqual:[NSNull null]] ) {
                        self.packetData.firmwareType = SOFTDEVICE;
                        [self processManifest:value];
                    }
                }
                else if ([key isEqualToString:@"softdevice_bootloader"])
                {
                    if (![value isEqual:[NSNull null]]) {
                        self.packetData.firmwareType = SOFTDEVICE_AND_BOOTLOADER;
                        [self processManifest:value];
                    }
                }
            }
            return self.packetData;
        }
        else {
            NSLog(@"Error. Json dont have top level dictionary");
            return nil;
        }
    }
    else {
        NSLog(@"data is empty");
        return nil;
    }
    
}

-(void)processManifest:(id)value
{
    if (value) {
        for (id firmwareKey in value) {
            id innerValue = [value objectForKey:firmwareKey];
            if ([firmwareKey isEqualToString:@"init_packet_data"]) {
                if (![innerValue isEqual:[NSNull null]] ) {
                    [self processInitPacketData:innerValue];
                }
            }
            else if ([firmwareKey isEqualToString:@"bin_file"]) {
                if (![innerValue isEqual:[NSNull null]] ) {
                    self.packetData.firmwareBinFileName = innerValue;
                }
            }
            else if ([firmwareKey isEqualToString:@"dat_file"]) {
                if (![innerValue isEqual:[NSNull null]] ) {
                    self.packetData.firmwareDatFileName = innerValue;
                }
            }
            else if ([firmwareKey isEqualToString:@"bl_size"]) {
                if (![innerValue isEqual:[NSNull null]] ) {
                    self.packetData.bootloaderSize = (int)[innerValue integerValue];
                }
                
            }
            else if ([firmwareKey isEqualToString:@"sd_size"]) {
                if (![innerValue isEqual:[NSNull null]] ) {
                    self.packetData.softdeviceSize = (int)[innerValue integerValue];
                }
            }
        }
    }
}

-(void)processInitPacketData:(id)value
{
    if (value) {
        for (id initPacketDataKey in value) {
            id innerValue = [value objectForKey:initPacketDataKey];
            if ([initPacketDataKey isEqualToString:@"application_version"]) {
                if (![innerValue isEqual:[NSNull null]]) {
                    self.packetData.applicationVersion = (uint32_t)[innerValue integerValue];
                }
            }
            else if ([initPacketDataKey isEqualToString:@"device_revision"]) {
                if (![innerValue isEqual:[NSNull null]]) {
                    self.packetData.deviceRevision = (uint16_t)[innerValue integerValue];
                }
                
            }
            else if ([initPacketDataKey isEqualToString:@"device_type"]) {
                if (![innerValue isEqual:[NSNull null]]) {
                    self.packetData.deviceType = (uint16_t)[innerValue integerValue];
                }
            }
            else if ([initPacketDataKey isEqualToString:@"firmware_crc16"]) {
                if (![innerValue isEqual:[NSNull null]]) {
                    self.packetData.firmwareCRC = (uint16_t)[[value valueForKey:initPacketDataKey] integerValue];
                }
            }
            else if ([initPacketDataKey isEqualToString:@"softdevice_req"]) {
                if (![innerValue isEqual:[NSNull null]]) {
                    self.packetData.softdeviceRequired = [value objectForKey:initPacketDataKey];
                }
            }
        }
    }
    
}
@end
