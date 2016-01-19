#pragma once
#include <cstdlib>

#define WINDOW_SIZE 3

typedef struct ImageStruct {
              unsigned char *data;
              unsigned width;
              unsigned height;
             } Image;

int clipToRange(int i, int lower, int upper)
{
    return (i < lower) ? lower : ((i > upper) ? upper : i);
}

unsigned char *byteAt(unsigned channel, unsigned x, unsigned y, Image *img, unsigned CHANNELS)
{
    return img->data + (x + img->width*y)*CHANNELS + channel;
}

int comp (const void * elem1, const void * elem2)
{
    unsigned char f = *((unsigned char*)elem1);
    unsigned char s = *((unsigned char*)elem2);
    if (f > s) return  1;
    if (f < s) return -1;
    return 0;
}

unsigned char median(unsigned char *array, unsigned size)
{
    for (unsigned i = 0; i <= size/2; ++i)
    {
        unsigned char min = 255;
        unsigned index = 0;
        for (unsigned j = 0; j < size - i; ++j)
        {
            if (array[j + i] < min)
            {
                index = j + i;
                min = array[index];
            }
            array[index] = array[i];
            array[i] = min;
        }
    }

    return array[size/2];
}

void swap(unsigned char *first, unsigned char *second)
{
    unsigned char temp = *first;
    *first = *second;
    *second = temp;
}

unsigned partition(unsigned char *array, unsigned left, unsigned right, unsigned pivot)
{
    unsigned char pivotValue = array[pivot];
    unsigned index, i;
    swap(array + pivot, array + right);

    index = left;

    for (i = left; i < right; ++i)
    {
        if (array[i] < pivotValue)
        {
            swap(array + index, array + i);
            ++index;
        }
    }
    swap(array + right, array + index);
    return index;
}

unsigned char quickMedian(unsigned char *array, unsigned size)
{
    unsigned n = (size)/2, left = 0, right = size - 1;
    unsigned pivot;

    while (1)
    {
        if (left == right)
        {
            return array[left];
        }
        pivot = (right - left)/2;
        pivot = partition(array, left, right, pivot);
        if (pivot == n)
        {
            return array[n];
        }
        else if (n < pivot)
        {
            right = pivot - 1;
        }
        else
        {
            left = pivot + 1;
        }
    }
}

void medianFilter(Image *src, Image *dst, unsigned CHANNELS)
{
    unsigned char window[WINDOW_SIZE*WINDOW_SIZE];

    for (unsigned c = 0; c < CHANNELS; ++c)
    {
        for (unsigned x = 0; x < dst->width; ++x)
        {
            for (unsigned y = 0; y < dst->height; ++y)
            {
                 for (int i = 0; i < WINDOW_SIZE; ++i)
                 {
                     int ni = x - WINDOW_SIZE/2 + i;
                     ni = clipToRange(ni, 0, dst->width - 1);

                     for (int j = 0; j < WINDOW_SIZE; ++j)
                     {
                         int nj = y - WINDOW_SIZE/2 + j;
                         nj = clipToRange(nj, 0, dst->height - 1);

                         window[i+WINDOW_SIZE*j] = *byteAt(c, ni, nj, src, CHANNELS);
                     }
                 }


                 //std::qsort(window, sizeof(window)/sizeof(*window), sizeof(*window), comp);
                 *byteAt(c, x, y, dst, CHANNELS) = quickMedian(window, 9);
            }
        }
    }
}

