`include "uvm_pkg.sv"

module p;

import uvm_pkg::*;

class comp1 extends uvm_component;
   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction

   task main();
      `uvm_info("comp1", "main thread started...", UVM_LOW);
      #5000;
      `uvm_info("comp1", "main thread completed...", UVM_LOW);
   endtask

   virtual task run();
      enable_stop_interrupt = 1;
      `uvm_info("comp1", "run phase started...", UVM_LOW);
      fork
         main();
      join_none
      #100;
      `uvm_info("comp1", "run phase ended...", UVM_LOW);
   endtask

   task interrupt();
      `uvm_info("comp1", "interrupt thread started...", UVM_LOW);
      #1000;
      `uvm_info("comp1", "interrupt thread completed...", UVM_LOW);
   endtask

   virtual task stop(string ph_name);
      `uvm_info("comp1", {"stop ", ph_name, " phase started..."}, UVM_LOW);
      fork
         interrupt();
      join_none
      #100;
      `uvm_info("comp1", {"stop ", ph_name, " phase ended..."}, UVM_LOW);
   endtask

   virtual function void extract();
      `uvm_info("comp1", "extract phase started...", UVM_LOW);
      if ($time() != 600) begin
         `uvm_error("test", $psprintf("extract() phase started at %0d instead of 600.", $time));
      end
   endfunction

   virtual function void report();
      $write("** UVM TEST PASSED **\n");
   endfunction
endclass


class test extends uvm_test;
   `uvm_component_utils(test)
   function new(string name, uvm_component parent);
      super.new(name,parent);
   endfunction
endclass


initial
begin
   comp1 c = new("c", null);
   fork
      run_test;
   join_none
   #500 global_stop_request;
end


endmodule