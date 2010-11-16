//----------------------------------------------------------------------
//   Copyright 2007-2010 Mentor Graphics Corporation
//   Copyright 2007-2010 Cadence Design Systems, Inc.
//   Copyright 2010 Synopsys, Inc.
//   All Rights Reserved Worldwide
//
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//----------------------------------------------------------------------

`ifndef UBUS_DEMO_TB_SV
`define UBUS_DEMO_TB_SV

`include "ubus_demo_scoreboard.sv"
`include "ubus_master_seq_lib.sv"
`include "ubus_example_master_seq_lib.sv"
`include "ubus_slave_seq_lib.sv"


//------------------------------------------------------------------------------
//
// CLASS: ubus_demo_tb
//
//------------------------------------------------------------------------------

class ubus_demo_tb extends uvm_env;

  // Provide implementations of virtual methods such as get_type_name and create
  `uvm_component_utils(ubus_demo_tb)

  // ubus environment
  ubus_env ubus0;

  // Scoreboard to check the memory operation of the slave.
  ubus_demo_scoreboard scoreboard0;

  // new
  function new (string name, uvm_component parent=null);
    super.new(name, parent);
  endfunction : new

  // build
  virtual function void build();
    super.build();
    set_config_int("ubus0", "num_masters", 1);
    set_config_int("ubus0", "num_slaves", 1);
    ubus0 = ubus_env::type_id::create("ubus0", this);
    scoreboard0 = ubus_demo_scoreboard::type_id::create("scoreboard0", this);
  endfunction : build

  function void connect();
    // Connect slave0 monitor to scoreboard
    ubus0.slaves[0].monitor.item_collected_port.connect(
      scoreboard0.item_collected_export);
  endfunction : connect

  function void end_of_elaboration();
    // Set up slave address map for ubus0 (basic default)
    ubus0.set_slave_address_map("slaves[0]", 0, 16'hffff);
  endfunction : end_of_elaboration

endclass : ubus_demo_tb

`endif // UBUS_DEMO_TB_SV

