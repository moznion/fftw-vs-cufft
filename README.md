FFTW VS cuFFT
==

Benchmark scripts to compare processing speed between [FFTW](http://www.fftw.org/) and [cuFFT](https://developer.nvidia.com/cuFFT).

Usage
--

```
make
./bench_fftw
./bench_cufft
```

Description
--

- `bench_fftw`: Run benchmark with FFTW
- `bench_cufft`: Run benchmark with cuFFT

Both of the binary have the same interfaces.

```
./bench_XXX [Number of Trials to Execute FFT] [Number of Trials to Execute Benchmark]
```

- Number of Trials to Execute FFT (int)

    You omit this when it will use default value (default value: `10000`).

- Number of Trials to Execute Benchmark (int)

    You omit this when it will use default value (default value: `10`).

And these binary accept `SIGNAL_LENGTH` environment variable.
It determines the signal length for signal to apply to FFT.
It must be int value. Default value is `4096`.

Author
--

moznion (<moznion@gmai.com>)

License
--

MIT

