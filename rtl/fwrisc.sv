/****************************************************************************
 * fwrisc.sv
 *
 * Copyright 2018 Matthew Ballance
 * 
 * Licensed under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in
 * compliance with the License.  You may obtain a copy of
 * the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in
 * writing, software distributed under the License is
 * distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied.  See
 * the License for the specific language governing
 * permissions and limitations under the License.
 ****************************************************************************/
 
/**
 * Module: fwrisc
 * 
 * Featherweight RISC-V implementation
 */
module fwrisc #(
		parameter ENABLE_COMPRESSED=1,
		parameter ENABLE_MUL=1,
		parameter ENABLE_DEP=1,
		parameter ENABLE_COUNTERS=1
		) (
		input			clock,
		input			reset,
		
		output[31:0]	iaddr,
		input[31:0]		idata,
		output			ivalid,
		input			iready,
		
		output[31:0]	daddr,
		output[31:0]	dwdata,
		input[31:0]		drdata,
		output[3:0]		dstrb,
		output			dwrite,
		output			dvalid,
		input			dready
		);
	
	wire[31:0]				pc;
	wire[31:0]				pc_seq;
	wire					fetch_valid;
	wire					instr_complete;
	wire[31:0]				instr;
	wire					instr_c;

	fwrisc_fetch #(
		.ENABLE_COMPRESSED  (ENABLE_COMPRESSED )
		) u_fetch (
		.clock              (clock             ), 
		.reset              (reset             ), 
		.next_pc            (pc                ), 
		.next_pc_seq        (pc_seq            ), 
		.iaddr              (iaddr             ), 
		.idata              (idata             ), 
		.ivalid             (ivalid            ), 
		.iready             (iready            ), 
		.fetch_valid        (fetch_valid       ), 
		.decode_complete    (instr_complete    ), 
		.instr              (instr             ), 
		.instr_c            (instr_c           ));

	wire[31:0]				ra_raddr;
	wire[31:0]				ra_rdata;
	wire[31:0]				rb_raddr;
	wire[31:0]				rb_rdata;
	wire					decode_valid;
	wire[31:0]				op_a;
	wire[31:0]				op_b;
	wire[31:0]				op_c;
	wire[5:0]				rd;
	wire[3:0]				op;
	wire[31:0]				rd_raddr;
	wire[4:0]				op_type;
	fwrisc_decode #(
		.ENABLE_COMPRESSED  (ENABLE_COMPRESSED )
		) u_decode (
		.clock              (clock             ), 
		.reset              (reset             ), 
		.fetch_valid        (fetch_valid       ), 
		.decode_ready       (decode_ready      ), 
		.instr_i            (instr             ), 
		.instr_c            (instr_c           ), 
		.pc                 (pc                ), 
		.ra_raddr           (ra_raddr          ), 
		.ra_rdata           (ra_rdata          ), 
		.rb_raddr           (rb_raddr          ), 
		.rb_rdata           (rb_rdata          ), 
		.decode_valid       (decode_valid      ), 
		.exec_ready         (exec_ready        ), 
		.op_a               (op_a              ), 
		.op_b               (op_b              ), 
		.op_c               (op_c              ), 
		.rd                 (rd                ), 
		.op                 (op                ), 
		.rd_raddr           (rd_raddr          ), 
		.op_type            (op_type           ));

	wire[5:0]				rd_waddr;
	wire[31:0]				rd_wdata;
	wire					rd_wen;
	fwrisc_exec #(
		.ENABLE_MUL_DIV  (ENABLE_MUL_DIV )
		) u_exec (
		.clock           (clock          ), 
		.reset           (reset          ), 
		.decode_valid    (decode_valid   ),
		.instr_complete  (instr_complete ), 
		.instr_c         (instr_c        ), 
		.op_type         (op_type        ), 
		.op_a            (op_a           ), 
		.op_b            (op_b           ), 
		.op              (op             ), 
		.op_c            (op_c           ), 
		.rd              (rd             ), 
		.rd_waddr        (rd_waddr       ), 
		.rd_wdata        (rd_wdata       ), 
		.rd_wen          (rd_wen         ), 
		.pc              (pc             ), 
		.pc_seq          (pc_seq         ));
	
	fwrisc_regfile #(
		.ENABLE_COUNTERS  (ENABLE_COUNTERS ),
		.ENABLE_DEP       (ENABLE_DEP      )
		) u_regfile (
		.clock            (clock           ), 
		.reset            (reset           ), 
		.instr_complete   (instr_complete  ), 
		.ra_raddr         (ra_raddr        ), 
		.ra_rdata         (ra_rdata        ), 
		.rb_raddr         (rb_raddr        ), 
		.rb_rdata         (rb_rdata        ), 
		.rd_waddr         (rd_waddr        ), 
		.rd_wdata         (rd_wdata        ), 
		.rd_wen           (rd_wen          ));


endmodule


