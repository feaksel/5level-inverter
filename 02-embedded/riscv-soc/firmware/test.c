int main(void) {
    volatile unsigned int *gpio = (unsigned int *)0x00020400;
    while(1) {
        *gpio = 0xAAAA;  // Toggle GPIOs
        for(int i = 0; i < 100000; i++);
        *gpio = 0x5555;
        for(int i = 0; i < 100000; i++);
    }
    return 0;
}
