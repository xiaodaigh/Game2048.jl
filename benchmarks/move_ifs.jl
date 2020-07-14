"""
	Perform a move left using if statements
"""
function move_ifs!(x)
	@inbounds if x[1] == 0
		# 0XXX
		if x[2] == 0
			# 00XX
			if x[3] == 0
				# 000A -> A000
				x[1], x[4] = x[4], 0
			elseif x[3] == x[4]
				# 00AA -> 2A000
				x[1], x[3], x[4] = 1+x[3], 0 , 0
			else
				# 00AB - AB00
				x[1], x[2], x[3], x[4] = x[3], x[4], 0, 0
			end
		else
			# 0AXX
			if x[3] == 0
				# 0A0X
				if x[4] == x[2]
					# 0A0A -> 2A000
					x[1], x[2], x[4] = 1+x[2], 0, 0
				else
					# 0A0B -> AB00
					x[1], x[2], x[4] = x[2], x[4], 0
				end
			else
				# 0AXX
				if x[3] == x[2]
					# 0AAX -> 2AX00
					x[1], x[2], x[3], x[4] = 1+x[2], x[4], 0, 0
				elseif x[3] == x[4]
					# 0ABB -> A2B00
					x[1], x[2], x[3], x[4] = x[2], 1+x[3], 0, 0
				else
					# 0ABC -> ABC0
					x[1], x[2], x[3], x[4] = x[2], x[3], x[4], 0
				end
			end
		end
	else
		# AXXX
		if x[2] == 0
			# A0XX
			if x[3] == 0
				if x[4] == x[1]
					# A00A -> a000
					x[1], x[4] = 1+x[1], 0
				else
					#A00B
					x[2], x[4] = x[4], 0
				end
			else
				# A0XX
				if x[3] == x[1]
					#A0AX -> # 2AX00
					x[1], x[2], x[3], x[4] = 1+x[1], x[4], 0, 0
				elseif x[3] == x[4]
					#A0BB -> A2B00
					x[2], x[3], x[4] = 1+x[3], 0, 0
				else
					#A0BC -> ABC0
					x[2], x[3], x[4] = x[3], x[4], 0
				end
			end
		else
			# AXXX
			if x[2] == x[1]
				# AAXX
				if x[3] == 0
					#AA0X -> aX00
					x[1], x[2], x[4] = 1+x[1], x[4], 0
				elseif x[3] == x[4]
					#AABB -> 2A2B00
					x[1], x[2], x[3], x[4] = 1+x[1], 1+x[3], 0, 0
				else
					#AABC -> 2ABC0
					x[1], x[2], x[3], x[4] = 1+x[1], x[3], x[4], 0
				end
			else
				# ABXX
				if x[3] == 0
					# AB0X -> ABX0
					x[3], x[4] = x[4], 0
				elseif x[3] == x[2]
					# ABBX -> A2BX0
					x[2], x[3], x[4] = 1+x[2], x[4], 0
				elseif x[3] == x[4]
					# ABCC -> ABc0
					x[3], x[4] = 1+x[4], 0
				#else
					#println("got here")
					# ABCD -> ABCD
					#x[1], x[2], x[3], x[4] = 1+x[1], x[3], x[4], 0
				end
			end
		end
	end
	x
end
