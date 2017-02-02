Library IEEE;
use ieee.fixed_float_types.all;
--!ieee_proposed for fixed point
use ieee.fixed_pkg.all;
--!ieee_proposed for floating point
use ieee.float_pkg.all;

package expdecay is

function CONDUCTANCE (dt : in natural) return float32;

-- other similar function definitions

end expdecay;

package body expdecay is

function CONDUCTANCE (dt : in natural) return float32 is

variable	g_syn : float32 := (others =>'0');
	begin
		case dt is	 
			when 0=> g_syn := to_float(1.0,g_syn);
			when 1=> g_syn := to_float(2.8396562499e-26,g_syn);
			when 2=> g_syn := to_float(8.06364761761e-52,g_syn);
			when 3=> g_syn := to_float(2.28979873544e-77,g_syn);
			when 4=> g_syn := to_float(6.5022412901e-103,g_syn);
			when 5=> g_syn := to_float(1.84641301178e-128,g_syn);
			when 6=> g_syn := to_float(5.2431782488e-154,g_syn);
			when 7=> g_syn := to_float(1.48888238836e-179,g_syn);
			when 8=> g_syn := to_float(4.22791417946e-205,g_syn);
			when 9=> g_syn := to_float(1.20058229238e-230,g_syn);
			when 10=> g_syn := to_float(3.40924101007e-256,g_syn);
			when 11=> g_syn := to_float(9.68107254166e-282,g_syn);
			when 12=> g_syn := to_float(2.74909181487e-307,g_syn);
			when others=> g_syn := to_float(0.0,g_syn);
		end case;
		return g_syn;
	end CONDUCTANCE;
end;