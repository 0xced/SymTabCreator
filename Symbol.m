//
//  Symbol.m
//  SymTabCreator
//
//  Created by Karsten Kusche on 17.06.10.
//  Copyright 2010 Briksoftware.com. All rights reserved.
//

#import "Symbol.h"


@implementation Symbol

- (NSComparisonResult)compareWithSymbol:(Symbol*)otherSymbol
{
	return [self offset] - [otherSymbol offset];
}

+ (id)fromLine:(NSString*) string
{
	if (string == nil || [string length] == 0) return nil;
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	uint64_t scannedOffset = 0;
	NSString *scannedSymbolName = nil;
	BOOL symbolNameOK = NO;
	if ([scanner scanHexLongLong:&scannedOffset])
	{
		[scanner scanString:@" " intoString:NULL];
		symbolNameOK = [scanner scanUpToString:@"" intoString:&scannedSymbolName];
	}
	
	if (!symbolNameOK)
	{
		fprintf(stderr,"error parsing line: %s\n",[string UTF8String]);
		return nil;
	}
	
	Symbol *new = [[[self alloc] init] autorelease];
	new.symbolName = scannedSymbolName;
	new.offset = scannedOffset;
	return new;
}

- (NSInteger)writeToFile: (FILE*)file fromOffset:(NSInteger)startOffset
{
	if (startOffset)
	{// already started, so just skip the gab between the previous symbol and the current symbol
		fprintf(file,".space %s,0x90\n",[[[NSNumber numberWithInteger:(self.offset - startOffset)] stringValue] UTF8String]);
	}
	else
	{// we start the file, first create a dummy space.
	 // the dummy space is required because we start -0x1000 before the desired offset and now need to fill the gap between 0x0000 and the first offset.
		int initialSpace = self.offset & 0x0fff;
		if (initialSpace)
			// only print if the initialSpace is > 0. Otherwise the assembler will fail
			fprintf(file,".space %s,0x90\n",[[[NSNumber numberWithInteger:initialSpace] stringValue] UTF8String]);
	}
	
	BOOL isMethodSymbol = ([self.symbolName hasPrefix:@"+["] || [self.symbolName hasPrefix:@"-["]);
	const char *name = [self.symbolName UTF8String];
	const char *nameWithUnderscore = isMethodSymbol ? name : [[@"_" stringByAppendingString:self.symbolName] UTF8String];
	fprintf(file,".globl \"%s\" \n \"%s\": \n .stabs \"%s:F(0,1)\",36,0,0,\"%s\" \n", nameWithUnderscore, nameWithUnderscore, name, nameWithUnderscore);
	return self.offset;
}

@end
