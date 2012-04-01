//
//------------------------------------------------------------------------------
//   Copyright 2007-2010 Mentor Graphics Corporation
//   Copyright 2007-2011 Cadence Design Systems, Inc. 
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
//------------------------------------------------------------------------------

`ifndef UVM_REPORT_SERVER_SVH
`define UVM_REPORT_SERVER_SVH

typedef class uvm_report_object;

//------------------------------------------------------------------------------
//
// CLASS: uvm_report_server
//
// uvm_report_server is a global server that processes all of the reports
// generated by an uvm_report_handler. None of its methods are intended to be
// called by normal testbench code, although in some circumstances the virtual
// methods process_report and/or compose_uvm_info may be overloaded in a
// subclass.
//
//------------------------------------------------------------------------------

class uvm_report_server extends uvm_object;

  local int m_quit_count;
  local int m_max_quit_count; 
  bit max_quit_overridable = 1;
  local int m_severity_count[uvm_severity_type];
  protected int m_id_count[string];
  // Probably needs documented.
  bit enable_report_id_count_summary=1;

// Reconsider show_verbosity bit and possibly show_terminator

  static protected uvm_report_server m_global_report_server = get_server();


  `uvm_object_utils(uvm_report_server)


  // Function: new
  //
  // Creates the central report server, if not already created. Else, does
  // nothing. The constructor is protected to enforce a singleton.

  function new(string name = "uvm_report_server");
    super.new(name);
    set_max_quit_count(0);
    reset_quit_count();
    reset_severity_counts();
  endfunction

  // Copy to support the set_server() method
  virtual function void do_copy (uvm_object rhs);

    uvm_report_server rs;
    uvm_severity_type l_severity_count_index;
    string l_id_count_index;

    super.do_copy(rhs);
    if(!$cast(rs, rhs) || (rs==null)) return;

    m_quit_count = rs.m_quit_count;
    m_max_quit_count = rs.m_max_quit_count;
    max_quit_overridable = rs.max_quit_overridable;

    // Copy the severity counts
    if (rs.m_severity_count.first(l_severity_count_index))
      do
        m_severity_count[l_severity_count_index] 
          = rs.m_severity_count[l_severity_count_index];
      while (rs.m_severity_count.next(l_severity_count_index));
  
    // Copy the id counts
    if (rs.m_id_count.first(l_id_count_index))
      do
        m_id_count[l_id_count_index] 
          = rs.m_id_count[l_id_count_index];
      while (rs.m_id_count.next(l_id_count_index));
  
    enable_report_id_count_summary = rs.enable_report_id_count_summary;

  endfunction


  // Print to show report server state
  virtual function void do_print (uvm_printer printer);

    uvm_severity_type l_severity_count_index;
    string l_id_count_index;

    printer.print_int("quit_count", m_quit_count, $bits(m_quit_count), UVM_DEC,
      ".", "int");
    printer.print_int("max_quit_count", m_max_quit_count,
      $bits(m_max_quit_count), UVM_DEC, ".", "int");
    printer.print_int("max_quit_overridable", max_quit_overridable,
      $bits(max_quit_overridable), UVM_BIN, ".", "bit");

    if (m_severity_count.first(l_severity_count_index)) begin
      printer.print_array_header("severity_count",m_severity_count.size(),"severity counts");
      do
        printer.print_int($sformatf("[%s]",l_severity_count_index.name()),
          m_severity_count[l_severity_count_index], 32, UVM_DEC);
      while (m_severity_count.next(l_severity_count_index));
      printer.print_array_footer();
    end

    if (m_id_count.first(l_id_count_index)) begin
      printer.print_array_header("id_count",m_id_count.size(),"id counts");
      do
        printer.print_int($sformatf("[%s]",l_id_count_index),
          m_id_count[l_id_count_index], 32, UVM_DEC);
      while (m_id_count.next(l_id_count_index));
      printer.print_array_footer();
    end

    printer.print_int("enable_report_id_count_summary", enable_report_id_count_summary,
      $bits(enable_report_id_count_summary), UVM_BIN, ".", "bit");

  endfunction


  //----------------------------------------------------------------------------
  // Group: Report Server Configuration
  //----------------------------------------------------------------------------


  // Function: set_server
  //
  // Sets the global report server to use for reporting. The report
  // server is responsible for formatting messages.

  static function void set_server(uvm_report_server server);
    if(m_global_report_server != null) begin
      server.copy(m_global_report_server);
    end
    m_global_report_server = server;
  endfunction


  // Function: get_server
  //
  // Gets the global report server. The method will always return 
  // a valid handle to a report server.

  static function uvm_report_server get_server();
    if (m_global_report_server == null)
      m_global_report_server = new();
    return m_global_report_server;
  endfunction


  //----------------------------------------------------------------------------
  // Group: Quit Count
  //----------------------------------------------------------------------------


  // Function: set_max_quit_count

  function void set_max_quit_count(int count, bit overridable = 1);
    if (max_quit_overridable == 0) begin
      uvm_report_info("NOMAXQUITOVR", 
        $sformatf("The max quit count setting of %0d is not overridable to %0d due to a previous setting.", 
        m_max_quit_count, count), UVM_NONE);
      return;
    end
    max_quit_overridable = overridable;
    m_max_quit_count = count < 0 ? 0 : count;
  endfunction

  // Function: get_max_quit_count
  //
  // Get or set the maximum number of COUNT actions that can be tolerated
  // before an UVM_EXIT action is taken. The default is 0, which specifies
  // no maximum.

  function int get_max_quit_count();
    return m_max_quit_count;
  endfunction


  // Function: set_quit_count

  function void set_quit_count(int quit_count);
    m_quit_count = quit_count < 0 ? 0 : quit_count;
  endfunction

  // Function: get_quit_count

  function int get_quit_count();
    return m_quit_count;
  endfunction

  // Function: incr_quit_count

  function void incr_quit_count();
    m_quit_count++;
  endfunction

  // Function: reset_quit_count
  //
  // Set, get, increment, or reset to 0 the quit count, i.e., the number of
  // COUNT actions issued.

  function void reset_quit_count();
    m_quit_count = 0;
  endfunction

  // Function: is_quit_count_reached
  //
  // If is_quit_count_reached returns 1, then the quit counter has reached
  // the maximum.

  function bit is_quit_count_reached();
    return (m_quit_count >= m_max_quit_count);
  endfunction


  //----------------------------------------------------------------------------
  // Group: Severity Count
  //----------------------------------------------------------------------------
 

  // Function: set_severity_count

  function void set_severity_count(uvm_severity severity, int count);
    m_severity_count[severity] = count < 0 ? 0 : count;
  endfunction

  // Function: get_severity_count

  function int get_severity_count(uvm_severity severity);
    return m_severity_count[severity];
  endfunction

  // Function: incr_severity_count

  function void incr_severity_count(uvm_severity severity);
    m_severity_count[severity]++;
  endfunction

  // Function: reset_severity_counts
  //
  // Set, get, or increment the counter for the given severity, or reset
  // all severity counters to 0.

  function void reset_severity_counts();
    uvm_severity_type s;
    s = s.first();
    forever begin
      m_severity_count[s] = 0;
      if(s == s.last()) break;
      s = s.next();
    end
  endfunction


  //----------------------------------------------------------------------------
  // Group: Severity Count
  //----------------------------------------------------------------------------


  // Function: set_id_count

  function void set_id_count(string id, int count);
    m_id_count[id] = count < 0 ? 0 : count;
  endfunction

  // Function: get_id_count

  function int get_id_count(string id);
    if(m_id_count.exists(id))
      return m_id_count[id];
    return 0;
  endfunction

  // Function: incr_id_count
  //
  // Set, get, or increment the counter for reports with the given id.

  function void incr_id_count(string id);
    if(m_id_count.exists(id))
      m_id_count[id]++;
    else
      m_id_count[id] = 1;
  endfunction


  // Function- f_display
  //
  // This method sends string severity to the command line if file is 0 and to
  // the file(s) specified by file if it is not 0.

  function void f_display(UVM_FILE file, string str);
    if (file == 0)
      $display("%s", str);
    else
      $fdisplay(file, "%s", str);
  endfunction


  // Function- m_process
  //
  //

  virtual function void m_process(uvm_report_message urm);

    bit report_ok = 1;

    // Set the report server for this message
    urm.rs = this;

`ifndef UVM_NO_DEPRECATED 


    // The hooks can do additional filtering.  If the hook function
    // return 1 then continue processing the report.  If the hook
    // returns 0 then skip processing the report.

    if(urm.action & UVM_CALL_HOOK)
      report_ok = urm.rh.run_hooks(urm.ro, urm.severity, urm.id,
        urm.message, urm.verbosity, urm.filename, urm.line);


`endif


    if(report_ok)
      report_ok = uvm_report_catcher::process_all_report_catchers(urm);

    if(report_ok) begin	


`ifdef UVM_DEPRECATED_REPORTING


      // Make these rm.xxx
      string m;
      m = compose_message(urm.severity, urm.rh.get_full_name(), urm.id, 
        urm.message, urm.filename, urm.line); 
      process_report(urm.severity, urm.rh.get_full_name(), urm.id, 
        urm.message, urm.action, urm.file, urm.filename, urm.line, m, 
        urm.verbosity, urm.ro);

`else

      execute(urm);

`endif


    end
  
  endfunction


  // Function: execute 
  //
  // Processes the message's actions.
 
  virtual function void execute(uvm_report_message urm);
    // Update counts 
    incr_severity_count(urm.severity);
    incr_id_count(urm.id);
    // Process UVM_RM_RECORD action (send to recorder)
    if(urm.action & UVM_RM_RECORD) 
      uvm_default_recorder.record_message(urm);
    // Process UVM_DISPLAY and UVM_LOG action (send to logger)
    if((urm.action & UVM_DISPLAY) || (urm.action & UVM_LOG)) begin
      string out_str;
      out_str = compose(urm);
      // DISPLAY action
      if(urm.action & UVM_DISPLAY)
        $display("%s", out_str);
      // if log is set we need to send to the file but not resend to the
      // display. So, we need to mask off stdout for an mcd or we need
      // to ignore the stdout file handle for a file handle.
      if(urm.action & UVM_LOG)
        if( (urm.file == 0) || (urm.file != 32'h8000_0001) ) begin //ignore stdout handle
          UVM_FILE tmp_file = urm.file;
          if((urm.file & 32'h8000_0000) == 0) begin //is an mcd so mask off stdout
            tmp_file = urm.file & 32'hffff_fffe;
          end
        f_display(tmp_file, out_str);
      end    
    end
    // Process the UVM_COUNT action
    if(urm.action & UVM_COUNT) begin
      if(get_max_quit_count() != 0) begin
        incr_quit_count();
        // If quit count is reached, add the UVM_EXIT action.
        if(is_quit_count_reached()) begin
          urm.action |= UVM_EXIT;
        end
      end  
    end
    // Process the UVM_EXIT action
    if(urm.action & UVM_EXIT) begin
      uvm_root l_root = uvm_root::get();
      l_root.die();
    end
    // Process the UVM_STOP action
    if (urm.action & UVM_STOP) 
      $stop;
  endfunction


  // Function: compose
  //
  // Constructs the actual string sent to the file or command line
  // from the severity, component name, report id, and the message itself. 
  //
  // Expert users can overload this method to customize report formatting.
  virtual function string compose(uvm_report_message urm);

    string sev_string;
    uvm_verbosity l_verbosity;
    string filename_line_string;
    string time_str;
    string line_str;
    string context_str;

    sev_string = urm.severity.name();

    if (urm.filename != "") begin
      $swrite(line_str, "%0d", urm.line);
      filename_line_string = {urm.filename, "(", line_str, ") "};
    end

    // Make definable in terms of units.
    $swrite(time_str, "%0t", $time);
 
    if (urm.context_name != "")
      context_str = {"@@", urm.context_name};

    compose = {sev_string, " ", filename_line_string, "@ ", time_str, ": ",
      urm.rh.get_full_name(), context_str, " [", urm.id, "] ", 
      urm.convert2string()};

  endfunction 


  // Function- report_relnotes_banner
  //

  static local bit m_relnotes_done;
  function void report_relnotes_banner(UVM_FILE file = 0);
    uvm_report_server srvr;

    if (m_relnotes_done) return;
     
    f_display(file,
      "\n  ***********       IMPORTANT RELEASE NOTES         ************");
       f_display(file, "\n  You are using a version of the UVM library that has been compiled");
       f_display(file, "  with `UVM_NO_DEPRECATED undefined.");
       f_display(file, "  See http://www.eda.org/svdb/view.php?id=3313 for more details.");
     
    m_relnotes_done = 1;
  endfunction


  // Function: report_header
  //
  // Prints version and copyright information. This information is sent to the
  // command line if ~file~ is 0, or to the file descriptor ~file~ if it is not 0. 
  // The <uvm_root::run_test> task calls this method just before it component
  // phasing begins.

  function void report_header(UVM_FILE file = 0);

    f_display(file,
      "----------------------------------------------------------------");
    f_display(file, uvm_revision_string());
    f_display(file, uvm_mgc_copyright);
    f_display(file, uvm_cdn_copyright);
    f_display(file, uvm_snps_copyright);
    f_display(file, uvm_cy_copyright);
    f_display(file,
      "----------------------------------------------------------------");

    begin
       uvm_cmdline_processor clp;
       string args[$];
     
       clp = uvm_cmdline_processor::get_inst();

       if (clp.get_arg_matches("+UVM_NO_RELNOTES", args)) return;

`ifndef UVM_NO_DEPRECATED
       report_relnotes_banner(file);
`endif

`ifndef UVM_OBJECT_MUST_HAVE_CONSTRUCTOR
       report_relnotes_banner(file);
       f_display(file, "\n  You are using a version of the UVM library that has been compiled");
       f_display(file, "  with `UVM_OBJECT_MUST_HAVE_CONSTRUCTOR undefined.");
       f_display(file, "  See http://www.eda.org/svdb/view.php?id=3770 for more details.");
`endif

       if (m_relnotes_done)
          f_display(file, "\n      (Specify +UVM_NO_RELNOTES to turn off this notice)\n");

    end
  endfunction


  // Function: report_summarize
  //
  // Outputs statistical information on the reports issued by this central report
  // server. This information will be sent to the command line if ~file~ is 0, or
  // to the file descriptor ~file~ if it is not 0.
  //
  // The run_test method in uvm_top calls this method.

  virtual function void report_summarize(UVM_FILE file=0);
    string id;
    string name;
    string output_str;
    uvm_report_catcher::summarize_report_catcher(file);
    f_display(file, "");
    f_display(file, "--- UVM Report Summary ---");
    f_display(file, "");

    if(m_max_quit_count != 0) begin
      if ( m_quit_count >= m_max_quit_count ) f_display(file, "Quit count reached!");
      $sformat(output_str, "Quit count : %5d of %5d",
                             m_quit_count, m_max_quit_count);
      f_display(file, output_str);
    end

    f_display(file, "** Report counts by severity");
    for(uvm_severity_type s = s.first(); 1; s = s.next()) begin
      if(m_severity_count.exists(s)) begin
        int cnt;
        cnt = m_severity_count[s];
        name = s.name();
        $sformat(output_str, "%s :%5d", name, cnt);
        f_display(file, output_str);
      end
      if(s == s.last()) break;
    end

    if (enable_report_id_count_summary) begin

      f_display(file, "** Report counts by id");
      for(int found = m_id_count.first(id);
           found;
           found = m_id_count.next(id)) begin
        int cnt;
        cnt = m_id_count[id];
        $sformat(output_str, "[%s] %5d", id, cnt);
        f_display(file, output_str);
      end

    end

  endfunction


`ifndef UVM_NO_DEPRECATED


  // Function- process_report
  //
  // Calls <compose_message> to construct the actual message to be
  // output. It then takes the appropriate action according to the value of
  // action and file. 
  //
  // This method can be overloaded by expert users to customize the way the
  // reporting system processes reports and the actions enabled for them.

  virtual function void process_report(
      uvm_severity severity,
      string name,
      string id,
      string message,
      uvm_action action,
      UVM_FILE file,
      string filename,
      int line,
      string composed_message,
      int verbosity_level,
      uvm_report_object client
      );
    // update counts
    incr_severity_count(severity);
    incr_id_count(id);

    if(action & UVM_DISPLAY)
      $display("%s",composed_message);

    // if log is set we need to send to the file but not resend to the
    // display. So, we need to mask off stdout for an mcd or we need
    // to ignore the stdout file handle for a file handle.
    if(action & UVM_LOG)
      if( (file == 0) || (file != 32'h8000_0001) ) //ignore stdout handle
      begin
        UVM_FILE tmp_file = file;
        if( (file&32'h8000_0000) == 0) //is an mcd so mask off stdout
        begin
           tmp_file = file & 32'hffff_fffe;
        end
        f_display(tmp_file,composed_message);
      end    

    if(action & UVM_EXIT) begin
      uvm_root l_root = uvm_root::get();
      l_root.die();
    end

    if(action & UVM_COUNT) begin
      if(get_max_quit_count() != 0) begin
          incr_quit_count();
        if(is_quit_count_reached()) begin
          uvm_root l_root = uvm_root::get();
          l_root.die();
        end
      end  
    end

    if (action & UVM_STOP) $stop;

  endfunction

  
  // Function- compose_message
  //
  // Constructs the actual string sent to the file or command line
  // from the severity, component name, report id, and the message itself. 
  //
  // Expert users can overload this method to customize report formatting.

  virtual function string compose_message(
      uvm_severity severity,
      string name,
      string id,
      string message,
      string filename,
      int    line
      );
    uvm_severity_type sv;
    string time_str;
    string line_str;
    
    sv = uvm_severity_type'(severity);
    $swrite(time_str, "%0t", $realtime);
 
    case(1)
      (name == "" && filename == ""):
	       return {sv.name(), " @ ", time_str, " [", id, "] ", message};
      (name != "" && filename == ""):
	       return {sv.name(), " @ ", time_str, ": ", name, " [", id, "] ", message};
      (name == "" && filename != ""):
           begin
               $swrite(line_str, "%0d", line);
		 return {sv.name(), " ",filename, "(", line_str, ")", " @ ", time_str, " [", id, "] ", message};
           end
      (name != "" && filename != ""):
           begin
               $swrite(line_str, "%0d", line);
	         return {sv.name(), " ", filename, "(", line_str, ")", " @ ", time_str, ": ", name, " [", id, "] ", message};
           end
    endcase
  endfunction 


  // Function- summarize
  //

  virtual function void summarize(UVM_FILE file=0);
    report_summarize(file);
  endfunction


  // Function: dump_server_state
  //
  // Dumps server state information.

  function void dump_server_state();

    string s;
    uvm_severity_type sev;
    string id;

    f_display(0, "report server state");
    f_display(0, "");   
    f_display(0, "+-------------+");
    f_display(0, "|   counts    |");
    f_display(0, "+-------------+");
    f_display(0, "");

    $sformat(s, "max quit count = %5d", m_max_quit_count);
    f_display(0, s);
    $sformat(s, "quit count = %5d", m_quit_count);
    f_display(0, s);

    sev = sev.first();
    forever begin
      int cnt;
      cnt = m_severity_count[sev];
      s = sev.name();
      $sformat(s, "%s :%5d", s, cnt);
      f_display(0, s);
      if(sev == sev.last())
        break;
      sev = sev.next();
    end

    if(m_id_count.first(id))
    do begin
      int cnt;
      cnt = m_id_count[id];
      $sformat(s, "%s :%5d", id, cnt);
      f_display(0, s);
    end
    while (m_id_count.next(id));

  endfunction


`endif


endclass



`ifndef UVM_NO_DEPRECATED


//----------------------------------------------------------------------
// CLASS- uvm_report_global_server
//
// Singleton object that maintains a single global report server
//----------------------------------------------------------------------
class uvm_report_global_server;

  function new();
    void'(get_server());
  endfunction


  // Function- get_server
  //
  // Returns a handle to the central report server.

  function uvm_report_server get_server();
    return uvm_report_server::get_server();
  endfunction


  // Function- set_server (deprecated)
  //
  //

  function void set_server(uvm_report_server server);
    uvm_report_server::set_server(server);
  endfunction

endclass


`endif


`endif // UVM_REPORT_SERVER_SVH
