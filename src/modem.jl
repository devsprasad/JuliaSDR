module modem



export pskmodem,
      display,
      getbps,
      destroy,
      modulate,
      demodulate,
      MODEM_SCHEME

 #module body
 #


function pskmodem(M::Int)
	scheme = round(Int,log2(M));
	m = ccall((:modem_create,"libliquid"), Ptr{Void}, (Int32, ), scheme);
end

function dpskmodem(M::Int)
	scheme = round(Int,log2(M)) + 8;
	m = ccall((:modem_create,"libliquid"), Ptr{Void}, (Int32, ), scheme);
end

function askmodem(M::Int)
	scheme = round(Int,log2(M)) + 16;
	m = ccall((:modem_create,"libliquid"), Ptr{Void}, (Int32, ), scheme);
end

function qammodem(M::Int)
	scheme = round(Int, log2(M))
	if(scheme <= 1)
	  error("QAM2 is not possible")
	else
		scheme = scheme + 23;
		m = ccall((:modem_create,"libliquid"), Ptr{Void}, (Int32, ), scheme);
		return m;
	end
end

@enum MODEM_SCHEME PSK=1 DPSK ASK QAM

function create_modem(scheme::MODEM_SCHEME, M::Int)
	if(scheme == PSK)
		m = pskmodem(M);
	elseif(scheme == ASK)
		m = askmodem(M);
	elseif(scheme == DPSK)
		m = dpskmodem(M);
	elseif(scheme == QAM)
		m = qammodem(M);
	end
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

function count_biterrors(x::Int, y::Int)
	err = ccall((:count_bit_errors, "libliquid"), Int, (Int, Int), x,y );
	return err;
end

function count_biterrors(x::Array{Int}, y::Array{Int})
	if(length(x) == length(y))
		errors = Array(Int, length(x))
		for i in range(1,length(x))
			errors[i] = count_biterrors(x[i], y[i]);
		end
		return errors;
	else
		error("x and y must be of same length")
	end
end

end
