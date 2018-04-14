#import "XeeYUVImage.h"

static void XeeYUVImageReadPixel(uint8_t *row, NSInteger x, NSInteger pixelsize, uint8_t *dest);
static void XeeBuildYUVConversionTables(void);

@implementation XeeYUVImage

- (id)initWithWidth:(NSInteger)pixelwidth height:(NSInteger)pixelheight
{
	if (self = [super init]) {
		if (![self allocWithWidth:pixelwidth height:pixelheight]) {
			return nil;
		}
	}

	return self;
}

- (void)setData:(uint8_t *)pixeldata freeData:(BOOL)willfree width:(NSInteger)pixelwidth height:(NSInteger)pixelheight bytesPerRow:(NSInteger)bprow
{
#ifdef __BIG_ENDIAN__
	[super setData:pixeldata
				freeData:willfree
				   width:pixelwidth
				  height:pixelheight
		   bytesPerPixel:2
			 bytesPerRow:bprow
		   premultiplied:NO
		glInternalFormat:GL_RGB8
				glFormat:GL_YCBCR_422_APPLE
				  glType:GL_UNSIGNED_SHORT_8_8_REV_APPLE];
#else
	[super setData:pixeldata
				freeData:willfree
				   width:pixelwidth
				  height:pixelheight
		   bytesPerPixel:2
			 bytesPerRow:bprow
		   premultiplied:NO
		glInternalFormat:GL_RGB8
				glFormat:GL_YCBCR_422_APPLE
				  glType:GL_UNSIGNED_SHORT_8_8_APPLE];
#endif
}

- (BOOL)allocWithWidth:(NSInteger)pixelwidth height:(NSInteger)pixelheight
{
	int bprow = (2 * pixelwidth + 2) & ~3;
	void *newdata = malloc(pixelheight * bprow);

	if (newdata) {
		uint32_t *ptr = (uint32_t *)newdata;
#ifdef __BIG_ENDIAN__
		for (int i = 0; i < pixelheight * bprow / 4; i++)
			*ptr++ = 0x7f007f00;
#else
		for (int i = 0; i < pixelheight * bprow / 4; i++)
			*ptr++ = 0x007f007f;
#endif

		[self setData:newdata
			   freeData:YES
				  width:pixelwidth
				 height:pixelheight
			bytesPerRow:bprow];
		return YES;
	}
	return NO;
}

- (void)fixYUVGamma
{
	static const unsigned char gammatable[256] =
		{
			0x00, 0x00, 0x01, 0x01, 0x02, 0x02, 0x03, 0x03, 0x04, 0x04, 0x05, 0x05, 0x06, 0x07, 0x07, 0x08,
			0x09, 0x09, 0x0a, 0x0b, 0x0b, 0x0c, 0x0d, 0x0d, 0x0e, 0x0f, 0x10, 0x10, 0x11, 0x12, 0x13, 0x13,
			0x14, 0x15, 0x16, 0x17, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f, 0x1f, 0x20,
			0x21, 0x22, 0x23, 0x24, 0x25, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2c, 0x2d, 0x2e,
			0x2f, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d,
			0x3e, 0x3f, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4c,
			0x4d, 0x4e, 0x4f, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x5b, 0x5c,
			0x5d, 0x5e, 0x5f, 0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d,
			0x6e, 0x6f, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7b, 0x7c, 0x7d, 0x7e,
			0x7f, 0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f,
			0x90, 0x91, 0x92, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9e, 0x9f, 0xa0, 0xa1,
			0xa2, 0xa3, 0xa4, 0xa5, 0xa7, 0xa8, 0xa9, 0xaa, 0xab, 0xac, 0xad, 0xaf, 0xb0, 0xb1, 0xb2, 0xb3,
			0xb4, 0xb5, 0xb7, 0xb8, 0xb9, 0xba, 0xbb, 0xbc, 0xbd, 0xbf, 0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc6,
			0xc7, 0xc8, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf, 0xd0, 0xd1, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8,
			0xda, 0xdb, 0xdc, 0xdd, 0xde, 0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xec,
			0xed, 0xee, 0xef, 0xf0, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf8, 0xf9, 0xfa, 0xfb, 0xfd, 0xfe, 0xff,
		};

	for (int y = 0; y < height; y++) {
		NSInteger n = width;
		unsigned char *ptr = (unsigned char *)data + y * bytesperrow + 1;

		while (n--) {
			*ptr = gammatable[*ptr];
			ptr += 2;
		}
	}
}

- (NSInteger)bitsPerComponentForCGImage
{
	return 8;
}

- (NSInteger)bytesPerPixelForCGImage
{
	return 3;
}

- (CGColorSpaceRef)createColorSpaceForCGImage
{
	return CGColorSpaceCreateDeviceRGB();
}

- (CGBitmapInfo)bitmapInfoForCGImage
{
	return 0;
}

- (XeeReadPixelFunction)readPixelFunctionForCGImage
{
	static BOOL tables_built = NO;
	if (!tables_built) {
		XeeBuildYUVConversionTables();
		tables_built = YES;
	}

	return XeeYUVImageReadPixel;
}

@end

static int cr_r_tab[256];
static int cb_b_tab[256];
static int cr_g_tab[256];
static int cb_g_tab[256];
static uint8_t range_table[256 * 3], *range_limit;

#define ONE_HALF (1 << 15)
#define FIX(x) ((int)((x) * (1 << 16) + 0.5))

static void XeeBuildYUVConversionTables()
{
	for (int i = 0; i < 256; i++) {
		range_table[i] = 0;
		range_table[i + 256] = i;
		range_table[i + 512] = 255;

		int x = i - 128;
		cr_r_tab[i] = (int)(FIX(1.40200) * x + ONE_HALF) >> 16;
		cb_b_tab[i] = (int)(FIX(1.77200) * x + ONE_HALF) >> 16;
		cr_g_tab[i] = -FIX(0.71414) * x;
		cb_g_tab[i] = -FIX(0.34414) * x + ONE_HALF;
	}

	range_limit = range_table + 256;
}

static void XeeYUVImageReadPixel(uint8_t *row, NSInteger x, NSInteger pixelsize, uint8_t *dest)
{
	uint8_t y = row[2 * x | 1];
	uint8_t cb = row[2 * x & ~2];
	uint8_t cr = row[2 * x | 2];

	dest[0] = range_limit[y + cr_r_tab[cr]];
	dest[1] = range_limit[y + ((cb_g_tab[cb] + cr_g_tab[cr]) >> 16)];
	dest[2] = range_limit[y + cb_b_tab[cb]];
}
