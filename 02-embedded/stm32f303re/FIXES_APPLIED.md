# STM32F303RE PWM Fixes Applied

## Summary of Critical Fixes

### ✅ **Fix #1: Changed Timer Mode from Output Compare to PWM**

**Before (WRONG):**
```c
if (HAL_TIM_OC_Init(&htim1) != HAL_OK)  // Output Compare mode
sConfigOC.OCMode = TIM_OCMODE_TIMING;   // Not PWM!
```

**After (CORRECT):**
```c
if (HAL_TIM_PWM_Init(&htim1) != HAL_OK)  // PWM mode
sConfigOC.OCMode = TIM_OCMODE_PWM1;      // PWM mode 1!
```

**Applied to:** TIM1 and TIM8

---

### ✅ **Fix #2: Fixed TIM1 Master Configuration**

**Before (WRONG):**
```c
sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
```

**After (CORRECT):**
```c
sMasterConfig.MasterOutputTrigger = TIM_TRGO_UPDATE;   // Trigger on update event
sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_ENABLE;  // Enable master mode
```

**Why:** TIM1 must trigger TIM8 for synchronized operation

---

### ✅ **Fix #3: Set Dead-Time to 1µs**

**Before (WRONG):**
```c
sBreakDeadTimeConfig.DeadTime = 0;  // No dead-time!
```

**After (CORRECT):**
```c
sBreakDeadTimeConfig.DeadTime = 72;  // 1µs at 72MHz
```

**Applied to:** TIM1 and TIM8

**Calculation:** 1µs × 72MHz = 72 ticks

---

### ✅ **Fix #4: Added PWM Start Code in main()**

**Added in `/* USER CODE BEGIN 2 */` section:**

```c
// Set 50% duty cycle
uint16_t duty_50_percent = 7200;
__HAL_TIM_SET_COMPARE(&htim1, TIM_CHANNEL_1, duty_50_percent);
__HAL_TIM_SET_COMPARE(&htim1, TIM_CHANNEL_2, duty_50_percent);
__HAL_TIM_SET_COMPARE(&htim8, TIM_CHANNEL_1, duty_50_percent);
__HAL_TIM_SET_COMPARE(&htim8, TIM_CHANNEL_2, duty_50_percent);

// Start TIM1 PWM with complementary outputs
HAL_TIM_PWM_Start(&htim1, TIM_CHANNEL_1);
HAL_TIMEx_PWMN_Start(&htim1, TIM_CHANNEL_1);    // Complementary
HAL_TIM_PWM_Start(&htim1, TIM_CHANNEL_2);
HAL_TIMEx_PWMN_Start(&htim1, TIM_CHANNEL_2);    // Complementary

// Start TIM8 PWM with complementary outputs
HAL_TIM_PWM_Start(&htim8, TIM_CHANNEL_1);
HAL_TIMEx_PWMN_Start(&htim8, TIM_CHANNEL_1);    // Complementary
HAL_TIM_PWM_Start(&htim8, TIM_CHANNEL_2);
HAL_TIMEx_PWMN_Start(&htim8, TIM_CHANNEL_2);    // Complementary
```

**Why:** CubeIDE only generates initialization code, NOT start code!

---

### ✅ **Fix #5: Enable MOE (Main Output Enable) Bit**

**Added in `/* USER CODE BEGIN 2 */` section:**

```c
// CRITICAL: Enable Main Output Enable (MOE) for advanced timers
__HAL_TIM_MOE_ENABLE(&htim1);
__HAL_TIM_MOE_ENABLE(&htim8);
```

**Why:** Without MOE bit set, complementary PWM outputs will NOT work on TIM1/TIM8!

---

### ✅ **Fix #6: Changed UART Baud Rate to 115200**

**Before:**
```c
huart2.Init.BaudRate = 38400;
```

**After:**
```c
huart2.Init.BaudRate = 115200;
```

---

### ✅ **Fix #7: Added Debug UART Messages**

Added startup messages to confirm initialization:
- Clock configuration
- PWM startup
- Pin assignments

---

### ✅ **Fix #8: Added LED Heartbeat**

Added LED blinking in main loop to confirm code is running

---

## Expected PWM Output

After these fixes, you should see on oscilloscope:

### TIM1 Outputs:
- **PA8** (TIM1_CH1): 50% duty, 5 kHz PWM
- **PA9** (TIM1_CH2): 50% duty, 5 kHz PWM
- **PB13** (TIM1_CH1N): Inverted PA8 with 1µs dead-time
- **PB14** (TIM1_CH2N): Inverted PA9 with 1µs dead-time

### TIM8 Outputs:
- **PC6** (TIM8_CH1): 50% duty, 5 kHz PWM (synced with TIM1)
- **PC7** (TIM8_CH2): 50% duty, 5 kHz PWM (synced with TIM1)
- **PC10** (TIM8_CH1N): Inverted PC6 with 1µs dead-time
- **PC11** (TIM8_CH2N): Inverted PC7 with 1µs dead-time

### Waveform Details:
- **Frequency:** 5 kHz (200µs period)
- **Duty Cycle:** 50% (100µs ON, 100µs OFF)
- **Dead-time:** 1µs between complementary outputs
- **Amplitude:** 0V to 3.3V

---

## How to Use This Fixed Code

### Option 1: Copy main() content to your generated code

1. Open your CubeIDE-generated `main.c`
2. Copy the content from `/* USER CODE BEGIN 2 */` section from `main_fixed.c`
3. Paste into your `main.c` at the same location
4. Build and flash

### Option 2: Replace init functions

1. Replace `MX_TIM1_Init()` function
2. Replace `MX_TIM8_Init()` function
3. Replace `MX_USART2_UART_Init()` function
4. Copy the USER CODE sections

### Option 3: Re-configure in CubeIDE (Recommended)

1. Open .ioc file
2. Change TIM1/TIM8 to "PWM Generation CH1 CH1N" and "PWM Generation CH2 CH2N"
3. Set OCMode to "PWM mode 1"
4. Set Dead Time to 72
5. Set Master Output Trigger to "Update Event"
6. Enable Master Slave Mode
7. Regenerate code
8. Add USER CODE sections manually

---

## Verification Steps

1. **Compile:** Should build with no errors
2. **Flash:** Program the board
3. **Check LED:** Should blink at 0.5 Hz (heartbeat)
4. **Check UART:** Connect serial terminal at 115200 baud - should see startup messages
5. **Check PWM:** Connect oscilloscope to PA8 - should see 5 kHz, 50% duty PWM
6. **Check Complementary:** Connect to PB13 - should see inverted PA8 with dead-time gaps

---

## Troubleshooting

If still no PWM output:

1. **Verify MOE bit is set:**
   ```c
   // Add this in main loop to check:
   if (TIM1->BDTR & TIM_BDTR_MOE) {
       // MOE is enabled - good!
   }
   ```

2. **Check timer is counting:**
   ```c
   // Add debug code:
   uint32_t cnt = TIM1->CNT;
   // Should increment from 0 to 14399
   ```

3. **Check GPIO alternate function:**
   - Verify PA8/PA9 are configured as AF6 (TIM1)
   - Verify PC6/PC7 are configured as AF4 (TIM8)

4. **Check clock configuration:**
   - SYSCLK should be 72 MHz
   - Timer clocks should be 72 MHz

---

## Files Modified

- `main_fixed.c` - Complete fixed main.c file
- `FIXES_APPLIED.md` - This documentation

## Date
2025-12-10

## Tested
Ready for testing on hardware
