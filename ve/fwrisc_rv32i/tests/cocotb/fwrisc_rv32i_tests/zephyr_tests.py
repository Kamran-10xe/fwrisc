'''
Created on Nov 23, 2019

@author: ballance
'''
import cocotb
from cocotb.bfms import BfmMgr
from fwrisc_rv32i_tests.instr_tests import InstrTests
from fwrisc_tracer_bfm.fwrisc_tracer_signal_bfm import FwriscTracerSignalBfm

from elftools.elf.elffile import ELFFile
from elftools.elf.sections import SymbolTableSection
from sys import stdout


class ZephyrTests(InstrTests):
    
    def __init__(self, tracer_bfm):
        super().__init__(tracer_bfm)
        
        sw_image = cocotb.plusargs["SW_IMAGE"]

        self.raw_console = False
        self.console_buffer = ""        
        with open(sw_image, "rb") as f:
            elffile = ELFFile(f)
            
            symtab = elffile.get_section_by_name(".symtab")
            
            self.ram_console_addr = symtab.get_symbol_by_name("ram_console")[0]["st_value"]
            tracer_bfm.add_addr_region(self.ram_console_addr, self.ram_console_addr+1023)
        

    def instr_exec(self, pc, instr):
#        print("instr_exec: " + hex(pc))
#        InstrTests.instr_exec(self, pc, instr)
        pass
    
    def mem_write(self, maddr, mstrb, mdata):
        if maddr >= self.ram_console_addr and maddr < self.ram_console_addr+1024 and mdata != 0:
            ch = 0
            if mstrb == 1:
                ch = ((mdata >> 0) & 0xFF)
            elif mstrb == 2:
                ch = ((mdata >> 8) & 0xFF)
            elif mstrb == 4:
                ch = ((mdata >> 16) & 0xFF)
            elif mstrb == 8:
                ch = ((mdata >> 24) & 0xFF)
                
            ch = str(chr(ch))
            if self.raw_console:
                stdout.write(ch)
                stdout.flush()
            elif ch == "\n":
                print(self.console_buffer)
                self.console_buffer = ""
                stdout.flush()
            else:
                self.console_buffer += ch
                

    @cocotb.coroutine
    def run(self):
        yield self.test_done_ev.wait()
        pass

    @cocotb.coroutine        
    def check(self):
        print("Check")
        pass
        

@cocotb.test()
def runtest(dut):
    use_tf_bfm = True
   
    if use_tf_bfm: 
        tracer_bfm = BfmMgr.find_bfm(".*u_tracer")
        tracer_bfm.set_trace_reg_writes(0)
        tracer_bfm.set_trace_instr(0, 0, 1)
        tracer_bfm.set_trace_all_memwrite(0)
    else:
        tracer_bfm = FwriscTracerSignalBfm(dut.u_dut.u_tracer)
    test = ZephyrTests(tracer_bfm)
    tracer_bfm.add_listener(test)
    
    
    yield test.run()
    
