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

typedef class uvm_report_catcher;

typedef class uvm_default_report_server;
virtual class uvm_report_server extends uvm_object;
	function string get_type_name();
		return "uvm_report_server";
	endfunction
	function new(string name="base");
		super.new();
	endfunction 

	// Function: set_max_quit_count
	// ~count~ is the maximum number of ~UVM_QUIT~ actions the uvm_report_server
	// will tolerate before before invoking client.die().
	// when ~overridable~=0 is passed the set quit count cannot be changed again 
	pure virtual  function void set_max_quit_count(int count, bit overridable = 1);

	// Function: get_max_quit_count
	// returns the currently configured max quit count
	pure virtual  function int get_max_quit_count();

	// Function: set_quit_count
	// sets the current number of ~UVM_QUIT~ actions already passed through this uvm_report_server  
	pure virtual  function void set_quit_count(int quit_count);

	// Function: get_quit_count
	// returns the current number of ~UVM_QUIT~ actions already passed through this server  
	pure virtual  function int get_quit_count();

	// Function: set_severity_count
	// sets the count of already passed messages with severity ~severity~ to ~count~        
	pure virtual  function void set_severity_count(uvm_severity severity, int count);
	// Function: get_severity_count
	// returns the count of already passed messages with severity ~severity~    
	pure virtual  function int get_severity_count(uvm_severity severity);

	// Function: set_id_count
	// sets the count of already passed messages with ~id~ to ~count~   
	pure virtual  function void set_id_count(string id, int count);

	// Function: get_id_count
	// returns the count of already passed messages with ~id~
	pure virtual  function int get_id_count(string id);

	// Function: get_id_set
	// returns the set of id's already used by this uvm_report_server
	pure virtual function void get_id_set(output string q[$]);

	// Function: get_severity_set
	// returns the set of severities's already used by this uvm_report_server
	pure virtual function void get_severity_set(output uvm_severity q[$]);

	// Function: do_copy
	// copies all message statistic severity,id counts to the dest uvm_report_server
	// the copy is cummulative (only items from the source are transfered, already existing entries are not deleted,
	// existing entries/counts are overridden when they exist in the source set)
	function void do_copy (uvm_object rhs);
		uvm_report_server rhs_;

		super.do_copy(rhs);
		assert($cast(rhs_,rhs)) else `uvm_error("UVM/REPORT/SERVER/RPTCOPY","cannot copy to report_server from the given datatype")

		begin
			uvm_severity q[$];
			rhs_.get_severity_set(q);
			foreach(q[s])
				set_severity_count(q[s],rhs_.get_severity_count(q[s]));
		end

		begin
			string q[$];
			rhs_.get_id_set(q);
			foreach(q[s])
				set_id_count(q[s],rhs_.get_id_count(q[s]));
		end

		set_max_quit_count(rhs_.get_max_quit_count());
		set_quit_count(rhs_.get_quit_count());
	endfunction

	// *US* revisit after msg revamp merge

	// Function: report
	//
	// main entry for the uvm_report_server
	// combines compose_message, report_message
	pure virtual function void report(
		uvm_severity severity,
		string name,
		string id,
		string message,
		int verbosity_level,
		string filename,
		int line,
		uvm_report_object client
	);

	// Function: process_report
	//
	// Processes a composed message and performs the remaining actions
	// such as logging to the target channel, incrementing ids, counts

	pure virtual function void process_report(
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

	// Function: compose_message
	//
	// Constructs the actual string sent to the file or command line
	// from the severity, component name, report id, and the message itself. 
	//
	// Expert users can overload this method to customize report formatting.
	pure virtual function string compose_message(
		uvm_severity severity,
		string name,
		string id,
		string message,
		string filename,
		int    line
	);

	pure virtual function void summarize();

	// Function: set_server
	//
	// Sets the global report server to use for reporting. The report
	// server is responsible for formatting messages.
	// in addition to setting the server this also copies the severity/id counts
	// from the current report_server to the new one

	static function void set_server(uvm_report_server server);
		server.copy(uvm_coreservice.get_report_server());
		uvm_coreservice.set_report_server(server);
	endfunction


	// Function: get_server
	//
	// Gets the global report server. The method will always return 
	// a valid handle to a report server.

	static function uvm_report_server get_server();
		return uvm_coreservice.get_report_server();
	endfunction
endclass

class uvm_default_report_server extends uvm_report_server;

	local int max_quit_count; 
	local int quit_count;
	local int severity_count[uvm_severity];

	// Needed for callbacks
	function string get_type_name();
		return "uvm_default_report_server";
	endfunction

	// Variable: id_count
	//
	// An associative array holding the number of occurences
	// for each unique report ID.
	local int id_count[string];

	bit enable_report_id_count_summary=1;


	// Function: new
	//
	// Creates an instance of the class.

	function new();
		set_name("uvm_report_server");
		set_max_quit_count(0);
		reset_quit_count();
		reset_severity_counts();
	endfunction



	local bit m_max_quit_overridable = 1;


	function void set_max_quit_count(int count, bit overridable = 1);
		if (m_max_quit_overridable == 0) begin
			uvm_report_info("NOMAXQUITOVR", $sformatf("The max quit count setting of %0d is not overridable to %0d due to a previous setting.", max_quit_count, count), UVM_NONE);
			return;
		end
		m_max_quit_overridable = overridable;
		max_quit_count = count < 0 ? 0 : count;
	endfunction

	// Function: get_max_quit_count
	//
	// Get or set the maximum number of COUNT actions that can be tolerated
	// before an UVM_EXIT action is taken. The default is 0, which specifies
	// no maximum.

	function int get_max_quit_count();
		return max_quit_count;
	endfunction


	// Function: set_quit_count

	function void set_quit_count(int quit_count);
		quit_count = quit_count < 0 ? 0 : quit_count;
	endfunction

	// Function: get_quit_count

	function int get_quit_count();
		return quit_count;
	endfunction

	// Function: incr_quit_count

	function void incr_quit_count();
		quit_count++;
	endfunction

	// Function: reset_quit_count
	//
	// Set, get, increment, or reset to 0 the quit count, i.e., the number of
	// COUNT actions issued.

	function void reset_quit_count();
		quit_count = 0;
	endfunction

	// Function: is_quit_count_reached
	//
	// If is_quit_count_reached returns 1, then the quit counter has reached
	// the maximum.

	function bit is_quit_count_reached();
		return (quit_count >= max_quit_count);
	endfunction


	// Function: set_severity_count

	function void set_severity_count(uvm_severity severity, int count);
		severity_count[severity] = count < 0 ? 0 : count;
	endfunction

	// Function: get_severity_count

	function int get_severity_count(uvm_severity severity);
		return severity_count[severity];
	endfunction

	// Function: incr_severity_count

	function void incr_severity_count(uvm_severity severity);
		severity_count[severity]++;
	endfunction

	// Function: reset_severity_counts
	//
	// Set, get, or increment the counter for the given severity, or reset
	// all severity counters to 0.

	function void reset_severity_counts();
		uvm_severity s;
		s = s.first();
		forever begin
			severity_count[s] = 0;
			if(s == s.last()) break;
			s = s.next();
		end
	endfunction


	// Function: set_id_count

	function void set_id_count(string id, int count);
		id_count[id] = count < 0 ? 0 : count;
	endfunction

	// Function: get_id_count

	function int get_id_count(string id);
		return id_count[id];
	endfunction

	// Function: incr_id_count
	//
	// Set, get, or increment the counter for reports with the given id.

	function void incr_id_count(string id);
		if(id_count.exists(id))
			id_count[id]++;
		else
			id_count[id] = 1;
	endfunction

	virtual function void get_severity_set(output uvm_severity q[$]); 
		foreach(severity_count[idx])
			q.push_back(idx);
	endfunction


	virtual function void get_id_set(output string q[$]);
		foreach(id_count[idx])
			q.push_back(idx);
	endfunction 

	// f_display
	//
	// This method sends string severity to the command line if file is 0 and to
	// the file(s) specified by file if it is not 0.

	function void f_display(UVM_FILE file, string str);
		if (file == 0)
			$display("%s", str);
		else
			$fdisplay(file, "%s", str);
	endfunction



	virtual function void report(
			uvm_severity severity,
			string name,
			string id,
			string message,
			int verbosity_level,
			string filename,
			int line,
			uvm_report_object client
		);
		string m;
		uvm_action a;
		UVM_FILE f;
		bit report_ok;
		uvm_report_handler rh;

		rh = client.get_report_handler();

		// filter based on verbosity level

		if(!client.uvm_report_enabled(verbosity_level, severity, id)) begin
			return;
		end

		// determine file to send report and actions to execute

		a = rh.get_action(severity, id); 
		if( uvm_action_type'(a) == UVM_NO_ACTION )
			return;

		f = rh.get_file_handle(severity, id);

		// The hooks can do additional filtering.  If the hook function
		// return 1 then continue processing the report.  If the hook
		// returns 0 then skip processing the report.

		if(a & UVM_CALL_HOOK)
			report_ok = rh.run_hooks(client, severity, id,
			message, verbosity_level, filename, line);
		else
			report_ok = 1;

		if(report_ok)
			report_ok = uvm_report_catcher::process_all_report_catchers(
				this, client, severity, name, id, message,
			verbosity_level, a, filename, line);

		if(report_ok) begin 
			// give the global server a chance to intercept the calls
			uvm_report_server svr = uvm_coreservice.get_report_server();
			// no need to compose when neither UVM_DISPLAY nor UVM_LOG is set
			if(a & (UVM_LOG|UVM_DISPLAY))
				m = svr.compose_message(severity, name, id, message, filename, line); 
			svr.process_report(severity, name, id, message, a, f, filename,
				line, m, verbosity_level, client);
		end

	endfunction

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

		if(action & UVM_EXIT) client.die();

		if(action & UVM_COUNT) begin
			if(get_max_quit_count() != 0) begin
				incr_quit_count();
				if(is_quit_count_reached()) begin
					client.die();
				end
			end  
		end

		if (action & UVM_STOP) $stop;

	endfunction




	virtual function string compose_message(
			uvm_severity severity,
			string name,
			string id,
			string message,
			string filename,
			int    line
		);
		uvm_severity sv;
		string time_str;
		string line_str;

		$swrite(time_str, "%0t", $realtime);

		case(1)
			(name == "" && filename == ""):
				return {severity.name(), " @ ", time_str, " [", id, "] ", message};
			(name != "" && filename == ""):
				return {severity.name(), " @ ", time_str, ": ", name, " [", id, "] ", message};
			(name == "" && filename != ""):
			begin
				$swrite(line_str, "%0d", line);
				return {severity.name(), " ",filename, "(", line_str, ")", " @ ", time_str, " [", id, "] ", message};
			end
			(name != "" && filename != ""):
			begin
				$swrite(line_str, "%0d", line);
				return {severity.name(), " ", filename, "(", line_str, ")", " @ ", time_str, ": ", name, " [", id, "] ", message};
			end
		endcase
	endfunction 

	virtual function void summarize();
		string id;
		string name;
		string output_str;
		string q[$];

		uvm_report_catcher::summarize();
		q.push_back("\n--- UVM Report Summary ---\n\n");

		if(max_quit_count != 0) begin
			if ( quit_count >= max_quit_count ) 
				q.push_back("Quit count reached!\n");
			q.push_back($sformatf("Quit count : %5d of %5d\n",quit_count, max_quit_count));
		end

		q.push_back("** Report counts by severity\n");
		foreach(severity_count[s]) begin
			q.push_back($sformatf("%s :%5d\n", s.name(), severity_count[s]));
		end 

		if (enable_report_id_count_summary) begin
			q.push_back("** Report counts by id\n");
			foreach(id_count[id])
				q.push_back($sformatf("[%s] %5d\n", id, id_count[id]));
		end

		`uvm_info("UVM/REPORT/SERVER",`UVM_STRING_QUEUE_STREAMING_PACK(q),UVM_LOW)
	endfunction

endclass

`endif // UVM_REPORT_SERVER_SVH
