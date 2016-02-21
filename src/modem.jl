module modem

export Modem, create_modem, modulate, demodulate,display,
       getbps,getM, destroy, count_biterrors, PSK, DPSK, 
       ASK, QAM


const PSK="psk"
const DPSK="dpsk"
const ASK="ask"
const QAM="qam"

immutable Modem
	scheme::AbstractString
	M::Int
	modemObjPtr::Ptr{Void}
end


function pskmodemPtr(M::Int)
	scheme = round(Int,log2(M));
	m = ccall((:modem_create,"libliquid"), Ptr{Void}, (Int32, ), scheme);
end

function dpskmodemPtr(M::Int)
	scheme = round(Int,log2(M)) + 8;
	m = ccall((:modem_create,"libliquid"), Ptr{Void}, (Int32, ), scheme);
end

function askmodemPtr(M::Int)
	scheme = round(Int,log2(M)) + 16;
	m = ccall((:modem_create,"libliquid"), Ptr{Void}, (Int32, ), scheme);
end

function qammodemPtr(M::Int)
	scheme = round(Int, log2(M))
	if(scheme <= 1)
	  error("QAM2 is not possible")
	else
		scheme = scheme + 23;
		m = ccall((:modem_create,"libliquid"), Ptr{Void}, (Int32, ), scheme);
		return m;
	end
end



function create_modem(scheme::AbstractString)
	scheme = uppercase(scheme);
	if(scheme == "QPSK")
		return create_modem(PSK, 4);
	else
		try
			if(startswith(scheme,"PSK"))
				M = parse(Int, replace(scheme, "PSK", ""));
				return create_modem(PSK, M);
			elseif(startswith(scheme, "DPSK"))
				M = parse(Int, replace(scheme, "DPSK", ""));
				return create_modem(PSK, M);
			elseif(startswith(scheme, "ASK"))
				M = parse(Int, replace(scheme, "ASK", ""));
				return create_modem(PSK, M);
			elseif(startswith(scheme, "QAM"))
				M = parse(Int, replace(scheme, "QAM", ""));
				return create_modem(PSK, M);
			else
				error("unknown modulation scheme : ", scheme );
			end
		catch
			error("unknown modulation scheme : ", scheme);
		end
	end
end


function create_modem(scheme::AbstractString, M::Int)
	if(scheme == PSK)
		func = pskmodemPtr;
	elseif(scheme == ASK)
		func = askmodemPtr;
	elseif(scheme == DPSK)
		func = dpskmodemPtr;
	elseif(scheme == QAM)
		func = qammodemPtr;
	else
		error("unknown modulation scheme : " , scheme);
	end
	return Modem(scheme, M, func(M));
end

function display(modem::Modem)
	ccall((:modem_print, "libliquid"), Void, (Ptr{Void}, ), modem.modemObjPtr);
end

function getbps(modem::Modem)
	bps = ccall((:modem_get_bps, "libliquid"), Int, (Ptr{Void}, ), modem.modemObjPtr);
	return bps;
end

function getM(modem::Modem)
	return modem.M;
end

function destroy(modem::Modem)
	ccall((:modem_destroy, "libliquid"), Void, (Ptr{Void}, ), modem.modemObjPtr);
end

function modulate(modem::Modem , symbol::Int)
	y = Array(Complex64,1);
	M = modem.M;
	if(symbol > (M-1))
		error("symbol exceeds constellation size (maximum = " , (M-1), ")");
	end
	ccall((:modem_modulate, "libliquid"), Void, (Ptr{Void}, Int, Ptr{Complex64}), 
		modem.modemObjPtr , symbol, y);
	return y[1];
end

function modulate(modem::Modem, symbols::Array{Int})
	y = Array(Complex64,length(symbols));
	for i in range(1, length(symbols))
		y[i] = modulate(modem.modemObjPtr, symbols[i]);
	end
	return y;
end

function demodulate(modem::Modem, mod::Complex64)
	x = Array(Int, 1);
	ccall((:modem_demodulate, "libliquid"), Void, (Ptr{Void}, Complex64, Ptr{Int}), 
		modem.modemObjPtr , mod, x );
	return x[1];
end

function demodulate(modem::Modem, mods::Array{Complex64})
	y = Array(Int,length(mods));
	for i in range(1, length(mods))
		y[i] = demodulate(modem.modemObjPtr, mods[i]);
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
