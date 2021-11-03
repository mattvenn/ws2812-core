import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, Timer

class WS2812_LED():

    # on, off and reset times are in ns
    def __init__(self, data, t_on = 800, t_off = 400, t_reset = 65000, leds = 8 ):

        self.data = data
        self.t_on = t_on
        self.t_off = t_off
        self.t_reset = t_reset
        self.num_leds = leds
        self.bits = []

    async def read(self):

        start_time = cocotb.utils.get_sim_time()
#        await RisingEdge(self.data)
#        if (cocotb.utils.get_sim_time() - start_time) > self.t_reset:
#            print("reset")

        num_bits = 8 * 3 * self.num_leds
        for i in range(num_bits):
            await RisingEdge(self.data)
            rise_time = cocotb.utils.get_sim_time()
            await FallingEdge(self.data)
            fall_time = cocotb.utils.get_sim_time()
            pulse_period = fall_time - rise_time
            if pulse_period > self.t_on:
                self.bits.append(1)
            elif pulse_period < self.t_off:
                self.bits.append(0)
        
        # do the bit shifting
        out = 0
        for bit in self.bits:
            out = (out << 1) | bit

        return out
        
async def reset(dut):
    dut.reset = 1
    await ClockCycles(dut.clk, 5)
    dut.reset = 0;
    await ClockCycles(dut.clk, 5)

async def load(dut, r, g, b, led):
    dut.rgb_data = (r << 16) + (g << 8) + b
    dut.led_num = led
    await RisingEdge(dut.clk)
    dut.write = 1
    await RisingEdge(dut.clk)
    dut.write = 0

@cocotb.test()
async def test_ws2812(dut):
    clock = Clock(dut.clk, 100, units="ns") # 10mhz
    cocotb.fork(clock.start())

    ws2812_led = WS2812_LED(dut.data)

    await reset(dut)

    for led in range(8):
        await load(dut, 0x40, 0x20, 0x10, led) 

    led_data = await ws2812_led.read()
    
    assert led_data == 0x402010402010402010402010402010402010402010402010

