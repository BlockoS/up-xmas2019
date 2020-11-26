#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <float.h>

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

typedef struct {
	int width;
	int height;
	uint8_t *data;
} image_t;

inline float clamp(float f) {
    return fmin(fmax(f, 0.f), 1.f);
}

void usage() {
	printf("convert image out\n");
}

void write_binary(image_t* text, const char* prefix) {
    char buffer[128];
	sprintf(buffer, "%s.bin", prefix);

	FILE *out = fopen(buffer, "wb");
	fwrite(text->data, 1, text->width*text->height, out);
	fclose(out);
	
    printf(
        "%s_width = %d\n"
        "%s_height = %d\n"
        "%s:\n"
        "incbin(\"%s\")\n",
        prefix, text->width, 
        prefix, text->height,
        prefix, buffer);
}

static uint8_t g_threshold_map[16] = {
     0,  8,  2, 10,
    12,  4, 14,  6,
     3, 11,  1,  9,
    15,  7, 13,  5 
};

void find_closest(uint16_t *col) {
    static const uint8_t level[3] = { 0, 128, 255 };
    unsigned int r, g, b;
    uint8_t closest[3] = { 0, 0, 0 };
    float closest_mag = FLT_MAX;

    for(r=0; r<3; r++) {
        for(g=0; g<3; g++) {
            for(b=0; b<3; b++) {
                unsigned int u = level[r];
                unsigned int v = level[g];
                unsigned int w = level[b];

                float dr = u - (float)col[0];
                float dg = v - (float)col[1];
                float db = w - (float)col[2];

                float mag = dr*dr + dg*dg + db*db;
                if(closest_mag > mag) {
                    closest_mag = mag;
                    closest[0] = u;
                    closest[1] = v;
                    closest[2] = w;
                }
            }
        }
    }

    col[0] = closest[0];
    col[1] = closest[1];
    col[2] = closest[2];
}

int main(int argc, char **argv) {
	image_t source;
    
	int i, j, k;
	int x;
	
	char str[128];
	
	if(argc != 3) {
		usage();
		return EXIT_FAILURE;
	}

	source.data = (uint8_t*)stbi_load(argv[1], &source.width, &source.height, NULL, STBI_rgb);
	if((source.width & 7) || (source.height & 7)) {
	    fprintf(stderr, "input image dimension must be a multiple of 8\n");
    	stbi_image_free(source.data);
        return EXIT_FAILURE;
	}
	
    float strength = 1.0f;

    for(j=0; j<source.height; j++) {
        for(i=0; i<source.width; i+=4) {
            k = (i + (j * source.width)) * 3;
            uint16_t mean[3] = {0};

            for(x=0; x<4; x++) {
                mean[0] += source.data[k+x*3  ];
                mean[1] += source.data[k+x*3+1];
                mean[2] += source.data[k+x*3+2];
            }
            mean[0] /= 4;
            mean[1] /= 4;
            mean[2] /= 4;

            float threshold_map_value = g_threshold_map[((i/4)&3) + (j&3)*4]  / (7.f * 16.f);
            float delta = strength * threshold_map_value;
            for(int k=0; k<3; k++)  {
                float v = (float)mean[k] + delta*255.f;
                mean[k] = (v > 255.f) ? 255.f : v;
            }
            find_closest(mean);

            for(x=0; x<4; x++) {
                source.data[k+x*3  ] = mean[0]; 
                source.data[k+x*3+1] = mean[1]; 
                source.data[k+x*3+2] = mean[2]; 
            }
        }
    }

    sprintf(str, "%s_bitmap.png", argv[2]);	
    stbi_write_png(str, source.width, source.height, 3, source.data, 0);
/*
    uint8_t *dummy = (uint8_t*)malloc(source.width * source.height * 3);

    for(j=0; j<source.height; j++) {
        for(i=0; i<source.width; i+=4) {
            k = (i + j*source.width) * 3;
            uint8_t col[3] = {
                source.data[k  ] ? 255 : 0,
                source.data[k+1] ? 255 : 0,
                source.data[k+2] ? 255 : 0
            };
            for(x=0; x<4; x++) {
                dummy[k+x*3  ] = col[0];
                dummy[k+x*3+1] = col[1];
                dummy[k+x*3+2] = col[2];
            }
        }
    }

    sprintf(str, "%s_lo.png", argv[2]);	
    stbi_write_png(str, source.width, source.height, 3, dummy, 0);

    for(j=0; j<source.height; j++) {
        for(i=0; i<source.width; i+=4) {
            k = (i + j*source.width) * 3;
            uint8_t col[3] = {
                (source.data[k  ] > 128)  ? 255 : 0,
                (source.data[k+1] > 128)  ? 255 : 0,
                (source.data[k+2] > 128) ? 255 : 0
            };
            for(x=0; x<4; x++) {
                dummy[k+x*3  ] = col[0];
                dummy[k+x*3+1] = col[1];
                dummy[k+x*3+2] = col[2];
            }
        }
    }

    sprintf(str, "%s_hi.png", argv[2]);	
    stbi_write_png(str, source.width, source.height, 3, dummy, 0);

    free(dummy);
*/
    FILE *out;
    // lo binary
    sprintf(str, "%s.bin", argv[2]);	
    out = fopen(str, "wb");
    for(j=0; j<source.height; j++) {
        for(i=0; i<source.width; i+=8) {
            k = (i + j*source.width) * 3;
            uint8_t col = 
                (source.data[k   ] ? 0x02 : 0) |
                (source.data[k+ 1] ? 0x04 : 0) |
                (source.data[k+ 2] ? 0x01 : 0) |
                (source.data[k+12] ? 0x20 : 0) |
                (source.data[k+13] ? 0x40 : 0) |
                (source.data[k+14] ? 0x10 : 0)
            ;
            fwrite(&col, 1, 1, out);
        }
    }
    // hi binary
    for(j=0; j<source.height; j++) {
        for(i=0; i<source.width; i+=8) {
            k = (i + j*source.width) * 3;
            uint8_t col = 
                ((source.data[k   ] > 128) ? 0x02 : 0) |
                ((source.data[k+ 1] > 128) ? 0x04 : 0) |
                ((source.data[k+ 2] > 128) ? 0x01 : 0) |
                ((source.data[k+12] > 128) ? 0x20 : 0) |
                ((source.data[k+13] > 128) ? 0x40 : 0) |
                ((source.data[k+14] > 128) ? 0x10 : 0)
            ;
            fwrite(&col, 1, 1, out);
        }
    }
    fclose(out);

	stbi_image_free(source.data);
	return EXIT_SUCCESS;
}
