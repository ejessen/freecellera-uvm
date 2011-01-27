import uvm_pkg::uvm_component;
import uvm_pkg::uvm_resource;
import uvm_pkg::uvm_resource_db;

import uvm_pkg::*;
`include "uvm_macros.svh"

function int unsigned rand_delay(int unsigned max = 19);
  return ( $urandom() % max ) + 1;
endfunction

//----------------------------------------------------------------------
// env
//
// The test consists of a pair of processes each of which read an write
// from a single resource.  One process does so using the normal
// non-locking interface, the other uses the locking interface.  When
// the resource is locked and the process using the non-locking
// interface attempts to read or write the value then an error is
// generated.
//----------------------------------------------------------------------
class env extends uvm_component;

  uvm_resource#(int) r;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build();
    r = uvm_resource_db#(int)::get_by_name(get_full_name(), "A");
  endfunction

  task run();

    fork
      locking();
      nonlocking();
    join

  endtask

  //-----------------------------------
  // locking process
  //-----------------------------------
  task locking();
    int i;
    int unsigned d;

    forever begin
      d = rand_delay();
      # d;
      r.read_with_lock(i, this);
      $display("%0t:    locking:  i = %0d", $time, i);

      d = rand_delay();
      # d;
      i++;
      r.write_with_lock(i, this);
    end

  endtask

  //-----------------------------------
  // non-locking process
  //-----------------------------------
  task nonlocking();
    int i;
    int unsigned d;

    forever begin
      i = r.read(this);
      $display("%0t: nonlocking:  i = %0d", $time, i);
      d = rand_delay();
      # d

      i++;
      r.write(i, this);
      d = rand_delay();
      # d;
    end

  endtask

endclass

//----------------------------------------------------------------------
// test
//----------------------------------------------------------------------
class test extends uvm_component;

  `uvm_component_utils(test);

  env e;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build();
    e = new("env", this);

    uvm_resource_db#(int)::set("*", "A", 0, this);
  endfunction

  task run();
    uvm_report_server srvr = get_report_server();

    #500;
    $display("UVM TEST EXPECT %0d UVM_ERROR", srvr.get_severity_count(UVM_ERROR));
    $display("** UVM TEST PASSED **");
    global_stop_request();
  endtask

endclass

//----------------------------------------------------------------------
// top
//----------------------------------------------------------------------
module top;
  initial run_test();
endmodule