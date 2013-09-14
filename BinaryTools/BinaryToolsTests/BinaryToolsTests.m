#import <XCTest/XCTest.h>

#import "BTBinaryTools.h"

@interface BinaryToolsTests : XCTestCase

@end

@implementation BinaryToolsTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testWriteReadBigEndian
{
    [self writeReadWithByteOrder:CFByteOrderBigEndian];
}

- (void)testWriteReadLittleEndian
{
    [self writeReadWithByteOrder:CFByteOrderLittleEndian];
}

-(void)testReaderStringDecodingError
{
    NSData* utf8ByteString = [@"בדיקה" dataUsingEncoding:NSUTF8StringEncoding];
    NSInputStream* inputStream = [NSInputStream inputStreamWithData:utf8ByteString];
    [inputStream open];
    BTBinaryStreamReader* reader = [[BTBinaryStreamReader alloc] initWithStream:inputStream andSourceByteOrder:CFByteOrderGetCurrent()];
    
    NSString* resultString = [reader readStringWithEncoding:NSUTF32BigEndianStringEncoding andLength:[utf8ByteString length]];
    XCTAssertNil(resultString);
    
    NSError* readError = [reader getError];
    XCTAssertNotNil(readError);
    XCTAssertEqual(readError.domain, BTBinaryStreamErrorDomain);
    XCTAssertEqual(readError.code, BTBinaryStreamReaderStringDecodingError);
}

-(void)testReaderEndOfStreamError
{
    NSInputStream* inputStream = [NSInputStream inputStreamWithData:[NSData data]];
    [inputStream open];
    BTBinaryStreamReader* reader = [[BTBinaryStreamReader alloc] initWithStream:inputStream andSourceByteOrder:CFByteOrderGetCurrent()];
    
    [reader readInt8];
    
    NSError* readError = [reader getError];
    XCTAssertNotNil(readError);
    XCTAssertEqual(readError.domain, BTBinaryStreamErrorDomain);
    XCTAssertEqual(readError.code, BTBinaryStreamReaderEndOfStream);
}

-(void)testReaderNotEnoughBytesReadError
{
    uint8_t bytes[2] = {0xAB, 0xCD};
    NSInputStream* inputStream = [NSInputStream inputStreamWithData:[NSData dataWithBytesNoCopy:bytes length:2 freeWhenDone:NO]];
    [inputStream open];
    BTBinaryStreamReader* reader = [[BTBinaryStreamReader alloc] initWithStream:inputStream andSourceByteOrder:CFByteOrderGetCurrent()];
    
    [reader readInt32];
    
    NSError* readError = [reader getError];
    XCTAssertNotNil(readError);
    XCTAssertEqual(readError.domain, BTBinaryStreamErrorDomain);
    XCTAssertEqual(readError.code, BTBinaryStreamReaderNotEnoughBytesRead);
}

-(void)testReaderStreamOperationError
{
    NSInputStream* inputStream = [NSInputStream inputStreamWithData:[NSData data]];
    BTBinaryStreamReader* reader = [[BTBinaryStreamReader alloc] initWithStream:inputStream andSourceByteOrder:CFByteOrderGetCurrent()];
    uint8_t test;
    [inputStream read:&test maxLength:1];
    
    [reader readInt8];
    
    NSError* readError = [reader getError];
    XCTAssertNotNil(readError);
    XCTAssertEqual(readError.domain, BTBinaryStreamErrorDomain);
    XCTAssertEqual(readError.code, BTBinaryStreamOperationError);
}

-(void)testWriterStringEncodingError
{
    NSString* unicodeString = @"בדיקה";
    NSOutputStream* outputStream = [NSOutputStream outputStreamToMemory];
    [outputStream open];
    BTBinaryStreamWriter* writer = [[BTBinaryStreamWriter alloc] initWithStream:outputStream andDesiredByteOrder:CFByteOrderGetCurrent()];
    
    [writer writeString:unicodeString withEncoding:NSASCIIStringEncoding];
    
    NSError* writeError = [writer getError];
    XCTAssertNotNil(writeError);
    XCTAssertEqual(writeError.domain, BTBinaryStreamErrorDomain);
    XCTAssertEqual(writeError.code, BTBinaryStreamWriterStringEncodingError);
}

-(void)testWriterEndOfStreamError
{
    uint8_t outputBuffer[1];
    NSOutputStream* outputStream = [NSOutputStream outputStreamToBuffer:outputBuffer capacity:1];
    [outputStream open];
    BTBinaryStreamWriter* writer = [[BTBinaryStreamWriter alloc] initWithStream:outputStream andDesiredByteOrder:CFByteOrderGetCurrent()];
    
    [writer writeInt8:0xFF];
    XCTAssertNil([writer getError]);
    
    [writer writeInt8:0xFF];
    
    NSError* writeError = [writer getError];
    XCTAssertNotNil(writeError);
    XCTAssertEqual(writeError.domain, BTBinaryStreamErrorDomain);
    
    // Note: the Foundation is lying to us, see documentation in BTBinaryStreamHandlingErrors.h.
    // XCTAssertEqual(writeError.code, BTBinaryStreamWriterEndOfStream);
    XCTAssertEqual(writeError.code, BTBinaryStreamOperationError);
}

-(void)testWriterNotEnoughBytesWrittenError
{
    uint8_t outputBuffer[3];
    NSOutputStream* outputStream = [NSOutputStream outputStreamToBuffer:outputBuffer capacity:3];
    [outputStream open];
    BTBinaryStreamWriter* writer = [[BTBinaryStreamWriter alloc] initWithStream:outputStream andDesiredByteOrder:CFByteOrderGetCurrent()];
    
    [writer writeInt32:0x12345678];
    
    NSError* writeError = [writer getError];
    XCTAssertNotNil(writeError);
    XCTAssertEqual(writeError.domain, BTBinaryStreamErrorDomain);
    
    // Note: the Foundation is lying to us, see documentation in BTBinaryStreamHandlingErrors.h.
    //    XCTAssertEqual(writeError.code, BTBinaryStreamWriterNotAllBytesWritten);
    XCTAssertEqual(writeError.code, BTBinaryStreamOperationError);
}

-(void)testWriterStreamOperationError
{
    NSOutputStream* outputStream = [NSOutputStream outputStreamToMemory];
    BTBinaryStreamWriter* writer = [[BTBinaryStreamWriter alloc] initWithStream:outputStream andDesiredByteOrder:CFByteOrderGetCurrent()];
    
    [writer writeInt8:0xFF];
    
    NSError* writeError = [writer getError];
    XCTAssertNotNil(writeError);
    XCTAssertEqual(writeError.domain, BTBinaryStreamErrorDomain);
    XCTAssertEqual(writeError.code, BTBinaryStreamOperationError);
}

-(void)writeReadWithByteOrder:(CFByteOrder)byteOrder
{
    NSStringEncoding stringEncoding = NSUTF8StringEncoding;
    
    int8_t i8 = -100;
    uint8_t ui8 = 0xFF;
    int16_t i16 = -30000;
    uint16_t ui16 = 0xFEDC;
    int32_t i32 = -2000000000;
    uint32_t ui32 = 0xFEDCAB98;
    int64_t i64 = -9000000000000000000;
    uint64_t ui64 = 0xFEDCAB9876543210;
    
    float f = 3.14;
    double d = 3.14;
    
    NSString* unicodeString = @"test בדיקה проверка";
    
    NSOutputStream* outputStream = [NSOutputStream outputStreamToMemory];
    [outputStream open];
    
    BTBinaryStreamWriter* writer = [[BTBinaryStreamWriter alloc] initWithStream:outputStream andDesiredByteOrder:byteOrder];
    
    [writer writeInt8:i8];
    XCTAssertNil([writer getError]);
    
    [writer writeUInt8:ui8];
    XCTAssertNil([writer getError]);
    
    [writer writeInt16:i16];
    XCTAssertNil([writer getError]);
    
    [writer writeUInt16:ui16];
    XCTAssertNil([writer getError]);
    
    [writer writeInt32:i32];
    XCTAssertNil([writer getError]);
    
    [writer writeUInt32:ui32];
    XCTAssertNil([writer getError]);
    
    [writer writeInt64:i64];
    XCTAssertNil([writer getError]);
    
    [writer writeUInt64:ui64];
    XCTAssertNil([writer getError]);
    
    [writer writeFloat:f];
    XCTAssertNil([writer getError]);
    
    [writer writeDouble:d];
    XCTAssertNil([writer getError]);
    
    NSUInteger sizeOfString = [unicodeString lengthOfBytesUsingEncoding:stringEncoding];
    [writer writeUInt32:sizeOfString];
    XCTAssertNil([writer getError]);
    
    [writer writeString:unicodeString withEncoding:stringEncoding];
    XCTAssertNil([writer getError]);
    
    NSData* outputData = [outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    
    NSInputStream* inputStream = [NSInputStream inputStreamWithData:outputData];
    [inputStream open];
    BTBinaryStreamReader* reader = [[BTBinaryStreamReader alloc] initWithStream:inputStream andSourceByteOrder:byteOrder];
    
    XCTAssertEqual([reader readInt8], i8);
    XCTAssertNil([reader getError]);
    
    XCTAssertEqual([reader readUInt8], ui8);
    XCTAssertNil([reader getError]);
    
    XCTAssertEqual([reader readInt16], i16);
    XCTAssertNil([reader getError]);
    
    XCTAssertEqual([reader readUInt16], ui16);
    XCTAssertNil([reader getError]);
    
    XCTAssertEqual([reader readInt32], i32);
    XCTAssertNil([reader getError]);
    
    XCTAssertEqual([reader readUInt32], ui32);
    XCTAssertNil([reader getError]);
    
    XCTAssertEqual([reader readInt64], i64);
    XCTAssertNil([reader getError]);
    
    XCTAssertEqual([reader readUInt64], ui64);
    XCTAssertNil([reader getError]);
    
    XCTAssertEqual([reader readFloat], f);
    XCTAssertNil([reader getError]);
    
    XCTAssertEqual([reader readDouble], d);
    XCTAssertNil([reader getError]);
    
    NSUInteger sizeOfStoredString = [reader readUInt32];
    XCTAssertNil([reader getError]);
    XCTAssertEqual(sizeOfString, sizeOfStoredString);
    
    XCTAssertEqualObjects(unicodeString, [reader readStringWithEncoding:stringEncoding andLength:sizeOfStoredString]);
    XCTAssertNil([reader getError]);
}

@end
