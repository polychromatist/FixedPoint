# FixedPoint

 why a fixed point library?
 1.  https://stackoverflow.com/questions/20963419/cross-platform-floating-point-consistency
     in summary: Floating point values are inconsistent cross-platform; small errors are not deterministic on each system.
 1b. Reducing floating point precision does not snuff out edge cases (see link).
 2.  I haven't found a pure Lua fixed-point implementation.
 3.  Fixed-point values are a solution for building a deterministic game state that can become necessary in lockstep networking.

 The basic math operators of addition, subtraction, multiplication, and division correspond to the following methods:
 
 `#add(a, b, ignoreOverflow*, errorlevel*)`
 
 `#sub(a, b, ignoreOverflow*, errorlevel*)`
 
 `#mult(a, b, policy*, ignoreOverflow*, errorlevel*)`
 
 `#div(a, b, policy*, ignoreOverflow*, errorlevel*)`
 
 \* optional.

 There are also trigonometric and exponential functions / operators with implementations in separate files.\
 On ROBLOX, you can parent them as ModuleScripts to this ModuleScript and it will try to pick up on them.

## Implementation Notes (referenced by comments in source)

 `_MAX_RADIUS`: note A1\
   why not 15? you can try it. the divison implementation may exhibit unknown behavior at edge-case size large numerator (i.e. `9e14`).\
   why not 16? the value `FLINTMAX = 2^53 (9007199254740992)` is the last double that can represent an integer safely.\
   16 refers to 16 digits, which FLINTMAX contains, so higher doubles are unsafe.
   "what do you mean safely?" i mean that `FLINTMAX + 1 == FLINTMAX`. thus, it is not a safe integer.
	
 `FixedPoint` class: note A2\
   This class produces high level objects for interpreting and working with fixed point numbers.\
   A fixed point number is an integer paired with a radix point, logically breaking the integer into a whole and fractional part.\
   The lower level class will be represented by doubles d with floor(d) == d and d - 1 < d, i.e. an integer.

 `RADIUS` positive integer: note A3\
   this represents place of digit in the integer that is the max distance from least significant digit (powers of 10)
   This is effectively a digit length for any given fixed point value, negative or positive
   Largest RADIUS is 14 because 10^15 is the last double that maps directly to an integer representation without rounding error
   (according to https://www.lua.org/pil/2.3.html)

 `RADIX_POINT` positive integer: note A4\
   this is where the 'decimal place' ought to be, in distance from least significant digit\
   (e.g. radius 4 radix 2, numbers are of the form '51.23')\
   more formally, it is the log base 10 of the reciprocal of the scaling factor ( radix point R corresponds to scaling factor 1/10^R )\
   must be an integer exclusively between 0 and 7. i recommend choosing an even radix, and as high as possible.

 `ROUND_POLICY` string or function: note A5\
   used on multiplication and division to decide how to round result of operation, accepts enum or function\
   if function, format should be:\
```lua
function(int, frac, RHS_VAL)
	[...]
	return <boolean: int_magnitude_needs_increment>
end
```
   int is the integer whole part, frac is the integer fractional part, and both numbers are in fixed point context ( returned by `#split()` )\
   `RHS_VAL` is the smallest difference between two rounded values (typically `RADIX_RHS_VAL`), can be considered "one"\
   note: return `true` if int needs to be increased IN MAGNITUDE by one, by your judgment. otherwise, the int itself will be the rounding result.

 note A6
   if `RADIX_POINT` is too large, then when multiplying fractional parts, we may end up in a space that is 10^14 large, at which point\
   doubles start to creep up in value too high. at that point, the underlying double values may not discretize to integers correctly\
   this limitation also allows flexibility for implementation.

 RADIX_RHS_VAL fixed point constant: note A7
   `RADIX_RHS_VAL` contains the smallest number where the virtual radix point is to the right hand side of a non-zero digit\
   useful in masklike operations (i.e. split a fixed point value into its fractional and whole parts)\
   it's also the reciprocal of the *scaling factor*\
   for all intents and purposes, this is the literal number, `ONE`

 FixedPoint#mult() function: note A8\
 # GENERAL MULTIPLICATION\
   the radix point "moves" a distance double that of its original from the least significant digit\
   (e.g. radius 5 radix 2, 010.00 * 010.00 = 100.0000)\
   however, the intermediate underlying integer representation can become large with this method, so a new one is advisable\
   raws will be split into two components, much like math.fmod\
 ## FRACTIONAL PARTS\
   0.099 is represented by 99. note 0.099 * 0.099 = 0.009801, whereas 99 * 99 = 9801.\
   alternative way to view the integer multiplication is 099 * 099 = 009801, where the first three are the main fractional product\
   the reason we have a six digit result is because we are multiplying in spaces of 1e3 and 1e3, which yields a space of 1e6 as a product\
   the least significant three digits are unnecessary for all but rounding policy\
 ### PLEASE NOTE DUE TO ROUNDING THAT FIXED POINT MULTIPLICATION IS ONLY ASSOCIATIVE WITHIN THAT ROUNDING ERROR MARGIN\
   the following paper "Synthesis of Fixed-Point Programs" provides examples of errors of up to 0.00311\
 ### PERFORMANCE NOTE\
   if you wish to maximize performance, with small enough values (product space less than 1e15), you may write:\
```lua
	local product = raw1 * raw2
	product = (product - math.fmod(product, fix.RADIX_RHS_VAL)) / fix.RADIX_RHS_VAL
```

 FixedPoint#div() function: note A9\
# DIVISION\
   consider dividing simply by one, in a fixed point context of radius 5 and radix 2:\
     123.45 / 001.00 = 123.45\
   underneath, we would be dividing by 100. thus, we have to first multiply the dividend by 100 (`RADIX_RHS_VAL`) to get the right result.\
   this is safe at radius 5, but at radius 14, it is dangerous. so, we must employ two doubles to represent the intermediate dividend, when needed.\
## USE OF FLOATING POINT DIVISION
   floating point division (native Lua division) is OK to use under the hood because numbers are double precision, so we should expect\
   cross platform accuracy up to our max radius. according to IEEE, double values have 15 decimal digits of precision.\
   it is this limit itself that restricts our choice of `_MAX_RADIUS` to 14.\
   (we would be at an unacceptable performance compromise to try implementing a division algorithm)
 
### PERFORMANCE NOTE   
   i don't boast about the lofty cost these wrapper functions incur for a simple operator. if you want better performance, here is an alternative:\
```lua
	raw1 = raw1 * self.RADIX_RHS_VAL
	local quotient = (raw1 - math.fmod(raw1, raw2)) / raw2
```
   but the numerator must be small, such that multiplying by `self.RADIX_RHS_VAL` will not land it in a space of 1e15\
   for radix point six, the numerator must be less than 100.000000 (1e9)

 large urmr case: note B1\
   here, if we scale urmr by RHS_VAL then it WILL go beyond 1e15, which is not allowable\
   so instead, we have no choice but to scale raw2 down and urmr up only slightly.\
   for example, at radix point 6, radius 14, ldlhsv is 1e9. if we attempt to divide numbers:\
   33554432.000000 / 66466672.494525\
   urmr is unum, which is 33554000.000000\
   this would be 3.3554e+19 if scaled, which is a dangerous double.\
   instead, we do 335544320.000000 / 0000066.4666724\
   for this special case, it will give an approximate result. we are losing some information given by the fractional part.\
   this will have a very minor effect on edge cases where urmr > ldlhsv.\
   it depends on how important small variations in the remainder are to the quotient.\
   e.g. 1000.055555 / 1001.495252 = 0.998562 translates to 10000.555550 div 0000.010015 = 0000.998557 or 0000.998558 (error of 0.000005)\
   two dozen tests of 2048 random divisions with radius 14 radix point 6 showed largest deviation as follows:\
```lua
	Test: 2048 random pairs, comparison with native Lua division
	>>> the largest error is 1.558443182148e-05
	>>> the expression producing the error is div( 91445222.018711 , -00001525.234388 ) = -00059954.865142
```

 FixedPoint#mustEnlarge() function: note B2\  
   this is the core method to rounding logic\   
   #mustEnlarge() should return truthy value iff the integer portion must be made larger IN MAGNITUDE by 1 when rounding\
   so if the integer is negative, return true to add negative one. if it is positive, return true to add one.\
   false will yield no operation.\
   if you provide a custom policy function, this is exactly the expected behavior it should have!\
 FixedPoint#genRand() function: note B3\
   get a random fixed point value from this context\
   you can provide a function randfn with the following specification: `number randfn(FixedPoint fix)`\
   where the returned number lies within the fixed point context given by the parameter fix\
   otherwise default randfn will be used! (you can set this per-instance with setRandFn, or classwide by overloading "RAND_FN" in a module)\
   (note: returned number of randfn shall be floored)

 FixedPoint#asValue() function: note B4\   
   this function will attempt to construct a value that is valid in the fixed point context given the whole part\
   and a fractional part that is multiplied by 10^6. for example, 1.225 can be representing as the following: `local nineFortieths = fix:asValue(1, 225000)`\
   NOTE: even if the radix point in use is not 6, the fractional part MUST be expressed in that manner.\
   given the example above, you can use asValue as a radix-point-invariant way to express fixed point values.\
   the fixed point context will try its best to represent these parts as a value, rounding where needed.

 sqrt algorithm: note B5\
 for `raw >= one`:\
 starting at p = 0, incrementing, i choose x_0 according to 2^p <= x < 2^(p+1).\
 `x_0 = 2^(p/2 + 1/4)`
 for `raw < one`:
 starting at p = 0, incrementing, i choose x_0 according to 2^p <= 1/x < 2^(p-1)
 `x_0 = 2^-(p/2 + 1/4)`

 FixedPoint#multOvf() function: note B6
 the "overmultiply" method, multOvf, will return the coefficient on overflow that the resultant product is closest to.\
 that is, it will return a fixed point value F where technically
 
	mult(raw1 , raw2) = mult(F , OVERFLOW_VAL)  

 that is to say, one factor of `OVERFLOW_VAL` is invisible in the result (this is called an overproduct).\
 note: `OVERFLOW_VAL = 10^RADIUS`, but represents `10^(RADIUS - RADIX_POINT)` in fixed point context.\
 this can be used on any fixed value pair and there will be no overflow.\
 if F is `ONE` or higher, multiplying this pair normally would produce overflow.\
 using this function, you can take ratios of, or get a value for large products.\
 **warning**: these values are coefficients on `OVERFLOW_VAL`, and in that respect, they are not regular fixed point values.
 
          if you multiply this coefficient with a regular fixed point value, the product is another coefficient, still on OVERFLOW_VAL.
            i.e. (X * OVERFLOW_VAL) * Y = (X * Y) * OVERFLOW_VAL  OVERFLOW_VAL being treated as an invisible factor.
	    
          if you overmultiply it with a regular fixed point value, a factor of OVERFLOW_VAL is removed, yielding a regular value as a product.
            i.e. ((X * OVERFLOW_VAL) * Y) / OVERFLOW_VAL = X * Y
	    
          if you overmultiply it with another coefficient, you get a new coefficient.
            i.e. ((X * OVERFLOW_VAL) * (Y * OVERFLOW_VAL)) / OVERFLOW_VAL = (X * Y) * OVERFLOW_VAL
	    
take care when performing operations with these values.
