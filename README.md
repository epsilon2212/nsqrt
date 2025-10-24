Square Root
For a given non-negative 2𝑛-bit integer 𝑋, we want to find a non-negative 𝑛-bit integer 𝑄 such that
𝑄² ≤ 𝑋 < (𝑄 + 1)².
Task
Implement in assembly a function callable from C, with the following declaration:
void nsqrt(uint64_t *Q, uint64_t *X, unsigned n);
The parameters Q and X are pointers to the binary representations of numbers 𝑄 and 𝑋, respectively.
The numbers are stored in standard binary form, little-endian order, with 64 bits per word (type uint64_t).
The parameter n specifies the bit-length of 𝑄 and is divisible by 64, ranging from 64 to 256000.
The memory pointed to by X is modifiable, intended for use as working space during computation.
