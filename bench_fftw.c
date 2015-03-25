#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <fftw3.h>
#include <omp.h>
#include "common.h"

extern const int DEFAULT_SIGNAL_LENGTH;
extern const int DEFAULT_FFT_TRIALS;
extern const int DEFAULT_META_TRIALS;

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

    fftw_complex *original_signal, *fft_applied_signal;
    original_signal    = (fftw_complex *)fftw_malloc(sizeof(fftw_complex) * signal_length);
    fft_applied_signal = (fftw_complex *)fftw_malloc(sizeof(fftw_complex) * signal_length);

    /*
     * generate random signal as original signal
     */
    srand(time(NULL)); // initialize random seed
    for (int i = 0; i < signal_length; i++) {
        original_signal[i][0] = (float)rand() / RAND_MAX;
        original_signal[i][1] = 0.0;
    }

    fftw_plan fft_plan;
    fft_plan = fftw_plan_dft_1d(signal_length, original_signal, fft_applied_signal, FFTW_FORWARD, FFTW_ESTIMATE);

    double sum_of_elapsed_times = 0.0;
    double start, end;

    printf("[INFO] Run benchmark...\n");
    for (int i = 0; i < meta_trials; i++) {
        start = omp_get_wtime();

        for (int j = 0; j < fft_trials; j++) {
            fftw_execute(fft_plan);
        }

        end = omp_get_wtime();

        double elapsed_time_sec = end - start;
        sum_of_elapsed_times += elapsed_time_sec;
        printf("%lf sec\n", elapsed_time_sec);
    }
    printf("[INFO] Finished!\n");
    printf("[INFO] Average: %lf sec\n", sum_of_elapsed_times / meta_trials);

    return 0;
}

