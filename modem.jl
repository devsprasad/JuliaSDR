# module modulename

# # using #dependencies

# # import #methods to overload

# # export #types/methods to export

#  #module body
#  #


function pskmodem(M::Int)
	"""
	# creates a modem object
	"""
	scheme = round(Int,log2(M));
	m = ccall((:modem_create,"libliquid"), Ptr{Void}, (Int32, ), scheme);
end

function display(modem::Ptr{Void})
	ccall((:modem_print, "libliquid"), Void, (Ptr{Void}, ), modem);
end

function getbps(modem::Ptr{Void})
	bps = ccall((:modem_get_bps, "libliquid"), Int, (Ptr{Void}, ), modem);
	return bps;
end

function destroy(modem::Ptr{Void})
	ccall((:modem_destroy, "libliquid"), Void, (Ptr{Void}, ), modem);
end

function modulate(modem::Ptr{Void} , symbol::Int)
	y = Array(Complex64,1);
	ccall((:modem_modulate, "libliquid"), Void, (Ptr{Void}, Int, Ptr{Complex64}), modem , symbol, y);
	return y[1];
end

function modulate(modem::Ptr{Void}, symbols::Array{Int})
	y = Array(Complex64,length(symbols));
	for i in range(1, length(symbols))
		y[i] = modulate(modem, symbols[i]);
	end
	return y;
end

function demodulate(modem::Ptr{Void}, mod::Complex64)
	x = Array(Int, 1);
	ccall((:modem_demodulate, "libliquid"), Void, (Ptr{Void}, Complex64, Ptr{Int}), modem , mod, x );
	return x[1];
end

function demodulate(modem::Ptr{Void}, mods::Array{Complex64})
	y = Array(Int,length(mods));
	for i in range(1, length(mods))
		y[i] = demodulate(modem, mods[i]);
	end
	return y;
end

# end