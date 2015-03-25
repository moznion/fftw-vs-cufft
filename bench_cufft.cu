#include <stdio.h>
#include <stdlib.h>
#include <cufft.h>
#include "common.h"

extern const int DEFAULT_SIGNAL_LENGTH;
extern const int DEFAULT_FFT_TRIALS;
extern const int DEFAULT_META_TRIALS;

const int BATCH_SIZE = 1;

int main(int argc, char **argv) {
    int fft_trials = DEFAULT_FFT_TRIALS;
    int meta_trials = DEFAULT_META_TRIALS;
    if (argc >= 2) {
        char *arg_fft_trials = argv[1];
        char *invalid_chars;
        fft_trials = strtol(arg_fft_trials, &invalid_chars, 10);
        if (*invalid_chars != '\0') {
            fprintf(stderr, "[ERROR] FFT trials number must be integer (but given: '%s')\n", arg_fft_trials);
            return 1;
        }

        if (argc >= 3) {
            char *arg_meta_trials = argv[2];
            char *invalid_chars;
            meta_trials = strtol(arg_meta_trials, &invalid_chars, 10);
            if (*invalid_chars != '\0') {
                fprintf(stderr, "[ERROR] Meta trials number must be integer (but given: '%s')\n", arg_meta_trials);
                return 1;
            }
        }
    }
    printf("[INFO] META trials: %d\n", meta_trials);
    printf("[INFO] FFT trials: %d\n", fft_trials);

    long signal_length = DEFAULT_SIGNAL_LENGTH;
    char *env_signal_length = getenv("SIGNAL_LENGTH");
    if (env_signal_length != NULL) {
        char *invalid_chars;
        signal_length = strtol(env_signal_length, &invalid_chars, 10);
        if (*invalid_chars != '\0') {
            fprintf(stderr, "[ERROR] Environment variable of 'SIGNAL_LENGTH' must be integer (but given: '%s')\n", env_signal_length);
            return 1;
        }
    }
    printf("[INFO] Signal Length: %ld\n", signal_length);

    cufftComplex *h_original_signal;
    cudaMallocHost((void **) &h_original_signal, sizeof(cufftComplex) * signal_length);

    cufftComplex *d_original_signal, *d_applied_fft_signal;
    cudaMalloc((void **) &d_original_signal, sizeof(cufftComplex) * signal_length);
    cudaMalloc((void **) &d_applied_fft_signal, sizeof(cufftComplex) * signal_length);

    /*
     * generate random signal as original signal
     */
    srand(time(NULL)); // initialize random seed
    for (int i = 0; i < signal_length; i++) {
        h_original_signal[i].x = (float)rand() / RAND_MAX;
        h_original_signal[i].y = 0.0;
    }
    cudaMemcpy(d_original_signal, h_original_signal, sizeof(cufftComplex) * signal_length, cudaMemcpyHostToDevice);

    cufftHandle fft_plan;
    cufftPlan1d(&fft_plan, signal_length, CUFFT_C2C, BATCH_SIZE);

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    float sum_of_elapsed_times = 0.0;

    printf("[INFO] Run benchmark...\n");
    for (int i = 0; i < meta_trials; i++) {
        cudaEventRecord(start, 0);

        for (int j = 0; j < fft_trials; j++) {
            cufftExecC2C(fft_plan, d_original_signal, d_applied_fft_signal, CUFFT_FORWARD);
        }

        cudaEventRecord(stop, 0);
        cudaEventSynchronize(stop);

        float elapsed_time_ms;
        cudaEventElapsedTime(&elapsed_time_ms, start, stop);

        float elapsed_time_sec = elapsed_time_ms / 1000.0;
        sum_of_elapsed_times += elapsed_time_sec;
        printf("%f sec\n", elapsed_time_sec);
    }
    printf("[INFO] Finished!\n");
    printf("[INFO] Average: %lf sec\n", sum_of_elapsed_times / meta_trials);

    cudaEventDestroy(start);
    cudaEventDestroy(stop);
}
